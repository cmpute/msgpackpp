
## MessagePack++ Basic Formats

### Overview

format name     | first byte (in binary) | first byte (in hex) | old v2 format |
--------------- | ---------------------- | ------------------- | ------------- |
positive fixint | 0xxxxxxx               | 0x00 - 0x7f         |               |
fixmap          | 1000xxxx               | 0x80 - 0x8f         |               |
fixarray        | 1001xxxx               | 0x90 - 0x9f         |               |
fixstr          | 101xxxxx               | 0xa0 - 0xbf         |               |
nil             | 11000000               | 0xc0                |               |
(never used)    | 11000001               | 0xc1                |               |
false           | 11000010               | 0xc2                |               |
true            | 11000011               | 0xc3                |               |
bin 8           | 11000100               | 0xc4                |               |
bin 16          | 11000101               | 0xc5                |               |
bin 32          | 11000110               | 0xc6                |               |
ext 8           | 11000111               | 0xc7                |               |
ext 16          | 11001000               | 0xc8                |               |
ext 32          | 11001001               | 0xc9                |               |
float 32        | 11001010               | 0xca                |               |
float 64        | 11001011               | 0xcb                |               |
uint 8          | 11001100               | 0xcc                |               |
uint 16         | 11001101               | 0xcd                |               |
uint 32         | 11001110               | 0xce                |               |
uint 64         | 11001111               | 0xcf                |               |
int 8           | 11010000               | 0xd0                |               |
int 16          | 11010001               | 0xd1                |               |
int 32          | 11010010               | 0xd2                |               |
int 64          | 11010011               | 0xd3                |               |
complex 64      | 11010100               | 0xd4                | fixext 1      |
complex 128     | 11010101               | 0xd5                | fixext 2      |
bin 64          | 11010110               | 0xd6                | fixext 4      |
ext 64          | 11010111               | 0xd7                | fixext 8      |
fixext          | 11011000               | 0xd8                | fixext 16     |
str 8           | 11011001               | 0xd9                |               |
str 16          | 11011010               | 0xda                |               |
str 32          | 11011011               | 0xdb                |               |
array 16        | 11011100               | 0xdc                |               |
array 32        | 11011101               | 0xdd                |               |
map 16          | 11011110               | 0xde                |               |
map 32          | 11011111               | 0xdf                |               |
negative fixint | 111xxxxx               | 0xe0 - 0xff         |               |

> Note: 0xc1 can be used as a signal in applications. Potential usages include splitting message packs, escape non-msgpack data etc.

### Notation in diagrams

    one byte:
    +--------+
    |        |
    +--------+

    a variable number of bytes:
    +========+
    |        |
    +========+

    variable number of objects stored in MessagePack++ format:
    +~~~~~~~~~~~~~~~~~+
    |                 |
    +~~~~~~~~~~~~~~~~~+

`X`, `Y`, `Z` and `A` are the symbols that will be replaced by an actual bit.

### nil format

Nil format stores nil in 1 byte.

    nil:
    +--------+
    |  0xc0  |
    +--------+

### bool format family

Bool format family stores false or true in 1 byte.

    false:
    +--------+
    |  0xc2  |
    +--------+

    true:
    +--------+
    |  0xc3  |
    +--------+

### int format family

Int format family stores an integer in 1, 2, 3, 5, or 9 bytes. An integer is represented in two's complement notation.

    positive fixint stores 7-bit positive integer
    +--------+
    |0XXXXXXX|
    +--------+

    negative fixint stores 5-bit negative integer
    +--------+
    |111YYYYY|
    +--------+

    * 0XXXXXXX is 8-bit unsigned integer
    * 111YYYYY is 8-bit signed integer

    uint 8 stores a 8-bit unsigned integer
    +--------+--------+
    |  0xcc  |ZZZZZZZZ|
    +--------+--------+

    uint 16 stores a 16-bit big-endian unsigned integer
    +--------+--------+--------+
    |  0xcd  |ZZZZZZZZ|ZZZZZZZZ|
    +--------+--------+--------+

    uint 32 stores a 32-bit big-endian unsigned integer
    +--------+--------+--------+--------+--------+
    |  0xce  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|
    +--------+--------+--------+--------+--------+

    uint 64 stores a 64-bit big-endian unsigned integer
    +--------+--------+--------+--------+--------+--------+--------+--------+--------+
    |  0xcf  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|
    +--------+--------+--------+--------+--------+--------+--------+--------+--------+

    int 8 stores a 8-bit signed integer
    +--------+--------+
    |  0xd0  |ZZZZZZZZ|
    +--------+--------+

    int 16 stores a 16-bit big-endian signed integer
    +--------+--------+--------+
    |  0xd1  |ZZZZZZZZ|ZZZZZZZZ|
    +--------+--------+--------+

    int 32 stores a 32-bit big-endian signed integer
    +--------+--------+--------+--------+--------+
    |  0xd2  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|
    +--------+--------+--------+--------+--------+

    int 64 stores a 64-bit big-endian signed integer
    +--------+--------+--------+--------+--------+--------+--------+--------+--------+
    |  0xd3  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|
    +--------+--------+--------+--------+--------+--------+--------+--------+--------+

### float format family

Float format family stores a floating point number in 5 bytes or 9 bytes.

    float 32 stores a floating point number in IEEE 754 single precision floating point number format:
    +--------+--------+--------+--------+--------+
    |  0xca  |XXXXXXXX|XXXXXXXX|XXXXXXXX|XXXXXXXX|
    +--------+--------+--------+--------+--------+

    float 64 stores a floating point number in IEEE 754 double precision floating point number format:
    +--------+--------+--------+--------+--------+--------+--------+--------+--------+
    |  0xcb  |YYYYYYYY|YYYYYYYY|YYYYYYYY|YYYYYYYY|YYYYYYYY|YYYYYYYY|YYYYYYYY|YYYYYYYY|
    +--------+--------+--------+--------+--------+--------+--------+--------+--------+

    where
    * XXXXXXXX_XXXXXXXX_XXXXXXXX_XXXXXXXX is a big-endian IEEE 754 single precision floating point number.
      Extension of precision from single-precision to double-precision does not lose precision.
    * YYYYYYYY_YYYYYYYY_YYYYYYYY_YYYYYYYY_YYYYYYYY_YYYYYYYY_YYYYYYYY_YYYYYYYY is a big-endian
      IEEE 754 double precision floating point number

### complex format family

Complex format family stores a complex number with two floating point elements in 9 or 17 bytes

    complex 64 stores a complex number with two single precision floating point numbers
    +--------+--------+--------+--------+--------+--------+--------+--------+--------+
    |  0xd4  |XXXXXXXX|XXXXXXXX|XXXXXXXX|XXXXXXXX|YYYYYYYY|YYYYYYYY|YYYYYYYY|YYYYYYYY|
    +--------+--------+--------+--------+--------+--------+--------+--------+--------+

    complex 128 stores a complex number with two double precision floating point numbers
    +--------+--------+--------+--------+--------+--------+--------+--------+--------+
    |  0xd5  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|
    +--------+--------+--------+--------+--------+--------+--------+--------+--------+
    +--------+--------+--------+--------+--------+--------+--------+--------+
     AAAAAAAA|AAAAAAAA|AAAAAAAA|AAAAAAAA|AAAAAAAA|AAAAAAAA|AAAAAAAA|AAAAAAAA|
    +--------+--------+--------+--------+--------+--------+--------+--------+

    where
    * XXXXXXXX_XXXXXXXX_XXXXXXXX_XXXXXXXX is a big-endian IEEE 754 single precision
      floating point number to represent real part.
    * YYYYYYYY_YYYYYYYY_YYYYYYYY_YYYYYYYY is a big-endian IEEE 754 single precision
      floating point number to represent imaginary real part.
    * ZZZZZZZZ_ZZZZZZZZ_ZZZZZZZZ_ZZZZZZZZ_ZZZZZZZZ_ZZZZZZZZ_ZZZZZZZZ_ZZZZZZZZ is a big-endian
      IEEE 754 double precision floating point number to represent real part.
    * AAAAAAAA_AAAAAAAA_AAAAAAAA_AAAAAAAA_AAAAAAAA_AAAAAAAA_AAAAAAAA_AAAAAAAA is a big-endian
      IEEE 754 double precision floating point number to represent imaginary part.

### str format family

Str format family stores a byte array in 1, 2, 3, or 5 bytes of extra bytes in addition to the size of the byte array.

    fixstr stores a byte array whose length is upto 31 bytes:
    +--------+========+
    |101XXXXX|  data  |
    +--------+========+

    str 8 stores a byte array whose length is upto (2^8)-1 bytes:
    +--------+--------+========+
    |  0xd9  |YYYYYYYY|  data  |
    +--------+--------+========+

    str 16 stores a byte array whose length is upto (2^16)-1 bytes:
    +--------+--------+--------+========+
    |  0xda  |ZZZZZZZZ|ZZZZZZZZ|  data  |
    +--------+--------+--------+========+

    str 32 stores a byte array whose length is upto (2^32)-1 bytes:
    +--------+--------+--------+--------+--------+========+
    |  0xdb  |AAAAAAAA|AAAAAAAA|AAAAAAAA|AAAAAAAA|  data  |
    +--------+--------+--------+--------+--------+========+

    where
    * XXXXX is a 5-bit unsigned integer which represents N
    * YYYYYYYY is a 8-bit unsigned integer which represents N
    * ZZZZZZZZ_ZZZZZZZZ is a 16-bit big-endian unsigned integer which represents N
    * AAAAAAAA_AAAAAAAA_AAAAAAAA_AAAAAAAA is a 32-bit big-endian unsigned integer which represents N
    * N is the length of data

### bin format family

Bin format family stores an byte array in 2, 3, or 5 bytes of extra bytes in addition to the size of the byte array.

    bin 8 stores a byte array whose length is upto (2^8)-1 bytes:
    +--------+--------+========+
    |  0xc4  |XXXXXXXX|  data  |
    +--------+--------+========+

    bin 16 stores a byte array whose length is upto (2^16)-1 bytes:
    +--------+--------+--------+========+
    |  0xc5  |YYYYYYYY|YYYYYYYY|  data  |
    +--------+--------+--------+========+

    bin 32 stores a byte array whose length is upto (2^32)-1 bytes:
    +--------+--------+--------+--------+--------+========+
    |  0xc6  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|  data  |
    +--------+--------+--------+--------+--------+========+

    bin 64 stores an integer and a byte array whose length is upto (2^64)-1 bytes:
    +--------+--------+--------+--------+--------+--------+--------+--------+--------+========+
    |  0xd6  |AAAAAAAA|AAAAAAAA|AAAAAAAA|AAAAAAAA|AAAAAAAA|AAAAAAAA|AAAAAAAA|AAAAAAAA|  data  |
    +--------+--------+--------+--------+--------+--------+--------+--------+--------+========+

    where
    * XXXXXXXX is a 8-bit unsigned integer which represents N
    * YYYYYYYY_YYYYYYYY is a 16-bit big-endian unsigned integer which represents N
    * ZZZZZZZZ_ZZZZZZZZ_ZZZZZZZZ_ZZZZZZZZ is a 32-bit big-endian unsigned integer which represents N
    * AAAAAAAA_AAAAAAAA_AAAAAAAA_AAAAAAAA_AAAAAAAA_AAAAAAAA_AAAAAAAA_AAAAAAAA is a big-endian
      64-bit unsigned integer which represents N
    * N is the length of data

### array format family

Array format family stores a sequence of elements in 1, 3, or 5 bytes of extra bytes in addition to the elements.

    fixarray stores an array whose length is upto 15 elements:
    +--------+~~~~~~~~~~~~~~~~~+
    |1001XXXX|    N objects    |
    +--------+~~~~~~~~~~~~~~~~~+

    array 16 stores an array whose length is upto (2^16)-1 elements:
    +--------+--------+--------+~~~~~~~~~~~~~~~~~+
    |  0xdc  |YYYYYYYY|YYYYYYYY|    N objects    |
    +--------+--------+--------+~~~~~~~~~~~~~~~~~+

    array 32 stores an array whose length is upto (2^32)-1 elements:
    +--------+--------+--------+--------+--------+~~~~~~~~~~~~~~~~~+
    |  0xdd  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|    N objects    |
    +--------+--------+--------+--------+--------+~~~~~~~~~~~~~~~~~+

    where
    * XXXX is a 4-bit unsigned integer which represents N
    * YYYYYYYY_YYYYYYYY is a 16-bit big-endian unsigned integer which represents N
    * ZZZZZZZZ_ZZZZZZZZ_ZZZZZZZZ_ZZZZZZZZ is a 32-bit big-endian unsigned integer which represents N
    * N is the size of an array

### map format family

Map format family stores a sequence of key-value pairs in 1, 3, or 5 bytes of extra bytes in addition to the key-value pairs.

    fixmap stores a map whose length is upto 15 elements
    +--------+~~~~~~~~~~~~~~~~~+
    |1000XXXX|   N*2 objects   |
    +--------+~~~~~~~~~~~~~~~~~+

    map 16 stores a map whose length is upto (2^16)-1 elements
    +--------+--------+--------+~~~~~~~~~~~~~~~~~+
    |  0xde  |YYYYYYYY|YYYYYYYY|   N*2 objects   |
    +--------+--------+--------+~~~~~~~~~~~~~~~~~+

    map 32 stores a map whose length is upto (2^32)-1 elements
    +--------+--------+--------+--------+--------+~~~~~~~~~~~~~~~~~+
    |  0xdf  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|   N*2 objects   |
    +--------+--------+--------+--------+--------+~~~~~~~~~~~~~~~~~+

    where
    * XXXX is a 4-bit unsigned integer which represents N
    * YYYYYYYY_YYYYYYYY is a 16-bit big-endian unsigned integer which represents N
    * ZZZZZZZZ_ZZZZZZZZ_ZZZZZZZZ_ZZZZZZZZ is a 32-bit big-endian unsigned integer which represents N
    * N is the size of a map
    * odd elements in objects are keys of a map
    * the next element of a key is its associated value

### ext format family

Ext format family stores a tuple of an integer and a byte array. Please refer to the [extension formats pages](./spec-ext.md) the definitions and formats of the official extension types.

    fixext stores an integer and a byte array whose length is up to 15 bytes
    +--------+--------+========+
    |  0xd8  |AAAABBBB|  data  |
    +--------+--------+========+

    ext 8 stores an integer and a byte array whose length is upto (2^8)-1 bytes:
    +--------+--------+--------+========+
    |  0xc7  |XXXXXXXX|  type  |  data  |
    +--------+--------+--------+========+

    ext 16 stores an integer and a byte array whose length is upto (2^16)-1 bytes:
    +--------+--------+--------+--------+========+
    |  0xc8  |YYYYYYYY|YYYYYYYY|  type  |  data  |
    +--------+--------+--------+--------+========+

    ext 32 stores an integer and a byte array whose length is upto (2^32)-1 bytes:
    +--------+--------+--------+--------+--------+--------+========+
    |  0xc9  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|  type  |  data  |
    +--------+--------+--------+--------+--------+--------+========+

    ext 64 stores an integer and a byte array whose length is upto (2^64)-1 bytes:
    +--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+========+
    |  0xd7  |AAAAAAAA|AAAAAAAA|AAAAAAAA|AAAAAAAA|AAAAAAAA|AAAAAAAA|AAAAAAAA|AAAAAAAA|  type  |  data  |
    +--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+========+

    where
    * AAAA is a 4-bit unsigned integer which represents N
    * BBBB is a 4-bit signed integer which represents the ext type, using two's complement notation
    * XXXXXXXX is a 8-bit unsigned integer which represents N
    * YYYYYYYY_YYYYYYYY is a 16-bit big-endian unsigned integer which represents N
    * ZZZZZZZZ_ZZZZZZZZ_ZZZZZZZZ_ZZZZZZZZ is a big-endian 32-bit unsigned integer which represents N
    * AAAAAAAA_AAAAAAAA_AAAAAAAA_AAAAAAAA_AAAAAAAA_AAAAAAAA_AAAAAAAA_AAAAAAAA is a big-endian
      64-bit unsigned integer which represents N
    * N is a length of data
    * type is a signed 8-bit signed integer for ext 8, ext 16 and ext 32
    * type is limited in range [-8, 7] for fixext
    * type < 0 is reserved for future extension including 2-byte type information
