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
  Dictionary encode and decode are one native call. The FlatBuffers tests cross into GDScript once per field. Load's `Use` in `project/bench/fb_scripts/case_fb.gd`, for each of the 64 records, calls `list_at`, `name`, `postfix`, `rating`, `sibling`, three struct fields, `parent`, and four more struct fields. The call count, not the byte layout, matches the tests that lose. How much of the gap is calls versus allocations has not been profiled.

**Reader and builder objects**
  `list_at` without `into` constructs an `FBFooBar`. `sibling()` constructs an `FBBar`. The `parent` getter constructs an `FBFoo`. Store's `create_FBFoo` and `create_FBBar` in `project/bench/fb_scripts/bench_generated.gd` each allocate a struct object per record, and each struct owns a fresh `PackedByteArray`. The timed scenario code does not pass `into`. Reusing those readers removes three allocations per record. That should show up. It is unlikely, on its own, to close a gap of several times, because the GDScript calls remain.

**No bulk materialization**
  Spawn and Update copy fields into a dictionary in GDScript. That work is competing with `bytes_to_var` at producing a dictionary. The extension has no single call that walks a FlatBuffer and fills a dictionary, which is what Dictionary's decode already is. A field-by-field transcription does not win that job.

**Store includes construction**
  Dictionary Store encodes a value built before the timer. FlatBuffers Store, in `compare_work.gd` `encode_flat`, builds the buffer inside the timer: formulas, a new builder, 64 `create_variant` copies of the name, the struct objects above, and `finish`. There is no call that takes an existing dictionary and writes a FlatBuffer in one native walk. Until that exists, Store is a different piece of work from `var_to_bytes`.

**Smaller costs**
  Each table-field access re-reads the vtable in `FlatBuffer::get_field_offset`. `create_variant` writes the name string once per record, and each `name()` read builds a new `String`. `FlatBufferBuilder.create(0)` grows the buffer as the tables are added. These are real. They sit under the per-field calls.

## Where a faster number has to come from

Beating Dictionary at handing back a dictionary means filling that dictionary in native code, in one walk, the way `bytes_to_var` does. The current generated API has no such walk.

Reading fields without building the dictionary is the case Peek already wins. An application that keeps the buffer and reads the fields it needs is not in the race the full-payload tests measure.
