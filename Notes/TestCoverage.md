# Test coverage

Coverage here means the plan in `project/tests/TESTING.md`: the tutorial and reflection anchors, one schema-feature suite, one Godot-type suite, the `flatc` flags, and the schema highlighter. It does not mean porting the upstream C++ `tests/` tree.

Top headings follow `project/tests/`, except the schema folder is split into Values and Declarations. The subheadings are the feature. A checked line is what that suite calls today. A checked schema feature was marked after a run. Assertions added after those runs are in the scripts and have not been run again.

## Monster

This is the buffer a new user copies from the tutorial. If this one cannot be built, read, and rejected when a slot is damaged, the generator is not fit to use.

An orc is written, read, and checked. An empty monster returns the schema defaults. One damaged slot at a time fails `verify()`.

- [x] Generate, encode the orc, decode, and use it.
- [x] An empty monster reads the schema defaults.
- [x] `verify()` fails on one broken slot at a time: empty buffer, tail cut after the root, a vtable offset outside the buffer, a name offset outside the buffer, a name length past the end, an inventory length past the end, a weapon element that is not a table, and an equipped offset that stays in range but does not point at a weapon.

## Reflection

Tools read a compiled schema when the `.fbs` source is not the input. This is that file.

`Reflection.fbs` is generated, and `Reflection.bfbs` is opened through `get_Schema`.

- [x] Generate from `Reflection.fbs`.
- [x] Decode `Reflection.bfbs` through `get_Schema`.
- [ ] Verify the decoded schema and read its tables and fields.

## Values

These are the bytes a buffer holds. A wrong width, offset, or default here shows up in every other suite.

Each feature below is generated from `project/tests/flatbuffers/` and written back out. The lines under it are the cases.

### Minimum

This is the smallest table. It has to work before any feature is added on top.

One integer field is encoded by hand, by function, and with the builder, then verified, decoded, and used. A broken buffer is still open.

- [x] Generate. Encode by hand, by function, and with the builder.
- [x] Verify the happy path. Decode and use.
- [ ] One broken slot, and `verify()` returns false. Do not read fields after a failed verify.

### Scalar

Every numeric field uses these widths and these default rules.

A built scalar table is generated, encoded, verified, decoded, and used. A single broken slot is still open.

- [x] Generate, encode, verify a built buffer, decode, and use.
- [ ] One broken slot, and `verify()` returns false.

### String

The length prefix is a byte count. An empty string is stored. A missing string is not.

Hand, function, and builder paths write a string, an empty string, and an absent string, then verify and decode. The use phase and a broken slot are still open.

- [x] Encode by hand, by function, and with the builder. Verify the built buffer, an empty string, and an absent string. Decode by function and by hand.
- [ ] Add the use phase. The flow stops after verify.
- [ ] One broken slot, and `verify()` returns false.

### Struct

A struct is inline bytes. A short read walks off the end of the buffer.

The struct is written and read. Its span is checked. A reused reader keeps its old span when the field is missing. A broken table slot is still open.

- [x] Generate, encode, decode, and use.
- [x] Verify a built buffer, a struct span, and a missing inline struct. `custom_struct(into)` reuses the reader and leaves it unchanged when the field is absent.
- [ ] One broken slot, and `verify()` returns false.

### Vector

An empty vector is present. An absent vector is not. A union discriminant of zero is legal.

Vectors are written, verified, and read, including empty, absent, a reused table view, and the `TestUnion` numbers. The enum pack type and a broken slot are still open.

- [x] Generate, encode, decode, and use.
- [x] Verify a built buffer, an empty vector, and an absent vector. `tables_at(into)` reuses one table across indexes. `TestUnion` is `0`, `1`, `2`. `NONE` verifies and an unmatched type fails.
- [ ] The enum vector is packed as `TYPE_PACKED_BYTE_ARRAY`. The FIXME in `vector_strategy.gd` asks for a clearer pack type.
- [ ] One broken slot, and `verify()` returns false.

### Union alias

An alias is another name for a union. The generator can mistake it for a new type.

Nothing yet. `Alias:Type` is not in a suite.

- [ ] `Alias:Type`, separate from the union vector.

### Required

A field marked required must be in the buffer. An empty string still counts, because it has an offset.

A present string and table pass `verify()`. A missing field fails the build and fails `verify()`.

- [x] A present string and table verify. An empty string still satisfies `required`.
- [x] Building without the string or the table returns `0`. `verify()` fails when either is absent.

### Bit flags

The names are sparse powers of two. Writing zero has to stay in the buffer, or a cleared flag looks like an omitted one.

The generated constants, a combined mask, an omitted flag, and a written zero are checked and verified.

- [x] Generated values are `1 << N`, including the sparse gaps.
- [x] A combined mask, an omitted flag, and a written zero. Those buffers verify.

### Nested flatbuffer

The payload is a second buffer. The outer check must not pretend it read the inner table.

The inner table is read from the payload bytes, including a default `n`. A 3-byte vector still passes, because only the `ubyte` vector is checked. `payload_nested_root` is not generated.

- [x] A `[ubyte]` payload is read back as `Inner`, including an inner table whose `n` was left at the default.
- [x] A 3-byte vector still verifies. The generated check only requires a `ubyte` vector. `payload_nested_root` is not generated.

### Key

Lookup is wrong when the sort order and the key's default disagree.

A sorted vector is looked up by key. An omitted integer key reads `0`. A missing required name fails the build. The buffer is verified.

- [x] Sort a vector and look up by the key. An omitted integer key reads `0`. A missing required name fails the build. The buffer verifies.

### Flexbuffer

Flexbuffers reuse a `[ubyte]` field. A generator that only sees a byte vector will drop the attribute.

Nothing yet.

- [ ] A `[ubyte]` field marked `flexbuffer`.

## Declarations

These sit around the values: names, includes, identifiers, and which code is emitted. A mistake here changes the script, not one field.

Each heading is one declaration. The suites live in `project/tests/flatbuffers/`. `generic.fbs` is shared declarations with no root and no suite.

### Grammar

The schema file is a grammar. A production this compiler skips will never appear in a later suite.

`TableDecl` defaults and the `Fruit` numbering are checked. The commented productions are still off.

- [x] `TableDecl` defaults: omitted, an explicit default, and a stored zero. Verify those buffers.
- [x] `Fruit` shares `1`, skips `3`, and sets `4`. An empty enum body is `NONE = 0`.
- [ ] Turn the commented productions back on one group at a time, generate, and round-trip one value. Stop when a production has no GDScript shape yet, and record that here. Still commented: `file_extension`, `file_identifier`, fixed-length arrays, unions, nested tables, `root_type`, and `rpc_service`.

### Include

A schema that cannot see another file cannot use a shared table.

An included table and an empty array are written, verified, decoded, and used. An absent include, `res://` paths, and an include of `godot.fbs` are still open.

- [x] Encode, decode, and use.
- [x] Verify a present included table and an empty array.
- [ ] Verify a root whose included table is absent. The strategy skips that call because the generated check follows the offset.
- [ ] `res://` and `user://` includes. `include.fbs` already says absolute Godot paths are unsupported. A test should fail with that message until `flatc` learns them.
- [ ] Include `godot.fbs` so the schema can use the built-in Godot types.

### Attribute

An attribute changes the generated script without changing the field's type.

`(deprecated)` drops the accessor, and the table still finishes. The documentation-comment form, a field that used to be required, and `id` are not tested.

- [x] `(deprecated)`: the accessor is absent, and an empty table finishes and verifies.
- [ ] `id` on every field of a table, including the implicit type field of a union.
- [ ] `(deprecated)` is written as `## @deprecated`, and as `## @deprecated: Use [AnotherClass] instead`. Include a field that used to be required.

### Enum

FlatBuffers enums are named. Godot also has unnamed enums, and a schema may need to reuse an enum that already exists.

Nothing yet for these cases. The `Fruit` numbers are covered under Grammar.

- [ ] Named FlatBuffers enums against Godot's unnamed enums.
- [ ] `native:"ExistingClass.ExistingEnum"` reuses an existing enum instead of generating a new one.
- [ ] Metadata on a single enumerator.

### Ignored attributes

These attributes are legal schema and this project ignores them. The test records that the generated script does not change.

Nothing yet.

- [ ] `force_align` on a struct.
- [ ] `force_align` on a vector.
- [ ] `original_order` on a table.

### Tool

A generated script sometimes has to run in the editor. `@tool` is the annotation for that.

Nothing yet.

- [ ] A generated script can be marked `@tool`.

### File identifier

Readers use four bytes to tell schemas apart. This generator checks those bytes beside `verify()`, not inside it.

`finish` writes `RQID`. `buffer_has_identifier` accepts it and rejects a mismatch. Table `verify()` still passes when the bytes are wrong.

- [x] `finish(offset, "RQID")` writes the bytes. `buffer_has_identifier` accepts them and rejects a mismatch or a plain finish.
- [x] `verify()` of the table still passes when the identifier does not match. The child table verifies either way.

### File extension

The extension is how a file is recognised as this schema.

Nothing yet. It should be recorded on the generated script.

- [ ] The extension is recorded on the generated script.

### Namespace

Two schemas with the same table name collide in one Godot project unless the namespace keeps them apart.

Nothing yet. Either a preloadable namespace, or a recorded reason that shape is wrong.

- [ ] A namespace becomes something a Godot script can preload, or the test records why a namespace file is the wrong shape.

### Identifier collision

A field named `bytes` or `start` can hide a member of the extension, and the generated script will not parse.

Nothing yet.

- [ ] A field named like an extension member (`start`, `bytes`) still generates a callable script.

### Root type

A schema can be a library and have no root. Generation still has to succeed.

Nothing yet. There should be no `get_Root` helper.

- [ ] An optional `root_type` generates successfully, and there is no `get_Root` helper.

### RPC

Services are part of the schema language, even when a game never calls them.

Nothing yet. The generated shape is not chosen, so this stays a design note.

- [ ] `rpc_service` and `rpc_method`, after the generated shape is chosen. Until then this stays a design note, not a failing test.

### Object API

The object API is a second way to build the same buffer. GDScript does not have that shape yet.

Nothing yet.

- [ ] `--object-api` and the `native_*` attributes. No test until the GDScript shape exists.

### Hash

`hash` would change how a table is identified. `TESTING.md` has not decided if it is in scope.

Nothing until that decision.

- [ ] `hash` stays undecided in `TESTING.md`. No test until the attribute is accepted or dropped.

## godot

Godot values are not FlatBuffers scalars. The generator has to pick a real engine type for each one.

`variant.fbs` is the single values. `array_types.fbs` is those values in vectors.

### Variant

A `Vector3` or a bool that does not survive a round trip cannot be used as a field.

The generated fields are built, verified, and decoded, including omitted scalar defaults. Use, a broken slot, `StringName`, `NodePath`, and the commented reference types are still open.

- [x] Generate, encode with the builder, verify a built buffer and the omitted scalars, and decode.
- [ ] Add a use phase for every field the schema currently generates.
- [ ] One broken slot, and `verify()` returns false.
- [ ] Uncomment and round-trip `StringName` and `NodePath`.
- [ ] Decide `RID`, `Object`, `Callable`, `Signal`, `Dictionary`, and `Array` the same way `TESTING.md` treats `hash`: a test, or a line here that says the type is out of scope. `variant.fbs` still comments these out.

### Array types

Some vectors become a `Packed*Array`. The rest stay an `Array`. The wrong choice is a type error at the call site.

Nothing yet. The schema has a generated script and no runner.

- [ ] Assert which widths become `Packed*Array` and which stay `Array`. The schema has a generated script and no runner.

## flatc

A flag changes where the script is written and what is in it. That is a broken project, not a bad buffer.

Nothing yet. `project/tests/flatc/` is empty. Each flag needs one schema and one assertion about the generated file.

- [ ] `-o` writes the script to the given directory.
- [ ] `-I` resolves an include from a second directory.
- [ ] `--filename-suffix` defaults to `_generated` and honours an override.
- [ ] `--gen-onefile` produces one script.
- [ ] `--include-prefix` is visible in the generated preloads.
- [ ] `--gen-mutable` generates a setter, and the default generator does not.
- [ ] `--object-api`, `--object-prefix`, `--object-suffix`, and `--gen-compare`, once the object API shape exists.

## highlighter

The highlighter is the schema parser the editor runs. Legal schema that it rejects never reaches the generator.

Nothing yet. One schema holds every legal arrangement, and a second file is included from it. The diagnose command should report no issues for either file.

- [ ] The main schema: every legal declaration, type, value, and attribute the highlighter accepts.
- [ ] The included schema, referenced from the main one.
- [ ] A runner that opens both files and checks that the stored issue list is empty.
