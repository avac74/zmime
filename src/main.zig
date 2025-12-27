const std = @import("std");
const zmime = @import("zmime");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Cross-platform argument handling
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) {
        std.debug.print("usage: zmime <file name>\n", .{});
        std.process.exit(1);
    }

    const file_name = args[1];

    const info = try zmime.detectFileType(file_name);
    std.log.info("File type: {s}, MIME: {s}", .{
        @tagName(info.file_type),
        zmime.mimeToString(info.mime),
    });
}
