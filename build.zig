const std = @import("std");

fn dirExists(path: []const u8) bool {
    var cwd = std.fs.cwd();
    cwd.access(path, .{}) catch return false;
    return true;
}

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

    const check = b.step("check", "Check if zmime compiles");

    if (target.result.os.tag == .linux) {
        var arena = std.heap.ArenaAllocator.init(b.allocator);
        const alloc = arena.allocator();

        const is_ci = (std.process.getEnvVarOwned(alloc, "CI") catch null) != null;
        const local_tests = "benchmarks/tests";

        var test_dir: []const u8 = undefined;

        if (!is_ci and dirExists(local_tests)) {
            test_dir = local_tests;
            std.log.info("Not running CI and found tests in {s}", .{test_dir});
        } else {
            const fetch = b.addSystemCommand(&[_][]const u8{ "sh", "-c", "mkdir -p .cache/file-tests && curl -L https://github.com/file/file/archive/refs/heads/master.tar.gz | tar xz -C .cache/file-tests --strip-components=2 file-master/tests/" });
            test_dir = ".cache/file-tests";
            check.dependOn(&fetch.step);
        }

        const benchmark = b.addSystemCommand(&[_][]const u8{
            "bash", "./run_tests.sh", test_dir,
        });
        benchmark.step.dependOn(b.getInstallStep());
        benchmark.step.dependOn(&exe.step);
        check.dependOn(&benchmark.step);

        check.dependOn(&fmt.step);
    }

    check.dependOn(&exe.step);
    check.dependOn(test_step);
}
