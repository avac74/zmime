const std = @import("std");
const zmime = @import("zmime");

const CliError = error{
    MissingFileName,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Cross-platform argument handling
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) {
        std.log.err("usage: zmime <file name>", .{});
        return CliError.MissingFileName;
    }

    const file_name = args[1];

    const result = try zmime.detectFileType(file_name);
    std.log.info("File type is {s}", .{@tagName(result)});
}
