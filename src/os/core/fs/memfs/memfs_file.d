/**
 * Authors: initkfs
 */
module os.core.fs.memfs.memfs_file;

import os.core.fs.memfs.memfs_partition;

import Allocator = os.core.mem.allocator;
import Strings = os.std.text.strings;

enum fileNameMaxLength = 64;

struct MemfsFile
{
    char[fileNameMaxLength] name;
    size_t nameLength;
    bool isDir;
    MemfsFileData* fileData;
    MemfsFile* next;
}

struct MemfsFileData
{
    size_t length;
    size_t* data;
}

string getFileName(MemfsFile* file)
{
    if (file.nameLength == 0 || file.nameLength > fileNameMaxLength)
    {
        return "";
    }

    return cast(string) file.name[0 .. file.nameLength];
}

MemfsFile* createDir(string name)
{
    auto file = createFile(name);
    file.isDir = true;
    return file;
}

MemfsFile* createFile(string name, MemfsFile* dir = null)
{
    auto file = cast(MemfsFile*) Allocator.alloc(MemfsFile.sizeof);
    file.nameLength = name.length > fileNameMaxLength ? fileNameMaxLength : name.length;
    file.name = name[0 .. (file.nameLength)];
    file.isDir = false;
    file.fileData = null;
    file.next = null;

    if (dir)
    {
        if (dir.next)
        {
            file.next = dir.next;
        }

        dir.next = file;
    }

    return file;
}

//TODO name only
MemfsFile* findFile(string name, MemfsFile* rootDir)
{
    auto node = rootDir;
    while (node)
    {
        if (Strings.isEquals(getFileName(node), name))
        {
            return node;
        }
        node = node.next;
    }

    return null;
}

bool write(MemfsFile* file, ubyte[] data)
{
    if (data.length == 0)
    {
        return false;
    }

    auto fileData = cast(MemfsFileData*) Allocator.alloc(MemfsFileData.sizeof);

    const dataLength = data.length;
    auto dataPtr = Allocator.alloc(dataLength);
    auto dataBuff = cast(ubyte*) dataPtr;
    foreach (i, d; data)
    {
        Allocator.set(dataBuff, d, dataPtr, i);
    }

    fileData.data = dataPtr;
    fileData.length = dataLength;
    file.fileData = fileData;
    return true;
}

ubyte[] read(MemfsFile* file, size_t length)
{
    if (!file.fileData)
    {
        return null;
    }

    auto fileData = file.fileData;
    if (length > fileData.length)
    {
        return null;
    }

    auto dataBuff = cast(ubyte*) fileData.data;
    return dataBuff[0 .. length];
}

string readString(MemfsFile* file)
{
    if (!file.fileData)
    {
        return "";
    }

    const length = file.fileData.length;
    ubyte[] data = read(file, length);
    if (!data || data.length != length)
    {
        return "";
    }

    return cast(string) data[0 .. length];
}
