class_name FlatBufferPrinter

var dent : String = ""


func indent():
	dent += "\t"


func outdent():
	dent = dent.erase(0,1)


func rint( object, heading = "" ):
	if object is FlatBufferArray:
		print_Array( object, heading )
		return

	if object is FlatBuffer:
		if object.has_method("pprint"):
			object.pprint( self, heading )
		else:
			printerr( indent, heading, "Unknown Flatbuffer Object" )
		return

	if not heading.is_empty():
		heading += ": "

	print( dent, heading, object )


func print_Array( array : FlatBufferArray, heading = "" ):
	if array.count() == 0:
		rint("Array[empty]", heading )
		return
	rint("Array{", heading )
	indent()
	rint( array.count(), "count" )
	rint( "constructor: %s" % array.constructor.get_method() )
	rint( "items [")
	indent()
	for idx in range( array.count() ):
		rint( array.get(idx) )
	outdent()
	rint( "]")
	outdent()
	rint("}")
