# Beating Dictionary

The scenario suite compares FlatBuffers with two Godot serializers on one 64-record payload. Dictionary is `var_to_bytes` / `bytes_to_var` of a dictionary tree. Objects is `var_to_bytes_with_objects` / `bytes_to_var_with_objects` of `Foo`, `Bar`, `FooBar`, and `FooBarContainer`. The goal for the FlatBuffers path is to beat Dictionary.

Construction and fairness are specified in `project/bench/BENCH.md` under Scenario suite. The slides and the compare scene label the object codec Objects. Saved benchmark names stay `BM_BuiltIn_`.

## One release pass

These times are the `template_release` rows stamped `2026-10-14T00:31:51` UTC in `project/bench/results/history.tres`. They are one pass, not a baseline. Editor and template_debug from the same day are debug Godot binaries and are not in this table.

| Test | FlatBuffers | Objects | Dictionary |
| --- | ---: | ---: | ---: |
| Store | 927 µs | 926 µs | 185 µs |
| Load | 929 µs | 1211 µs | 400 µs |
| Spawn | 1010 µs | 1099 µs | 217 µs |
| Update | 926 µs | 1169 µs | 424 µs |
| Peek | 6.6 µs | 1084 µs | 218 µs |

FlatBuffers is level with Objects on Store and ahead of Objects on Load, Spawn, Update, and Peek. Dictionary is ahead on every test except Peek.

That pass has no Dict from objects row. `BM_DictFromObj_Store` was added later. The objects already exist, and the timer builds a dictionary from their fields and then calls `var_to_bytes`. Load, Spawn, Update, and Peek for that codec time the dictionary path on the bytes that copy produced. The copy stays outside those timers. The table above does not include it.

## What the split already shows

Peek reads one rating. Dictionary and Objects still decode the whole buffer first. FlatBuffers builds a root and reads that field, and that pass was about 30 times faster than Dictionary. The buffer format is not the loss.

Store, Load, Spawn, and Update touch every field from GDScript. Those are the tests behind Dictionary. Objects is the closer race because `var_to_bytes_with_objects` also builds a Godot object graph. Dictionary is one native walk over a Variant tree.

## Limiting factors

**Per-field GDScript**
  Dictionary encode and decode are one native call. The FlatBuffers tests cross into GDScript once per field. Load's `Use` in `project/bench/fb_scripts/case_fb.gd`, for each of the 64 records, calls `list_at`, `name`, `postfix`, `rating`, `sibling`, three struct fields, `parent`, and four more struct fields. The call count, not the byte layout, matches the tests that lose. How much of the gap is calls versus allocations has not been profiled. The allocation sites are under Needless allocation. The round trips are under GDScript and C++.

**Reader and builder objects**
  `list_at` without `into` constructs an `FBFooBar`. `sibling()` constructs an `FBBar`. The `parent` getter constructs an `FBFoo`. Store's `create_FBFoo` and `create_FBBar` in `project/bench/fb_scripts/bench_generated.gd` each allocate a struct object per record, and each struct owns a fresh `PackedByteArray`. The timed scenario code does not pass `into`. Reusing those readers removes three allocations per record. That should show up. It is unlikely, on its own, to close a gap of several times, because the GDScript calls remain.

**No bulk materialization**
  Spawn and Update copy fields into a dictionary in GDScript. That work is competing with `bytes_to_var` at producing a dictionary. The extension has no single call that walks a FlatBuffer and fills a dictionary, which is what Dictionary's decode already is. A field-by-field transcription does not win that job.

**Store includes construction**
  Dictionary Store encodes a value built before the timer. FlatBuffers Store, in `compare_work.gd` `encode_flat`, builds the buffer inside the timer: formulas, a new builder, 64 `create_variant` copies of the name, the struct objects above, and `finish`. There is no call that takes an existing dictionary and writes a FlatBuffer in one native walk. Until that exists, Store is a different piece of work from `var_to_bytes`.

**Smaller costs**
  Each table-field access re-reads the vtable in `FlatBuffer::get_field_offset`. That repeated work sits under the per-field calls. The copies and objects on top of it are under Needless allocation.

## Needless allocation

These copies and objects are extra. The bytes, or a reader that could be reused, already exist. String-key lookup, union vectors, and custom-struct vectors are off the scenario timer. They are the same kind of copy in the extension API.

**String decode**
  `string_from_buffer` in `src/flatbuffer.cpp` loads the length prefix and calls `String::utf8` on that span. It does not check the range. `verify_string` is that check, and repeating it would put the cost back on every `name()` and `location()`. `decode_variant` for `STRING`, `STRING_NAME`, and `NODE_PATH`, `decode_gtype<String>`, and `decode_packed_string` call it. Generated string getters still reach this through `decode_variant`. The `String`, `StringName`, or `NodePath` is still built. The intermediate `PackedByteArray` from `slice` is gone from the source. The loaded extension DLL still slices until that DLL is rebuilt.

**Wide scalar vectors**
  `slice_packed_bytes` returns a new `PackedByteArray`, and the `int32`, `int64`, `float`, and `double` cases call `to_*_array()` on that copy (`src/flatbuffer.cpp`). `GenFieldVectorScalarGet` and the packed branch of `GenFieldVectorStructGet` emit the same two copies. `decode_packed_struct` is the single copy used for `Vector2`, `Vector3`, `Color`, and `Vector4`.

**Builder created twice**
  `FlatBufferBuilder::FlatBufferBuilder(int)` allocates the inner `flatbuffers::FlatBufferBuilder`. `FlatBufferBuilder::Create` in `src/flatbufferbuilder.hpp` then replaces that pointer with a second one. Every `FlatBufferBuilder.create` pays both.

**Struct staging buffers**
  `GenStructInit` allocates a `PackedByteArray` of the struct size when the constructor is given no bytes. `create_FBFoo` and `create_FBBar` in `project/bench/fb_scripts/bench_generated.gd` do that per record. The `parent` setter copies the `FBFoo` bytes into the `FBBar`, and `add_sibling` copies the `FBBar` into the builder. `encode_flat` in `project/bench/compare_work.gd` and the suite encoder in `project/bench/fb_scripts/case_fb.gd` call both creators inside the timer. `encode_flat` also starts the builder with `FlatBufferBuilder.create(0)`, so the builder buffer is reallocated as the tables are written.

**A new view per read**
  `GenFieldStruct` and `GenFieldTable` always construct a new object and take no `into`. Whole-vector getters construct one per element (`GenFieldVectorTableGet`, the struct branch of `GenFieldVectorStructGet`). `list_at` can reuse a reader. `sibling()` and the `parent` getter cannot. The timed reads call them that way in `case_fb.gd` and `compare_work.gd`.

**String-key probes**
  `cmp_string_value` in `src/flatbuffer.cpp` builds a `CharString` from the lookup key on every call. `named_lookup` in `project/tests/flatbuffers/schemas/key_generated.gd` calls `named_at` with no `into`, so each probe also constructs a `Named`. A hit constructs one more. `numbered_lookup` and the `*_lookup` functions in `project/tests/fb_reflection/Reflection_generated.gd` do the same.

**Union pairs**
  `CreateVectorOfUnion` in `src/flatbufferbuilder.cpp` stores each callable result as a two-int `PackedInt32Array`.

**Custom struct vectors**
  `CreateVectorOfCustomStructs` reads each struct with `ptrw()`, which copies a shared `PackedByteArray`.

## GDScript and C++

A field read or a table write leaves the extension, runs a few lines of GDScript, and comes back for the rest of the same value. Dictionary encode and decode stay in one native call. String-key search, verify, and the debug dictionary are off the scenario timer.

**Scalar table field**
  `GenFieldScalar` and `GenFieldEnum` call `get_inline_field_start` in the extension, then `_fb_bytes.decode_*` on `PackedByteArray`. The extension already holds the buffer. In the scenario that is `rating`, `postfix`, `initialized`, and `fruit` in `project/bench/fb_scripts/bench_generated.gd`.

**String field**
  `GenFieldString` calls `get_offset_field_start`, returns to GDScript, then calls `decode_variant`. Both calls enter the extension. The GDScript between them checks for a missing field. `name()` and `location()` do this on the timed path.

**Vector index**
  `list_at` calls `get_offset_field_start`, then `decode_u32` for the length and again for the element, then sets `_fb_bytes` and `_fb_start`. Those sets are `set_bytes` and `set_start`. `list_size` looks up the same vtable slot, and every `list_at` looks it up again. `Use` in `project/bench/fb_scripts/case_fb.gd` and `spawn_flat` in `project/bench/compare_work.gd` do that once per record. `GenFieldVectorTableAt` still returns between the offset call and the two `decode_u32` calls. Its `into` path then uses one `assign_buffer`.

**Root view**
  `get_FBFooBarContainer` decodes the root offset with `PackedByteArray.decode_u32` and then constructs the object. `FlatBuffer::get_root` takes the buffer and calls `assign_buffer`. Generated `get_{{STRUCT_NAME}}` in `GenStructGet` follows the GDScript decode.

**Nested struct view**
  Once `_fb_start` is set, a struct scalar such as `bar.time` is one `decode_*`. Reaching the view is the extra trip. `sibling()` calls `get_inline_field_start` and then `FBBar.new`. The bench `_init` sets `_fb_bytes` and `_fb_start`. `parent` is that constructor trip at a constant offset. `Use` does both per record. Current `GenTableInit` and `GenStructInit` fold the two sets into one `assign_buffer`. The offset lookup still returns to GDScript first.

**Table write**
  `GenTableCreate` builds a builder and calls `add_*` once per field. Each `add_*` is one extension call (`add_element_*`, `add_offset`, `add_bytes`, or `add_variant`), and `finish` calls `end_table`. A new builder also calls `start_table` from `_init`. On the bench, `create_FBFooBar` is four `add_*` calls and `finish`. `create_FBFooBarContainer` is four `add_*` calls and `finish`.

**Struct write**
  `create_FBFoo` and `create_FBBar` assign each field from GDScript. Each setter calls `encode_*` on the staging `PackedByteArray`. The `parent` setter then calls `overwrite_bytes`. `add_sibling` calls `add_bytes`, which reads that array into the builder. `encode_flat` and the encoder in `case_fb.gd` do this per record, and call `create_variant` for the name between the struct and the table.

**Per-element callback**
  `CreateVectorOfTable` and `CreateVectorOfUnion` in `src/flatbufferbuilder.cpp` call a GDScript `Callable` from C++ for every element, and the callable calls the builder again. The scenario loop has the same shape from the GDScript side. Each record enters the extension several times, and `create_vector_offset` runs once after the loop.

**String-key search**
  `named_lookup` in `project/tests/flatbuffers/schemas/key_generated.gd` stays in GDScript. Each probe calls `named_at`, which does the vector-index trip above, then `key_compare`. The `*_lookup` functions in `project/tests/fb_reflection/Reflection_generated.gd` do the same.

**Verify**
  `GenTableVerifier` calls `set_buffer`, `verify_table_start`, one `verify_*` per field, and `verify_end_table`. A vector verify calls `_at` and `verify` for each element, so the index trip runs again inside the check.

**Debug dictionary**
  With `gdscript_debug`, the vector branch stores `get_offset_field_start` in `start`, then calls `get_offset_field_start` again as the argument to `decode_u32`. The field getter walks that vector after both calls. The emitter is the debug-dictionary block in `lib/flatbuffers/src/idl_gen_gdscript.cpp`.

## Where a faster number has to come from

Beating Dictionary at handing back a dictionary means filling that dictionary in native code, in one walk, the way `bytes_to_var` does. The current generated API has no such walk.

Reading fields without building the dictionary is the case Peek already wins. An application that keeps the buffer and reads the fields it needs is not in the race the full-payload tests measure.
