# Performance coverage

Coverage here means a performance question has a named benchmark, a timer window written down, and a row in `project/bench/results/history.tres` that can be compared with the other codecs inside one Godot binary. A row is not a baseline. Whether FlatBuffers beats Dictionary is a separate claim, written in `Notes/BeatingDictionary.md`.

The suites live in `project/bench`. `run.ps1` with no arguments runs suite, prealloc, array-size, and scenario on `editor`, then `template_debug`, then `template_release`. `-Suite` selects one. The bench list opens on Scenarios.

## Layout

Three runners register benchmarks. The scenario runner is the comparison. The other two keep older names runnable.

**Scenario**
  `runner_scenario.gd` is Store, Load, Spawn, Update, and Peek on one 64-record payload. FlatBuffers, Objects (`BM_BuiltIn_*`, `var_to_bytes_with_objects`), and Dictionary (`BM_GDict_*`, `var_to_bytes`) share the field formulas in `compare_work.gd`. The timer window is `project/bench/BENCH.md` under Scenario suite.

**Upstream copy**
  `runner_suite.gd` is the 3-record sample copied from the upstream Google benchmark. Encode, Decode, ReadAll, and RoundTrip exist for all three codecs. It is kept so those names still run. It is not the fairness document for the scenario suite.

**Ranges**
  `runner_prealloc.gd` and `runner_array_size.gd` register only `BM_Flatbuffers_Encode` and pass `kPreAllocateSize` from a benchmark range. They do not register Objects or Dictionary, and they do not run the scenario operations.

## Methods

`BENCH.md` lists four methods. Two of them have scenario rows. Two do not.

**Dictionary**
  Godot's built-in dictionary path, `var_to_bytes` / `bytes_to_var`. Covered by `BM_GDict_Store`, `Load`, `Spawn`, `Update`, and `Peek`.

**Objects**
  GDScript classes `Foo`, `Bar`, `FooBar`, and `FooBarContainer`, through `var_to_bytes_with_objects`. Covered by `BM_BuiltIn_*` for the same five operations. The list, the compare scene, and the slides label this Objects.

**FlatBuffers through generated GDScript**
  The generated accessors in `fb_scripts/bench_generated.gd`, calling the extension one field at a time. Covered by `BM_Flatbuffers_*` for the same five operations.

**FlatBuffers with the hot loop in the extension**
  A native walk that builds or reads the payload without a GDScript call per field. No benchmark. `Notes/BeatingDictionary.md` is why that gap matters.

Upstream C++ FlatBuffers and a raw struct encode stay in `Notes/Performance.md`. They are a different harness and are not rows in `history.tres`.

## Scenario questions

A `template_release` pass of all fifteen scenario benchmarks is stamped `2026-10-14T00:31:51` UTC. Editor and template_debug from the same day are debug Godot binaries. Compare codecs inside one target. Each row also stores `bytes` and `bytes_per_s`. The slides judge time.

| Question | What the saved row measures | Against the sketch in `BENCH.md` |
| --- | --- | --- |
| Store | FlatBuffers builds the buffer inside the timer. Dictionary and Objects encode a value built outside it. `BM_DictFromObj_Store` keeps the object graph outside the timer and, inside it, copies those fields into a dictionary and then calls `var_to_bytes`. | Dictionary and Objects match the storage sketch. Dict from objects is that sketch when the fields start on objects. FlatBuffers includes construction from the formulas, not from the objects. No `template_release` row for `BM_DictFromObj_Store` yet. |
| Load | Decode and read every field. The checksum has to match. | Fair as touch-every-field. Dictionary and Objects walk the value a second time after `bytes_to_var`. |
| Spawn | Bytes become a new value. An empty result fails the run. The timer does not repeat the checksum. | FlatBuffers and Dictionary end as a dictionary. Objects ends as a `FooBarContainer`. |
| Update | Patch a destination built outside the timer. The timer does not repeat the checksum. | FlatBuffers writes into a dictionary. Dictionary and Objects decode a temporary, then copy. |
| Peek | Rating of record 32, checked against a value computed outside the timer. | FlatBuffers reads that field. Dictionary and Objects decode the whole buffer first. |

Peek is the scenario question where that release pass is ahead of Dictionary. Store, Load, Spawn, and Update are behind Dictionary on that same pass. The numbers and the reasons are in `Notes/BeatingDictionary.md`.

## Upstream-copy questions

Encode, Decode, ReadAll, and RoundTrip have history from earlier three-target runs of `runner_suite.gd`. Those runs are not the scenario methodology.

`MetadataOnly` and `RandomElement` are registered for FlatBuffers and Objects only. Dictionary has neither.

The `PA`, `SR`, and `PASR` names are registered for FlatBuffers only. They pass `&'pre_allocate'` and `&'static_reader'`. `case_fb.gd` reads `&'kPreAllocateSize'` and `&'kStaticReader'`. Those variants do not change the bench they time. `runner_prealloc.gd` and `runner_array_size.gd` do pass `kPreAllocateSize`, and only for FlatBuffers Encode.

## Still open

Each item is one missing measurement. The scenario payload stays the comparison until a new question says otherwise.

### The Dictionary goal

- [ ] FlatBuffers Store ahead of Dictionary Store, with construction outside the timer, once an encode-existing-value call exists.
- [ ] FlatBuffers Load ahead of Dictionary Load on the same touch-every-field window.
- [ ] FlatBuffers Spawn ahead of Dictionary Spawn, both ending as a dictionary.
- [ ] FlatBuffers Update ahead of Dictionary Update, both patching a dictionary.
- [ ] Keep Peek as the one-field question. Do not treat a Peek win as a full-payload win.

### A measurement that separates the current costs

- [ ] The five scenario operations with `list_at(..., into)` and reused struct readers, so allocation cost is separate from per-field calls.
- [ ] The same five operations around a native walk that fills a dictionary in one call.
- [ ] Scenario Store with `kPreAllocateSize` set to the finished buffer size, so growth from `FlatBufferBuilder.create(0)` is separate from construction.
- [ ] The fourth method in `BENCH.md`: the hot loop inside the extension, compared with the generated GDScript path on the same payload.

### Shapes and names that are not the scenario

- [ ] Record count other than 64, on Store, Load, Spawn, Update, and Peek, for all three codecs.
- [ ] A payload other than the FooBar sample: long strings, a wide table, or a nested buffer. No scenario covers those shapes.
- [ ] `MetadataOnly` and `RandomElement` for Dictionary, or a line here that those two questions are retired.
- [ ] `PA` / `SR` / `PASR` either call `kPreAllocateSize` and `kStaticReader`, or drop out of this list. Until then the names are registered and the options are not.

### Outside this list

The slides and the compare scene read `history.tres`. They do not add a question.

C# and Rust are still the questions in `BENCH.md` under Methods. No benchmark until a harness exists.

`Notes/Performance.md` remains the note for the upstream C++ binary. Those numbers are not coverage in this file.
