const std = @import("std");
const py = @import("python.zig").py;
const impl = @import("msgpackpp").pack;
const io = @import("io_py.zig");
const print = @import("std").debug.print;

// utility function for creating a common stream type
fn WriteStream(comptime OutStream: type) type {
    return impl.WriteStream(OutStream, .{ .checked_to_fixed_depth = 256 });
}

fn packPyLong(comptime OutStream: type, object: *py.PyObject, packer: *WriteStream(OutStream)) !void {
    const value = py.PyLong_AsLong(object);
    if (value == -1 and py.PyErr_Occurred() != 0) {
        // 处理超出普通整数范围的情况
        py.PyErr_Clear();

        // 调用 int.to_bytes() 方法
        const bit_length = py.PyObject_CallMethod(object, "bit_length", null);
        if (bit_length == null) {
            return;
        }
        const byte_length = @divFloor(py.PyLong_AsLongLong(bit_length) + 7, 8);
        const byte_order = "big";
        const bytes_obj = py.PyObject_CallMethod(object, "to_bytes", "Ls", byte_length, byte_order);

        if (bytes_obj == null) {
            return;
        }

        const length = py.PyBytes_Size(bytes_obj);
        print("Long integer byte length: {}\n", .{length});
    } else {
        try packer.write(value);
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
