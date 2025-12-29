const std = @import("std");
const FileType = @import("file_type.zig").FileType;
const MimeType = @import("mime.zig").MimeType;

pub const Magic = struct {
    signature: []const u8,
    offset: usize = 0,
    file_type: FileType,
    mime: MimeType,
};

pub const magic_table = [_]Magic{
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
/// Return `Magic` if `buf` contains magic numbers stored in `magic_table` and `null` otherwise.
///
pub fn detectMagic(buf: []const u8) ?Magic {
    inline for (magic_table) |m| {
        if (buf.len >= m.signature.len + m.offset) {
            if (std.mem.eql(u8, buf[m.offset .. m.offset + m.signature.len], m.signature)) {
                return m;
            }
        }
    }

    return null;
}

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
