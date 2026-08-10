Godot Flatbuffers
=================
Serialise to, and from, flatbuffer objects.

This is a work in progress, and I would appreciate any and all feedback relating to it.

**If there are any requests please drop them in an issue and I'll look into it.**

The project consists of four main areas:

1. The modifications to the flatc compiler which generates gdscript
   * `flatc --gdscript <schema.fbs>`
   * [enetheru/flatbuffers](https://github.com/enetheru/flatbuffers) is acquired automatically during CMake configuration.
1. The GDExtension binary plugin - this repository
   * `FlatbufferBuilder` Godot Object Class for serialising data
   * `FlatBufferVerifier` Godot Object Class for verifying serialised data
   * `Flatbuffer` Godot Object Class for reading serialised data
   * `UUID` Godot Object Class for creating uuid numbers( requires additional libraries )
1. The Godot Editor addon/plugin
   * Syntax Highlighting of FlatBuffers schema files `*.fbs`
   * Context menu's for calling flatc to generate GDScript from flatbuffer schema
   * [enetheru/godot-flatbuffers-addon](https://github.com/enetheru/godot-flatbuffers-addon/)
1. The Development and Testing Godot Project
    - For all the integration testing and experimentation
    - [enetheru/godot-flatbuffers-project](https://github.com/enetheru/godot-flatbuffers-project/)


### Installation

Due to the work in progress nature, there are no release binaries yet.

I've tried to make compilation as straight forward as possible, dependencies are pulled using CMake's FetchContent.
After CMake configure completes, you will need to build two targets: `flatc` and `godot-flatbuffers`.

To generate the documentation XML files for the GDExtension classes, you can run the `godot-docs` target.
This will use the Godot executable to scan the project and update the `docxml` folder.

Then copy or link the `project/addons/enetheru.flatbuffers-extension` folder into your `project/addons` folder.

```sh
cmake -DCMAKE_BUILD_TYPE=Release -B build
cmake --build build --config Release

cp -r project/addons/enetheru.flatbuffers-extension ~/godot/my-godot-project/addons
./project/addons/enetheru.flatbuffers-extension/bin/flatc --version
```

I do know that at least on windows `flatc` builds using mingw, if you run into trouble please hit me up in issues, or in godot discord gdextension/c++ channels linked at the bottom of this document.

### Basic Usage

First you might want to read up on the [Flatbuffers Documentation](https://flatbuffers.dev/index.html)

#### Step One - Create a schema file

```fbs
// my_object.fbs
table MyObject {
    var_name:int32;
}

root_type MyObject;
```

#### Step Two - Generate the GDScript code

Right click on the file in the file explorer, or the script editor and select `flatc --gdscript` to call the flatc compiler on the buffer and generate the code.

A new file `my_object_generated.gd` should appear next to my_object.fbs

#### Step Three - Serialise/De-Serialise some data

If you had read the flatbuffer documentation above, you might see that serialising data is a bit more involved than what might be expected.

Here is an editor script demonstrating serialisation and de-serialiastion of the simple case
```gdscript
@tool
extends EditorScript

# the generated files do not have a class_name so that we dont pollute the global namespace
const MyObjectSchema = preload('res://flatbuffers/my_object_generated.gd')

# Handy trick to get shorter names.
const MyFlatBuf = MyObjectSchema.MyObject
const MyBuilder = MyObjectSchema.MyObjectBuilder

## The value I wish to serialise
var my_value : int = 42


## Construct the flabuffer data in one shot using the create_* function
func serialise() -> PackedByteArray:
	# Make a new builder
	var fbb = FlatBufferBuilder.new()

	# If you want to serialise all the values at once
	var offset = MyObjectSchema.create_MyObject( fbb, my_value )

	# finalise the builder and return the PackedByteArray
	fbb.finish( offset )
	return fbb.to_packed_byte_array()

## Construct the flabuffer data using the builder object, this would be most
## useful in larger objects when you want to only partially construct the buffer.
func serialise_parts() -> PackedByteArray:
	# Create a new builder
	var fbb = FlatBufferBuilder.new()

	# if you want to partially serialise a buffer with many fields
	var my_builder = MyBuilder.new(fbb)
	my_builder.add_var_name(my_value)
	var offset = my_builder.finish()

	# Finalise the fbb
	fbb.finish(offset)

	# return the final buffer
	return fbb.to_packed_byte_array()


## Use the MyObject Flatbuffer specialisation to deserialise the bytes
func deserialise( buffer : PackedByteArray ) -> void:
	var flatbuf : MyFlatBuf = MyObjectSchema.get_MyObject( buffer )

	if flatbuf.var_name_is_present():
		my_value = flatbuf.var_name()


## EditorScripts can be run form the script editor panel by right clicking
## their filename and selecting 'Run'
func _run() -> void:
	print("serialise using create_ function")
	var my_value:int = 42

	print( "Start Value: %d" % my_value )
	var buffer1 : PackedByteArray = serialise()

	my_value = 9001
	print( "Value changed to: %d" % my_value )

	deserialise( buffer1 )
	print( "Deserialised Value: %d" % my_value )

	print()
	print("serialise fields independently")

	print( "Start Value: %d" % my_value )
	var buffer2 : PackedByteArray = serialise_parts()

	my_value = 37
	print( "Value changed to: %d" % my_value )

	deserialise( buffer2 )
	print( "Deserialised Value: %d" % my_value )

```

###  FAQ
Some of these items are to remind myself even.

#### PackedArrays
I got caught out recently with my interpretation of the FlatBuffers schema, and how it relates to data within the Godot engine. FlatBuffers have both signed and unsigned bytes, however, `PackedByteArray` doesn't specify signedness and so I assume anything that uses bytes as the name is talking about data width and not mathematical primitives, signedness makes no sense to me but that's how the FlatBuffers schema is defined so I have to roll with that.

So when generating code...
```flatbuffers
table TableName {
    first:[byte];
    second:[ubyte];
}
```

The access functions will need to decode the signed 8bit type and return an `Array[int]`. Whereas the `ubyte` case will use `internal_buf.slice(a,b)` to return a `PackedByteArray`, making it the more efficient option.

Here is the mapping:
```flatbuffers
table mapping {
    f2:[uint8];     //[ubyte|uint8]     PackedByteArray
    f3:[int32];     //[int|int32]       PackedInt32Array
    f4:[int64];     //[long|int64]      PackedInt64Array
    f5:[float32];   //[float|float32]   PackedFloat32Array
    f6:[float64];   //[double|float64]  PackedFloat64Array
}
```
The remaining integer types (`[byte|int8|short|ushort|int16|uint16|uint|uint32|ulong|uint64]`) need to be decoded from the underlying bytes and so they all return as `Array[int]`, and it may be better to access them individually using the `<field_name>_at(index:int)` method.
#### Compiling
To change the godot target add `-DGODOTCPP_TARGET:STRING=<target>` where `<target>` is one of
`[template_debug, template_release, editor]`.

Godot's `template_debug`/`template_release` target are completely different concept to `Debug`/`Release` in the typical
C++ sense with symbols and less optimisation. `template_debug` is for developing and debugging in the editor, and providing debug versions to customers that provide more information. When in doubt, build in `Release` mode with `template_debug`

your cmake command will probably have these two items in it somewhere: `-DCMAKE_BUILD_TYPE=Release`, `-DGODOTCPP_TARGET:STRING=template_debug`

#### Import Plugin
I just spent three to four days trying to get an import plugin to work that would still allow editing of the schema file as a text document and frustrated myself over and over with the limitations of that process. I eventually gave up on the endeavour for now. The primary frustrations was the insistence of godot to re-interpret the text based schema files as anything else, preventing them from being edited as text files.

#### Resource Format Loader Plugin
Similar situation to the import plugin, all of my attempts failed to produce something of value.

#### Schema Includes
- While the flatc compiler can use relative paths, the highlighter is not aware of the file path of the file it is currently highlighting, this is a limitation of the plain text editor in godot, and requires a change to the engine code to expose the path. So highlighting will fail on relative paths.
- flatc also does not recognise res:// or user:// paths, and I will not be changing that.
- the res:// path is always added to the include list so including files relative to res:// will work fine.
- I have an outdated PR for this: https://github.com/godotengine/godot/pull/96058

---

### Help me help you

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/P5P61CW89K)

### Discord
I'm frequently available in both the official and the unofficial discord channels for gdextension and C++
as 'Enetheru' during Australian Central Standard Time GMT+930. Keep in mind that these channels are for gdextension development discussion, if your question is directly about this project then its best to either @ me with a very short message, or private message me. I am very responsive.

* [GodotEngine #cplusplus-discuss](https://discord.com/channels/1235157165589794909/1259879534392774748)
* [Godot Café #gdnative-gdextension](https://discord.com/channels/212250894228652034/342047011778068481)

### Upstream
* https://flatbuffers.dev/index.html
* https://github.com/google/flatbuffers

### Alternative Projects
* https://github.com/V-Sekai-archive/godot-flatbuffers
* https://gitlab.com/JudGenie/flatbuffersgdscript
