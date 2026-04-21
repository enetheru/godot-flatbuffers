# 2026-04-03
I guess its time to start recording the important changes since there have been enough, and this project is old enough to track them.
Mostly this is about the things that will have to change, or at least the ones I am aware of. since I tend to use only a subset of the things.
The full change log can be gleaned from git.
## FlatBuffer
- `get_*` functions are limited to only the root type for any schema file, inline with the FlatBuffers defaults
    - FlatBuffer.get_root(buffer, Variant::Type) was added to replicate the templated get_root function convenience, where the type is optional for error checking.
    - alternative method is to use the new function with the bytes and position, or new and then assign.
- most `create_*` functions have replaced with `create_variant(variant, TYPE_*)` to simplify the API
- `builder.to_packed_byte_array()` has been replaced with `builder.get_buffer()` inline with FlatBuffers defaults
- Added FlatBufferVerifier object, and a bunch of verify functions to FlatBuffer.
- added an assign_buffer function to make re-using the Object easier
- bytes and start internal variables have been renamed, but are still accessible from get/set_bytes and get/set_start. this was done to reduce the chance of name collisions

## FlatBufferBuilder
- Added required function when finishing to notify of missing items, inline with FlatBuffers c++ generator.
## flatc Compiler/Generator
- Updated to reflect changes in the above