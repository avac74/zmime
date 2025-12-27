const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ========================= the library itself =========================

    const mod = b.addModule("zmime", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    // ========================= an executable to test the library =========================

    const exe = b.addExecutable(.{
        .name = "zmime",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zmime", .module = mod },
            },
        }),
    });

    b.installArtifact(exe);

    // ========================= Run step =========================

    const run_step = b.step("run", "Run the zmime CLI");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // ========================= Test step =========================

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);

    // ========================= Format step =========================

    const fmt = b.addFmt(.{
        .paths = &.{ "src", "build.zig", "build.zig.zon" },
    });

    const fmt_check = b.step("fmt-check", "Check formatting");
    fmt_check.dependOn(&fmt.step);

    // ========================= Check step =========================

    const exe_check = b.addExecutable(.{
        .name = "zmime",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zmime", .module = mod },
            },
        }),
    });

    const check = b.step("check", "Check if zmime compiles");
    check.dependOn(&exe_check.step);
    check.dependOn(test_step);
    check.dependOn(&fmt.step);
}
