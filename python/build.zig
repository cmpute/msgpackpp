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
    lib.root_module.addImport("msgpackpp", impl_lib.module("msgpackpp"));

    const python_include = b.option([]const u8, "PYTHON_INCLUDE_DIR", "the include folder of python") orelse {
        return error.PythonArgsMissing;
    };
    const python_libs = b.option([]const u8, "PYTHON_LIBS_DIR", "the library folder of python") orelse {
        return error.PythonArgsMissing;
    };
    const python_debug = b.option(bool, "PYTHON_DEBUG", "whether the python intepreter was built in debug mode") orelse {
        return error.PythonArgsMissing;
    };
    const use_limited_api = b.option(bool, "use-limited-api", "use the limited api only") orelse false;
    _ = .{ python_debug, use_limited_api }; // TODO: use them

    lib.addIncludePath(std.Build.LazyPath{ .cwd_relative = python_include });
    lib.addLibraryPath(std.Build.LazyPath{ .cwd_relative = python_libs });
    lib.linkLibC();
    lib.linkSystemLibrary("python3");

    b.installArtifact(lib);
}
