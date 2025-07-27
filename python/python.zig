const std = @import("std");
pub const py = @cImport({
    @cDefine("PY_SSIZE_T_CLEAN", {});
    @cDefine("Py_LIMITED_API", "0x030500f0"); // TODO: provide switch to lift this limitation
    @cInclude("Python.h");
});

// override the translated Py_DECREF to automatically inject line numbers in debug builds
pub inline fn Py_DECREF(object: *py.PyObject, src: std.builtin.SourceLocation) void {
    // py.Py_DECREF(src.fn_name, @as(c_int, @intCast(src.line)), object);
    _ = src;
    py.Py_DecRef(object);
}
