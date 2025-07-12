pub const Marker = enum(u8) {
    null = 0xc0,
    false = 0xc2,
    true = 0xc3,
    uint8 = 0xcc,
    uint16 = 0xcd,
    uint32 = 0xce,
    uint64 = 0xcf,
    int8 = 0xd0,
    int16 = 0xd1,
    int32 = 0xd2,
    int64 = 0xd3,
    float32 = 0xca,
    float64 = 0xcb,
    complex64 = 0xd4, // msgpack: fixext1
    complex128 = 0xd5, // msgpack: fixext2

    // small containers
    fixPos = 0x00,
    fixNeg = 0xe0,
    fixMap = 0x80,
    fixArray = 0x90,
    fixStr = 0xa0,
    fixExt = 0xd8,

    // large containers
    bin8 = 0xc4,
    bin16 = 0xc5,
    bin32 = 0xc6,
    bin64 = 0xd6, // msgpack: fixext4
    ext8 = 0xc7,
    ext16 = 0xc8,
    ext32 = 0xc9,
    ext64 = 0xd7, // msgpack: fixext8
    str8 = 0xd9,
    str16 = 0xda,
    str32 = 0xdb,
    array16 = 0xdc,
    array32 = 0xdd,
    map16 = 0xde,
    map32 = 0xdf,
};

pub const ExtMarker = enum(u8) {
    timestamp = 0xff,
    ap_pos_int = 0xff - 1,
    ap_neg_int = 0xff - 2,
    ap_float = 0xff - 3,
    ap_decimal = 0xff - 4,
    bit_array = 0xff - 5,
    packed_msg = 0xff - 8,
    deflated_msg = 0xff - 9,
    num_1d_arry = 0xff - 10,
    num_2d_array = 0xff - 11,
    num_3d_array = 0xff - 12,
    num_nd_array = 0xff - 13,
};

/// Define all the type tags within msgpackpp
pub const MarkerValue = union(Marker) {
    null,
    false,
    true,
    uint8,
    uint16,
    uint32,
    uint64,
    int8,
    int16,
    int32,
    int64,
    float32,
    float64,
    complex64, // msgpack: fixext1
    complex128, // msgpack: fixext2

    // small containers
    fixPos: u7,
    fixNeg: i5,
    fixMap: u4,
    fixArray: u4,
    fixStr: u5,
    fixExt,

    // large containers
    bin8,
    bin16,
    bin32,
    bin64, // msgpack: fixext4
    ext8,
    ext16,
    ext32,
    ext64, // msgpack: fixext8
    str8,
    str16,
    str32,
    array16,
    array32,
    map16,
    map32,
};
