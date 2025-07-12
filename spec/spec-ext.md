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

TODO: clarify that only most-frequently used and short types should occupy -1~-8 

### Date and Time extension types

See the [specific page for date and time](./spec-datetime.md)

### Arbitrary Precision Number extension types

See the [specific page for arbitrary precision (ap-) numbers](./spec-apnum.md).

### Container extension types

TODO: packed_msg, deflated_msg

Used for specify that the payload is strictly a msgpack packed data. For deserializing,
this wrapper could be transparently decoded. It's mainly used for insert a offset clue in a long data, or used at the beginning of a file to note that this file stores MessagePack++ data.

### Multi-dimensional Typed Array extension type

See the [specific page for multi-dimensional typed arrays](./spec-ndarray.md).