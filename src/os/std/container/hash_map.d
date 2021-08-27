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

private string getMapNodeKey(MapNode* node)
{
	if (node is null || node.length == 0)
	{
		return "";
	}
	return cast(string) node.name[0 .. node.length];
}

private err insertMapNode(MapNodeList* list, MapNode* node)
{
	if (node is null)
	{
		return error("Unable to insert hashmap node: node is null");
	}

	const string key = getMapNodeKey(node);
	if (Strings.isBlank(key))
	{
		return error("Unable to insert hashmap node: node key is empty or null");
	}

	MapNode* previous = null;
	MapNode* current = list.first;
	while (current !is null && Strings.compare(key, getMapNodeKey(current)) == 1)
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
	return null;
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

private err removeMapNode(MapNodeList* list, string key)
{
	if (Strings.isBlank(key))
	{
		return error("Unable to remove hashmap node: key is empty or null");
	}

	MapNode* previous = null;
	MapNode* current = list.first;
	while (current !is null && !Strings.isEquals(key, getMapNodeKey(current)))
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

	if (forDelete is null)
	{
		return error("Unable to remove hashmap node: node is null");
	}

	if (!Strings.isEquals(getMapNodeKey(forDelete), key))
	{
		return error("Unable to remove hashmap node: node keys are not equal");
	}

	freeMapNode(forDelete);
	return null;
}

private MapNode* findMapNode(MapNodeList* list, string key)
{
	if (Strings.isBlank(key))
	{
		return null;
	}

	MapNode* current = list.first;
	while (current !is null && (Strings.compare(getMapNodeKey(current), key) <= 0))
	{
		if (Strings.isEquals(getMapNodeKey(current), key) && getMapNodeKey(current).length != 0)
		{
			return current;
		}
		current = current.next;
	}
	return null;
}

HashMap* initHashMap(size_t initCapacity = 16)
{
	auto map = cast(HashMap*) Allocator.alloc(HashMap.sizeof);
	map.size = 0;

	map.nodes = List.initList!MapNodeList(initCapacity);

	foreach (i; 0 .. initCapacity)
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

err put(T)(HashMap* map, const string key, T value)
{
	if (Strings.isBlank(key))
	{
		return error("Unable to insert into map: key must not be empty");
	}

	static if (isPointer!T)
	{
		if (value is null)
		{
			return error("Unable to insert into map: value pointer must not be null");
		}
	}

	static if (is(T == string))
	{
		if (value is null)
		{
			return error("Unable to insert into map: string value must not be null");
		}
	}

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

	MapNodeList* nodeList;
	List.get!(MapNodeList*)(map.nodes, hash, nodeList);
	if (nodeList is null)
	{
		return error("Unable to insert into map: not found node list by key hash");
	}

	const insertErr = insertMapNode(nodeList, node);
	if (insertErr)
	{
		return insertErr;
	}
	map.size++;
	return null;
}

err remove(HashMap* map, string key)
{
	if (Strings.isBlank(key))
	{
		return error("Unable to remove from map: key must not be empty");
	}

	const hash = hashKey(map, key);
	MapNodeList* nodeList;
	List.get!(MapNodeList*)(map.nodes, hash, nodeList);
	if (nodeList is null)
	{
		return error("Unable to remove from map: not found node list by key hash");
	}

	const removeErr = removeMapNode(nodeList, key);
	return removeErr;
}

bool containsKey(HashMap* map, string key)
{
	const hash = hashKey(map, key);
	if (hash >= map.nodes.length)
	{
		return false;
	}
	MapNodeList* nodeList;
	List.get!(MapNodeList*)(map.nodes, hash, nodeList);
	if (nodeList is null)
	{
		return false;
	}
	auto node = findMapNode(nodeList, key);
	return node !is null;
}

private err getNodeValue(T)(MapNode* node, ref T value)
{
	if (node is null)
	{
		return error("Unable to get value from node: node is null");
	}

	MapNodeData* dataNode = node.data;
	if (!dataNode)
	{
		return error("Unable to get value from node: data is null");
	}

	static if (is(T == char*))
	{
		auto dataPtr = cast(char*) dataNode.data;
		string s = cast(string) dataPtr[0 .. dataNode.length];
		value = Strings.toStringz(s);
	}
	else
	{
		T* dataPtr = cast(T*) dataNode.data.ptr;
		T data = cast(T)*dataPtr;
		value = data;
	}
	return null;
}

err get(T)(HashMap* map, string key, ref T value)
{
	if (Strings.isBlank(key))
	{
		return error("Unable to get value from map: key must not be empty");
	}

	const hash = hashKey(map, key);

	MapNodeList* nodeList;
	List.get!(MapNodeList*)(map.nodes, hash, nodeList);
	if (!nodeList)
	{
		return error("Unable to get value from map: not found node list by key");
	}

	MapNode* node = findMapNode(nodeList, key);
	if (node is null)
	{
		return error("Unable to get value from map: not found node by key");
	}

	T nodeValue;
	const valueErr = getNodeValue!T(node, nodeValue);
	if (valueErr)
	{
		return valueErr;
	}

	value = nodeValue;

	return null;
}

//TODO iterator
err byKeyValue(T)(HashMap* map, void delegate(string key, T value) onValue)
{
	foreach (i; 0 .. map.nodes.length)
	{
		MapNodeList* nodeList;
		const getErr = List.get!(MapNodeList*)(map.nodes, i, nodeList);
		if (getErr)
		{
			return getErr;
		}

		if (nodeList is null)
		{
			return error("Unable to iterate map: node list is null");
		}

		MapNode* current = list.first;
		while (current !is null)
		{
			string key = getMapNodeKey(current);
			T value;
			const valueErr = getNodeValue(current);
			if (valueErr)
			{
				return valueErr;
			}
			onValue(key, value);
			current = current.next;
		}
	}
}

unittest
{
	import os.std.asserts : kassert;
	import os.std.math.math_core : isEquals;

	auto map = initHashMap(2);
	const string key1 = "foo";
	const string value1 = "bar";
	const putErr1 = put!string(map, key1, value1);
	kassert(putErr1 is null);
	kassert(containsKey(map, key1));
	kassert(map.size == 1);

	char* val1;
	const getErr1 = get!(char*)(map, key1, val1);
	kassert(getErr1 is null);
	kassert(Strings.isEqualz(value1.ptr, val1));
	Allocator.free(val1);

	const string key2 = "bar";
	const string value2 = "baz";
	const putErr2 = put!string(map, key2, value2);
	kassert(putErr2 is null);
	kassert(containsKey(map, key2));
	kassert(map.size == 2);

	char* val2;
	const getErr2 = get!(char*)(map, key2, val2);
	kassert(getErr2 is null);
	kassert(Strings.isEqualz(value2.ptr, val2));
	Allocator.free(val2);

	const string key3 = "fob";
	const double value3 = 4.55;
	const putErr3 = put!double(map, key3, value3);
	kassert(putErr3 is null);
	kassert(containsKey(map, key3));
	kassert(map.size == 3);

	double val3;
	const getErr3 = get!(double)(map, key3, val3);
	kassert(getErr3 is null);
	kassert(isEquals(value3, val3));

	free(map);
}
