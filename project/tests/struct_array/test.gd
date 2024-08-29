@tool
extends TestBase

const fb = preload('./FBTestStruct_generated.gd')

var builtin_ := Vector3i(1,2,3)

func _run() -> void:
	short_way()
	long_way()
	if not silent:
		print_rich( "\n[b]== Struct ==[/b]\n" )
		for o in output: print( o )


func short_way():
	var builder = FlatBufferBuilder.new()

	var my_struct = fb.MyStruct.new()

	var offset = fb.CreateRootTable( builder, my_struct, builtin_ )
	builder.finish( offset )

	## This must be called after `Finish()`.
	var buf = builder.to_packed_byte_array()
	reconstruction( buf )


func long_way():
	var builder = FlatBufferBuilder.new()

	var root_builder = fb.RootTableBuilder.new( builder )
	root_builder.add_builtin_struct( builtin_ )
	builder.finish( root_builder.finish() )

	## This must be called after `Finish()`.
	var buf = builder.to_packed_byte_array()
	reconstruction( buf )


func reconstruction( buffer : PackedByteArray ):
	var root_table := fb.GetRoot( buffer )
	output.append( "root_table: " + JSON.stringify( root_table.debug(), '\t', false ) )

	TEST_EQ( root_table.builtin_struct(), builtin_, "builtin_struct()" )
