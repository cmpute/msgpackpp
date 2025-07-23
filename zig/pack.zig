const std = @import("std");
const assert = std.debug.assert;
const native_endian = @import("builtin").target.cpu.arch.endian();
const big_endian = std.builtin.Endian.big;
const little_endian = std.builtin.Endian.little;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const BitStack = std.BitStack;

const common = @import("common.zig");
const Marker = common.Marker;
const ExtMarker = common.ExtMarker;

// Store the type and remaining size of the containers
const ContainerStatus = union(enum) {
    empty, // padding
    array: u32,
    str: u32,
    map: u33, // key-value
    bin: u64,
    ext: u64,
};

pub const PackOptions = struct {
    /// Arrays/slices of u8 are typically encoded as JSON strings.
    /// This option emits them as arrays of numbers instead.
    /// Does not affect calls to `objectField*()`.
    emit_strings_as_arrays: bool = false,

    /// Should unicode characters be escaped in strings?
    escape_unicode: bool = false,

    /// When true, renders numbers outside the range `+-1<<53` (the precise integer range of f64) as JSON strings in base 10.
    emit_nonportable_numbers_as_strings: bool = false,
};

/// Pack an unsigned integer into buffer (in little-endian order) and return how many bytes are necessary
fn packIntTight(value: anytype) struct { buf: [(@typeInfo(@TypeOf(value)).int.bits + 7) / 8]u8, start: usize } {
    const T = @TypeOf(value);
    if (@typeInfo(T).int.signedness == .signed)
        @compileError("the function only accepts an unsigned integer");

    // write to bytes
    const int_bytes = (@typeInfo(T).int.bits + 7) / 8;
    var buf: [int_bytes]u8 = undefined;
    std.mem.writeInt(std.meta.Int(.unsigned, int_bytes * 8), &buf, value, big_endian);

    // remove leading zeros
    var pos: usize = 0;
    while (pos < int_bytes and buf[pos] == 0) {
        pos += 1;
    }
    return .{ .buf = buf, .start = pos };
}

pub fn writeStream(
    out_stream: anytype,
    options: PackOptions,
) WriteStream(@TypeOf(out_stream), .{ .checked_to_fixed_depth = 256 }) {
    return writeStreamMaxDepth(out_stream, options, 256);
}

pub fn writeStreamMaxDepth(
    out_stream: anytype,
    options: PackOptions,
    comptime max_depth: usize,
) WriteStream(
    @TypeOf(out_stream),
    .{ .checked_to_fixed_depth = max_depth },
) {
    return WriteStream(
        @TypeOf(out_stream),
        .{ .checked_to_fixed_depth = max_depth },
    ).init(undefined, out_stream, options);
}

/// Writes JSON ([RFC8259](https://tools.ietf.org/html/rfc8259)) formatted data
/// to a stream.
///
/// The sequence of method calls to write JSON content must follow this grammar:
/// ```
///  <once> = <value>
///  <value> =
///    | <object>
///    | <array>
///    | write
///    | print
///    | <writeRawStream>
///  <object> = beginObject ( <field> <value> )* endObject
///  <field> = objectField | objectFieldRaw | <objectFieldRawStream>
///  <array> = beginArray ( <value> )* endArray
///  <writeRawStream> = beginWriteRaw ( stream.writeAll )* endWriteRaw
///  <objectFieldRawStream> = beginObjectFieldRaw ( stream.writeAll )* endObjectFieldRaw
/// ```
///
/// The `safety_checks_hint` parameter determines how much memory is used to enable assertions that the above grammar is being followed,
/// please refer to the std.json.stringify.WriteStream for detailed information.
pub fn WriteStream(
    comptime OutStream: type,
    comptime safety_checks_hint: union(enum) {
        checked_to_arbitrary_depth,
        checked_to_fixed_depth: usize, // Rounded up to the nearest multiple of 8.
        assumed_correct,
    },
) type {
    return struct {
        const Self = @This();
        const build_mode_has_safety = switch (@import("builtin").mode) {
            .Debug, .ReleaseSafe => true,
            .ReleaseFast, .ReleaseSmall => false,
        };
        const safety_checks: @TypeOf(safety_checks_hint) = if (build_mode_has_safety)
            safety_checks_hint
        else
            .assumed_correct;

        pub const Stream = OutStream;
        pub const Error = switch (safety_checks) {
            .checked_to_arbitrary_depth => Stream.Error || error{OutOfMemory},
            .checked_to_fixed_depth, .assumed_correct => Stream.Error,
        };

        options: PackOptions,
        stream: OutStream,

        nesting_stack: switch (safety_checks) {
            .checked_to_arbitrary_depth => ArrayList(ContainerStatus),
            .checked_to_fixed_depth => |fixed_buffer_size| struct {
                data: [fixed_buffer_size]ContainerStatus,
                size: usize = 0,
            },
            .assumed_correct => void,
        },

        pub fn init(safety_allocator: Allocator, stream: OutStream, options: PackOptions) Self {
            return .{
                .options = options,
                .stream = stream,
                .nesting_stack = switch (safety_checks) {
                    .checked_to_arbitrary_depth => BitStack.init(safety_allocator),
                    .checked_to_fixed_depth => |fixed_buffer_size| .{
                        .data = [_]ContainerStatus{ContainerStatus.empty} ** (fixed_buffer_size),
                        .size = 0,
                    },
                    .assumed_correct => {},
                },
            };
        }

        /// Only necessary with .checked_to_arbitrary_depth.
        pub fn deinit(self: *Self) void {
            switch (safety_checks) {
                .checked_to_arbitrary_depth => self.nesting_stack.deinit(),
                .checked_to_fixed_depth, .assumed_correct => {},
            }
            self.* = undefined;
        }

        fn peekStack(self: *Self) ?*ContainerStatus {
            switch (safety_checks) {
                .checked_to_arbitrary_depth => {
                    if (self.nesting_stack.items.len != 0) {
                        return &self.nesting_stack[self.nesting_stack.items.len - 1];
                    } else return null;
                },
                .checked_to_fixed_depth => {
                    if (self.nesting_stack.size != 0) {
                        return &self.nesting_stack.data[self.nesting_stack.size - 1];
                    } else return null;
                },
                .assumed_correct => return null,
            }
        }

        fn pushContainer(self: *Self, status: ContainerStatus) Error!void {
            switch (safety_checks) {
                .checked_to_arbitrary_depth => try self.nesting_stack.append(status),
                .checked_to_fixed_depth => |depth| {
                    if (self.nesting_stack.size == depth) {
                        // stack full, TODO: change to error?
                        assert(false);
                    }
                    self.nesting_stack.data[self.nesting_stack.size] = status;
                    self.nesting_stack.size += 1;
                },
                .assumed_correct => {},
            }
        }

        fn popContainer(self: *Self, expect: ContainerStatus) void {
            var top: ContainerStatus = .empty;
            switch (safety_checks) {
                .checked_to_arbitrary_depth => {
                    top = self.nesting_stack.pop() orelse .empty;
                },
                .checked_to_fixed_depth => {
                    self.nesting_stack.size -= 1;
                    top = self.nesting_stack.data[self.nesting_stack.size];
                },
                .assumed_correct => {},
            }

            // FIXME: why zig doesn't support top == expect?
            switch (expect) {
                .array => assert(top == .array),
                .bin => assert(top == .bin),
                .str => assert(top == .str),
                .map => assert(top == .map),
                .ext => assert(top == .ext),
                .empty => assert(top == .empty),
            }
        }

        pub fn beginArray(self: *Self, length: u32) Error!void {
            try switch (length) {
                0 => self.stream.writeByte(@intFromEnum(Marker.fixArray)),
                1...15 => self.stream.writeByte(@intFromEnum(Marker.fixArray) + @as(u8, @intCast(length))),
                16...((1 << 16) - 1) => self.stream.writeByte(@intFromEnum(Marker.array16)),
                (1 << 16)...((1 << 32) - 1) => self.stream.writeByte(@intFromEnum(Marker.array32)),
            };

            try self.pushContainer(ContainerStatus{ .array = length });
        }
        pub fn endArray(self: *Self) Error!void {
            self.popContainer(ContainerStatus{ .array = 0 });
        }

        pub fn beginMap() void {} // TODO
        pub fn endMap() void {} // TODO

        pub fn beginExt(self: *Self, length: u64, type_tag: i8) Error!void {
            if (length < 16 and type_tag >= -8 and type_tag < 8) {
                const tag_hi: u8 = @intCast(length);
                const tag_lo: u8 = @bitCast(type_tag & 0xf);
                try self.stream.writeByte(@intFromEnum(Marker.fixExt));
                try self.stream.writeByte(tag_hi << 4 | tag_lo);
            } else {
                if (length < (1 << 8)) {
                    try self.stream.writeByte(@intFromEnum(Marker.ext8));
                    try self.stream.writeByte(@intCast(length));
                } else if (length < (1 << 16)) {
                    try self.stream.writeByte(@intFromEnum(Marker.ext16));
                    try self.stream.writeInt(u16, @intCast(length), big_endian);
                } else if (length < (1 << 32)) {
                    try self.stream.writeByte(@intFromEnum(Marker.ext32));
                    try self.stream.writeInt(u32, @intCast(length), big_endian);
                } else {
                    try self.stream.writeByte(@intFromEnum(Marker.ext64));
                    try self.stream.writeInt(u64, @intCast(length), big_endian);
                }
                try self.stream.writeByte(@bitCast(type_tag));
            }

            try self.pushContainer(ContainerStatus{ .ext = length });
        }
        pub fn endExt(self: *Self) Error!void {
            self.popContainer(ContainerStatus{ .ext = 0 });
        }

        /// Reduce the remaining size of the container at the stack top, return if the top container should be removed.
        fn shrinkContainer(self: *Self, size: usize) void {
            const status = self.peekStack() orelse return;
            switch (status.*) {
                .empty => unreachable,
                .array, .str => |*len| {
                    const s = @as(u32, @intCast(size));
                    assert(len.* >= s); // TODO: produce error set?
                    len.* -= s;
                },
                .map => |*len| {
                    const s = @as(u32, @intCast(size));
                    assert(len.* >= s);
                    len.* -= s;
                },
                .bin, .ext => |*len| {
                    const s = @as(u64, @intCast(size));
                    assert(len.* >= s);
                    len.* -= s;
                },
            }
        }

        fn valueDone(self: *Self) void {
            self.shrinkContainer(1);
        }

        /// Renders the given Zig value as Msgpack++ bytes.
        pub fn write(self: *Self, value: anytype) Error!void {
            const T = @TypeOf(value);
            switch (@typeInfo(T)) {
                .int => |int_type| {
                    if (value < (1 << 8)) {
                        if (value < (1 << 7)) {
                            // fixnum
                            try self.stream.writeByte(@intFromEnum(Marker.fixPos) + @as(u8, @intCast(value)));
                        } else {
                            // unsigned 8
                            try self.stream.writeByte(@intFromEnum(Marker.uint8));
                            try self.stream.writeByte(@as(u8, @intCast(value)));
                        }
                    } else if (value < (1 << 64)) {
                        if (value < (1 << 16)) {
                            // unsigned 16
                            try self.stream.writeByte(@intFromEnum(Marker.uint16));
                            try self.stream.writeInt(u16, @intCast(value), big_endian);
                        } else if (value < (1 << 32)) {
                            // unsigned 32
                            try self.stream.writeByte(@intFromEnum(Marker.uint32));
                            try self.stream.writeInt(u32, @intCast(value), big_endian);
                        } else {
                            // unsigned 64
                            try self.stream.writeByte(@intFromEnum(Marker.uint64));
                            try self.stream.writeInt(u64, @intCast(value), big_endian);
                        }
                    } else if (value < (1 << 120)) {
                        // cast to u128 before packing to reduce memory usage
                        const pack = packIntTight(@as(u128, @intCast(value)));
                        const bytes = pack.buf[pack.start..];
                        try self.beginExt(bytes.len, @intFromEnum(ExtMarker.ap_pos_int));
                        try self.stream.writeAll(bytes);
                        try self.endExt();
                    } else {
                        const total_bytes: u16 = (int_type.bits - @clz(value) + 7) / 8; // largest int type supported in Zig has 2^16 -1 bytes
                        try self.beginExt(total_bytes, @intFromEnum(ExtMarker.ap_pos_int));

                        // serialize 64 bits at a time
                        var start: std.math.Log2Int(T) = @intCast(total_bytes - total_bytes % 8);
                        if (total_bytes % 8 > 0) {
                            const pack = packIntTight(@as(u64, @intCast(value >> (8 * start))));
                            const bytes = pack.buf[pack.start..];
                            try self.writeBytes(bytes);
                        }
                        while (start > 0) {
                            start -= 8;
                            const segment: u64 = @truncate(value >> (8 * start));
                            try self.stream.writeInt(u64, segment, big_endian);
                            self.shrinkContainer(8);
                        }

                        try self.endExt();
                    }

                    self.valueDone();
                    return;
                },
                .comptime_int => {
                    return self.write(@as(std.math.IntFittingRange(value, value), value));
                },
                .float => |float_type| {
                    switch (float_type.bits) {
                        32 => {
                            try self.stream.writeByte(@intFromEnum(Marker.float32));
                            try self.stream.writeInt(u32, @bitCast(value), big_endian);
                        },
                        64 => {
                            try self.stream.writeByte(@intFromEnum(Marker.float64));
                            try self.stream.writeInt(u64, @bitCast(value), big_endian);
                        },
                        128 => {},
                        else => @compileError("unsupported float precision"),
                    }

                    self.valueDone();
                    return;
                },
                .comptime_float => {
                    return self.write(@as(value, f64));
                },
                .bool => {
                    try self.stream.writeByte(if (value) @intFromEnum(Marker.true) else @intFromEnum(Marker.false));
                    self.valueDone();
                    return;
                },
                .null => {
                    try self.stream.writeByte(@intFromEnum(Marker.null));
                    self.valueDone();
                    return;
                },
                .optional => {
                    if (value) |payload| {
                        return try self.write(payload);
                    } else {
                        return try self.write(null);
                    }
                },
                .pointer => |ptr_info| switch (ptr_info.size) {
                    .one => switch (@typeInfo(ptr_info.child)) {
                        .array => {
                            // Coerce `*[N]T` to `[]const T`.
                            const Slice = []const std.meta.Elem(ptr_info.child);
                            return self.write(@as(Slice, value));
                        },
                        else => {
                            return self.write(value.*);
                        },
                    },
                    // .many, .slice => {
                    //     if (ptr_info.size == .many and ptr_info.sentinel() == null)
                    //         @compileError("unable to stringify type '" ++ @typeName(T) ++ "' without sentinel");
                    //     const slice = if (ptr_info.size == .many) std.mem.span(value) else value;
                    //
                    //     if (ptr_info.child == u8) {
                    //         // This is a []const u8, or some similar Zig string.
                    //         if (!self.options.emit_strings_as_arrays and std.unicode.utf8ValidateSlice(slice)) {
                    //             return self.stringValue(slice);
                    //         }
                    //     }
                    //
                    //     try self.beginArray();
                    //     for (slice) |x| {
                    //         try self.write(x);
                    //     }
                    //     try self.endArray();
                    //     return;
                    // },
                    else => @compileError("Unable to stringify type '" ++ @typeName(T) ++ "'"),
                },
                .array => {
                    // Coerce `[N]T` to `*const [N]T` (and then to `[]const T`).
                    return self.write(&value);
                },
                .vector => |info| {
                    const array: [info.len]info.child = value;
                    return self.write(&array);
                },
                else => {
                    if (std.meta.hasFn(T, "msgPack")) {
                        return value.msgPack(self);
                    } else {
                        @compileError("Unable to pack type '" ++ @typeName(T) ++ "'");
                    }
                },
            }
        }

        pub fn writeBytes(self: *Self, value: []const u8) Error!void {
            try self.stream.writeAll(value);
            self.shrinkContainer(value.len);
        }
    };
}
