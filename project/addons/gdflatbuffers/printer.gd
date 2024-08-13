class_name FlatBufferPrinter

var dent : String = ""


func indent():
	dent += "\t"


func outdent():
	dent = dent.erase(0,1)


func print( object, heading = "" ):
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
		self.print("Array[empty]", heading )
		return
	self.print("Array {", heading )
	indent()
	self.print( array.count(), "count" )
	self.print( "constructor: %s" % array.constructor.get_method() )
	self.print( "items [")
	indent()
	for idx in range( array.count() ):
		self.print( array.get(idx) )
	outdent()
	self.print( "]")
	outdent()
	self.print("}")
