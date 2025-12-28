const std = @import("std");

const BUFFER_SIZE: usize = 4096;

pub const DetectionSource = enum {
    /// magic number match, extension irrelevant or absent
    magic_only,
    /// magic number match agrees with file extension
    magic_and_extension_match,
    /// magic number matched but conflicts with file extension
    magic_and_extension_mismatch,
    /// no magic number match, using extension only
    extension_only,
    /// text heuristic
    content_text,
    /// nothing matched / could not determine the file type
    unknown,
};

pub const FileType = enum {
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
    source: DetectionSource,
};

const ExtensionInfo = struct {
    ext: []const u8,
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

const extension_table = [_]ExtensionInfo{
    .{ .ext = "txt", .file_type = .text, .mime = .text_plain },
    .{ .ext = "png", .file_type = .image, .mime = .image_png },
    .{ .ext = "jpg", .file_type = .image, .mime = .image_jpeg },
    .{ .ext = "jpeg", .file_type = .image, .mime = .image_jpeg },
    .{ .ext = "gif", .file_type = .image, .mime = .image_gif },
    .{ .ext = "bmp", .file_type = .image, .mime = .image_bmp },
    .{ .ext = "tiff", .file_type = .image, .mime = .image_tiff },
    .{ .ext = "ico", .file_type = .image, .mime = .image_ico },

    // ZIP refinement
    .{ .ext = "zip", .file_type = .archive, .mime = .application_zip },
    .{ .ext = "docx", .file_type = .document, .mime = .application_zip },
    .{ .ext = "xlsx", .file_type = .document, .mime = .application_zip },
    .{ .ext = "pptx", .file_type = .document, .mime = .application_zip },

    .{ .ext = "pdf", .file_type = .document, .mime = .application_pdf },
    .{ .ext = "sqlite", .file_type = .document, .mime = .application_sqlite },
    .{ .ext = "epub", .file_type = .document, .mime = .application_epub },

    .{ .ext = "wasm", .file_type = .binary, .mime = .application_wasm },
};

///
/// Return the `FileInfo` of a file named `path`
///
pub fn detectFileInfo(path: []const u8) !FileInfo {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var buffer: [BUFFER_SIZE]u8 = undefined;
    const n = try file.read(&buffer);

    const slice = buffer[0..n];

    const ext = getExtension(path);
    const ext_info = if (ext) |e| lookupExtension(e) else null;

    // Magic number detection
    if (detectMagic(slice)) |m| {
        if (ext_info) |ei| {
            const is_docx_refine =
                (m.file_type == .archive and ei.file_type == .document);

            const is_exact_match =
                (ei.file_type == m.file_type and ei.mime == m.mime);

            if (is_docx_refine or is_exact_match) {
                return .{
                    .file_type = if (is_docx_refine) ei.file_type else m.file_type,
                    .mime = m.mime,
                    .source = .magic_and_extension_match,
                };
            } else {
                return .{
                    .file_type = m.file_type,
                    .mime = m.mime,
                    .source = .magic_and_extension_mismatch,
                };
            }
        }

        return .{
            .file_type = m.file_type,
            .mime = m.mime,
            .source = .magic_only,
        };
    }

    // Text heuristic (treat as a "magic" match)
    if (isText(slice)) {
        if (ext_info) |ei| {
            if (ei.file_type == .text) {
                return .{
                    .file_type = .text,
                    .mime = .text_plain,
                    .source = .magic_and_extension_match,
                };
            } else {
                return .{
                    .file_type = .text,
                    .mime = .text_plain,
                    .source = .magic_and_extension_mismatch,
                };
            }
        }

        return .{
            .file_type = .text,
            .mime = .text_plain,
            .source = .magic_only,
        };
    }

    // Extension fallback
    if (ext_info) |ei| {
        return .{
            .file_type = ei.file_type,
            .mime = ei.mime,
            .source = .extension_only,
        };
    }

    return .{
        .file_type = .unknown,
        .mime = .application_octet_stream,
        .source = .unknown,
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

///
/// Extract the extension of a file. Return the extension as a string or null if the
/// file has no extension.
///
fn getExtension(path: []const u8) ?[]const u8 {
    if (std.mem.lastIndexOfScalar(u8, path, '.')) |idx| {
        return path[idx + 1 ..];
    }

    return null;
}

///
/// Lookup an extension in the extension table
///
fn lookupExtension(ext: []const u8) ?ExtensionInfo {
    inline for (extension_table) |e| {
        if (std.ascii.eqlIgnoreCase(ext, e.ext)) {
            return e;
        }
    }

    return null;
}

// Unit tests

// ------------------------------
// detectMagic
// ------------------------------

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

// ------------------------------
// isText
// ------------------------------

test "isText detects ASCII text" {
    const buf = "Hello, world!";
    try std.testing.expect(isText(buf));
}

test "isText rejects binary data" {
    const buf = [_]u8{ 0, 1, 2, 3 };
    try std.testing.expect(!isText(&buf));
}

// ------------------------------
// getExtension
// ------------------------------

test "getExtension extracts extension correctly" {
    try std.testing.expectEqualStrings("png", getExtension("image.png").?);
    try std.testing.expectEqualStrings("txt", getExtension("notes.txt").?);
}

test "getExtension returns null when no extension exists" {
    try std.testing.expect(getExtension("Makefile") == null);
    try std.testing.expect(getExtension("no_extension") == null);
}

// ------------------------------
// lookupExtension
// ------------------------------

test "lookupExtension finds known extension" {
    const ei = lookupExtension("png") orelse return error.TestExpectedExtension;
    try std.testing.expectEqual(.image, ei.file_type);
    try std.testing.expectEqual(.image_png, ei.mime);
}

test "lookupExtension is case-insensitive" {
    const ei = lookupExtension("JpEg") orelse return error.TestExpectedExtension;
    try std.testing.expectEqual(.image, ei.file_type);
    try std.testing.expectEqual(.image_jpeg, ei.mime);
}

test "lookupExtension returns null for unknown extension" {
    try std.testing.expect(lookupExtension("unknownext") == null);
}

// ------------------------------
// detectFileInfo
// ------------------------------

test "detectFileInfo detects PNG from magic and matches extension" {
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
    try std.testing.expectEqual(.magic_and_extension_match, info.source);
}

test "detectFileInfo detects text file via content" {
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
    try std.testing.expectEqual(.magic_and_extension_match, info.source);
}

test "detectFileInfo falls back to extension when magic is unknown" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const f = try tmp.dir.createFile("file.pdf", .{});
    defer f.close();

    try f.writeAll("NOT A REAL PDF");

    const full_path = try tmp.dir.realpathAlloc(std.testing.allocator, "file.pdf");
    defer std.testing.allocator.free(full_path);

    const info = try detectFileInfo(full_path);

    try std.testing.expectEqual(.text, info.file_type);
    try std.testing.expectEqual(.text_plain, info.mime);
    try std.testing.expectEqual(.magic_and_extension_mismatch, info.source);
}

test "detectFileInfo refines ZIP magic using DOCX extension" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const f = try tmp.dir.createFile("report.docx", .{});
    defer f.close();

    try f.writeAll("PK\x03\x04");

    const full_path = try tmp.dir.realpathAlloc(std.testing.allocator, "report.docx");
    defer std.testing.allocator.free(full_path);

    const info = try detectFileInfo(full_path);

    try std.testing.expectEqual(.document, info.file_type);
    try std.testing.expectEqual(.application_zip, info.mime);
    try std.testing.expectEqual(.magic_and_extension_match, info.source);
}

test "detectFileInfo detects mismatch between magic and extension" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const f = try tmp.dir.createFile("wrong.png", .{});
    defer f.close();

    // Write JPEG magic but extension is .png
    try f.writeAll("\xff\xd8\xff");

    const full_path = try tmp.dir.realpathAlloc(std.testing.allocator, "wrong.png");
    defer std.testing.allocator.free(full_path);

    const info = try detectFileInfo(full_path);

    try std.testing.expectEqual(.image, info.file_type);
    try std.testing.expectEqual(.image_jpeg, info.mime);
    try std.testing.expectEqual(.magic_and_extension_mismatch, info.source);
}

test "detectFileInfo returns unknown when nothing matches" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const f = try tmp.dir.createFile("mystery.bin", .{});
    defer f.close();

    const buf = [_]u8{ 0, 1, 2, 3 };
    try f.writeAll(&buf);

    const full_path = try tmp.dir.realpathAlloc(std.testing.allocator, "mystery.bin");
    defer std.testing.allocator.free(full_path);

    const info = try detectFileInfo(full_path);

    try std.testing.expectEqual(.unknown, info.file_type);
    try std.testing.expectEqual(.application_octet_stream, info.mime);
    try std.testing.expectEqual(.unknown, info.source);
}
