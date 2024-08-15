@tool
extends EditorScript

const fb = preload('./FBTestStringArray_generated.gd')

var pp := FlatBufferPrinter.new()

var string_array : PackedStringArray = []

var retcode : int = OK

func _run() -> void:
	# Setup
	var incrementing : String = ""
	for i in range(8):
		#string_offsets.append( builder.create_string( "ABCDEFG%s" % i ) )
		incrementing += "%s" % i
		string_array.append( incrementing )

	short_way()
	long_way()

func short_way():

	var builder = FlatBufferBuilder.new()
	var offset = fb.CreateRootTable(builder, string_array )
	builder.finish( offset )

	## This must be called after `Finish()`.
	var buf = builder.to_packed_byte_array()

	reconstruction( buf )

func long_way():
	var builder = FlatBufferBuilder.new()

	# Creation of the string array needs to come before creation of the table
	var string_array_offset = builder.create_PackedStringArray( string_array )

	var root_builder = fb.RootTableBuilder.new( builder )
	root_builder.add_my_strings( string_array_offset )
	builder.finish( root_builder.finish() )

	## This must be called after `Finish()`.
	var buf = builder.to_packed_byte_array()
	reconstruction( buf )

func reconstruction( buffer : PackedByteArray ):
	var root_table := fb.GetRoot( buffer )
	pp.print( root_table )

	# Size of arrays should match
	if root_table.my_strings_size() != string_array.size(): retcode |= FAILED

	# strings retrieved with the *_at( int ) method should match
	for index in string_array.size():
		if root_table.my_strings_at(index) != string_array[index]: retcode |= FAILED

	# retrieve the whole array
	var my_strings = root_table.my_strings()

	# size should match
	if my_strings.size() != string_array.size(): retcode |= FAILED

	# strings should match
	for index in string_array.size():
		if my_strings[index] != string_array[index]: retcode |= FAILED
