const std = @import("std");

pub fn build(b: *std.Build) !void {
    _ = b.addModule("msgpackpp", .{
        .root_source_file = b.path("lib.zig"),
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });
}
