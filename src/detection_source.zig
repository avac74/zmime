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
