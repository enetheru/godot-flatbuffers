@tool
extends EditorScript

const fb = preload('./FBTestStruct_generated.gd')

var pp := FlatBufferPrinter.new()

var data := Vector3(1,2,3)

var result = "Success"

func _run() -> void:
	print("== Test String ==")
	short_way()
	long_way()


func short_way():
	print("# Short Way")

	print( data )

	var builder = FlatBufferBuilder.new()
	var offset = fb.CreateRootTable( builder, data )
	builder.finish( offset )

	## This must be called after `Finish()`.
	var buf = builder.to_packed_byte_array()
	print( " - size:%s\n - data: %s" % [ builder.get_size(), buf] )

	reconstruction( buf )


func long_way():
	print("# Long Way")
	var builder = FlatBufferBuilder.new()

	var root_builder = fb.RootTableBuilder.new( builder )
	root_builder.add_my_struct( data )
	builder.finish( root_builder.finish() )

	## This must be called after `Finish()`.
	print("# Final Buffer")
	var buf = builder.to_packed_byte_array()
	print( " - size:%s\n - data: %s" % [ builder.get_size(), buf] )

	reconstruction( buf )


func reconstruction( buffer : PackedByteArray ):
	print("# Reconstruction")
	var root_table := fb.GetRoot( buffer )
	print( root_table.my_struct() )
	pp.print( root_table )


	for i in buffer.size():
		print("%s: %s" %[i, buffer[i]] )

	print( "start: ", root_table.start )
	print( "VT_MY_STRUCT: ", root_table.VT_MY_STRUCT )
	print( "get_field_offset: ", root_table.get_field_offset( root_table.VT_MY_STRUCT ) )
	print( "field_start: ", root_table.start + root_table.get_field_offset( root_table.VT_MY_STRUCT ) )
