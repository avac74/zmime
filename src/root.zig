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

/// MIME types we support
pub const MimeType = enum {
    text_plain,
    image_png,
    image_jpeg,
    image_gif,
    image_bmp,
    image_tiff,
    image_heic,
    image_ico,
    audio_mp3,
    audio_flac,
    audio_ogg,
    audio_aac,
    video_mp4,
    video_mkv,
    video_mov,
    application_zip,
    application_gzip,
    application_bzip2,
    application_tar,
    application_pdf,
    application_sqlite,
    application_epub,
    application_wasm,
    application_octet_stream,
};

const Magic = struct {
    signature: []const u8,
    offset: usize = 0,
    file_type: FileType,
    mime: MimeType,
};

pub const FileInfo = struct {
    file_type: FileType,
    mime: MimeType,
};

const magic_table = [_]Magic{
    // --- Images ---
    .{ .signature = "\x89PNG\r\n\x1a\n", .file_type = .image, .mime = .image_png },
    .{ .signature = "\xff\xd8\xff", .file_type = .image, .mime = .image_jpeg },
    .{ .signature = "GIF87a", .file_type = .image, .mime = .image_gif },
    .{ .signature = "GIF89a", .file_type = .image, .mime = .image_gif },
    .{ .signature = "BM", .file_type = .image, .mime = .image_bmp },
    .{ .signature = "II*\x00", .file_type = .image, .mime = .image_tiff },
    .{ .signature = "MM\x00*", .file_type = .image, .mime = .image_tiff },
    .{ .signature = "ftypheic", .offset = 4, .file_type = .image, .mime = .image_heic },
    .{ .signature = "\x00\x00\x01\x00", .file_type = .image, .mime = .image_ico },

    // --- Archives ---
    .{ .signature = "PK\x03\x04", .file_type = .archive, .mime = .application_zip },
    .{ .signature = "7z\xBC\xAF\x27\x1C", .file_type = .archive, .mime = .application_octet_stream },
    .{ .signature = "Rar!\x1A\x07\x00", .file_type = .archive, .mime = .application_octet_stream },
    .{ .signature = "\x1F\x8B", .file_type = .archive, .mime = .application_gzip },
    .{ .signature = "BZh", .file_type = .archive, .mime = .application_bzip2 },
    .{ .signature = "ustar", .offset = 257, .file_type = .archive, .mime = .application_tar },

    // --- Documents ---
    .{ .signature = "%PDF-", .file_type = .document, .mime = .application_pdf },
    .{ .signature = "PK\x03\x04", .file_type = .document, .mime = .application_zip },
    .{ .signature = "SQLite format 3\x00", .file_type = .document, .mime = .application_sqlite },
    .{ .signature = "EPUB", .offset = 30, .file_type = .document, .mime = .application_epub },

    // --- Executables ---
    .{ .signature = "\x7FELF", .file_type = .executable, .mime = .application_octet_stream },
    .{ .signature = "MZ", .file_type = .executable, .mime = .application_octet_stream },
    .{ .signature = "\xFE\xED\xFA\xCE", .file_type = .executable, .mime = .application_octet_stream },
    .{ .signature = "\xFE\xED\xFA\xCF", .file_type = .executable, .mime = .application_octet_stream },
    .{ .signature = "\xCE\xFA\xED\xFE", .file_type = .executable, .mime = .application_octet_stream },
    .{ .signature = "\xCF\xFA\xED\xFE", .file_type = .executable, .mime = .application_octet_stream },
    .{ .signature = "\xCA\xFE\xBA\xBE", .file_type = .executable, .mime = .application_octet_stream },

    // --- Audio ---
    .{ .signature = "ID3", .file_type = .audio, .mime = .audio_mp3 },
    .{ .signature = "fLaC", .file_type = .audio, .mime = .audio_flac },
    .{ .signature = "OggS", .file_type = .audio, .mime = .audio_ogg },
    .{ .signature = "\xFF\xF1", .file_type = .audio, .mime = .audio_aac },
    .{ .signature = "\xFF\xF9", .file_type = .audio, .mime = .audio_aac },

    // --- Video ---
    .{ .signature = "\x00\x00\x00\x18ftypmp42", .file_type = .video, .mime = .video_mp4 },
    .{ .signature = "\x1A\x45\xDF\xA3", .file_type = .video, .mime = .video_mkv },
    .{ .signature = "ftypqt", .offset = 4, .file_type = .video, .mime = .video_mov },

    // --- Fonts ---
    .{ .signature = "\x00\x01\x00\x00", .file_type = .font, .mime = .application_octet_stream },
    .{ .signature = "OTTO", .file_type = .font, .mime = .application_octet_stream },
    .{ .signature = "wOFF", .file_type = .font, .mime = .application_octet_stream },
    .{ .signature = "wOF2", .file_type = .font, .mime = .application_octet_stream },

    // --- Misc ---
    .{ .signature = "\x00asm", .file_type = .binary, .mime = .application_wasm },
};

///
/// Return the `FileInfo` of a file named `path`
///
pub fn detectFileInfo(path: []const u8) !FileInfo {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var buffer: [BUFFER_SIZE]u8 = undefined;

    const n = try file.read(&buffer);

    if (detectMagic(buffer[0..n])) |m| {
        return .{
            .file_type = m.file_type,
            .mime = m.mime,
        };
    }

    if (isText(buffer[0..n])) {
        return .{
            .file_type = .text,
            .mime = .text_plain,
        };
    }

    return .{
        .file_type = .binary,
        .mime = .application_octet_stream,
    };
}

///
/// Convert MIME enum → string
///
pub fn mimeToString(m: MimeType) []const u8 {
    return switch (m) {
        .text_plain => "text/plain",
        .image_png => "image/png",
        .image_jpeg => "image/jpeg",
        .image_gif => "image/gif",
        .image_bmp => "image/bmp",
        .image_tiff => "image/tiff",
        .image_heic => "image/heic",
        .image_ico => "image/x-icon",
        .audio_mp3 => "audio/mpeg",
        .audio_flac => "audio/flac",
        .audio_ogg => "audio/ogg",
        .audio_aac => "audio/aac",
        .video_mp4 => "video/mp4",
        .video_mkv => "video/x-matroska",
        .video_mov => "video/quicktime",
        .application_zip => "application/zip",
        .application_gzip => "application/gzip",
        .application_bzip2 => "application/x-bzip2",
        .application_tar => "application/x-tar",
        .application_pdf => "application/pdf",
        .application_sqlite => "application/vnd.sqlite3",
        .application_epub => "application/epub+zip",
        .application_wasm => "application/wasm",
        .application_octet_stream => "application/octet-stream",
    };
}

///
/// Return `Magic` if `buf` contains magic numbers stored in `magic_table` and `null` otherwise.
///
fn detectMagic(buf: []const u8) ?Magic {
    inline for (magic_table) |m| {
        if (buf.len >= m.signature.len + m.offset) {
            if (std.mem.eql(u8, buf[m.offset .. m.offset + m.signature.len], m.signature)) {
                return m;
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
    const m = detectMagic(buf) orelse return error.TestExpectedMagic;
    try std.testing.expectEqual(.image, m.file_type);
    try std.testing.expectEqual(.image_png, m.mime);
}

test "detectMagic returns null for unknown signatures" {
    const buf = "not-a-real-file";
    try std.testing.expectEqual(@as(?Magic, null), detectMagic(buf));
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

    const f = try tmp.dir.createFile("test.png", .{});
    defer f.close();

    try f.writeAll("\x89PNG\r\n\x1a\n");

    const full_path = try tmp.dir.realpathAlloc(std.testing.allocator, "test.png");
    defer std.testing.allocator.free(full_path);

    const info = try detectFileInfo(full_path);

    try std.testing.expectEqual(.image, info.file_type);
    try std.testing.expectEqual(.image_png, info.mime);
}

test "detectFileType detects text file" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const f = try tmp.dir.createFile("hello.txt", .{});
    defer f.close();

    try f.writeAll("Hello!");

    const full_path = try tmp.dir.realpathAlloc(std.testing.allocator, "hello.txt");
    defer std.testing.allocator.free(full_path);

    const info = try detectFileInfo(full_path);

    try std.testing.expectEqual(.text, info.file_type);
    try std.testing.expectEqual(.text_plain, info.mime);
}
