@tool
extends EditorScript

const fb = preload('./FBTestStringArray_generated.gd')
var silent : bool = false


var string_array : PackedStringArray = []

func _run() -> void:
	# Setup
	var incrementing : String = ""
	for i in range(8):
		#string_offsets.append( builder.create_string( "ABCDEFG%s" % i ) )
		incrementing += "%s" % i
		string_array.append( incrementing )

	short_way()
	long_way()
	if not silent:
		print_rich( "\n[b]== String Arrays ==[/b]\n" )
		for o in output: print( o )

func short_way():

	var builder = FlatBufferBuilder.new()
	var strings_offset = builder.create_PackedStringArray( string_array )
	var offset = fb.CreateRootTable(builder, strings_offset )
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
	output.append( "root_table: " + JSON.stringify( root_table.debug(), '\t', false ) )

	# Size of arrays should match
	TEST_EQ( root_table.my_strings_size(), string_array.size(), "my_strings_size()")

	# strings retrieved with the *_at( int ) method should match
	for index in string_array.size():
		TEST_EQ( root_table.my_strings_at(index), string_array[index], "my_strings_at(%s)" % index )

	# retrieve the whole array
	var my_strings = root_table.my_strings()

	# size should match
	TEST_EQ( my_strings.size(), string_array.size(), "my_strings.size()" )

	# strings should match
	for index in string_array.size():
		TEST_EQ( my_strings[index], string_array[index], "my_strings[%s] != string_array[%s]" % [index,index])

#region == Test Results ==
var retcode : int = OK
var output : PackedStringArray = []
func TEST_EQ( value1, value2, msg : String = "" ):
	if value1 == value2: return
	retcode |= FAILED
	printerr( "%s | got '%s' wanted '%s'" % [msg, value1, value2 ] )
#endregion
