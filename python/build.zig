const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const lib = b.addSharedLibrary(.{
        .name = "msgpackpp_python",
        .root_source_file = b.path("lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    const impl_lib = b.dependency("msgpackpp", .{
        .target = target,
        .optimize = optimize,
    });

    const python_include = b.option([]const u8, "PYTHON_INCLUDE_DIR", "the include folder of python") orelse {
        const fail = b.addFail("requires -DPYTHON_INCLUDE_DIR argment.");
        b.getInstallStep().dependOn(&fail.step);
        return;
    };
    const python_libs = b.option([]const u8, "PYTHON_LIBS_DIR", "the library folder of python") orelse {
        const fail = b.addFail("requires -DPYTHON_LIBS_DIR argument.");
        b.getInstallStep().dependOn(&fail.step);
        return;
    };

    lib.addIncludePath(std.Build.LazyPath{ .cwd_relative = python_include });
    lib.addLibraryPath(std.Build.LazyPath{ .cwd_relative = python_libs });
    lib.linkLibC();
    lib.linkSystemLibrary("python3");
    lib.root_module.addImport("msgpackpp", impl_lib.module("msgpackpp"));

    b.installArtifact(lib);
}
