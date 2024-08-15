@tool
extends EditorScript

const fb = preload('./FBTestTableArray_generated.gd')
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

	short_way()
	#long_way()


func short_way():
	var builder = FlatBufferBuilder.new()
	var offset = fb.CreateRootTable( builder, table_array )
	#builder.finish( offset )
#
	### This must be called after `Finish()`.
	#var buf = builder.to_packed_byte_array()
	#reconstruction( buf )


func long_way():
	var builder = FlatBufferBuilder.new()

	var string_offset : int # builder.create_table_array( table_array, constructor )

	var root_builder = fb.RootTableBuilder.new( builder )
	root_builder.add_table_array( string_offset )
	builder.finish( root_builder.finish() )

	## This must be called after `Finish()`.
	var buf = builder.to_packed_byte_array()
	reconstruction( buf )


func reconstruction( buffer : PackedByteArray ):
	var root_table := fb.GetRoot( buffer )
	#pp.print( root_table )

	retcode = FAILED


#region == Test Results ==
var retcode : int = OK
func TEST_EQ( value1, value2, msg : String = "" ):
	if value1 == value2: return
	retcode |= FAILED
	printerr( "%s | got '%s' wanted '%s'" % [msg, value1, value2 ] )
#endregion
