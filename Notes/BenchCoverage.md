# Bench coverage

A question is covered when three things exist: a named benchmark, a timer window in `project/bench/BENCH.md`, and a row in `project/bench/results/history.tres`. A row is a measurement. Whether FlatBuffers beats Dictionary is a separate claim, in `Notes/BeatingDictionary.md`.

`project/bench/run.ps1` with no arguments runs `suite`, `prealloc`, `array-size`, `scenario`, and `reuse` on `editor`, then `template_debug`, then `template_release`. `-Suite` selects one. The bench list opens on Scenarios. Compare codecs inside one target. Editor and template_debug are debug Godot binaries.

`[x]` means that piece is in place. `[ ]` means it is still missing. A goal stays open until the claim is true.

## Scenario

`runner_scenario.gd`. One 64-record FooBar payload. FlatBuffers, Objects (`var_to_bytes_with_objects`), Dictionary (`var_to_bytes`), and Dict from objects share the field formulas in `compare_work.gd`. The timer window is `BENCH.md` under Scenario suite.

- [x] Store, Load, Spawn, Update, and Peek are registered for all four codecs.
- [x] The timer windows are written.
- [x] `editor`, `template_debug`, and `template_release` rows exist for all twenty names. The latest pass is `2026-10-15`.
- [ ] `Notes/BeatingDictionary.md` still describes the `2026-10-14` pass and leaves out Dict from objects. The `2026-10-15` rows are not written up there.

### Store

FlatBuffers builds the buffer from the formulas inside the timer, including a new builder and 64 string copies. Dictionary and Objects encode a value built before the timer. Dict from objects keeps the object graph outside the timer and, inside it, copies those fields into a dictionary, then calls `var_to_bytes`.

- [x] Covered for all four codecs.
- [ ] FlatBuffers Store on the Dictionary window: construction outside the timer. That needs an encode-existing-value call.
- [ ] FlatBuffers Store ahead of Dictionary Store on that window.

### Load

Decode and read every field. The checksum has to match. Dict from objects walks the dictionary buffer encoded before the timer. Dictionary, Objects, and Dict from objects also walk the value again after `bytes_to_var`.

- [x] Covered for all four codecs, as touch-every-field.
- [ ] FlatBuffers Load ahead of Dictionary Load on that window.

### Spawn

Bytes become a new value. An empty result fails the run. The timer does not repeat the checksum. FlatBuffers, Dictionary, and Dict from objects end as a dictionary. Objects ends as a `FooBarContainer`.

- [x] Covered for all four codecs.
- [ ] FlatBuffers Spawn ahead of Dictionary Spawn, both ending as a dictionary.

### Update

Patch a destination built outside the timer. The timer does not repeat the checksum. FlatBuffers writes into a dictionary. Dictionary, Objects, and Dict from objects decode a temporary, then copy.

- [x] Covered for all four codecs.
- [ ] FlatBuffers Update ahead of Dictionary Update, both patching a dictionary.

### Peek

Rating of record 32, checked against a value computed outside the timer. FlatBuffers reads that field. Dictionary, Objects, and Dict from objects decode the whole buffer first.

- [x] Covered for all four codecs.
- [x] Peek stays the one-field question. A Peek win is a one-field result.

## Reuse

`runner_reuse.gd`. Same 64-record payload. Each bench takes one allocation out of the FlatBuffers scenario operation. The metric is the scenario time minus this time. That difference is the allocation.

### Store

One `FBFoo` and one `FBBar`, written on every record, instead of `create_FBFoo` and `create_FBBar`. `FlatBufferBuilder.create(0)`, the name copies, and `finish` stay inside the timer. The difference from `BM_Flatbuffers_Store` is the per-record struct allocation.

- [x] `BM_Flatbuffers_StoreReuse` is registered.
- [x] The timer window is in `BENCH.md`.
- [ ] A `history.tres` row on `editor`, `template_debug`, and `template_release`.

### Load

`list_at(..., into)`, one reused `FBBar`, and one reused `FBFoo`. The difference from `BM_Flatbuffers_Load` is those reader allocations. The strings returned by the field calls are still new objects.

- [x] `BM_Flatbuffers_LoadReuse` is registered, the window is written, and `editor`, `template_debug`, and `template_release` rows exist (`2026-10-15`).
- [ ] The difference from `BM_Flatbuffers_Load` is written down.

### Spawn

The same dictionary as scenario Spawn. The new dictionaries are still allocated inside the timer. Only the FlatBuffers readers are reused.

- [x] `BM_Flatbuffers_SpawnReuse` is registered.
- [x] The timer window is in `BENCH.md`.
- [ ] A `history.tres` row on `editor`, `template_debug`, and `template_release`.

### Update

The same patch as scenario Update. The destination dictionary already exists. The readers are reused.

- [x] `BM_Flatbuffers_UpdateReuse` is registered.
- [x] The timer window is in `BENCH.md`.
- [ ] A `history.tres` row on `editor`, `template_debug`, and `template_release`.

### Peek

Rating at index 32 through one reused `FBFooBar`. Sibling and parent are not read. The difference from `BM_Flatbuffers_Peek` is that one table.

- [x] `BM_Flatbuffers_PeekReuse` is registered.
- [x] The timer window is in `BENCH.md`.
- [ ] A `history.tres` row on `editor`, `template_debug`, and `template_release`.

## Other cost splits

Same 64-record payload. Each box is one missing measurement.

- [ ] Scenario Store with `kPreAllocateSize` set to the finished buffer size. The difference from `BM_Flatbuffers_Store` is growth from `FlatBufferBuilder.create(0)`.
- [ ] Store, Load, Spawn, Update, and Peek around a native walk that fills a dictionary in one call.
- [ ] The hot loop inside the extension, compared with generated GDScript on the same payload. `BENCH.md` calls this FlatBuffers with GDExtension.

## Other shapes

- [ ] A record count other than 64, on Store, Load, Spawn, Update, and Peek, for all four codecs.
- [ ] A payload other than FooBar: long strings, a wide table, or a nested buffer.

## Upstream copy

`runner_suite.gd` is the 3-record sample copied from the upstream Google benchmark. These rows are a different question from the scenario.

- [x] Encode, Decode, ReadAll, and RoundTrip have suite history for FlatBuffers, Objects, and Dictionary.
- [x] `MetadataOnly` and `RandomElement` have suite history for FlatBuffers and Objects.
- [ ] Dictionary `MetadataOnly` and `RandomElement`, or those two questions are retired.
- [x] `PA`, `SR`, and `PASR` are registered and have suite history.
- [ ] Those variants read `kPreAllocateSize` and `kStaticReader`, or the names are dropped. They pass `pre_allocate` and `static_reader`. `case_fb.gd` reads the `k` names, so the timed bench does not change.
- [x] `runner_prealloc.gd` and `runner_array_size.gd` pass `kPreAllocateSize` into FlatBuffers Encode and have history rows. Objects, Dictionary, and the scenario operations are outside those two runners.

## Methods without a bench

From `BENCH.md` under Methods. No benchmark until a harness exists.

- [ ] Godot built-in with GDExtension.
- [ ] C# and Rust as their own codecs.
- [ ] Generated C++ Godot classes backed by FlatBuffers.

## Choosing this

A Godot project uses these to decide whether to take this instead of `var_to_bytes`. The sections above are the FooBar sample those decisions can cite today.

### Release time and size

Microseconds and encoded bytes on `template_release`, against Dictionary and Objects, for a payload a game would store.

- [x] FooBar, 64 records: Store, Load, Spawn, Update, and Peek have `template_release` rows, including `bytes` and `bytes_per_s`. The latest pass is `2026-10-15`.
- [ ] A save file.
- [ ] A spawn list.
- [ ] A network packet.

### Partial read

Time to read part of a buffer built before the timer.

- [x] One field: scenario Peek, the rating at record 32, for all four codecs, including `template_release`.
- [x] Upstream `MetadataOnly` reads the container fields. `RandomElement` reads rating and postfix at the middle record. FlatBuffers and Objects have suite history on the 3-record sample. Dictionary for those two is an open box under Upstream copy.
- [ ] A few fields from one scenario record, against Dictionary.
- [ ] Time to skip a buffer the caller does not read.

### Another language

Bytes this extension writes, read by ordinary FlatBuffers in another language, and the reverse. `StringName`, `NodePath`, and `Vector3` are part of that buffer. C# and Rust under Methods without a bench are a separate question.

- [ ] Godot writes the buffer. Another FlatBuffers implementation reads it.
- [ ] Another implementation writes the buffer. Godot reads it.

### What the caller writes

- [ ] The generated GDScript calls for one record, counted beside the timing.
- [ ] The steps from a `.fbs` file to that read.

### Schema change

Reading a buffer written by an older shape of the same schema.

- [ ] A field added since the buffer was written.
- [ ] A field left out of the buffer.
- [ ] Fields reordered since the buffer was written.

## Outside this note

The slides and the compare scene read `history.tres`. They add no question.

`Notes/Performance.md` is the upstream C++ binary. Those numbers are not rows here.
