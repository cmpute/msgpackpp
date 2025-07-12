const std = @import("std");
const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;
const bufPrint = std.fmt.bufPrint;

const pack = @import("pack.zig");
const writeStream = @import("pack.zig").writeStream;

fn test_single_value_wbuf(v: anytype, s: []const u8, comptime n: usize) !void {
    var out_buf: [n]u8 = undefined;
    var slice_stream = std.io.fixedBufferStream(&out_buf);
    const out = slice_stream.writer();
    var w = writeStream(out, .{});
    try w.write(v);

    var fmt_buf: [2 * n]u8 = undefined;
    try expectEqualStrings(s, try bufPrint(&fmt_buf, "{X}", .{std.fmt.fmtSliceHexUpper(slice_stream.getWritten())}));
}

fn test_single_value(v: anytype, s: []const u8) !void {
    try test_single_value_wbuf(v, s, 1024);
}

test "pack integers" {
    const TestCase = struct { u2049, []const u8 };
    const test_cases = [_]TestCase{
        .{ 0, "00" },
        .{ 1, "01" },
        .{ 2, "02" },
        .{ 10, "0A" },
        .{ 100, "64" },
        .{ 127, "7F" },
        .{ 128, "CC80" },
        .{ (1 << 8) - 1, "CCFF" },
        .{ (1 << 8), "CD0100" },
        .{ (1 << 8) + 1, "CD0101" },
        .{ (1 << 16) - 1, "CDFFFF" },
        .{ (1 << 16), "CE00010000" },
        .{ (1 << 16) + 1, "CE00010001" },
        .{ (1 << 32) - 1, "CEFFFFFFFF" },
        .{ (1 << 32), "CF0000000100000000" },
        .{ (1 << 32) + 1, "CF0000000100000001" },
        .{ (1 << 64) - 1, "CFFFFFFFFFFFFFFFFF" },

        // represented as apint
        .{ (1 << 64), "D89E010000000000000000" },
        .{ (1 << 64) + 1, "D89E010000000000000001" },
        .{ (1 << 120) - 1, "D8FEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF" },
        .{ (1 << 120), "C710FE01000000000000000000000000000000" },
        .{ (1 << 120) + 1, "C710FE01000000000000000000000000000001" },
        .{ (1 << 128) - 1, "C710FEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF" },
    };

    for (test_cases) |case| {
        const v, const s = case;
        try test_single_value(v, s);
    }
}

test "pack floats" {
    var out_buf: [1024]u8 = undefined;
    var slice_stream = std.io.fixedBufferStream(&out_buf);
    const out = slice_stream.writer();

    {
        var w = writeStream(out, .{});
        try w.beginArray(2);
        try w.write(@as(f32, 12.34));
        try w.write(@as(f64, 12.34));
        try w.endArray();
    }
}
