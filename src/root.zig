const std = @import("std");

pub const DetectionSource = @import("detection_source.zig").DetectionSource;
pub const FileType = @import("file_type.zig").FileType;
pub const MimeType = @import("mime.zig").MimeType;
const Magic = @import("magic.zig").Magic;
const ExtensionInfo = @import("extension.zig").ExtensionInfo;

pub const mimeToString = @import("mime.zig").mimeToString;
const lookupExtension = @import("extension.zig").lookupExtension;
const detectMagic = @import("magic.zig").detectMagic;

const BUFFER_SIZE: usize = 4096;

pub const FileInfo = struct {
    file_type: FileType,
    mime: MimeType,
    source: DetectionSource,
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

    const ext_info = lookupExtension(path);

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
