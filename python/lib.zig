const py = @import("python.zig").py;
const std = @import("std");
const packAnyToBytes = @import("pack_py.zig").packAnyToBytes;
const print = std.debug.print;

fn hello(self: [*c]py.PyObject, args: [*c]py.PyObject) callconv(.C) [*]py.PyObject {
    _ = self;
    _ = args;
    print("welcome to ziglang\n", .{});
    return py.Py_BuildValue("");
}

pub fn pymethod(comptime name: [:0]const u8, func: anytype, flags: c_int) py.PyMethodDef {
    return py.PyMethodDef{
        .ml_name = name,
        .ml_meth = func,
        .ml_flags = flags,
        .ml_doc = null,
    };
}

const pymethod_sentinel = py.PyMethodDef{
    .ml_name = null,
    .ml_meth = null,
    .ml_flags = 0,
    .ml_doc = null,
};
const pymethod_hello = pymethod("hello", hello, py.METH_NOARGS);
const pymethod_pack = pymethod("pack", packAnyToBytes, py.METH_VARARGS);
var pymethods = [_]py.PyMethodDef{ pymethod_hello, pymethod_pack, pymethod_sentinel };

var module = py.PyModuleDef{
    .m_base = py.PyModuleDef_Base{
        .ob_base = py.PyObject{
            .ob_refcnt = 1,
            .ob_type = null,
        },
        .m_init = null,
        .m_index = 0,
        .m_copy = null,
    },
    .m_name = "msgpackpp",
    .m_doc = null,
    .m_size = -1,
    .m_methods = &pymethods,
    .m_slots = null,
    .m_traverse = null,
    .m_clear = null,
    .m_free = null,
};

pub export fn PyInit_msgpackpp() [*]py.PyObject {
    return py.PyModule_Create(&module);
}
