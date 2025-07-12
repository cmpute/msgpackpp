
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

The timestamp type with other sizes are reserved for future extension, but they will use UTC time with UNIX epoch. If other timescale is going to be used (for example: TAI time with PTP epoch), then another extension type will be created.

TODO: add TAI time type?
TODO: add timestamp 16 (or other sizes) to support days since epoch
