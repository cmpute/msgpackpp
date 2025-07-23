const std = @import("std");
const py = @import("python.zig").py;
const impl = @import("msgpackpp").pack;
const ExtMarker = @import("msgpackpp").common.ExtMarker;
const io = @import("io_py.zig");
const print = @import("std").debug.print;

const PackError = error{
    CallingError, // error happened in calling python functions, just pass through
    IncorrectType, // unexpected object type
    OutOfMemory, // inherited from allocator
};

// utility function for creating a common stream type
fn WriteStream(comptime OutStream: type) type {
    return impl.WriteStream(OutStream, .{ .checked_to_fixed_depth = 256 });
}

fn packPyLongLarge(comptime OutStream: type, object: *py.PyObject, packer: *WriteStream(OutStream), neg: bool) PackError!void {
    // call to_bytes to get internal representations
    const bit_length = py.PyObject_CallMethod(object, "bit_length", null) orelse {
        return PackError.CallingError;
    };
    const byte_length = @divFloor(py.PyLong_AsLongLong(bit_length) + 7, 8);
    const byte_order = "big";
    const bytes_obj = py.PyObject_CallMethod(object, "to_bytes", "Ls", byte_length, byte_order) orelse {
        return PackError.CallingError;
    };

    // pack bytes as ext
    const length: u64 = @intCast(py.PyBytes_Size(bytes_obj));
    if (neg) {
        try packer.beginExt(length, @intFromEnum(ExtMarker.ap_neg_int));
    } else {
        try packer.beginExt(length, @intFromEnum(ExtMarker.ap_pos_int));
    }
    const ptr: [*]u8 = @ptrCast(py.PyBytes_AsString(bytes_obj));
    try packer.writeBytes(ptr[0..length]);
    try packer.endExt();
}

fn packPyLong(comptime OutStream: type, object: *py.PyObject, packer: *WriteStream(OutStream)) PackError!void {
    var overflow: c_int = undefined;
    const value = py.PyLong_AsLongLongAndOverflow(object, &overflow);
    if (overflow == 0) {
        // a small integer
        try packer.write(value);
    } else if (overflow == 1) {
        // a positive large integer
        try packPyLongLarge(OutStream, object, packer, false);
    } else if (overflow == -1) {
        // a negative large integer, call abs() and then pack
        const abs = py.PyNumber_Absolute(object);
        try packPyLongLarge(OutStream, abs, packer, true);
    } else {
        std.debug.panic("overflow should be -1,0,1", .{});
    }
}

fn packAny(comptime OutStream: type, object: *py.PyObject, packer: *WriteStream(OutStream)) !void {
    // deal with integers
    if (py.PyLong_CheckExact(object) != 0) {
        try packPyLong(OutStream, object, packer);
    } else {
        // 不是整数类型
        py.PyErr_SetString(py.PyExc_TypeError, "Argument must be an integer.");
        return;
    }

    // otherwise return none
    // py.Py_IncRef(py.Py_None());
    // return py.Py_None();
    return;
}

pub fn packAnyToBytes(self: [*c]py.PyObject, args: [*c]py.PyObject) callconv(.C) ?*py.PyObject {
    _ = self;
    var src: *py.PyObject = undefined;

    // parse arguments
    if (py.PyArg_ParseTuple(args, "O", &src) == 0) {
        return null;
    }

    var allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator.deinit();
    var sink = io.MemorySink.init(allocator.allocator());
    defer sink.deinit();
    const writer = sink.writer();

    var stream = impl.writeStream(writer, .{});
    packAny(@TypeOf(writer), src, &stream) catch |err| {
        // TODO: raise Python error
        std.debug.print("Error: {}\n", .{err});
        py.Py_IncRef(py.Py_None());
        return py.Py_None();
    };

    const bytes: *py.PyObject = sink.getBytes();
    return bytes;
}
