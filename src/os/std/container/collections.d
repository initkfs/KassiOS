/**
 * Authors: initkfs
 */
module os.std.container.collections;

import os.std.container.array_list : ArrayList;
import os.std.errors;

private
{
	alias Allocator = os.core.mem.allocator;
	alias Kstdio = os.std.io.kstdio;
}

public size_t fill(T)(T[] arr, T placeholder)
{
	size_t count;
	foreach (i, T element; arr)
	{
		if (element != placeholder)
		{
			arr[i] = placeholder;
			count++;
		}
	}
	return count;
}

unittest
{
	import os.std.asserts : kassert;

	int[5] arr = [1, 2, 3, 4, 5];
	auto count = fill(arr, 0);
	kassert(count == arr.length);
	foreach (i, ele; arr)
	{
		kassert(ele == 0);
	}
}

void append(ref ArrayList!char list, string str)
{
	foreach (charStr; str)
	{
		list.push(charStr);
	}
}

err copy(T)(ref ArrayList!T src, size_t srcPos, ref ArrayList!T dest, size_t destPos, size_t length)
{
	if (length == 0)
	{
		return null;
	}

	const srcLength = src.length;
	if (srcLength == 0)
	{
		return error(
				"Can't copy array, source length is zero, but length of elements to copy is not");
	}

	if (srcPos >= srcLength)
	{
		size_t[2] errArgs = [srcPos, srcLength];
		return errorf("Can't copy array: source index %l must be less than source length %l",
				errArgs);
	}

	//TODO check overflow
	const endPosWithLength = srcPos + length;
	const endPos = endPosWithLength - 1;
	if (endPos >= srcLength)
	{
		size_t[4] errArgs = [srcPos, length, endPos, src.length];
		return errorf("Can't copy array, count of copied elements exceeds source length: start index %l + %l length, end index is %l, but source length is %l",
				errArgs);
	}

	if (destPos >= dest.length)
	{
		size_t[2] errArgs = [destPos, dest.length];
		return errorf("Can't copy array: destination index %l must be less than destination length %l",
				errArgs);
	}

	const endDestPosWithLength = destPos + length;
	const endDestPos = endDestPosWithLength - 1;
	if (endDestPos >= dest.length)
	{
		size_t[4] errArgs = [destPos, length, endDestPos, dest.length];
		return errorf("Can't copy array, count of copied elements exceeds destination length: start index %l + %l length, end index is %l, but source length is %l",
				errArgs);
	}

	if (src !is dest)
	{
		auto destIndex = destPos;
		foreach (i; srcPos .. endPosWithLength)
		{
			T value;
			const srcGetError = src.get(i, value);
			if (srcGetError)
			{
				return srcGetError;
			}

			const destSetError = dest.set(destIndex, value);
			if (destSetError)
			{
				return destSetError;
			}

			destIndex++;
		}

		return null;
	}

	auto temp = ArrayList!T(length * T.sizeof);
	scope (exit)
	{
		temp.free;
	}

	foreach (i; srcPos .. endPosWithLength)
	{
		T value;
		const isGetErr = src.get(i, value);
		if (isGetErr)
		{
			return isGetErr;
		}
		temp.push(value);
	}

	auto destIndex = destPos;
	for (auto i = 0; i < temp.length; i++)
	{
		T value;
		const tempGetError = temp.get(i, value);
		if (tempGetError)
		{
			return tempGetError;
		}

		const destSetError = dest.set(destIndex, value);
		if (destSetError)
		{
			return destSetError;
		}

		destIndex++;
	}

	return null;
}

unittest
{
	import os.std.asserts : kassert;

	enum itemsCount = 4;
	auto src = ArrayList!int(itemsCount);
	auto dest = ArrayList!int(itemsCount);
	scope (exit)
	{
		src.free;
		dest.free;
	}

	kassert(copy(src, 0, dest, 0, 0) is null);
	kassert(copy(src, 0, dest, 0, 1) !is null);

	foreach (i; 0 .. 4)
	{
		src.push(i);
		dest.push(i);
	}

	kassert(copy(src, 0, dest, 0, 0) is null);
	kassert(copy(src, (itemsCount + 1), dest, 0, 1) !is null);
	kassert(copy(src, 0, dest, 0, 10) !is null);
	kassert(copy(src, 0, dest, (itemsCount + 1), 2) !is null);

	int first;
	int last;
	kassert(src.first(first) is null);
	kassert(src.last(last) is null);
	kassert(first == 0);
	kassert(last == itemsCount - 1);

	kassert(copy(src, 0, src, 3, 1) is null);

	kassert(src.last(last) is null);
	kassert(first == 0);
	kassert(last == 0);
}
