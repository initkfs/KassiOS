/**
 * Authors: initkfs
 */
module os.std.text.hash;

extern(C) uint jenkins(char* data);

extern(C) uint adler32(char* data);

extern(C) uint pjw32(char* data);

extern(C) uint murmur32(char* data);