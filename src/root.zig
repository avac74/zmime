const std = @import("std");

const BUFFER_SIZE: usize = 4096;

const FileType = enum {
    text,
    image,
    audio,
    video,
    archive,
    document,
    executable,
    font,
    binary,
    unknown,
};

const Magic = struct {
    signature: []const u8,
    offset: usize = 0,
    file_type: FileType,
};

const magic_table = [_]Magic{
    // --- Images ---
    .{ .signature = "\x89PNG\r\n\x1a\n", .file_type = .image },
    .{ .signature = "\xff\xd8\xff", .file_type = .image }, // JPEG
    .{ .signature = "GIF87a", .file_type = .image },
    .{ .signature = "GIF89a", .file_type = .image },
    .{ .signature = "BM", .file_type = .image }, // BMP
    .{ .signature = "II*\x00", .file_type = .image }, // TIFF little-endian
    .{ .signature = "MM\x00*", .file_type = .image }, // TIFF big-endian
    .{ .signature = "ftypheic", .offset = 4, .file_type = .image }, // HEIC
    .{ .signature = "\x00\x00\x01\x00", .file_type = .image }, // ICO

    // --- Archives ---
    .{ .signature = "PK\x03\x04", .file_type = .archive }, // ZIP, DOCX, XLSX, PPTX
    .{ .signature = "7z\xBC\xAF\x27\x1C", .file_type = .archive },
    .{ .signature = "Rar!\x1A\x07\x00", .file_type = .archive },
    .{ .signature = "\x1F\x8B", .file_type = .archive }, // GZIP
    .{ .signature = "BZh", .file_type = .archive }, // BZIP2
    .{ .signature = "ustar", .offset = 257, .file_type = .archive }, // TAR

    // --- Documents ---
    .{ .signature = "%PDF-", .file_type = .document },
    .{ .signature = "PK\x03\x04", .file_type = .document }, // DOCX, XLSX, PPTX (specific type needs detection by extension)
    .{ .signature = "SQLite format 3\x00", .file_type = .document },
    .{ .signature = "EPUB", .offset = 30, .file_type = .document },

    // --- Executables ---
    .{ .signature = "\x7FELF", .file_type = .executable }, // Linux
    .{ .signature = "MZ", .file_type = .executable }, // Windows PE
    .{ .signature = "\xFE\xED\xFA\xCE", .file_type = .executable }, // Mach-O 32-bit BE
    .{ .signature = "\xFE\xED\xFA\xCF", .file_type = .executable }, // Mach-O 64-bit BE
    .{ .signature = "\xCE\xFA\xED\xFE", .file_type = .executable }, // Mach-O 32-bit LE
    .{ .signature = "\xCF\xFA\xED\xFE", .file_type = .executable }, // Mach-O 64-bit LE
    .{ .signature = "\xCA\xFE\xBA\xBE", .file_type = .executable }, // Fat binary

    // --- Audio ---
    .{ .signature = "ID3", .file_type = .audio }, // MP3
    .{ .signature = "fLaC", .file_type = .audio },
    .{ .signature = "OggS", .file_type = .audio },
    .{ .signature = "\xFF\xF1", .file_type = .audio }, // AAC
    .{ .signature = "\xFF\xF9", .file_type = .audio },

    // --- Video ---
    .{ .signature = "\x00\x00\x00\x18ftypmp42", .file_type = .video },
    .{ .signature = "\x1A\x45\xDF\xA3", .file_type = .video }, // MKV/WebM
    .{ .signature = "ftypqt", .offset = 4, .file_type = .video }, // MOV

    // --- Fonts ---
    .{ .signature = "\x00\x01\x00\x00", .file_type = .font }, // TTF
    .{ .signature = "OTTO", .file_type = .font }, // OTF
    .{ .signature = "wOFF", .file_type = .font },
    .{ .signature = "wOF2", .file_type = .font },

    // --- Misc ---
    .{ .signature = "\x00asm", .file_type = .binary }, // WASM
};

///
/// Return the `FileType` of a file named `path`
///
pub fn detectFileType(path: []const u8) !FileType {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var buffer: [BUFFER_SIZE]u8 = undefined;

    const n = try file.read(&buffer);

    if (detectMagic(buffer[0..n])) |ft| {
        return ft;
    }

    if (isText(buffer[0..n])) {
        return .text;
    }

    return .binary;
}

///
/// Return `FileType` if `buf` contains magic numbers stored in `magic_table` and `null` otherwise.
///
fn detectMagic(buf: []const u8) ?FileType {
    inline for (magic_table) |m| {
        if (buf.len >= m.signature.len + m.offset) {
            if (std.mem.eql(u8, buf[m.offset .. m.offset + m.signature.len], m.signature)) {
                return m.file_type;
            }
        }
    }

    return null;
}

///
/// Return `true` if `buf` contains text-only data
///
fn isText(buf: []const u8) bool {
    for (buf) |b| {
        if (b == 0) return false;
        if (b < 0x09) return false;
        if (b >= 0x0e and b <= 0x1f) return false;
    }

    return true;
}

// Unit tests

test "detectMagic detects known signatures" {
    const buf = "\x89PNG\r\n\x1a\n";
    try std.testing.expectEqual(.image, detectMagic(buf));
}

test "detectMagic returns null for unknown signatures" {
    const buf = "not-a-real-file";
    try std.testing.expectEqual(@as(?FileType, null), detectMagic(buf));
}

test "isText detects ASCII text" {
    const buf = "Hello, world!";
    try std.testing.expect(isText(buf));
}

test "isText rejects binary data" {
    const buf = [_]u8{ 0, 1, 2, 3 };
    try std.testing.expect(!isText(&buf));
}

test "detectFileType detects PNG from in-memory file" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const path = try tmp.dir.createFile("test.png", .{});
    defer path.close();

    try path.writeAll("\x89PNG\r\n\x1a\n");

    const full_path = try tmp.dir.realpathAlloc(std.testing.allocator, "test.png");
    defer std.testing.allocator.free(full_path);

    const ft = try detectFileType(full_path);
    try std.testing.expectEqual(.image, ft);
}

test "detectFileType detects text file" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const path = try tmp.dir.createFile("hello.txt", .{});
    defer path.close();

    try path.writeAll("Hello!");

    const full_path = try tmp.dir.realpathAlloc(std.testing.allocator, "hello.txt");
    defer std.testing.allocator.free(full_path);

    const ft = try detectFileType(full_path);
    try std.testing.expectEqual(.text, ft);
}
