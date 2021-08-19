/**
 * Authors: initkfs
 */
module os.std.container.array_list;

import std.traits;

import os.std.errors;

private
{
	alias Allocator = os.core.mem.allocator;
}

struct ArrayList(T)
{
	private
	{
		size_t* _ptr;
		size_t _size;
		size_t _capacity;
		size_t _length;
	}

	@property size_t capacityScalingFactor = 2;
	@property bool isFrozenCapacity;

	this(size_t capacity)
	{
		const size = T.sizeof * capacity;
		if (size == 0)
		{
			panic("Can't create array list with zero capacity");
		}
		_ptr = Allocator.alloc(size);
		_size = size;
		_capacity = capacity;
	}

	err push(T value)
	{
		if (_length >= _capacity)
		{
			if (isFrozenCapacity)
			{
				return error("Array list capacity frozen. List length must not exceed capacity");
			}

			increaseCapacity;
		}

		size_t index;
		if (_length > 0)
		{
			const lastIndexError = lastIndex(index);
			if (lastIndexError)
			{
				return lastIndexError;
			}
		}
		const nextIndex = _length > 0 ? (index + 1) : 0;
		auto addr = getIndexAddress(nextIndex);
		Allocator.set(addr, value, _ptr);
		_length++;
		return null;
	}

	err pop(ref T value)
	{
		if (isEmpty)
		{
			return error("Cannot pop from list. Stack is empty");
		}

		size_t last;
		auto lastIndexError = lastIndex(last);
		if (lastIndexError)
		{
			return lastIndexError;
		}

		auto valueError = get(last, value);
		if (valueError)
		{
			return valueError;
		}

		auto removeError = removeAt(last);
		if (removeError)
		{
			return removeError;
		}

		return null;
	}

	bool isEmpty()
	{
		return _length == 0;
	}

	private err increaseCapacity()
	{
		auto newCapacity = _capacity * capacityScalingFactor;
		auto newSize = T.sizeof * newCapacity;
		auto newPtr = Allocator.alloc(newSize);
		foreach (i; 0 .. _length)
		{
			T value;
			const isGetValueError = get(i, value);
			if (isGetValueError)
			{
				return isGetValueError;
			}
			auto newAddr = getIndexAddress(newPtr, i);
			Allocator.set(newAddr, value, newPtr);
		}

		free;

		_ptr = newPtr;
		_size = newSize;
		_capacity = newCapacity;
		return null;
	}

	err set(size_t index, T value)
	{
		if (_length == 0)
		{
			return error("Can't set array list value: list length is 0");
		}

		if (index >= _length)
		{
			return error("Can't set array list value: list index must be less than the length");
		}
		auto addr = getIndexAddress(index);
		Allocator.set(addr, value, _ptr);
		return null;
	}

	err get(const size_t index, ref T value)
	{
		if (_length == 0)
		{
			return error("Can't get array list value: list length is 0");
		}

		if (index >= _length)
		{
			return error("Can't get array list value: list index must be less than the length");
		}
		auto addr = getIndexAddress(index);
		value = cast(T)(*addr);

		return null;
	}

	err first(ref T value)
	{
		if (_length == 0)
		{
			return error("Can't get first value from array: length is 0");
		}
		const getValueError = get(0, value);
		return getValueError;
	}

	err last(ref T value)
	{
		if (_length == 0)
		{
			return error("Can't get last value from array: length is 0");
		}
		size_t index;
		const lastIndexError = lastIndex(index);
		if (lastIndexError)
		{
			return lastIndexError;
		}
		const getValueError = get(index, value);
		return getValueError;
	}

	err lastIndex(ref size_t index)
	{
		if (_length == 0)
		{
			return error("Unable to get the last index: array length is 0");
		}
		index = _length - 1;
		return null;
	}

	err removeAt(size_t index)
	{
		if (_length == 0)
		{
			return error("Can't remove value from array by index: length is 0");
		}

		if (index >= _length)
		{
			return error("Can't remove value from array: index must be less than the length");
		}

		foreach (i; index .. (_length - 1))
		{
			T value;
			const getNewValueError = get(i + 1, value);
			if (getNewValueError)
			{
				return getNewValueError;
			}

			const setValueError = set(i, value);
			if (setValueError)
			{
				return setValueError;
			}
		}

		size_t mustBeLastIndex;
		const lastIndexError = lastIndex(mustBeLastIndex);
		if (lastIndexError)
		{
			return lastIndexError;
		}
		const setLastValueError = set(mustBeLastIndex, 0);
		if (setLastValueError)
		{
			return setLastValueError;
		}
		_length--;
		return null;
	}

	private T* getIndexAddress(size_t* basePtr, const size_t index) pure
	{
		ubyte* base = cast(ubyte*) basePtr;
		auto addr = cast(T*)(base + index * T.sizeof);
		return addr;
	}

	private T* getIndexAddress(const size_t index) pure
	{
		return getIndexAddress(_ptr, index);
	}

	int opApply(scope int delegate(ref T) dg)
	{
		int result = 0;

		foreach (i; 0 .. _length)
		{
			T value;
			const getValueError = get(i, value);
			if (getValueError)
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
		Allocator.free(_ptr);
	}

	@property size_t size() @safe pure
	{
		return _size;
	}

	@property size_t capacity() @safe pure
	{
		return _capacity;
	}

	@property size_t length() @safe pure
	{
		return _length;
	}

	@property size_t* ptr() @safe pure {
		return _ptr;
	}
}

unittest
{
	import os.std.asserts : kassert;

	enum size = 8;
	enum sizeInBytes = size.sizeof * size;
	auto list = ArrayList!int(size);
	scope(exit){
		list.free;
	}
	kassert(list.capacity == size);
	kassert(list.size == sizeInBytes);
	kassert(list.length == 0);

	kassert(list.set(0, 1) !is null);
	kassert(list.set(list.length + 1, 1) !is null);
	int invalidEmptyValue;
	kassert(list.get(0, invalidEmptyValue) !is null);

	foreach (i; 0 .. size)
	{
		const addValueError = list.push(i);
		kassert(addValueError is null);
	}

	kassert(list.length == size);

	enum newSize = size + 1;

	const isIncreaseError = list.push(newSize - 1);
	kassert(isIncreaseError is null);
	kassert(list.length == newSize);
	kassert(list.capacity == size * 2);
	kassert(list.size == sizeInBytes * 2);

	int firstValue;
	const firstValueError = list.first(firstValue);
	kassert(firstValueError is null);
	kassert(firstValue == 0);

	int lastValue;
	const lastValueError = list.last(lastValue);
	kassert(lastValueError is null);
	kassert(lastValue == (newSize - 1));

	foreach (i; 0 .. newSize)
	{
		int value;
		auto getValueError = list.get(i, value);
		kassert(getValueError is null);
		kassert(value == i);
	}

	int i = 0;
	foreach (v; list)
	{
		kassert(v == i);
		i++;
	}
	kassert(i == newSize);

	const removeValueError = list.removeAt(0);
	kassert(removeValueError is null);
	kassert(list.length == (newSize - 1));
	int y = 1;
	foreach (v; list)
	{
		kassert(v == y);
		y++;
	}

	int lastAndNextInvalidValue;
	kassert(list.get(newSize - 1, lastAndNextInvalidValue) !is null);
}
