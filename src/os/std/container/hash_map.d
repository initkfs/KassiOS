/**
 * Authors: initkfs
 */
module os.std.container.hash_map;

import std.traits;

import os.std.errors;

private
{
	alias Allocator = os.core.mem.allocator;
	alias List = os.std.container.linear_list;
	alias Strings = os.std.text.strings;
}

struct HashMap
{
	List.LinearList* nodes;
	size_t size;
}

private struct MapNodeList
{
	MapNode* first;
}

private struct MapNode
{
	size_t key;
	MapNode* next;
	MapNodeData* data;
	size_t length;
	char[0] name;
}

private struct MapNodeData
{
	size_t length;
	size_t[0] data;
}

void insertMapNode(MapNodeList* list, MapNode* node)
{
	const size_t key = node.key;
	MapNode* previous = null;
	MapNode* current = list.first;
	while (current !is null && key > current.key)
	{
		previous = current;
		current = current.next;
	}

	if (previous is null)
	{
		list.first = node;
	}
	else
	{
		previous.next = node;
	}

	node.next = current;
}

private void freeMapNode(MapNode* node)
{
	if (node is null)
	{
		return;
	}

	if (node.data)
	{
		Allocator.free(node.data);
	}
	Allocator.free(node);
}

private void freeMapNodes(MapNodeList* list)
{
	MapNode* current = list.first;
	while (current !is null)
	{
		auto forDelete = current;
		current = current.next;
		freeMapNode(forDelete);
	}
}

void deleteMapNode(MapNodeList* list, size_t key)
{
	MapNode* previous = null;
	MapNode* current = list.first;
	while (current !is null && key != current.key)
	{
		previous = current;
		current = current.next;
	}

	MapNode* forDelete;
	if (previous == null)
	{
		list.first = list.first.next;
		forDelete = list.first;
	}
	else
	{
		previous.next = current.next;
		forDelete = current;
	}

	if (forDelete && forDelete.key == key)
	{
		freeMapNode(forDelete);
	}
}

MapNode* findMapNode(MapNodeList* list, size_t key)
{
	MapNode* current = list.first;
	while (current !is null && current.key <= key)
	{
		if (current.key == key)
		{
			return current;
		}
		current = current.next;
	}
	return null;
}

HashMap* initHashMap(size_t size = 16)
{
	auto map = cast(HashMap*) Allocator.alloc(HashMap.sizeof);

	map.nodes = List.initList!MapNodeList(size);

	foreach (i; 0 .. size)
	{
		auto s = cast(MapNodeList*) Allocator.alloc(MapNodeList.sizeof);
		s.first = null;
		List.push!(MapNodeList*)(map.nodes, s);
	}

	return map;
}

void free(HashMap* map)
{
	foreach (i; 0 .. map.nodes.length)
	{
		MapNodeList* nodeList;
		List.get!(MapNodeList*)(map.nodes, i, nodeList);
		if (nodeList is null)
		{
			continue;
		}
		freeMapNodes(nodeList);
		Allocator.free(nodeList);
	}
	Allocator.free(map.nodes);
	Allocator.free(map);
}

private size_t hashKey(HashMap* map, string key)
{
	size_t hash;
	foreach (ch; key)
	{
		const letter = ch - 96;
		hash = (hash * 27 + letter) % map.nodes.length;
	}
	return hash;
}

void put(T)(HashMap* map, const string key, T value)
{
	auto node = cast(MapNode*) Allocator.alloc(MapNode.sizeof + key.length);
	node.next = null;
	node.data = null;

	foreach (i, ch; key)
	{
		Allocator.set(node.name.ptr, ch, cast(size_t*) node, i);
	}
	node.length = key.length;

	auto dataSize = value.sizeof;
	static if (is(T == string))
	{
		dataSize = value.length;
	}

	auto dataNode = cast(MapNodeData*) Allocator.alloc(MapNodeData.sizeof + dataSize);

	static if (is(T == string))
	{
		auto dataPtr = cast(char*) dataNode.data.ptr;
		foreach (i, ch; value)
		{
			Allocator.set(dataPtr, ch, cast(size_t*) dataNode, i);
		}
	}
	else
	{
		auto dataPtr = cast(T*) dataNode.data.ptr;
		*dataPtr = value;
	}

	dataNode.length = dataSize;

	node.data = dataNode;

	const size_t hash = hashKey(map, key);
	node.key = hash;

	MapNodeList* nodeList;
	List.get!(MapNodeList*)(map.nodes, hash, nodeList);
	if (nodeList !is null)
	{
		insertMapNode(nodeList, node);
		map.size++;
	}

}

void remove(HashMap* map, string key)
{
	const hash = hashKey(map, key);
	MapNodeList* nodeList;
	List.get!(MapNodeList*)(map.nodes, hash, nodeList);
	if (nodeList is null)
	{
		return;
	}
	deleteMapNode(nodeList, hash);
}

bool containsKey(HashMap* map, string key){
	const hash = hashKey(map, key);
	MapNodeList* nodeList;
	List.get!(MapNodeList*)(map.nodes, hash, nodeList);
	return nodeList !is null;
}

MapNode* get(T)(HashMap* map, string key, ref T value)
{
	const hash = hashKey(map, key);

	MapNodeList* nodeList;
	List.get!(MapNodeList*)(map.nodes, hash, nodeList);
	if (!nodeList)
	{
		return null;
	}

	MapNode* node = findMapNode(nodeList, hash);
	MapNodeData* dataNode = node.data;

	static if (is(T == char*))
	{
		auto dataPtr = cast(char*) dataNode.data;
		string s = cast(string) dataPtr[0..dataNode.length];
		value = Strings.toStringz(s);
	}
	else
	{
		T data = cast(T)*dataNode.data.ptr;
		value = data;
	}

	return node;
}

unittest
{

	import os.std.asserts : kassert;
	import os.std.io.kstdio;
	import os.std.text.strings;

	auto map = initHashMap;
	const string key1 = "foo";
	const string value1 = "hello world";
	put!string(map, key1, value1);

	char* val;
	get!(char*)(map, key1, val);
	kassert(Strings.isEqualz(value1.ptr, val));
	Allocator.free(val);

	free(map);
}
