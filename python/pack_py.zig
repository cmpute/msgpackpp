const std = @import("std");
const py = @import("python.zig").py;
const Py_DECREF = @import("python.zig").Py_DECREF;
const impl = @import("msgpackpp").pack;
const ExtMarker = @import("msgpackpp").common.ExtMarker;
const io = @import("io_py.zig");
const print = @import("std").debug.print;

// utility function for creating a common stream type
fn WriteStream(comptime OutStream: type) type {
    return impl.WriteStream(OutStream, .{ .checked_to_fixed_depth = 256 });
}

fn PackError(comptime OutStream: type) type {
    return WriteStream(OutStream).Error || error{
        CallingError, // error happened in calling python functions, just pass through
        IncorrectType, // unexpected object type
        UnsupportedType, // unsupported object type
    };
}

fn packPyLongLarge(comptime OutStream: type, object: *py.PyObject, packer: *WriteStream(OutStream), neg: bool) PackError(OutStream)!void {
    // call to_bytes to get internal representations
    const bit_length = py.PyObject_CallMethod(object, "bit_length", null) orelse {
        return error.CallingError;
    };
    const byte_length = @divFloor(py.PyLong_AsLongLong(bit_length) + 7, 8);
    const byte_order = "big";
    const bytes_obj = py.PyObject_CallMethod(object, "to_bytes", "Ls", byte_length, byte_order) orelse {
        return error.CallingError;
    };

    // pack bytes as ext
    const length: u64 = @intCast(py.PyBytes_Size(bytes_obj));
    if (neg) {
        try packer.beginExt(length, @intFromEnum(ExtMarker.ap_neg_int));
    } else {
        try packer.beginExt(length, @intFromEnum(ExtMarker.ap_pos_int));
    }
    const ptr: [*]u8 = @ptrCast(py.PyBytes_AsString(bytes_obj));
    try packer.writeRaw(ptr[0..length]);
    try packer.endExt();
}

fn packPyLong(comptime OutStream: type, object: *py.PyObject, packer: *WriteStream(OutStream)) PackError(OutStream)!void {
    var overflow: c_int = undefined;
    const value = py.PyLong_AsLongLongAndOverflow(object, &overflow);
    if (py.PyErr_Occurred() != 0 and value == -1) {
        return error.CallingError;
    }

    if (overflow == 0) {
        // a small integer
        if (value < 0) {
            try packer.write(value);
        } else {
            try packer.write(@abs(value));
        }
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

fn packPyFloat(comptime OutStream: type, object: *py.PyObject, packer: *WriteStream(OutStream)) PackError(OutStream)!void {
    const value = py.PyFloat_AsDouble(object);
    if (py.PyErr_Occurred() != 0 and value == -1) {
        return error.CallingError;
    }
    try packer.write(value);
}

fn packPyBool(comptime OutStream: type, object: *py.PyObject, packer: *WriteStream(OutStream)) PackError(OutStream)!void {
    if (object == py.Py_False()) {
        try packer.write(false);
    } else if (object == py.Py_True()) {
        try packer.write(true);
    } else {
        std.debug.panic("boolean value being neither True or False", .{});
    }
}

fn packPyString(comptime OutStream: type, object: *py.PyObject, packer: *WriteStream(OutStream)) PackError(OutStream)!void {
    // TODO: use PyUnicode_AsUTF8AndSize when limited API is lifted or Python newer than 3.10
    const bytes = py.PyUnicode_AsUTF8String(object) orelse {
        return error.CallingError;
    };

    const length: u64 = @intCast(py.PyBytes_Size(bytes));
    const ptr: [*]u8 = @ptrCast(py.PyBytes_AsString(bytes));
    try packer.writeString(ptr[0..length]);
}

fn packPySequence(comptime OutStream: type, object: *py.PyObject, packer: *WriteStream(OutStream)) PackError(OutStream)!void {
    const len: u32 = @intCast(py.PySequence_Length(object));
    try packer.beginArray(len);

    if (py.PyList_Check(object) != 0) {
        // shortcut for PyList
        for (0..len) |i| {
            const py_i: isize = @intCast(i);
            // FIXME: use PyList_GET_ITEM when Zig is ready
            try packAny(OutStream, py.PyList_GetItem(object, py_i), packer);
        }
    } else if (py.PyTuple_Check(object) != 0) {
        // TODO: shortcut for PyTuple
        for (0..len) |i| {
            const py_i: isize = @intCast(i);
            // FIXME: use PyTuple_GET_ITEM when Zig is ready
            try packAny(OutStream, py.PyTuple_GetItem(object, py_i), packer);
        }
    } else {
        // fallback to normal PySequence API
        for (0..len) |i| {
            try packAny(OutStream, py.PySequence_GetItem(object, @intCast(i)), packer);
        }
    }

    try packer.endArray();
}

fn packPyMapping(comptime OutStream: type, object: *py.PyObject, packer: *WriteStream(OutStream)) PackError(OutStream)!void {
    const len: u32 = @intCast(py.PyMapping_Length(object));
    try packer.beginMap(len);

    if (py.PyDict_Check(object) != 0) {
        // shortcut for PyDict
        var key: [*c]py.PyObject = undefined;
        var value: [*c]py.PyObject = undefined;
        var pos: py.Py_ssize_t = 0;

        while (py.PyDict_Next(object, &pos, &key, &value) != 0) {
            try packAny(OutStream, @ptrCast(key), packer);
            try packAny(OutStream, @ptrCast(value), packer);
        }
    } else {
        // fallback to normal PyMapping API
        const items = py.PyMapping_Items(object);
        for (0..len) |i| {
            const py_i: isize = @intCast(i);
            // FIXME: use PyList_GET_ITEM when Zig is ready
            const item = py.PyList_GetItem(items, py_i);
            try packAny(OutStream, py.PyList_GetItem(item, 0), packer);
            try packAny(OutStream, py.PyList_GetItem(item, 1), packer);
        }
    }

    try packer.endMap();
}

// TODO: accept an option flag to select default float or int precisions
fn packAny(comptime OutStream: type, object: *py.PyObject, packer: *WriteStream(OutStream)) !void {
    // TODO: integers -> floats -> str -> bytes -> bool -> none -> array -> dict
    if (py.PyLong_CheckExact(object) != 0) {
        // deal with integers
        try packPyLong(OutStream, object, packer);
    } else if (py.PyFloat_Check(object) != 0) {
        // deal with floats
        try packPyFloat(OutStream, object, packer);
    } else if (object.ob_type == &py.PyUnicode_Type) {
        // deal with string
        // TODO: use PyUnicode_Check when there is an tag to lift limited API use
        try packPyString(OutStream, object, packer);
    } else if (object.ob_type == &py.PyBool_Type) {
        // deal with boolean
        try packPyBool(OutStream, object, packer);
    } else if (object == py.Py_None()) {
        // deal with None
        try packer.write(null);
    } else if (py.PySequence_Check(object) != 0) {
        // deal with sequences
        try packPySequence(OutStream, object, packer);
    } else if (py.PyMapping_Check(object) != 0) {
        // deal with mappings
        try packPyMapping(OutStream, object, packer);
    } else {
        // unsupported types
        const tp_object = py.PyObject_Type(object);
        defer Py_DECREF(tp_object, @src());
        const tp_name = py.PyObject_GetAttrString(tp_object, "__name__");
        defer Py_DECREF(tp_name, @src());
        const tp_bytes = py.PyUnicode_AsUTF8String(tp_name);
        defer Py_DECREF(tp_bytes, @src());

        const length: u64 = @intCast(py.PyBytes_Size(tp_bytes));
        const ptr: [*]u8 = @ptrCast(py.PyBytes_AsString(tp_bytes));

        var buffer: [64]u8 = [_]u8{0} ** 64;
        _ = std.fmt.bufPrint(&buffer, "unsupported type: {s}", .{ptr[0..length]}) catch {
            // fallback to default text
            py.PyErr_SetString(py.PyExc_TypeError, "unsupported type: <failed to read type info>");
            return error.UnsupportedType;
        };
        py.PyErr_SetString(py.PyExc_TypeError, &buffer);
        return error.UnsupportedType;
    }
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
