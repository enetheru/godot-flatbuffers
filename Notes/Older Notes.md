Planning document for flatbuffers addon.

In editor settings there is  a subheading for external programs, might be extended to allow specifying the flatbuffer compiler executable

Will need to be able to recognise flatbuffer schema files, '.fbs' and auto parse them to generate the gdscript files

In the editor settings->docks->filesystem I had to add fbs to the text editor setting to have the schem afiles show up.

There is a plugins header in the settings, which I might be able to add stuff to if required.

I think generating the gdscript api access files next to their schema counterparts might be a good way to start, but generally I want an option to put them in a folder of their own, so the schema files stay separate and the generated files can be ignored.

I know how to compile the code
I've used flatbuffers in c++ and C# before

The workflow appears to be to generate a schema, which is used to generate native source to interface with the flatbuffer library.

Given I have access to c++ in the plugin, the expose of godot api will be created in the c++ codebase.

Which means I can expose all the native types without them having equivalent gdscript code in the plugin.

I guess that means that the majority of the code i will be enabling is about the grouping of objects, and not the initial serialisation of the types themselves.

I have to create the plugin bits and get that compiling which I have done in the past, but it was a massive hassle and I worked mostly in clion.

---

I've been thinking about how to implement the flatbuffers into godot, and I have two layers to deal with.

I have the c++ representation of the variant class and all its subtypes
I have the gdscript representation of the variant classes.

It feels like there is some reality where I can create the relevant schema translation from the variant class to flatbuffers, and perform the automatic conversion.

that of course wont be formal enough for backwards compatibility, so would require a schema anyway, but I might be able to make all the variant class types into structs, or similar.

Because the gdscript language can be defined from c++, I can have any structural classes built into c++ and implemented directly inline with the flatbuffer code.

And the rest can use generated gdscript code.. which means I will have to perform some generation of a sort.

It does require that I have a working plugin, which I've been dreading honestly.

Given I have a working plugin compiled and in the editor, What are some things I want to get working.

Recognition of the flatbuffer file format and syntax highlighting in the editor.
Generation of the gdscript interface for flatbuffer schema objects 
	- Optional Folder selection for where to place generated objects

To this end I have re-purchased clion, I am a little surprised I am willing to shell out $200 for an IDE, but it will last me till october 2025, which is more than a year away.

