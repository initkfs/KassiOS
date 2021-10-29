/**
 * Authors: initkfs
 */
module os.core.fs.memfs.memfs;

import Allocator = os.core.mem.allocator;
import Partition = os.core.fs.memfs.memfs_partition;
import File = os.core.fs.memfs.memfs_file;

import Kstdio = os.std.io.kstdio;

private
{
	__gshared Partition.MemfsPartition* rootPartition;
}

bool isMount()
{
	return rootPartition !is null;
}

string getRootParitionId()
{
	if (!isMount)
	{
		return "";
	}

	return Partition.getPartitionId(rootPartition);
}

string getRootMountPoint()
{
	if (!isMount || !rootPartition.mountPoint)
	{
		return "";
	}
	return File.getFileName(rootPartition.mountPoint);
}

void mount(string id = "/", string mountPoint = "home")
{
	if (isMount)
	{
		return;
	}
	rootPartition = Partition.createPartition(id);

	File.MemfsFile* homeDirectory = File.createDir("home");
	rootPartition.mountPoint = homeDirectory;
}

void unmount()
{
	if (!isMount)
	{
		return;
	}

	Partition.deletePartition(rootPartition);
	rootPartition = null;
}

bool createFile(string name)
{
	if (!isMount)
	{
		return false;
	}
	return File.createFile(name, rootPartition.mountPoint) !is null;
}

void list()
{
	if (!isMount || !rootPartition.mountPoint)
	{
		return;
	}

	Kstdio.kprintln;

	auto rootDir = rootPartition.mountPoint;
	Kstdio.kprint(getRootMountPoint);
	Kstdio.kprint('/');
	Kstdio.kprintln;

	auto file = rootDir.next;
	while (file)
	{
		Kstdio.kprintln(File.getFileName(file));
		file = file.next;
	}
}

bool write(string fileName, string data)
{
	if (!isMount)
	{
		return false;
	}

	auto file = File.findFile(fileName, rootPartition.mountPoint);
	if (!file)
	{
		return false;
	}

	bool isWrite = File.write(file, cast(ubyte[]) data);
	return isWrite;
}

string read(string fileName)
{
	if (!isMount || fileName.length == 0)
	{
		return "";
	}

	auto file = File.findFile(fileName, rootPartition.mountPoint);
	if (!file)
	{
		return "";
	}

	string data = File.readString(file);
	return data;
}
