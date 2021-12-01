pub fn jenkins(data: *u8) u32 {
    const dataPtr: [*]u8 = @ptrCast([*]u8, data);

    var length: usize = 0;
    while (dataPtr[length] != 0) {
        length += 1;
    }

    var hash: u32 = 0;
    var index: usize = 0;
    while (index < length) {
        hash +%= dataPtr[index];
        hash +%= hash << 10;
        hash ^= hash >> 6;
        index += 1;
    }

    hash +%= hash << 3;
    hash ^= hash >> 11;
    hash +%= hash << 15;

    return hash;
}
