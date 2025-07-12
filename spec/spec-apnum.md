> This page describes the definitions of arbitrary precision (ap-) number extension types.

### Arbitrary precision integer extension types

There are two arbitrary precision integer types defined in MessagePack++, one for non-negative integers (ap_pos_int) and one for negative integers (ap_neg_int), which are assigned to extension types `-2` and `-3`. All the bytes within the extension format represents the integer in big-endian.

    ap_pos_int stores an arbitrary precision big-endian positive integer
    +--------+--------+--------+========+
    |  0xc7  |YYYYYYYY|   -2   | apint  |
    +--------+--------+--------+========+
    
    when the non-negative integer is less than 2^120, it can be stored more efficiently
    +--------+--------+========+
    |  0xd8  |XXXX1110| apint  |
    +--------+--------+========+

    ap_neg_int stores an arbitrary precision big-endian negative integer
    +--------+--------+--------+========+
    |  0xc7  |YYYYYYYY|   -3   | apint  |
    +--------+--------+--------+========+

    when the negative integer is greater than or equal to -2^120, it can be stored more efficiently
    +--------+--------+========+
    |  0xd8  |XXXX1101| apint  |
    +--------+--------+========+

    where
    * XXXX is a 4-bit unsigned integer which represents N
    * YYYYYYYY is a 8-bit unsigned integer which represents N
    * N is the byte length of the integer
    * apint is the bytes of the absolute value of the integer in big endian representation, following the two's complement notation.

### Arbitrary floating point extension types

decimal float ap_dec: m*10^e
binary float ap_float: m*2^e

each contains two part, first is an unsigned integer representing exponent `e` packed by MessagePack++, second is the binary representation of mantissa `m`, whose length can be deducted from the total length.

定长的float（fp16, bf16等）和decimal（IEEE decimal32 decimal64等）暂不做统一支持（因为非常用的浮点数标准一直在变），用户可以选择利用apfloat/apdecimal，或者使用自定义ext编号
