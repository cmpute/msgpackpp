// TODO: define two io, bytes and file. exposed API should be compatible with msgpack

const py = @import("python.zig").py;
const std = @import("std");

pub const MemorySink = struct {
    const Buffer = std.ArrayList(u8);
    const Self = @This();

    buffer: Buffer,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .buffer = Buffer.init(allocator),
        };
    }
    pub inline fn deinit(self: *Self) void {
        self.buffer.deinit();
    }
    pub inline fn writer(self: *Self) Buffer.Writer {
        return self.buffer.writer();
    }

    // return a Python bytes object
    pub inline fn getBytes(self: *const Self) [*c]py.PyObject {
        // data are copied
        return py.PyBytes_FromStringAndSize(self.buffer.items.ptr, @intCast(self.buffer.items.len));
    }
};

const FileSink = struct {};
