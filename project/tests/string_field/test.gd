@tool
extends EditorScript

const fb = preload('./FBTestString_generated.gd')

var pp := FlatBufferPrinter.new()

var result = "Success"

func _run() -> void:
	print("== Test String ==")
	short_way()
	long_way()


func short_way():
	print("# Short Way")

	var builder = FlatBufferBuilder.new()
	var offset = fb.CreateRootTable(builder, "This is a string that I am adding to te flatbuffer" )
	builder.finish( offset )

	## This must be called after `Finish()`.
	var buf = builder.to_packed_byte_array()
	print( " - size:%s\n - data: %s" % [ builder.get_size(), buf] )

	reconstruction( buf )


func long_way():
	print("# Long Way")
	var builder = FlatBufferBuilder.new()

	var string_offset = builder.create_String( "This is a string that I am adding to te flatbuffer" )

	var root_builder = fb.RootTableBuilder.new( builder )
	root_builder.add_my_string( string_offset )
	builder.finish( root_builder.finish() )

	## This must be called after `Finish()`.
	print("# Final Buffer")
	var buf = builder.to_packed_byte_array()
	print( " - size:%s\n - data: %s" % [ builder.get_size(), buf] )

	reconstruction( buf )


func reconstruction( buffer : PackedByteArray ):
	print("# Reconstruction")
	var root_table := fb.GetRoot( buffer )
	print( root_table.my_string() )
	pp.print( root_table )
