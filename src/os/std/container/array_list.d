/**
 * Authors: initkfs
 */
module os.std.container.array_list;

import std.traits;

import os.std.errors;

import Allocator = os.core.mem.allocator;
import List = os.std.container.linear_list;

struct ArrayList(T)
{
	private
	{
		List.LinearList* list;
	}

	@property size_t capacityScalingFactor = 2;
	@property bool isFrozenCapacity;

	this(size_t capacity)
	{
		if (const initErr = initList(capacity))
		{
			panic("Cannot initialize list in constructor");
		}
	}

	err initList(size_t capacity = 8, size_t initCapacityScaleFactor = 2, bool frozenCapacity = false)
	{
		if (list)
		{
			return error("Array list is already initialized");
		}
		list = List.initList!T(capacity);
		capacityScalingFactor = initCapacityScaleFactor;
		isFrozenCapacity = frozenCapacity;
		return null;
	}

	err push(T value)
	{
		return List.push(list, value, isFrozenCapacity);
	}

	err pop(ref T value)
	{
		return List.pop(list, value);
	}

	bool isEmpty()
	{
		return List.isEmpty(list);
	}

	err set(size_t index, T value)
	{
		return List.set(list, index, value);
	}

	err get(const size_t index, ref T value)
	{
		return List.get(list, index, value);
	}

	err first(ref T value)
	{
		return List.first(list, value);
	}

	err last(ref T value)
	{
		return List.last(list, value);
	}

	err lastIndex(ref size_t index)
	{
		return List.lastIndex(list, index);
	}

	err removeAt(size_t index)
	{
		return List.removeAt!T(list, index);
	}

	void clear()
	{
		List.clear(list);
	}

	int opApply(scope int delegate(ref T) dg)
	{
		int result = 0;

		foreach (i; 0 .. list.length)
		{
			T value;
			if (const getValueError = List.get(list, i, value))
			{
				break;
			}

			result = dg(value);
			if (result)
			{
				break;
			}
		}
		return result;
	}

	void free()
	{
		Allocator.free(cast(size_t*) list);
	}

	@property size_t size() @safe pure
	{
		return list !is null ? list.size : 0;
	}

	@property size_t capacity() @safe pure
	{
		return list !is null ? list.capacity : 0;
	}

	@property size_t length() @safe pure
	{
		return list !is null ? list.length : 0;
	}

	@property size_t* ptr()
	{
		return list !is null ? list.data.ptr : null;
	}
}

unittest
{
	import os.std.asserts : kassert;

	enum capacity = 8;
	auto list = ArrayList!int(capacity);
	scope (exit)
	{
		list.free;
	}
	kassert(list.capacity == capacity);
	kassert(list.length == 0);

	foreach (i; 0 .. capacity)
	{
		const addValueError = list.push(i);
		kassert(addValueError is null);
	}

	kassert(list.length == capacity);

	enum newSize = capacity + 1;

	const isIncreaseError = list.push(newSize - 1);
	kassert(isIncreaseError is null);
	kassert(list.length == newSize);

	size_t index;
	foreach (element; list)
	{
		kassert(element == index);
		index++;
	}

	kassert(index == newSize);
}
