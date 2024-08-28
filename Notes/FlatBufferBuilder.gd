class_name FlatBufferBuilder

func start_table() -> int:
	return 0

func end_table( offset : int ) -> int:
	return 0


func add_offset( voffset : int, value : int ) -> void:
	pass


func add_element_ulong_default( voffset : int, value : int, default : int = 0 ) -> void:
	pass


func add_Vector3( voffset : int, value : Vector3 ) -> void:
	pass



func create_String( string : String ) -> int:
	return 0

func create_vector_uint8( value : Variant ) -> int:
	return 0
