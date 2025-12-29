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
