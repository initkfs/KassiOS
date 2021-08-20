/**
 * Authors: initkfs
 *
 * https://wiki.osdev.org/Multiboot
 * https://www.gnu.org/software/grub/manual/multiboot2/html_node/multiboot2_002eh.html
 */
module os.core.boot.multiboot2;

import os.core.boot.multiboot2spec;

struct MultibootTagIterator
{
	private
	{
		void* tag;
	}

	bool empty()
	{
		return front.type == MULTIBOOT_TAG_TYPE_END || front.size < 4;
	}

	multiboot_tag* front()
	{
		return cast(multiboot_tag*) tag;
	}

	void popFront()
	{
		tag += (front().size + 7) & (~7);
	}
}

MultibootTagIterator createTagIterator(void* multibootAddr)
{
	return MultibootTagIterator(multibootAddr + 8);
}

struct MultibootEntryIterator
{
	private
	{
		multiboot_tag_mmap* tag;
		multiboot_memory_map_t* entry;
	}

	this(multiboot_tag_mmap* tag){
		this.tag = tag;
		entry = cast(multiboot_memory_map_t*) tag.entries;
	}

	bool empty()
	{
		return cast(multiboot_uint8_t*) entry >= cast(multiboot_uint8_t*) tag + tag.size;
	}

	multiboot_memory_map_t* front()
	{
		return cast(multiboot_memory_map_t*) entry;
	}

	void popFront()
	{
		auto newEntryPos = (cast(multiboot_uint8_t*) entry) + tag.entry_size;
		entry = cast(multiboot_memory_map_t*)(newEntryPos);
	}
}

MultibootEntryIterator createMapEntryIterator(multiboot_tag_mmap* tag){
	return MultibootEntryIterator(tag);
}