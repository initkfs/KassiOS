#!/usr/bin/env bash
#script name
scriptName="$(basename "$([[ -L "$0" ]] && readlink "$0" || echo "$0")")"
if [[ -z $scriptName ]]; then
  echo "Error, script name is empty. Exit" >&2
  exit 1
fi
#script directory
_source="${BASH_SOURCE[0]}"
while [[ -h "$_source" ]]; do
  _dir="$( cd -P "$( dirname "$_source" )" && pwd )"
  _source="$(readlink "$_source")"
  [[ $_source != /* ]] && _source="$_dir/$_source"
done
scriptDir="$( cd -P "$( dirname "$_source" )" && pwd )"
if [[ ! -d $scriptDir ]]; then
  echo "$scriptName error: incorrect script source directory $scriptDir, exit" >&2
  exit 1
fi
#Start script

buildDir=$scriptDir/build
osImageDir=$scriptDir/iso

if [[ -e $buildDir ]]; then
	gio trash -f "$buildDir"
	if [[ $? -ne 0 ]]; then
		echo "Error. Cannot remove build directory: $buildDir">&2
		exit 1
	fi
fi

mkdir "$buildDir"
if [[ $? -ne 0 ]]; then
	echo "Error. Unable to create build directory: $buildDir">&2
	exit 1
fi
	
if [[ -e $osImageDir ]]; then
	gio trash -f "$osImageDir"
	if [[ $? -ne 0 ]]; then
		echo "Error. Cannot remove image directory: $osImageDir">&2
		exit 1
	fi
fi

mkdir "$osImageDir"
	if [[ $? -ne 0 ]]; then
	echo "Error. Unable to create os image directory: $osImageDir">&2
	exit 1
fi

osImageBootFiles=$osImageDir/boot

grubDir=$osImageBootFiles/grub
	mkdir -p "$grubDir"
	if [[ $? -ne 0 ]]; then
		echo "Error. Unable to create grub directory: $grubDir" >&2
		exit 1
	fi

sourceDir=$scriptDir/src
if [[ ! -d $sourceDir ]]; then
	echo "Error. Not found source directory: $sourceDir">&2
	exit 1
fi

sourceAsmDir=$sourceDir/boot
if [[ ! -d $sourceAsmDir ]]; then
	echo "Error. Not found directory with assembly sources: $sourceAsmDir">&2
	exit 1
fi

pushd .
cd "$sourceAsmDir"
if [[ $? -ne 0 ]]; then
	echo "Error. Cannot set current directory for asm files: $sourceAsmDir">&2
	exit 1
fi

asmSources=$(find "$sourceAsmDir" -type f -name "*.asm")
while read -r asmSourceFile;
do
	fullName=${asmSourceFile##*/}
	fileName="${fullName%.*}"
	nasm -f elf64 -g -o "$buildDir/${fileName}.o" "$asmSourceFile"
	if [[ $? -ne 0 ]]; then
		echo "NASM error" >&2
		exit 1
	fi
done <<EOF
$asmSources
EOF

popd

zig build
if [[ $? -ne 0 ]]; then
	echo "Zig build error" >&2
	exit 1
fi

#dmd -betterC -map -vtls -m64 -i=app.core.main_controller  -boundscheck=off -release -c $sourceDir/kernel.d -of=$buildDir/kernel.o
#ldc2 -nogc -g -betterC -boundscheck=off -c -od="$buildDir" "$dSourceFile"
dub build --arch=x86_64
if [[ $? -ne 0 ]]; then
	echo "Dub build error" >&2
	exit 1
fi

kernelPath=$osImageBootFiles/kernel.bin

ld -n -o -T "${scriptDir}/linker.ld" -o "$kernelPath" "$buildDir"/*.o* "$scriptDir/zig-out/lib"/*.a*
if [[ $? -ne 0 ]]; then
	echo "Linker error" >&2
	exit 1
fi

grub-file --is-x86-multiboot2 "$kernelPath"
if [[ $? -ne 0 ]]; then
	echo "Kernel is not a multiboot2 image: $kernelPath" >&2
	exit 1
fi

grubConfig=$scriptDir/grub.cfg
cp -rf "$grubConfig" "$grubDir/grub.cfg"
if [[ $? -ne 0 ]]; then
	echo "Error. Cannot copy grub config $grubConfig to grub directory: $grubDir" >&2
	exit 1
fi

osFile=$scriptDir/os.iso
if [[ -f $osFile ]]; then
rm "$osFile"
if [[ $? -ne 0 ]]; then
	echo "Error. Cannot remove os file: $osFile" >&2
	exit 1
fi
fi

grub-mkrescue -o "$osFile" "$osImageDir" 
if [[ $? -ne 0 ]]; then
	echo "Error. Cannot create rescue iso image: $osFile" >&2
	exit 1
fi

#https://stackoverflow.com/questions/6142925/how-can-i-use-bochs-to-run-assembly-code
#https://stackoverflow.com/questions/43786251/int-13h-42h-doesnt-load-anything-in-bochs
#bochs -qf /dev/null -rc "$__dir/bochs_debug.rc" 'clock: sync=realtime, time0=local' ' display_library: x, options="gui_debug' 'megs: 128' 'boot: c' "ata0-master: type=disk, path=$osFile, mode=flat, cylinders=0, heads=0, spt=0, model=\"Generic 1234\", biosdetect=auto, translation=auto"

#'display_library: x, options = "gui_debug"'
#bochs -qf /dev/null 'boot: cdrom' 'display_library: sdl' 'vga: extension=vbe, update_freq=5' 'clock: sync=none, time0=local, rtc_sync=1' 'cpu: count=1, ips=200000000' 'cpuid: x86_64=1, mmx=1, sep=1, sse=sse4_2' 'com1: enabled=1, mode=file, dev=serial.txt' 'megs: 64' "ata0-slave: type=cdrom, path=$osFile, status=inserted"

#memory size over 64M may give a mapping error for ACPI (Page Fault) due to the small number of page tables
qemu-system-x86_64 -serial file:serial.txt -soundhw pcspk -d int,cpu_reset -s -m 64M -cdrom $osFile -monitor stdio
