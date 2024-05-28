@tool
extends EditorScript

var pp := FlatBufferPrinter.new()

func _run() -> void:
	print("Test script is running")
	var filename : String = "res://fbs_files/Reflection.bfbs"
	var bfbs : PackedByteArray = FileAccess.get_file_as_bytes( filename )

	print( filename, ", size: ", bfbs.size() )
	print( "data: ", bfbs )

	var root_start = bfbs.decode_u32(0)
	print( "root_start: ", root_start)
	var schema := Reflection.GetSchema( root_start, bfbs )

	pp.rint( schema )

