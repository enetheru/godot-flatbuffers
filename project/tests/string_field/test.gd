@tool
extends EditorScript

const fb = preload('./FBTestString_generated.gd')

func _run() -> void:
	short_way()
	long_way()

var test_string : String = "This is a string that I am adding to te flatbuffer"

func short_way():
	var builder = FlatBufferBuilder.new()
	var string_offset = builder.create_String( test_string )
	var offset = fb.CreateRootTable( builder, string_offset )
	builder.finish( offset )

	## This must be called after `Finish()`.
	var buf = builder.to_packed_byte_array()
	reconstruction( buf )


func long_way():
	var builder = FlatBufferBuilder.new()

	var string_offset = builder.create_String( test_string )

	var root_builder = fb.RootTableBuilder.new( builder )
	root_builder.add_my_string( string_offset )
	builder.finish( root_builder.finish() )

	## This must be called after `Finish()`.
	var buf = builder.to_packed_byte_array()
	reconstruction( buf )


func reconstruction( buffer : PackedByteArray ):
	var root_table := fb.GetRoot( buffer )

	output.append( "root_table: " + JSON.stringify( root_table.debug(), '\t', false ) )

	TEST_EQ( root_table.my_string(), test_string, "my_string()" )

#region == Test Results ==
var retcode : int = OK
var output : PackedStringArray = []
func TEST_EQ( value1, value2, msg : String = "" ):
	if value1 == value2: return
	retcode |= FAILED
	printerr( "%s | got '%s' wanted '%s'" % [msg, value1, value2 ] )
#endregion
