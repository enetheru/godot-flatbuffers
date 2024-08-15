@tool
extends EditorScript

const fb = preload('./FBTestStringArray_generated.gd')

var pp := FlatBufferPrinter.new()

var string_array : PackedStringArray = []

var result = "Success"

func _run() -> void:
	print("== Test Table Arrays ==")
	# Setup

	var incrementing : String = ""
	for i in range(8):
		#string_offsets.append( builder.create_string( "ABCDEFG%s" % i ) )
		incrementing += "%s" % i
		string_array.append( incrementing )

	short_way()
	long_way()

func short_way():
	print("# Short Way")

	var builder = FlatBufferBuilder.new()
	var offset = fb.CreateRootTable(builder, string_array )
	builder.finish( offset )

	## This must be called after `Finish()`.
	var buf = builder.to_packed_byte_array()
	print( " - size:%s\n - data: %s" % [ builder.get_size(), buf] )

	reconstruction( buf )

func long_way():
	print( "# Long Way")
	var builder = FlatBufferBuilder.new()

	var string_array_offset = builder.create_PackedStringArray( string_array )

	var root_builder = fb.RootTableBuilder.new( builder )
	root_builder.add_my_strings( string_array_offset )
	builder.finish( root_builder.finish() )

	## This must be called after `Finish()`.
	#print("# Final Buffer")
	var buf = builder.to_packed_byte_array()
	print( " - size:%s\n - data: %s" % [ builder.get_size(), buf] )
	for i in buf.size():
		print("byte %s: " %i, buf[i])

	var table : Dictionary = {}
	var vtable : Dictionary = {}
	var my_strings : Dictionary = {}
	var strings : Array = []
	print("# Reconstruction")
	table['start'] = buf.decode_u32(0)
	table['vtable'] = buf.decode_s32( table.start )
	vtable['start'] = table.start - buf.decode_s32( table.start )
	vtable['size'] = buf.decode_u16( vtable.start )
	vtable['table_size'] = buf.decode_u16( vtable.start + 2 )
	vtable['VT_MY_STRINGS'] = buf.decode_u16( vtable.start + 4 )
	table['my_strings'] = buf.decode_u32(table.start + vtable.VT_MY_STRINGS)
	my_strings['start'] = table.start + table.my_strings + buf.decode_u32( table.start + table.my_strings )
	my_strings['size'] = buf.decode_u32( my_strings.start )
	my_strings['bytes'] = my_strings.size * 4 + 4

	var offsets : Array
	offsets.resize( my_strings.size )
	for i in range( my_strings.size ):
		var position = my_strings.start + 4 + i * 4
		offsets[i] = position + buf.decode_u32( position )
	my_strings['values'] = offsets

	for i in range( my_strings.size ):
		#var string_start = my_strings.start + my_strings.bytes + offsets[i]
		var string_start = offsets[i]
		var string_size = buf.decode_u32( string_start )
		strings.append( buf.slice( string_start + 4, string_start + 4 + string_size ).get_string_from_ascii() )


	print( "table: ", table )
	print( "vtable: ", vtable )
	print( "my_strings: ", my_strings )
	print( "strings: ", strings )

	var root_table := fb.GetRoot( buf )

	var strings_size = root_table.my_strings_size()
	print( "my_strings_size(): ", strings_size )
	print( "my_strings_at( 0->%s ): " % strings_size )
	for i in strings_size:
		print( "\t%s: " % i, root_table.my_strings_at(i) )


func reconstruction( buffer : PackedByteArray ):
	print("# Reconstruction")
	var root_table := fb.GetRoot( buffer )
	pp.print( root_table )
