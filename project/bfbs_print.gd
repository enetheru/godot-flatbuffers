@tool
extends EditorScript

func _run() -> void:
	print("Test script is running")
	var filename : String = "res://binary_schema.bfbs"
	var bfbs : PackedByteArray = FileAccess.get_file_as_bytes( filename )

	print( filename, ", size: ", bfbs.size() )
	print( "data: ", bfbs )

	var schema := reflection.FB_Schema.GetSchema(bfbs.decode_u32(0), bfbs)

	pprint( schema )

# Dumping the bfbs using flatcc's tool to convert it to json and pretty print provides the below structure.
#{
	#"objects": [
		#{
			#"name": "Smol",
			#"fields": [
				#{
					#"name": "value",
					#"type": {
						#"base_type": "UByte"
					#},
					#"default_integer": 7
				#}
			#],
			#"minalign": 1
		#}
	#],
	#"enums": [],
	#"file_ident": "",
	#"file_ext": "",
	#"root_table": {
		#"name": "Smol",
		#"fields": [
			#{
				#"name": "value",
				#"type": {
					#"base_type": "UByte"
				#},
				#"default_integer": 7
			#}
		#],
		#"minalign": 1
	#},
	#"services": []
#}

var indent : String = ""
func pprint( object, heading = "" ):
	if object is FlatBufferArray:
		print_Array( object, heading )
		return
	if object is reflection.FB_Schema:
		print_Schema( object, heading )
		return
	if object is reflection.FB_Object:
		print_Object( object, heading )
		return
	if object is reflection.FB_SchemaFile:
		print_SchemaFile( object, heading )
		return
	if object is reflection.FB_Field:
		print_Field( object, heading )
		return
	if object is reflection.FB_Type:
		print_Type( object, heading )
		return
	if not heading.is_empty():
		heading += ": "
	print( indent, heading, object )

func Indent():
	indent += "\t"

func Outdent():
	indent = indent.erase(0,1)


func print_Type( type : reflection.FB_Type, heading = "" ):
	pprint("Type {", heading)
	Indent()
	#base_type:BaseType;
	if type.base_type_is_present():
		print_BaseType( type.base_type(), "base_type")
	#element:BaseType = None;  // Only if base_type == Vector
							  #// or base_type == Array.
	if type.element_is_present():
		print_BaseType( type.element(), "element")
	#index:int = -1;  // If base_type == Object, index into "objects" below.
					 #// If base_type == Union, UnionType, or integral derived
					 #// from an enum, index into "enums" below.
					 #// If base_type == Vector && element == Union or UnionType.
	if type.index_is_present():
		pprint( type.index(), "index")
	#fixed_length:uint16 = 0;  // Only if base_type == Array.
	if type.fixed_length_is_present():
		pprint( type.fixed_length(), "fixed_length")
	#/// The size (octets) of the `base_type` field.
	#base_size:uint = 4; // 4 Is a common size due to offsets being that size.
	if type.base_size_is_present():
		pprint( type.base_size(), "base_size")
	#/// The size (octets) of the `element` field, if present.
	#element_size:uint = 0;
	if type.element_size_is_present():
		pprint( type.element_size(), "element_size")
	Outdent()
	pprint("}")

func print_Field( field : reflection.FB_Field, heading = ""):
	pprint("Field {", heading )
	Indent()
	#name:string (required, key);
	pprint( field.name(), "name")
	#type:Type (required);
	pprint( field.type(), "type")
	#id:ushort;
	if field.id_is_present():
		pprint( field.id(), "id")
	#offset:ushort;  // Offset into the vtable for tables, or into the struct.
	if field.offset_is_present():
		pprint( field.offset(), "offset")
	#default_integer:long = 0;
	if field.default_integer_is_present():
		pprint( field.default_integer(), "default_integer")
	#default_real:double = 0.0;
	if field.default_real_is_present():
		pprint( field.default_real(), "default_real" )
	#deprecated:bool = false;
	if field.deprecated_is_present():
		pprint( field.deprecated(), "deprecated")
	#required:bool = false;
	if field.required_is_present():
		pprint( field.required(), "required")
	#key:bool = false;
	if field.key_is_present():
		pprint( field.key(), "key" )
	#attributes:[KeyValue];
	if field.attributes_is_present():
		pprint( field.attributes(), "attributes" )
	#documentation:[string];
	if field.documentation_is_present():
		pprint( field.documentation(), "documentation")
	#optional:bool = false;
	if field.optional_is_present():
		pprint( field.optional(), "optional")
	#/// Number of padding octets to always add after this field. Structs only.
	#padding:uint16 = 0;
	if field.padding_is_present():
		pprint( field.padding(), "padding")
	Outdent()
	pprint("}")

func print_SchemaFile( object : reflection.FB_SchemaFile, heading = "" ):
	pprint("SchemaFile {", heading)
	Indent()
	#/// Filename, relative to project root.
	#filename:string (required, key);
	pprint( object.filename(), "filename")
	#/// Names of included files, relative to project root.
	#included_filenames:[string];
	pprint( object.included_filenames(), "included_filenames" )

	Outdent()
	pprint("}")

func print_Object( object : reflection.FB_Object, heading = ""):
	pprint( "Object {", heading )
	Indent()
	#name:string (required, key);
	if object.name_is_present():
		pprint( object.name(), "name" )
	#fields:[Field] (required);  // Sorted.
	if object.fields_is_present():
		pprint( object.fields(), "fields" )
	#is_struct:bool = false;
	if object.is_struct_is_present():
		pprint( object.is_struct(), "is_struct" )
	#minalign:int;
	if object.minalign_is_present():
		pprint( object.minalign(), "minalign" )
	#bytesize:int;  // For structs.
	if object.bytesize_is_present():
		pprint( object.bytesize(), "bytesize" )
	#attributes:[KeyValue];
	if object.attributes_is_present():
		pprint( object.attributes(), "attributes" )
	#documentation:[string];
	if object.documentation_is_present():
		pprint( object.documentation(), "documentation" )
	#/// File that this Object is declared in.
	#declaration_file: string;
	if object.declaration_file_is_present():
		pprint( object.declaration_file(), "declaration_file" )
	Outdent()
	pprint("}")

func print_AdvancedFeatures( features : reflection.AdvancedFeatures, heading = "" ):
	pprint("AdvancedFeatures {", heading )
	Indent()
	var keys = reflection.AdvancedFeatures.keys()
	for key in keys:
		if reflection.AdvancedFeatures[key] & features:
			pprint(key)
	Outdent()
	pprint("}")

func print_BaseType( base_type : reflection.BaseType, heading = "" ):
	pprint( reflection.BaseType.keys()[base_type], heading )

func print_Array( array : FlatBufferArray, heading = "" ):
	if array.count() == 0:
		pprint("Array[empty]", heading )
		return
	pprint("Array{", heading )
	Indent()
	pprint( array.count(), "count" )
	pprint( "constructor: %s" % array.constructor.get_method() )
	pprint( "items [")
	Indent()
	for idx in range( array.count() ):
		pprint( array.get(idx) )
	Outdent()
	pprint( "]")
	Outdent()
	pprint("}")

func print_Schema( schema : reflection.FB_Schema, heading = "" ):
	pprint( "Schema {", heading )
	Indent()
	#objects:[Object] (required);    // Sorted.
	if schema.objects_is_present():
		pprint( schema.objects(), "objects" )
	##enums:[Enum] (required);        // Sorted.
	if schema.enums_is_present():
		pprint( schema.enums(), "enums" )
	##file_ident:string;
	if schema.file_ident_is_present():
		pprint( schema.file_ident(), "file_ident" )
	##file_ext:string;
	if schema.file_ext_is_present():
		pprint( schema.file_ext(), "file_ext" )
	##root_table:Object;
	if schema.root_table_is_present():
		pprint( schema.root_table(), "root_table" )
	##advanced_features:AdvancedFeatures;
	if schema.advanced_features_is_present():
		print_AdvancedFeatures( schema.advanced_features(), "advanced_features" )
	##/// All the files used in this compilation. Files are relative to where
	##/// flatc was invoked.
	##fbs_files:[SchemaFile];         // Sorted.
	if schema.fbs_files_is_present():
		pprint( schema.fbs_files(), "fbs_files" )
	Outdent()
	pprint("}")
