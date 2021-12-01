/**
 * Authors: initkfs
 */
module os.std.container.linear_list;

import std.traits;

import os.std.errors;
import Allocator = os.core.mem.allocator;

struct LinearList
{
	size_t size;
	size_t capacity;
	size_t length;
	size_t[0] data;

	@disable this();
}

private size_t getListSize(T)(size_t initCapacity)
{
	const size = T.sizeof * initCapacity + LinearList.sizeof;
	return size;
}

LinearList* initList(T)(size_t initCapacity, const string file = __FILE__, const int line = __LINE__)
{
	const size = getListSize!T(initCapacity);
	if (size == 0)
	{
		panic("Can't create linear list with zero capacity");
	}
	auto list = cast(LinearList*) Allocator.alloc(size, file, line);
	list.size = size;
	list.capacity = initCapacity;
	list.length = 0;

	return list;
}

bool isEmpty(LinearList* list)
{
	return list.length == 0;
}

private T* getIndexAddress(T)(LinearList* list, const size_t index) pure
{
	ubyte* base = cast(ubyte*) list.data.ptr;
	auto addr = cast(T*)(base + index * T.sizeof);
	return addr;
}

err push(T)(ref LinearList* list, T value, bool isFrozenCapacity = false,
	size_t capacityScaleFactor = 2)
{
	if (list.length >= list.capacity)
	{
		if (isFrozenCapacity)
		{
			return error("Array list capacity frozen. List length must not exceed capacity");
		}

		LinearList* newList;
		const isErrorIncrease = increaseCapacity!T(list, newList, capacityScaleFactor);
		if (isErrorIncrease)
		{
			return isErrorIncrease;
		}

		Allocator.free(list);

		list = newList;
	}

	size_t index;
	if (list.length > 0)
	{
		if (const lastIndexError = lastIndex(list, index))
		{
			return lastIndexError;
		}
	}

	const nextIndex = list.length > 0 ? (index + 1) : 0;
	auto addr = getIndexAddress!T(list, nextIndex);
	Allocator.set(addr, value, cast(size_t*) list);

	list.length++;

	return null;
}

err pop(T)(LinearList* list, ref T value)
{
	if (isEmpty(list))
	{
		return error("Cannot pop from list. List is empty");
	}

	size_t last;
	if (const lastIndexError = lastIndex(list, last))
	{
		return lastIndexError;
	}

	if (const valueError = get(list, last, value))
	{
		return valueError;
	}

	list.length--;
	return null;
}

private err increaseCapacity(T)(LinearList* list, ref LinearList* newList, size_t scalingFactor)
{
	auto newCapacity = list.capacity * scalingFactor;
	newList = initList!T(newCapacity);

	foreach (i; 0 .. list.length)
	{
		T value;
		if (const isGetValueError = get(list, i, value))
		{
			return isGetValueError;
		}

		if (const isSetValueError = push(newList, value))
		{
			return isSetValueError;
		}
	}

	return null;
}

err set(T)(LinearList* list, size_t index, T value)
{
	if (list.length == 0)
	{
		return error("Can't set array list value: list length is 0");
	}

	if (index >= list.length)
	{
		return error("Can't set array list value: list index must be less than the length");
	}

	auto addr = getIndexAddress!T(list, index);
	Allocator.set(addr, value, cast(size_t*) list);

	return null;
}

err get(T)(LinearList* list, const size_t index, ref T value)
{
	if (list.length == 0)
	{
		return error("Can't get array list value: list length is 0");
	}

	if (index >= list.length)
	{
		return error("Can't get array list value: list index must be less than the length");
	}

	auto addr = getIndexAddress!T(list, index);
	value = cast(T)(*addr);

	return null;
}

err first(T)(LinearList* list, ref T value)
{
	if (list.length == 0)
	{
		return error("Can't get first value from array: length is 0");
	}

	const getValueError = get(list, 0, value);
	return getValueError;
}

err last(T)(LinearList* list, ref T value)
{
	if (list.length == 0)
	{
		return error("Can't get last value from array: length is 0");
	}

	size_t index;
	if (const lastIndexError = lastIndex(list, index))
	{
		return lastIndexError;
	}

	const getValueError = get(list, index, value);
	return getValueError;
}

err lastIndex(LinearList* list, ref size_t index)
{
	if (list.length == 0)
	{
		return error("Unable to get the last index: array length is 0");
	}

	index = list.length - 1;

	return null;
}

err removeAt(T)(LinearList* list, size_t index)
{
	if (list.length == 0)
	{
		return error("Can't remove value from array by index: length is 0");
	}

	if (index >= list.length)
	{
		return error("Can't remove value from array: index must be less than the length");
	}

	foreach (i; index .. (list.length - 1))
	{
		T value;
		if (const getNewValueError = get(list, i + 1, value))
		{
			return getNewValueError;
		}

		if (const setValueError = set(list, i, value))
		{
			return setValueError;
		}
	}

	size_t mustBeLastIndex;

	if (const lastIndexError = lastIndex(list, mustBeLastIndex))
	{
		return lastIndexError;
	}

	if (const setLastValueError = set(list, mustBeLastIndex, 0))
	{
		return setLastValueError;
	}

	list.length--;

	return null;
}

size_t orMaxIndex(LinearList* list, size_t value)
{
	if (list.length == 0)
	{
		return 0;
	}

	return value < list.length ? value : list.length - 1;
}

void clear(LinearList* list)
{
	list.length = 0;
}

void iteratelist(T)(LinearList* list, void delegate(size_t, T, err) onIndexElement)
{
	foreach (i; 0 .. list.length)
	{
		T value;
		const valueError = get(list, i, value);
		onIndexElement(i, value, valueError);
	}
}

unittest
{
	import os.std.asserts : kassert;

	enum capacity = 8;
	auto list = initList!int(capacity);
	scope (exit)
	{
		Allocator.free(list);
	}

	kassert(list.capacity == capacity);
	kassert(list.size >= capacity * int.sizeof);
	kassert(list.length == 0);

	kassert(set(list, 0, 1) !is null);
	kassert(set(list, list.length + 1, 1) !is null);
	int invalidEmptyValue;
	kassert(get(list, 0, invalidEmptyValue) !is null);

	foreach (i; 0 .. capacity)
	{
		const addValueError = push(list, i);
		kassert(addValueError is null);
	}

	kassert(list.length == capacity);

	enum newSize = capacity + 1;

	const isIncreaseError = push(list, newSize - 1);
	kassert(isIncreaseError is null);

	kassert(list.length == newSize);
	kassert(list.capacity == capacity * 2);
	kassert(list.size >= capacity * 2 * int.sizeof);

	int firstValue;
	const firstValueError = first(list, firstValue);
	kassert(firstValueError is null);
	kassert(firstValue == 0);

	int lastValue;
	const lastValueError = last(list, lastValue);
	kassert(lastValueError is null);
	kassert(lastValue == (newSize - 1));

	iteratelist!int(list, (index, element, err) {
		kassert(err is null);
		kassert(element == index);
	});

	const removeValueError = removeAt!int(list, 0);
	kassert(removeValueError is null);
	kassert(list.length == (newSize - 1));
	iteratelist!int(list, (index, element, err) {
		kassert(err is null);
		kassert(element == index + 1);
	});

	int lastAndNextInvalidValue;
	kassert(get(list, newSize - 1, lastAndNextInvalidValue) !is null);
}
