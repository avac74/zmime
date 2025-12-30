const std = @import("std");

pub const TextEncoding = enum {
    ascii,
    utf8,
    utf8_bom,
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

    if (buf.len >= 2 and std.mem.eql(u8, buf[0..2], "\xFF\xFE")) {
        return .utf16_le;
    }

    if (buf.len >= 2 and std.mem.eql(u8, buf[0..2], "\xFE\xFF")) {
        return .utf16_be;
    }

    if (buf.len >= 4 and std.mem.eql(u8, buf[0..4], "\xFF\xFE\x00\x00")) {
        return .utf32_le;
    }

    if (buf.len >= 4 and std.mem.eql(u8, buf[0..4], "\x00\x00\xFE\xFF")) {
        return .utf32_be;
    }

    if (std.unicode.utf8ValidateSlice(buf)) {
        return .utf8;
    }

    var ascii = true;
    var extended = false;

    for (buf) |b| {
        if (b >= 0x80) {
            ascii = false;
            if (b <= 0x9f or b >= 0xa0) {
                extended = true;
            } else {
                break;
            }
        }
    }

    if (ascii) return .ascii;
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
