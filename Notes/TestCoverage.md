# Test coverage

Coverage here means the plan in `project/tests/TESTING.md`: the tutorial and reflection anchors, one schema-feature suite, one Godot-type suite, and the `flatc` flags. It does not mean porting the upstream C++ `tests/` tree.

The suites live in `project/tests/`. A feature is covered when its generated script can be compiled and the phases that apply to it have run: encode, verify, decode, use.

## Layout

Three folders hold runnable tests. `flatc/` is reserved and empty.

**Upstream-shaped**
  `fb_monster/` follows the FlatBuffers tutorial. `fb_reflection/` decodes a binary schema. These are anchors, not the upstream suite.

**Schema features**
  `flatbuffers/` is one `.fbs` per FlatBuffers concept: scalars, strings, structs, vectors, includes, attributes, and a grammar file.

**Godot types**
  `godot/` maps engine types through `godot.fbs`. `variant.fbs` is the scalar and builtin-struct list. `array_types.fbs` is the vector list.

## Existing tests

| Test | Generate | Encode | Verify | Decode | Use |
| --- | --- | --- | --- | --- | --- |
| `fb_monster/test_monster.gd` | yes | tutorial orc | happy path, plus one broken slot per check | yes | yes |
| `fb_reflection/test_reflection.gd` | yes | — | — | `Reflection.bfbs` through `get_Schema` | — |
| `flatbuffers/test_00_minimum.gd` | yes | manual, function, builder | happy path only | yes | yes |
| `flatbuffers/test_01_grammar.gd` | yes | — | — | — | — |
| `flatbuffers/test_include.gd` | yes | yes | — | yes | yes |
| `flatbuffers/test_attributes.gd` | yes | — | — | — | `deprecated` accessor is absent |
| `flatbuffers/test_scalar.gd` | yes | yes | — | yes | yes |
| `flatbuffers/test_string.gd` | yes | manual, function, builder | — | function and manual | — |
| `flatbuffers/test_struct.gd` | yes | yes | — | yes | yes |
| `flatbuffers/test_vector.gd` | yes | yes | — | yes | yes |
| `godot/test_variant.gd` | yes | builder | — | yes | — |

`flatbuffers/schemas/generic.fbs` has no `root_type` and no test script. `godot/schemas/array_types.fbs` has a generated script and no test script. `project/tests/flatc/` has no files.

Monster's hostile cases are empty, tail cut after the root, a vtable offset outside the buffer, a name offset outside the buffer, a name length past the end, an inventory length past the end, a weapon element that is not a table, and an equipped offset that stays in range but does not point at a weapon.

`grammar.fbs` still comments out `file_extension`, `file_identifier`, fixed-length arrays, unions, nested tables, `root_type`, and `rpc_service`. `attribute.fbs` only carries `(deprecated)`. `variant.fbs` comments out `StringName`, `NodePath`, `RID`, `Object`, `Callable`, `Signal`, `Dictionary`, and `Array`.

## Still open

Each item is one missing proof. Schema work stays in `flatbuffers/`. Engine types stay in `godot/`.

### Phases on tests that already exist

These scripts compile and run. The open work is a phase the strategy never calls.

- [ ] `test_string.gd`: add the use phase. The strategy file already notes it is missing.
- [ ] `test_scalar.gd`, `test_string.gd`, `test_struct.gd`, `test_vector.gd`, `test_include.gd`, `test_variant.gd`: verify a buffer that was just built.
- [ ] Repeat the Monster hostile-slot pattern on minimum, string, vector, struct, and variant. One broken slot per check, and `verify()` returns false. Do not read fields after a failed verify.
- [ ] `test_vector.gd`: clear the pack-type FIXME in `vector_strategy.gd` for scalar, enum, string, struct, table, and union vectors.
- [ ] `test_variant.gd`: add a use phase for every field the schema currently generates.
- [ ] `test_01_grammar.gd`: turn the commented productions back on one group at a time, generate, and round-trip one value. Stop when a production has no GDScript shape yet, and record that here.

### Schema features with no proof

`TESTING.md` lists these. No current `.fbs` exercises them, apart from `(deprecated)`.

- [x] `(required)` on a string or table field. Building without it fails, and `verify()` fails when the field is absent. Covered by `res://tests/flatbuffers/test_required.gd`.
- [ ] `id` on every field of a table, including the implicit type field of a union.
- [ ] `bit_flags` on an unsigned enum. Generated values are `1 << N`.
- [ ] `nested_flatbuffer` on a `[ubyte]` field, then verify and read the inner root.
- [ ] `flexbuffer` on a `[ubyte]` field.
- [x] `key` on a table field, then sort a vector and look up by that key. Covered by `res://tests/flatbuffers/test_key.gd`.
- [ ] Union type alias (`Alias:Type`), separate from the union vector already in `vector.fbs`.
- [x] `file_identifier` round-trip, and a mismatch that `verify()` rejects. Covered by `res://tests/flatbuffers/test_file_identifier.gd`.
- [ ] `file_extension` is recorded on the generated script.
- [ ] Namespace becomes something a Godot script can preload, or the test records why a namespace file is the wrong shape.
- [ ] Identifier collision: a field named like an extension member (`start`, `bytes`) still generates a callable script.
- [ ] Optional `root_type`. Generation succeeds, and there is no `get_Root` helper.
- [ ] `rpc_service` / `rpc_method`, after the generated shape is chosen. Until then this stays a design note, not a failing test.
- [ ] Object API (`--object-api`, `native_*` attributes). Same rule: no test until the GDScript shape exists.

`hash` stays undecided in `TESTING.md`. No test until the attribute is either accepted or dropped.

### Godot types with no proof

`variant.fbs` covers the builtins that already generate. These are the ones left commented, plus the vector schema that has no runner.

- [ ] `test_array_types.gd` for `array_types.fbs`. Assert which widths become `Packed*Array` and which stay `Array`.
- [ ] Uncomment and round-trip `StringName` and `NodePath` in `variant.fbs`.
- [ ] Decide `RID`, `Object`, `Callable`, `Signal`, `Dictionary`, and `Array` the same way `TESTING.md` treats `hash`: a test, or a line here that says the type is out of scope.
- [ ] Include path `res://` and `user://`. `include.fbs` already says absolute Godot paths are unsupported. A test should fail with that message until `flatc` learns them.

### flatc flags

`project/tests/flatc/` is the place for these. Each flag gets one schema and one assertion about the generated file.

- [ ] `-o` writes the script to the given directory.
- [ ] `-I` resolves an include from a second directory.
- [ ] `--filename-suffix` defaults to `_generated` and honours an override.
- [ ] `--gen-onefile` produces one script.
- [ ] `--include-prefix` is visible in the generated preloads.
- [ ] `--gen-mutable` generates a setter, and the default generator does not.
- [ ] `--object-api`, `--object-prefix`, `--object-suffix`, and `--gen-compare`, once the object API shape exists.

### Outside this list

The GDScript schema highlighter is not a validator. `TEST_CASE.md` already says it has no test hook. A highlighter test belongs with the addon, not in this tree.

Upstream `monster_test.fbs`, the JSON suite, and the libFuzzer targets stay upstream. `fb_monster/` remains the tutorial.
