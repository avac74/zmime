const std = @import("std");
const zmime = @import("zmime");

const CliError = error{
    MissingFileName,
};

pub fn main() !void {
    if (std.os.argv.len != 2) {
        std.log.err("usage: zmime <file name>", .{});
        return CliError.MissingFileName;
    }

    const file_name: [:0]const u8 = std.mem.span(std.os.argv[1]);

    const result = try zmime.detectFileType(file_name);
    std.log.info("File type is {}", .{result});
}
