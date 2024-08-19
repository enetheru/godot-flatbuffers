@tool
extends EditorScript

const fb = preload('./FBTestTableArray_generated.gd')
var silent : bool = false


#region == Testing Setup ==

class RootTable:
	var table_array : Array
	var subtable : SubTable

class SubTable:
	var item : int

var root_table : RootTable
#endregion

func _run() -> void:
	root_table = RootTable.new()
	root_table.subtable = SubTable.new()
	root_table.subtable.item = 5
	root_table.table_array.resize( 13 )
	for i in root_table.table_array.size():
		var new_table := SubTable.new()
		new_table.item = i * 13
		root_table.table_array[i] = new_table

	short_way()
	long_way()
	if not silent:
		print_rich( "\n[b]== Table Array ==[/b]\n" )
		for o in output: print( o )


func short_way():
	var builder = FlatBufferBuilder.new()
	var offset = fb.CreateRootTable2( builder, root_table )
	builder.finish( offset )
#
	### This must be called after `Finish()`.
	var buf = builder.to_packed_byte_array()
	reconstruction( buf )


func long_way():
	var builder = FlatBufferBuilder.new()

	var offsets : PackedInt32Array
	offsets.resize( root_table.table_array.size() )
	for i in root_table.table_array.size():
		offsets[i] = fb.CreateSubTable( builder, root_table.table_array[i].item )

	var table_array_offset = builder.create_vector_offset( offsets )
	var subtable_offset = fb.CreateSubTable( builder, 5 )
#
	var root_builder = fb.RootTableBuilder.new( builder )
	root_builder.add_subtable( subtable_offset )
	root_builder.add_table_array( table_array_offset )
	builder.finish( root_builder.finish() )
#
	## This must be called after `Finish()`.
	var buf = builder.to_packed_byte_array()
	reconstruction( buf )


func reconstruction( buffer : PackedByteArray ):
	var rt := fb.GetRoot( buffer )
	output.append( "root_table: " + JSON.stringify( rt.debug(), '\t', false ) )

	TEST_EQ( rt.subtable().item(), root_table.subtable.item, "result == input")


#region == Test Results ==
var retcode : int = OK
var output : PackedStringArray = []
func TEST_EQ( value1, value2, msg : String = "" ):
	if value1 == value2: return
	retcode |= FAILED
	printerr( "%s | got '%s' wanted '%s'" % [msg, value1, value2 ] )
#endregion
