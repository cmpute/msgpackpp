## MessagePack++ Extension Types

Here is the list of predefined extension types.

Name      | Type ID | Type family |
--------- | ------- | ----------- |
timestamp | -1 | Date and Time |
ap_pos_int  | -2 | Arbitrary Precision Number |
ap_neg_int  | -3 | Arbitrary Precision Number |
ap_float   | -4 | Arbitrary Precision Number |
ap_decimal | -5 | Arbitrary Precision Number |
packed_msg | -9 | Containers |
deflated_msg | -10 | Containers |
num_1d_array | -11 | Multi-dimensional Typed Array |
num_2d_array | -12 | Multi-dimensional Typed Array |
num_3d_array | -13 | Multi-dimensional Typed Array |
num_nd_array | -14 | Multi-dimensional Typed Array |

Only the types with id in range -1~8 can be used in the fixext format, therefore only short extension types should be assigned with id -1~8.

In the following of the specs page, the extension headers (ext type bytes like `0xc7`/`0xc8`/`0xc9`/`0xd7`/`0xd8`, and the extension type id) are abbreviated as `header(x)` in the following sections, where x is the type id.

### Date and Time extension types

Timestamp extension type is assigned to extension type `-1`. It defines 3 formats: 32-bit format, 64-bit format, and 96-bit format. The timescale used for this type is UTC time with Unix Epoch.

    timestamp 32 stores the number of seconds that have elapsed since 1970-01-01 00:00:00 UTC
    in an 32-bit unsigned integer:
    +--------+--------+--------+--------+--------+--------+
    |  0xd8  |00101111|   seconds in 32-bit unsigned int  |
    +--------+--------+--------+--------+--------+--------+

    timestamp 64 stores the number of seconds and nanoseconds that have elapsed since 1970-01-01 00:00:00 UTC
    in 32-bit unsigned integers:
    +--------+--------+--------+--------+--------+------|-+--------+--------+--------+--------+
    |  0xd8  |01001111| nanosec. in 30-bit unsigned int |   seconds in 34-bit unsigned int    |
    +--------+--------+--------+--------+--------+------^-+--------+--------+--------+--------+

    timestamp 96 stores the number of seconds and nanoseconds that have elapsed since 1970-01-01 00:00:00 UTC
    in 64-bit signed integer and 32-bit unsigned integer:
    +--------+--------+--------+--------+--------+--------+
    |  0xd8  |11001111|nanoseconds in 32-bit unsigned int |
    +--------+--------+--------+--------+--------+--------+
    +--------+--------+--------+--------+--------+--------+--------+--------+
                        seconds in 64-bit signed int                        |
    +--------+--------+--------+--------+--------+--------+--------+--------+

    * Timestamp 32 format can represent a timestamp in [1970-01-01 00:00:00 UTC, 2106-02-07 06:28:16 UTC) range. Nanoseconds part is 0.
    * Timestamp 64 format can represent a timestamp in [1970-01-01 00:00:00.000000000 UTC, 2514-05-30 01:53:04.000000000 UTC) range.
    * Timestamp 96 format can represent a timestamp in [-292277022657-01-27 08:29:52 UTC, 292277026596-12-04 15:30:08.000000000 UTC) range.
    * In timestamp 64 and timestamp 96 formats, nanoseconds must not be larger than 999999999.

The timestamp type with other sizes are reserved for future extension, but they will use UTC time with UNIX epoch. If other timescale is going to be used (for example: TAI time with PTP epoch), then another extension type id shall be used.

TODO: add timestamp 16 (or other sizes) to support days since epoch

### Arbitrary precision integer extension types

There are two arbitrary precision integer types defined in MessagePack++, one for non-negative integers (ap_pos_int) and one for negative integers (ap_neg_int), which are assigned to extension types `-2` and `-3`. All the bytes within the extension format represents the integer in big-endian.

    ap_pos_int stores an arbitrary precision big-endian positive integer
    +========+========+========+
    |  ext header(-2) |  data  |
    +========+========+========+

    ap_neg_int stores an arbitrary precision big-endian negative integer
    +========+========+========+
    |  ext header(-3) |  data  |
    +========+========+========+

    where
    * data denote the bytes of the absolute value of the integer in big endian representation.

### Arbitrary floating point extension types

The arbitrary floating point numbers are represented as `mantissa*base^expn`. The pre-defined bases in this format include base-2 (with type id `-4`) and base-10 (with type id `-5`). 

    ap_float stores an arbitrary precision base-2 floating point number
    +========+========+--------+========+
    |  ext header(-4) |x0yyyyyy|mantissa|   (compact format)
    +========+========+--------+========+
    +========+========+--------+========+========+
    |  ext header(-4) |x1nnnnnn|  expn  |mantissa|
    +========+========+--------+========+========+

    ap_decimal stores an arbitrary precision base-10 floating point number
    +========+========+--------+========+
    |  ext header(-5) |x0yyyyyy|mantissa|   (compact format)
    +========+========+--------+========+
    +========+========+--------+========+========+
    |  ext header(-4) |x1nnnnnn|  expn  |mantissa|
    +========+========+--------+========+========+

    where
    * x is the sign bit (1=negative)
    * yyyyyy is a 6-bit signed integer representing the exponent of the number
    * nnnnnn is a 6-bit unsigned integer representing the byte size of the exponent of the number (the `expn` bytes)
    * mantissa is an arbitrary precision integer in big endian representation.

> Some binary float formats like float16(fp16), brainfloat16(bf16), etc. are not included in the specs. The format of these kinds are evolving along the time. Please use user-defined extension types (with type id >= 0) to support these float formats, or convert them to a arbitrary precision representation.

### Container extension types

The container types are used to mark the payload of the extension is also an array of bytes in msgpackpp format. During For deserializing, the content of the wrapper should be transparently decoded when requested.

    packed_msg stores the msgpackpp-packed data as plain bytes in the payload of extension type.
    +========+========+========+
    |  ext header(-9) |  data  |
    +========+========+========+

    deflated_msg stores the msgpackpp-packed data compressed by the deflate algorithm (RFC 1951) in the payload of extension type.
    +========+========+========+
    | ext header(-10) |  data  |
    +========+========+========+

This type can be used for inserting an offset clue in a long data (for fast skipping), or used at the beginning of a file to note that this file stores MessagePack++ data.

### Multi-dimensional Typed Array extension type

This extension type represents a dense-packed numeric array.

    num_1d_array stores an one-dimensional numeric array.
    +========+========+--------+========+========+
    | ext header(-11) |AABBCDEE|  dim   |  data  |
    +========+========+--------+========+========+

    num_2d_array stores a two-dimensional numeric array.
    +========+========+--------+========+========+========+
    | ext header(-12) |AABBCDEE|  dim1  |  dim2  |  data  |
    +========+========+--------+========+========+========+

    num_3d_array stores a two-dimensional numeric array.
    +========+========+--------+========+========+========+========+
    | ext header(-13) |AABBCDEE|  dim1  |  dim2  |  dim3  |  data  |
    +========+========+--------+========+========+========+========+

    num_nd_array stores a n-dimensional numeric array.
    +========+========+--------+--------+========+========+
    | ext header(-14) |AABBCDEE|  ndim  |  dims  |  data  |
    +========+========+--------+--------+========+========+

    where
    * dim, dim1, dim2, dim3 are unsigned integer with big-endianness.
      The size of these integers are determined by the flag EE.
    * dims is an array of unsigned integers, with length determined by ndim, size of each integer determined by EE.
    * ndim is an unsigned byte representing the number of elements in dims.
    * AA are two bits representing the element type: 00=unsigned int, 01=signed int, 10=float, 11=complext
    * BB are two bits representing the size of the element, defined as follows:
        +-------+----------+----------+-----------+-------------+
        | BB\AA | uint(00) | sint(01) | float(10) | complex(11) |
        +=======+==========+==========+===========+=============+
        | 00    | uint8    | int8     | float16   | complex32   |
        +-------+----------+----------+-----------+-------------+
        | 01    | uint16   | int16    | float32   | complex64   |
        +-------+----------+----------+-----------+-------------+
        | 10    | uint32   | int32    | float64   | complex128  |
        +-------+----------+----------+-----------+-------------+
        | 11    | uint64   | int64    | float128  | complex256  |
        +-------+----------+----------+-----------+-------------+
        note that:
        * float16 and float128 follows the extended definitions in IEEE 754 standard
        * complex numbers are composed of two floats with half its size
    * C is the endianess bit: 0=big-endian, 1=little-endian
    * D is the ordering bit: 0=row-major, 1=column-major
    * EE are two bits representing the size of each dimension length: 00=uint8, 01=uint16, 02=uint32, 03=uint64.
      For example, when EE=01, for a two-dimensinal array, dim1 and dim2 are all 16-bit unsigned integers.
    * data is the actual binary representation of all the numbers in the multi-dimensional array. 
      The data must be contiguous to enable efficient memory mapping.

Since endianness makes no difference for uint8 and int8, it's forced that uint8 and int8 use the default big-endianess. The type tag combining uint8 and little-endian is representing bool, the type tag combining int8 and the other endianess is reserved.

Note that the bool arrays are always bit-packed. To prevent bit packing, save the array as a uint8 array.
