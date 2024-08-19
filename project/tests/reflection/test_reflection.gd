@tool
extends TestBase

const schema = preload('./Reflection_generated.gd')

func _run() -> void:
	var filename : String = "res://tests/reflection/Reflection.bfbs"
	var bfbs : PackedByteArray = FileAccess.get_file_as_bytes( filename )
	if bfbs.is_empty():
		print( error_string( FileAccess.get_open_error() ) )
		return

	var root_table = schema.GetRoot( bfbs )
	output.append( "root_table: " + JSON.stringify( root_table.debug(), '\t', false ) )
	if not silent:
		print_rich( "\n[b]== Scalar Arrays ==[/b]\n" )
		for o in output: print_rich( o )
