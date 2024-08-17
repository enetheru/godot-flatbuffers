@tool
extends EditorScript

const fb = preload('./FBTestTableArray_old.gd')
var pp := FlatBufferPrinter.new()

#region == Testing Setup ==

class SubTable:
	var item : int

var table_array : Array
#endregion

func _run() -> void:
	table_array.resize( 13 )
	for i in table_array.size():
		var new_table := SubTable.new()
		new_table.item = i * 13
		table_array[i] = new_table

	#short_way()
	long_way()
	print( "Test Completed")


func short_way():
	var builder = FlatBufferBuilder.new()
	var offset = fb.CreateRootTable( builder, table_array )
	builder.finish( offset )

	## This must be called after `Finish()`.
	var buf = builder.to_packed_byte_array()
	reconstruction( buf )


func long_way():
	var builder = FlatBufferBuilder.new()

	var offsets : PackedInt32Array
	offsets.resize( table_array.size() )
	for i in table_array.size():
		offsets[i] = fb.CreateSubTable2( builder, table_array[i] ) # Call the variant version

	var table_array_offset = builder.create_vector_offset( offsets )
#
	var root_builder = fb.RootTableBuilder.new( builder )
	root_builder.add_table_array( table_array_offset )
	builder.finish( root_builder.finish() )
#
	## This must be called after `Finish()`.
	var buf = builder.to_packed_byte_array()
	reconstruction( buf )


func reconstruction( buffer : PackedByteArray ):
	var root_table := fb.GetRoot( buffer )
	#pp.print( root_table )
	#for n in buffer.size():
		#print( "%s : %s" % [n,buffer[n]] )

	var array : Dictionary = {}
	array['start'] = root_table.get_field_start( root_table.VT_TABLE_ARRAY )
	if not array.start: return FAILED

	array['size'] = buffer.decode_u32( array.start )
	array['data'] = array.start + 4
	var starts : Array; starts.resize( array.size )
	var offsets : Array; offsets.resize( array.size )
	for i in array.size:
		var pos = array.data + i * 4
		offsets[i] = buffer.decode_u32( pos )
		starts[i] = pos + offsets[i]
	array['offsets'] = offsets
	array['starts'] = starts

	var subtables : Array; subtables.resize( array.size )
	for i in array.size:
		subtables[i] = fb.GetSubTable( starts[i], buffer )
	array['subtables'] = subtables

	#for key in array:
		#print( "%s : %s" % [key, array[key]] )
#
	#for subtable in array.subtables:
		#print( "subtable: ", JSON.stringify( subtable.debug(), '\t', false ) )
		#pp.print( subtable )

	print( "root_table: ", JSON.stringify( root_table.debug(), '\t', false ) )

	var builder = FlatBufferBuilder.new()
	var subtable_builder = fb.SubTableBuilder.new( builder )
	subtable_builder.add_item( 5 )
	builder.finish( subtable_builder.finish() )
#
	## This must be called after `Finish()`.
	var buf = builder.to_packed_byte_array()
	var subtable := fb.GetSubTable( buf.decode_u32( 0 ), buf )
	#pp.print( subtable )
	retcode = FAILED


#region == Test Results ==
var retcode : int = OK
func TEST_EQ( value1, value2, msg : String = "" ):
	if value1 == value2: return
	retcode |= FAILED
	printerr( "%s | got '%s' wanted '%s'" % [msg, value1, value2 ] )
#endregion
