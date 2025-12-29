const std = @import("std");
const FileType = @import("file_type.zig").FileType;
const MimeType = @import("mime.zig").MimeType;

pub const ExtensionInfo = struct {
    ext: []const u8,
    file_type: FileType,
    mime: MimeType,
};

pub const extension_table = [_]ExtensionInfo{
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
pub fn lookupExtension(path: []const u8) ?ExtensionInfo {
    const ext = getExtension(path) orelse return null;

    inline for (extension_table) |e| {
        if (std.ascii.eqlIgnoreCase(ext, e.ext)) {
            return e;
        }
    }

    return null;
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
    const ei = lookupExtension("a.png") orelse return error.TestExpectedExtension;
    try std.testing.expectEqual(.image, ei.file_type);
    try std.testing.expectEqual(.image_png, ei.mime);
}

test "lookupExtension is case-insensitive" {
    const ei = lookupExtension("a.JpEg") orelse return error.TestExpectedExtension;
    try std.testing.expectEqual(.image, ei.file_type);
    try std.testing.expectEqual(.image_jpeg, ei.mime);
}

test "lookupExtension returns null for unknown extension" {
    try std.testing.expect(lookupExtension("unknownext") == null);
}
