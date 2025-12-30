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

    const info = try zmime.detectFileInfo(file_name);
    std.log.info("File type: {s}, MIME: {s}", .{
        @tagName(info.file_type),
        zmime.mimeToString(info.mime),
    });

    // you can also just check if a file is (likely) text or binary
    const is_test = try zmime.isTextFile(file_name);
    if (is_test) {
        std.log.info("File {s} is a text file", .{file_name});
    } else {
        std.log.info("File {s} is a binary file", .{file_name});
    }
}
