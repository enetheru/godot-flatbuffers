@tool
extends EditorScript

func _run() -> void:
	print("Test script is running")
	var filename : String = "res://smol.bfbs"
	var bfbs : PackedByteArray = FileAccess.get_file_as_bytes( filename )

	print( filename, ", size: ", bfbs.size() )
	print( "data: ", bfbs )

	var builder = FlatBufferBuilder.new()
	builder.add_int(1,1)
