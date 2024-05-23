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
	var short_end = FB_MyTable.CreateMyTable( builder_short, value )
	builder_short.finish( short_end )
#
	# This must be called after `Finish()`.
	var buf : PackedByteArray = builder_short.to_packed_byte_array()
	var size : int = builder_short.get_size() # Returns the size of the buffer that `GetBufferPointer()` points to.
	print( "buffer:%s { %s }" % [size, buf] )

	var my_table := FB_MyTable.GetMyTable( buf.decode_u32(0), buf )

	pp.rint( my_table )

	# Long way
	#var builder_long = FlatBufferBuilder.create(1024)
	#var my_table_builder = FB_MyTable.MyTableBuilder.new( builder_long )
	#my_table_builder.add_value( value )
	#var offset = my_table_builder.finish()
	#builder_long.finish( offset )

	# This must be called after `Finish()`.
	#buf = builder_long.GetBufferPointer()
	#size = builder_long.GetSize() # Returns the size of the buffer that `GetBufferPointer()` points to.
	#print( "buffer:%s { %s }" % [size, buf] )
