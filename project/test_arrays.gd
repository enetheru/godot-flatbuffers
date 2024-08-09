@tool
extends EditorScript

var pp := FlatBufferPrinter.new()

func _run() -> void:
	print("Test script is running")
	var filename : String = "res://smol.bfbs"
	var bfbs : PackedByteArray = FileAccess.get_file_as_bytes( filename )

	print( filename, ", size: ", bfbs.size() )
	print( "data: ", bfbs )
	var payload : PackedByteArray = [5,4,3,2,1]

	## Short way
	#var builder_short : FlatBufferBuilder = FlatBufferBuilder.new()
	#var short_end = FBTestArrays.CreateRootTable( builder_short, FIXME )
	#builder_short.finish( short_end )
##
	## This must be called after `Finish()`.
	#var buf_short : PackedByteArray = builder_short.to_packed_byte_array()
	#var size_short : int = builder_short.get_size() # Returns the size of the buffer that `GetBufferPointer()` points to.
	#print( "buffer:%s { %s }" % [size_short, buf_short] )
#
	#var my_table_short := FBTestArrays.GetRootTable( buf_short.decode_u32(0), buf_short )
	#pp.print( my_table_short )

	# Long way
	var builder_long = FlatBufferBuilder.new()

	var payload_offset = builder_long.create_packed_byte_array( payload )

	var root_table_builder = FBTestArrays.RootTableBuilder.new( builder_long )
	root_table_builder.add_test_bytes( payload_offset )
	var offset = root_table_builder.finish()
	builder_long.finish( offset )

	# This must be called after `Finish()`.
	var buf_long = builder_long.to_packed_byte_array()
	var size_long = builder_long.get_size() # Returns the size of the buffer that `GetBufferPointer()` points to.
	print( "\nbuffer:%s { %s }" % [size_long, buf_long] )

	var my_table_long := FBTestArrays.GetRoot( buf_long )
	print("")
	pp.print( my_table_long )
