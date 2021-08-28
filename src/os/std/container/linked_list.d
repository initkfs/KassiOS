/**
 * Authors: initkfs
 */
module os.std.container.linked_list;

import std.traits;

import os.std.errors;

private
{
	alias Allocator = os.core.mem.allocator;
	alias Strings = os.std.text.strings;
}

enum ListItemType
{
	UNDEFINED,
	INTEGRAL,
	FLOATING,
	STRING,
	BYTE
}

struct ListItem
{
	ListItem* next;
	ListItem* previous;
	ListItemType type;
	size_t length;
	size_t[0] data;
}

struct LinkedList
{
	ListItem* first;
	ListItem* last;
	size_t size;
}

bool isEmpty(LinkedList* list)
{
	return list.first is null && list.size == 0;
}

LinkedList* createList()
{
	auto list = cast(LinkedList*) Allocator.alloc(LinkedList.sizeof);
	list.first = null;
	list.last = null;
	list.size = 0;
	return list;
}

void freeItems(ListItem* startItem)
{
	ListItem* item = startItem;
	while (item !is null)
	{
		auto forDelete = item;
		item = item.next;
		Allocator.free(forDelete);
	}
}

void free(LinkedList* list)
{
	clear(list);
	Allocator.free(list);
}

void clear(LinkedList* list)
{
	freeItems(list.first);
	list.size = 0;
	list.first = null;
	list.last = null;
}

T getItemData(T)(ListItem* item)
{
	static if (is(T == string))
	{
		if (item.type == ListItemType.STRING)
		{
			size_t length = item.length;
			char* ptr = cast(char*) item.data.ptr;
			string data = cast(string) ptr[0 .. length];
			return data;
		}
		else
		{
			//TODO error, invalid type
			return null;
		}
	}
	else
	{
		//TODO check types
		T* ptr = cast(T*) item.data.ptr;
		return cast(T)*ptr;
	}

}

private ListItem* createItem(T)(T data)
{
	auto type = ListItemType.UNDEFINED;
	auto size = data.sizeof;

	static if (is(T == string))
	{
		size = data.length;
		type = ListItemType.STRING;
	}
	else static if (isFloatingPoint!(T))
	{
		type = ListItemType.FLOATING;
	}
	else static if (isIntegral!(T))
	{
		type = ListItemType.INTEGRAL;
	}
	else static if (T.sizeof == 1)
	{
		type = ListItemType.BYTE;
	}

	auto item = cast(ListItem*) Allocator.alloc(ListItem.sizeof + size);
	item.next = null;
	item.previous = null;
	item.type = type;
	item.length = size;

	static if (is(T == string))
	{
		char* ptr = cast(char*) item.data.ptr;
		foreach (i, ch; data)
		{
			Allocator.set(ptr, ch, cast(size_t*) item, i);
		}
	}
	else
	{
		T* ptr = cast(T*) item.data.ptr;
		*ptr = data;
	}
	return item;
}

ListItem* addFirst(T)(LinkedList* list, T data)
{
	auto item = createItem!T(data);

	if (isEmpty(list))
	{
		list.last = item;
	}
	else
	{
		list.first.previous = item;
	}

	item.next = list.first;
	list.first = item;
	list.size++;
	return item;
}

ListItem* addLast(T)(LinkedList* list, T data)
{
	auto item = createItem!T(data);

	if (isEmpty(list))
	{
		list.first = item;
	}
	else
	{
		if (list.last !is null)
		{
			list.last.next = item;
		}

		item.previous = list.last;
	}

	list.last = item;
	list.size++;
	return item;
}

ListItem* removeFirst(LinkedList* list)
{
	if (isEmpty(list))
	{
		return null;
	}
	auto forDelete = list.first;
	if (list.first.next is null)
	{
		list.last = null;
	}
	else
	{
		list.first.next.previous = null;
	}
	list.first = list.first.next;
	list.size--;
	return forDelete;
}

ListItem* removeLast(LinkedList* list)
{
	if (isEmpty(list))
	{
		return null;
	}
	auto forDelete = list.last;
	if (list.first.next is null)
	{
		list.first = null;
	}
	else
	{
		list.last.previous.next = null;
	}
	list.last = list.last.previous;
	list.size--;
	return forDelete;
}

ListItem* peekFirst(LinkedList* list)
{
	return list.first;
}

ListItem* peekLast(LinkedList* list)
{
	return list.last;
}

ListItem* addByIndex(T)(LinkedList* list, size_t index, T data)
{

	if (index > list.size)
	{
		return null;
	}

	if (index == 0)
	{
		return addFirst!T(list, data);
	}

	if (index == list.size)
	{
		return addLast!T(list, data);
	}

	ListItem* item = createItem!T(data);
	ListItem* previous = list.first;
	size_t currentIndex = 1;
	while (previous !is null && currentIndex < index)
	{
		currentIndex++;
		previous = previous.next;
	}

	if (previous is null)
	{
		return null;
	}

	if (previous.next)
	{
		previous.next.previous = item;
	}

	item.next = previous.next;
	item.previous = previous;
	previous.next = item;
	list.size++;
	return item;
}

unittest
{
	import os.std.asserts : kassert;

	auto list = createList;

	string s1 = "foo";
	auto item = addFirst!string(list, s1);
	kassert(item !is null);
	kassert(list.size == 1);
	kassert(item.type == ListItemType.STRING);
	kassert(Strings.isEquals(getItemData!string(item), s1));

	auto removeItem1 = removeFirst(list);
	kassert(list.size == 0);
	kassert(removeItem1 is item);
	Allocator.free(removeItem1);

	string s2 = "bar";
	addFirst!string(list, s2);
	addFirst!string(list, s1);
	kassert(list.size == 2);

	auto firstItem = peekFirst(list);
	kassert(Strings.isEquals(getItemData!string(firstItem), s1));

	auto secondItem = firstItem.next;
	kassert(secondItem !is null);
	kassert(Strings.isEquals(getItemData!string(secondItem), s2));
	kassert(secondItem.next is null);
	kassert(firstItem.next is secondItem);
	kassert(secondItem.previous is firstItem);
	kassert(list.first is firstItem);
	kassert(list.last is secondItem);

	string s3 = "baz";
	auto itemIndex1 = addByIndex!string(list, 1, s3);
	kassert(itemIndex1 !is null);
	kassert(list.size == 3);
	kassert(itemIndex1.previous is firstItem);
	kassert(itemIndex1.next is secondItem);
	kassert(Strings.isEquals(getItemData!string(itemIndex1), s3));

	clear(list);
	kassert(list.size == 0);
	free(list);
}
