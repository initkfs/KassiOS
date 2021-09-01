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

struct ListItemKey
{
	size_t length;
	char[0] name;

	@disable this();
}

struct ListItem
{
	ListItem* next;
	ListItem* previous;
	ListItemKey* key;
	ListItemType type;
	size_t length;
	size_t[0] data;

	@disable this();
}

struct LinkedList
{
	ListItem* first;
	ListItem* last;
	size_t size;

	@disable this();

	static LinkedList* create()
	{
		auto list = cast(LinkedList*) Allocator.alloc(LinkedList.sizeof);
		list.first = null;
		list.last = null;
		list.size = 0;
		return list;
	}

	static void free(LinkedList* list)
	{
		list.clear;
		Allocator.free(list);
	}

	bool isEmpty()
	{
		return first is null && size == 0;
	}

	void freeListItem(ListItem* item)
	{
		if (item.key)
		{
			Allocator.free(item.key);
		}
		Allocator.free(item);
	}

	private void freeItems(ListItem* startItem)
	{
		ListItem* item = startItem;
		while (item)
		{
			auto forDelete = item;
			item = item.next;
			freeListItem(forDelete);
		}
	}

	void clear()
	{
		freeItems(first);
		size = 0;
		first = null;
		last = null;
	}

	string getItemKey(ListItem* item)
	{
		if (!item.key || item.key.length == 0)
		{
			return "";
		}

		string key = cast(string) item.key.name.ptr[0 .. (item.key.length)];
		return key;
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

	private ListItem* createItem(T)(T data, string key = null)
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
		item.key = null;
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

		if (!Strings.isBlank(key))
		{
			const keyLength = key.length;
			auto itemKey = cast(ListItemKey*) Allocator.alloc(ListItemKey.sizeof + keyLength);
			itemKey.length = keyLength;
			foreach (i, ch; key)
			{
				Allocator.set(itemKey.name.ptr, ch, cast(size_t*) itemKey, i);
			}

			item.key = itemKey;
		}

		return item;
	}

	ListItem* addFirst(T)(T data, string key = null)
	{
		auto item = createItem!T(data, key);

		if (isEmpty)
		{
			last = item;
		}
		else
		{
			first.previous = item;
		}

		item.next = first;
		first = item;
		size++;
		return item;
	}

	ListItem* addLast(T)(T data, string key = null)
	{
		auto item = createItem!T(data, key);

		if (isEmpty)
		{
			first = item;
		}
		else
		{
			if (last !is null)
			{
				last.next = item;
			}

			item.previous = last;
		}

		last = item;
		size++;
		return item;
	}

	ListItem* add(T)(T data, size_t index, string key = null)
	{
		if (index > size)
		{
			return null;
		}

		if (index == 0)
		{
			return addFirst!T(data);
		}

		if (index == size)
		{
			return addLast!T(data);
		}

		ListItem* item = createItem!T(data, key);
		ListItem* previous = first;
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
		size++;
		return item;
	}

	ListItem* removeFirst()
	{
		if (isEmpty)
		{
			return null;
		}

		auto forDelete = first;
		if (first.next is null)
		{
			last = null;
		}
		else
		{
			first.next.previous = null;
		}
		first = first.next;
		size--;
		return forDelete;
	}

	ListItem* removeLast()
	{
		if (isEmpty)
		{
			return null;
		}
		auto forDelete = last;
		if (first.next is null)
		{
			first = null;
		}
		else
		{
			last.previous.next = null;
		}
		last = last.previous;
		size--;
		return forDelete;
	}

	ListItem* peekFirst()
	{
		return first;
	}

	ListItem* peekLast()
	{
		return last;
	}

	ListItem* findItem(string key)
	{
		if (isEmpty)
		{
			return null;
		}
		ListItem* current = first;
		while (current)
		{
			if (Strings.isEquals(getItemKey(current), key))
			{
				return current;
			}
			current = current.next;
		}
		return null;
	}
}

unittest
{
	import os.std.asserts : kassert;

	auto list = LinkedList.create;

	string s1 = "foo";
	string s1Key = "fooKey";
	auto item = list.addFirst!string(s1, s1Key);
	kassert(item !is null);
	kassert(list.size == 1);
	kassert(item.type == ListItemType.STRING);
	kassert(Strings.isEquals(list.getItemData!string(item), s1));
	kassert(Strings.isEquals(list.getItemKey(item), s1Key));

	auto removeItem1 = list.removeFirst;
	kassert(list.size == 0);
	kassert(removeItem1 is item);
	list.freeListItem(removeItem1);

	string s2 = "bar";
	list.addFirst!string(s2);
	list.addFirst!string(s1);
	kassert(list.size == 2);

	auto firstItem = list.peekFirst;
	kassert(Strings.isEquals(list.getItemData!string(firstItem), s1));

	auto secondItem = firstItem.next;
	kassert(secondItem !is null);
	kassert(Strings.isEquals(list.getItemData!string(secondItem), s2));
	kassert(secondItem.next is null);
	kassert(firstItem.next is secondItem);
	kassert(secondItem.previous is firstItem);
	kassert(list.first is firstItem);
	kassert(list.last is secondItem);

	string s3 = "baz";
	auto itemIndex1 = list.add!string(s3, 1);
	kassert(itemIndex1 !is null);
	kassert(list.size == 3);
	kassert(itemIndex1.previous is firstItem);
	kassert(itemIndex1.next is secondItem);
	kassert(Strings.isEquals(list.getItemData!string(itemIndex1), s3));

	list.clear;
	kassert(list.size == 0);
	LinkedList.free(list);
}
