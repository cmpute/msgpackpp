const common_impl = @import("../zig/common.zig");
const pack_impl = @import("../zig/pack.zig");

const py = @cImport({
    @cDefine("PY_SSIZE_T_CLEAN", {});
    @cInclude("Python.h");
});
const std = @import("std");
const print = std.debug.print;

fn pack(self: [*c]py.PyObject, args: [*c]py.PyObject) callconv(.C) ?*py.PyObject {
    _ = self;
    var num_obj: *py.PyObject = undefined;

    // 解析参数，"O"表示接受一个Python对象
    if (py.PyArg_ParseTuple(args, "O", &num_obj) == 0) {
        return null;
    }

    // 检查是否为普通整数
    if (py.PyLong_CheckExact(num_obj) != 0) {
        // 尝试将其作为普通整数处理
        const value = py.PyLong_AsLong(num_obj);
        if (value == -1 and py.PyErr_Occurred() != 0) {
            // 处理超出普通整数范围的情况
            py.PyErr_Clear();

            // 调用 int.to_bytes() 方法
            const bit_length = py.PyObject_CallMethod(num_obj, "bit_length", null);
            if (bit_length == null) {
                return null;
            }
            const byte_length = @divFloor(py.PyLong_AsLongLong(bit_length) + 7, 8);
            const byte_order = "big";
            const bytes_obj = py.PyObject_CallMethod(num_obj, "to_bytes", "Ls", byte_length, byte_order);

            if (bytes_obj == null) {
                return null;
            }

            const length = py.PyBytes_Size(bytes_obj);
            print("Long integer byte length: {}\n", .{length});
        } else {
            // 普通整数处理
            print("Integer value plus one: {}\n", .{value + 1});
        }
    } else {
        // 不是整数类型
        py.PyErr_SetString(py.PyExc_TypeError, "Argument must be an integer.");
        return null;
    }

    // 返回None
    py.Py_IncRef(py.Py_None());
    return py.Py_None();
}
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
const pymethod_pack = pymethod("pack", pack, py.METH_VARARGS);
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
