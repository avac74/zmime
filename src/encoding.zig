const std = @import("std");

pub const TextEncoding = enum {
    ascii,
    utf8,
    utf8_bom, // utf-8 has no endianness, but sometimes magic numbers are used to mark UTF encoding
    utf16_le,
    utf16_be,
    utf32_le,
    utf32_be,
    extended_ascii,
    unknown,
};

pub fn detectEncoding(buf: []const u8) TextEncoding {
    if (buf.len >= 3 and std.mem.eql(u8, buf[0..3], "\xEF\xBB\xBF")) {
        return .utf8_bom;
    }

    if (buf.len >= 4 and std.mem.eql(u8, buf[0..4], "\xFF\xFE\x00\x00")) {
        return .utf32_le;
    }

    if (buf.len >= 4 and std.mem.eql(u8, buf[0..4], "\x00\x00\xFE\xFF")) {
        return .utf32_be;
    }

    if (buf.len >= 2 and std.mem.eql(u8, buf[0..2], "\xFF\xFE")) {
        return .utf16_le;
    }

    if (buf.len >= 2 and std.mem.eql(u8, buf[0..2], "\xFE\xFF")) {
        return .utf16_be;
    }

    var ascii = true;

    for (buf) |b| {
        if (b < 0x20 and b != 0x09 and b != 0x0A and b != 0x0D) {
            // control characters → not text
            return .unknown;
        }

        if (b >= 0x80) {
            ascii = false;
        }
    }

    if (ascii) return .ascii;

    if (std.unicode.utf8ValidateSlice(buf)) {
        return .utf8;
    }

    var extended = false;
    for (buf) |b| {
        if (b >= 0x80)
            extended = true;
    }
    if (extended) return .extended_ascii;

    return .unknown;
}

pub fn textEncodingToString(e: TextEncoding) []const u8 {
    return switch (e) {
        .ascii => "ASCII",
        .utf8 => "UTF-8",
        .utf8_bom => "UTF-8 (BOM)",
        .utf16_le => "UTF-16 (Little Endian)",
        .utf16_be => "UTF-16 (Big Endian)",
        .utf32_le => "UTF-32 (Little Endian)",
        .utf32_be => "UTF-32 (Big Endian)",
        .extended_ascii => "Extended ASCII",
        .unknown => "Umknown",
    };
}

test "detectEncoding detects UTF-8 BOM" {
    const buf = "\xEF\xBB\xBFHello";
    try std.testing.expectEqual(.utf8_bom, detectEncoding(buf));
}

test "detectEncoding detects UTF-16 LE BOM" {
    const buf = "\xFF\xFEh\x00e\x00";
    try std.testing.expectEqual(.utf16_le, detectEncoding(buf));
}

test "detectEncoding detects UTF-16 BE BOM" {
    const buf = "\xFE\xFF\x00h\x00e";
    try std.testing.expectEqual(.utf16_be, detectEncoding(buf));
}

test "detectEncoding detects UTF-32 LE BOM" {
    const buf = "\xFF\xFE\x00\x00h\x00\x00\x00";
    try std.testing.expectEqual(.utf32_le, detectEncoding(buf));
}

test "detectEncoding detects UTF-32 BE BOM" {
    const buf = "\x00\x00\xFE\xFF\x00\x00\x00h";
    try std.testing.expectEqual(.utf32_be, detectEncoding(buf));
}

test "detectEncoding detects valid UTF-8" {
    const buf = "Héllo"; // some characters that are missing in the ISO-8859-1 character set
    try std.testing.expectEqual(.utf8, detectEncoding(buf));
}

test "detectEncoding detects ASCII" {
    const buf = "Hello, world!";
    try std.testing.expectEqual(.ascii, detectEncoding(buf));
}

test "detectEncoding detects extended ASCII" {
    const buf = [_]u8{ 0x48, 0x65, 0x80, 0x90, 0xA0 }; // H e <extended>
    try std.testing.expectEqual(.extended_ascii, detectEncoding(&buf));
}
