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
  echo "$scriptName error: incorrect script source directory $scriptDir, exit." >&2
  exit 1
fi
#Start script

testMode=0
case "$1" in
  --test)
	testMode=1
    echo "Test mode on"
    ;;
esac

buildDir=$scriptDir/uefi-build
uefiBootDir=$scriptDir/uefi
uefiStartupScript=startup.nsh

dub build --compiler=ldc2 --config=uefi
errDub=$?
if [[ $errDub -ne 0 ]]; then
  echo "Dub error, exit." >&2
  exit 1
fi

x86_64-w64-mingw32-gcc -nostdlib -Wl,-dll -shared -Wl,--subsystem,10 -e efi_main -o "$uefiBootDir/kernel.efi" "$buildDir/libkernel.a"
errGcc=$?
if [[ $errGcc -ne 0 ]]; then
  echo "GCC error, exit." >&2
  exit 1
fi

startupScript=$uefiBootDir/$uefiStartupScript
if [[ ! -f $startupScript ]]; then
  startupScriptForCopy=$scriptDir/$uefiStartupScript
  cp "$startupScriptForCopy" "$startupScript"
    if [[ $? -ne 0 ]]; then
    echo "Unable to copy startup script $startupScriptForCopy to boot script $startupScript" >&2
    exit 1
  fi
fi

qemu-system-x86_64 \
	-drive if=pflash,format=raw,file=$scriptDir/ovmf/OVMF.fd \
	-drive format=raw,file=fat:rw:"$uefiBootDir" \
	-net none \