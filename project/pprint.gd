class_name PP

var dent : String = ""


func indent():
	dent += "\t"


func outdent():
	dent = dent.erase(0,1)


func rint( object, heading = "" ):
	if object is FlatBuffer:
		object.pprint( self, heading )
		return
	if not heading.is_empty():
		heading += ": "
	if object is FlatBuffer:
		printerr( indent, heading, "Unknown Flatbuffer Object" )
	else:
		print( dent, heading, object )
