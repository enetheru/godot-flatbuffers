OK, There are a bunch of things that need to happen to get a valid godot flatbuffers implementation.

Firstly I need to be able to read a flatbuffer.
I need to be able to create a flatbuffer
I need to generate gdscript to read flatbuffers generated from other schemas

Because gdscript is based in c++, I can offload any shared code to c++ and expose it as a function in gdscript.
## Reading a FlatBuffer
It would be impossible to read a flatbuffer without knowing what's inside it. So as long we we know the contents we can custom make a reader to interpret the binary data.

The reason we need to be able to read a binary file is that the code generation process is like this
`schema.fbs->schema.bfbs->generated_code`

The way to generate code is from the flatbuffer itself, and while this may happen in c++ under the hood, reading the results is left up to the target language.

So regardless of how we end up, there will be the process of understanding how to generate code that can read a flatbuffer.

So the logical first step is to build a custom reader from scratch without any code gen. which means we need a known schema.

there exists such a schema and its called reflection.fbs
But I can just as easily test reading my own simpler schemas to get started.

## Creating a FlatBuffer
Now that we can read a FlatBuffer in our target language using our custom reader, I want to make sure we can create the Flatbuffer using our target language.

## Generating Code
Using the above two examples, We can then use the IR flabuffer reflection.fbs and other generators to generate our own readers and writers.