/**
 * Authors: initkfs
 */
module os.core.fs.memfs.memfs_partition;

private
{
	alias Allocator = os.core.mem.allocator;
	alias Syslog = os.core.logger.syslog;
	alias Strings = os.std.text.strings;
	alias MemfsFile = os.core.fs.memfs.memfs_file;
}

enum partitionIdMaxLength = 64;

struct MemfsPartition
{
	char[partitionIdMaxLength] id;
	size_t idLength;
	MemfsFile.MemfsFile* mountPoint;
};

MemfsPartition* createPartition(string id)
{
	auto partition = cast(MemfsPartition*)  Allocator.alloc(MemfsPartition.sizeof);
	partition.idLength = id.length > partitionIdMaxLength ? partitionIdMaxLength : id.length;
	partition.id = id[0..partition.idLength];
	partition.mountPoint = null;

	if (Syslog.isTraceLevel)
	{
		string[1] partitionIdArgs = [id];
		Syslog.tracef("Create partition %s", partitionIdArgs);
	}

	return partition;
}

void deletePartition(MemfsPartition* partition)
{
	if (partition.mountPoint)
	{
		auto file = partition.mountPoint;
		while (file)
		{
			if (file.fileData)
			{
				Allocator.free(file.fileData);
			}
			auto forDelete = file;
			file = file.next;
			Allocator.free(forDelete);
		}
	}

	const id = getPartitionId(partition);

	Allocator.free(partition);
	if (Syslog.isTraceLevel)
	{
		string[1] partitionIdArgs = [id];
		Syslog.tracef("Delete partition: %s", partitionIdArgs);
	}
}

string getPartitionId(MemfsPartition* partition)
{
	if (partition.idLength == 0 || partition.idLength > partitionIdMaxLength)
	{
		return "";
	}

	return cast(string) partition.id[0 .. partition.idLength];
}
