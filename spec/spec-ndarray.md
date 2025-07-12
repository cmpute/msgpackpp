
array element type info:
1. basic type (2bit): uint, sint, float, complex
2. size (2bit): uint 8/16/32/64, float 16/32/64/128
3. endianness (1bit): big/little
4. major (1bit): row-major/column-major
5. shape length bits?: 8/16/32/64

    Length ll	uint	sint	float
    0	uint8	int8	binary16
    1	uint16	int16	binary32
    2	uint32	int32	binary64
    3	uint64	int64	binary128

since endianness makes no sense for uint8 and int8, it's forced that uint8 and int8 use the default endianess. The type tag combining uint8 and the other endianess is representing bool, the type tag combining int8 and the other endianess is reserved.

Note that the bool arrays are always bit-packed. To prevent bit packing, save the array as a uint8 array.