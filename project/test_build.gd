@tool
extends EditorScript

var pp : PP = PP.new()

func _run() -> void:
	print("Test script is running")
	var filename : String = "res://smol.bfbs"
	var bfbs : PackedByteArray = FileAccess.get_file_as_bytes( filename )

	print( filename, ", size: ", bfbs.size() )
	print( "data: ", bfbs )
	var value : int = 5

	# Short way
	var builder_short : FlatBufferBuilder = FlatBufferBuilder.create(1024)
	var short_end = MyTable.CreateMyTable_( builder_short, value )
	builder_short.finish( short_end )
#
	# This must be called after `Finish()`.
	var buf_short : PackedByteArray = builder_short.to_packed_byte_array()
	var size_short : int = builder_short.get_size() # Returns the size of the buffer that `GetBufferPointer()` points to.
	print( "buffer:%s { %s }" % [size_short, buf_short] )

	var my_table_short := MyTable.GetMyTable_( buf_short.decode_u32(0), buf_short )
	pp.rint( my_table_short )

	# Long way
	var builder_long = FlatBufferBuilder.create(1024)
	var my_table_builder = MyTable.MyTable_Builder.new( builder_long )
	my_table_builder.add_value( value )
	var offset = my_table_builder.finish()
	builder_long.finish( offset )

	# This must be called after `Finish()`.
	var buf_long = builder_long.to_packed_byte_array()
	var size_long = builder_long.get_size() # Returns the size of the buffer that `GetBufferPointer()` points to.
	print( "buffer:%s { %s }" % [size_long, buf_long] )

	var my_table_long := MyTable.GetMyTable_( buf_long.decode_u32(0), buf_long )
	pp.rint( my_table_long )
