# MessagePack++ specification

MessagePack++ (abbr. msgpack++ or msgpackpp) is an object serialization specification like JSON, derived from vanilla MessagePack.

There are a few motivations for creating MessagePack++:
1. To pack data in the most space-efficient way
2. To be compatible with MessagePack as much as possible
3. To be able to pack modern data structures

MessagePack++ has two concepts: **type system** and **formats**.

Serialization is conversion from application objects into MessagePack++ formats via MessagePack++ type system.

Deserialization is conversion from MessagePack++ formats into application objects via MessagePack++ type system.

    Serialization:
        Application objects
        -->  MessagePack++ type system
        -->  MessagePack++ formats (byte array)

    Deserialization:
        MessagePack++ formats (byte array)
        -->  MessagePack++ type system
        -->  Application objects

This document describes the MessagePack++ type system, MessagePack++ formats and conversion of them.

## Versioning

> MessagePack++ is now in alpha-stage.

The majority of MessagePack++ spec is considered stable when it's officially released (with the git tag "stable"), and there is no versioning on MessagePack++ itself because it is frozen. However, the extension types (especially the officially reserved section) can be updated, therefore the versioning on MessagePack++ is actually on the extension definitions.

TODO: consider versioning by date (year-month like 2502), but this will requires the spec to be fully backward compatible

TODO: the stable part is spec-basic.md, the versioned part is spec-ext.md

## Compatibility

Ths MessagePack++ is fully compatible with the vanilla MessagePack format except for the extension types. If no extension types are used, the MessagePack++ serializers and deserializers can directly handle MessagePack data. Nevertheless, it's still recommended for MessagePack++ implementations to offer an "compatible mode" to enable and disable compatibility with MessagePack. 

Please refer to the Serialization and Deserialization sections for the recommendations on how to implement the MessagePack-compatible mode.

## Type system

* Types
  * **Integer** represents an integer
  * **Nil** represents nil
  * **Boolean** represents true or false
  * **Float** represents a IEEE 754 compliant floating point number including NaN and Infinity
  * **Complex** represents a complex number holding two floating point elements
  * **Raw**
      * **String** extending Raw type represents a UTF-8 string
      * **Binary** extending Raw type represents a byte array
  * **Array** represents a sequence of objects
  * **Map** represents key-value pairs of objects
  * **Extension** represents a tuple of type information and a byte array where type information is an integer whose meaning is defined by applications or MessagePack++ specification. The extensions types officially defined by MessagePack++ include:
      * **Timestamp** represents an instantaneous point on the time-line in the world that is independent from time zones or calendars. Maximum precision is nanoseconds.
      * **Arbitrary Precision Number** represents a number with arbitrary numerical precisions. It includes integers, binary floats and decimal floats.
      * **Typed Array** represents a sequence or nested sequences of values with the same type.
      * **Container** represent a marker noting that the content of the byte array is still a Msgpack++ representation.

### Type formats

Please refer to the [basic formats page](./spec-basic.md) for the definitions of the types.

### Limitation

* a value of an Integer object is limited from `-(2^63)` upto `(2^64)-1`
* maximum length of a Binary object is `(2^64)-1`
* maximum byte size of a String object is `(2^32)-1`
* String objects may contain invalid byte sequence and the behavior of a deserializer depends on the actual implementation when it received invalid byte sequence
    * Deserializers should provide functionality to get the original byte array so that applications can decide how to handle the object
* maximum number of elements of an Array object is `(2^32)-1`
* maximum number of key-value associations of a Map object is `(2^32)-1`

### Extension types

MessagePack++ allows applications to define application-specific types using the Extension type.
Extension type consists of an integer and a byte array where the integer represents a kind of types and the byte array represents data.

Applications can assign `0` to `127` to store application-specific type information. An example usage is that application defines `type = 0` as the application's unique type system, and stores name of a type and values of the type at the payload.

MessagePack++ reserves `-1` to `-128` for future extension to add predefined types. These types will be added to exchange more types without using pre-shared statically-typed schema across different programming environments.

    [0, 127]: application-specific types
    [-128, -1]: reserved for offcial predefined types

Because extension types are intended to be added, old applications may not implement all of them. However, they can still handle such type as one of Extension types. Therefore, applications can decide whether they reject unknown Extension types, accept as opaque data, or transfer to another application without touching payload of them.

Please refer to the [extension types pages](./spec-ext.md) for the definitions and formats of the  offcial types defined by far.

## Serialization: type to format conversion

MessagePack++ serializers convert MessagePack++ types into formats as following:

source types | output format
------------ | ---------------------------------------------------------------------------------------
Integer      | int format family (positive fixint, negative fixint, int 8/16/32/64 or uint 8/16/32/64) and apint extension family (positive apint and negative apint)
Nil          | nil
Boolean      | bool format family (false or true)
Float        | float format family (float 32/64) and apfloat extension family
String       | str format family (fixstr or str 8/16/32)
Binary       | bin format family (bin 8/16/32)
Array        | array format family (fixarray or array 16/32)
Map          | map format family (fixmap or map 16/32)
Extension    | ext format family (fixext or ext 8/16/32)

If an object can be represented in multiple possible output formats, serializers SHOULD use the format which represents the data in the smallest number of bytes.

### Recommended behavior for MessagePack compatbile mode

Serialize complex / bin 64 / ext 64: throw error for old version
Serialize fixext: force user to explicitly specify the msgpack version
Serialize other types: same as before

## Deserialization: format to type conversion

MessagePack++ deserializers convert MessagePack++ formats into types as following:

source formats                                                       | output type
-------------------------------------------------------------------- | -----------
positive fixint, negative fixint, int 8/16/32/64 and uint 8/16/32/64 | Integer
nil                                                                  | Nil
false and true                                                       | Boolean
float 32/64                                                          | Float
fixstr and str 8/16/32                                               | String
bin 8/16/32                                                          | Binary
fixarray and array 16/32                                             | Array
fixmap map 16/32                                                     | Map
fixext and ext 8/16/32                                               | Extension


### Recommended behavior for MessagePack compatbile mode

Deserialize complex / bin 64 / ext 64 / fixext: force user to explicitly specify the msgpack version
Deserialize other types: same as before
