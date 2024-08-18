@tool
extends EditorScript

const fb = preload('./FBTestStruct_generated.gd')

var test_vector := Vector3i(1,2,3)

func _run() -> void:
	short_way()
	long_way()


func short_way():
	var builder = FlatBufferBuilder.new()
	var offset = fb.CreateRootTable( builder, test_vector )
	builder.finish( offset )

	## This must be called after `Finish()`.
	var buf = builder.to_packed_byte_array()
	reconstruction( buf )


func long_way():
	var builder = FlatBufferBuilder.new()

	var root_builder = fb.RootTableBuilder.new( builder )
	root_builder.add_my_struct( test_vector )
	builder.finish( root_builder.finish() )

	## This must be called after `Finish()`.
	var buf = builder.to_packed_byte_array()
	reconstruction( buf )


func reconstruction( buffer : PackedByteArray ):
	var root_table := fb.GetRoot( buffer )
	output.append( "root_table: " + JSON.stringify( root_table.debug(), '\t', false ) )

	TEST_EQ( root_table.my_struct(), test_vector, "my_struct()" )


#region == Test Results ==
var retcode : int = OK
var output : PackedStringArray = []

func TEST_EQ( value1, value2, msg : String = "" ):
	if value1 == value2: return
	retcode |= FAILED
	printerr( "%s | got '%s' wanted '%s'" % [msg, value1, value2 ] )
#endregion
