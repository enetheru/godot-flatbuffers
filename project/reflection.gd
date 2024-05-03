extends Node

enum BaseType {
	None,
	UType,
	Bool,
	Byte,
	UByte,
	Short,
	UShort,
	Int,
	UInt,
	Long,
	ULong,
	Float,
	Double,
	String,
	Vector,
	Obj,     # Used for tables & structs.
	Union,
	Array,
	# Add any new type above this value.
	MaxBaseType
}

# New schema language features that are not supported by old code generators.
enum AdvancedFeatures {
	AdvancedArrayFeatures,
	AdvancedUnionFeatures,
	OptionalScalars,
	DefaultVectorsAndStrings,
}

class GD_FlatBuffer:
	var bytes : PackedByteArray
	var start: int

	func get_subobj_position( element_idx ):
		# get vtable
		var vtable_pos : int = start - bytes.decode_s32(start)
		var vtable_size = bytes.decode_s16( vtable_pos )
		#var table_size = bytes.decode_s16( vtable_pos + 2 )
		assert(element_idx * 2 < vtable_size, "index is out of vtable range" )
		# decode subobj table offset
		var toffset : int = bytes.decode_s16(vtable_pos + 4 + (element_idx *2))
		return start + toffset + bytes.decode_u32(start + toffset)

	func get_string( pos : int ) -> String:
		return "'%s'" %bytes.slice(pos + 4, pos + 4 + bytes.decode_u32(pos) ).get_string_from_utf8()

class FB_Array:
	var bytes : PackedByteArray
	var start : int
	var size : int
	var interpreter : Callable

	static func GetArray( _start, _bytes, _interpreter ):
		var new_array = FB_Array.new()
		new_array.start = _start
		new_array.bytes = _bytes
		new_array.size = _bytes.decode_u32( _start )
		new_array.interpreter = _interpreter
		return new_array

	func get_idx( idx ) -> GD_FlatBuffer:
		# what do we need to do here? decode the offset for the object from the array, and then pass it tothe interpretor.
		var offset = bytes.decode_u32( start + 4 + (idx * 4) )
		var pos = start + 4 + (idx * 4) + offset
		return interpreter.call( pos, bytes )


class FB_Object extends GD_FlatBuffer:
	static func GetObject( _start : int, _bytes : PackedByteArray ) -> FB_Object:
		var new_object := FB_Object.new()
		new_object.start = _start
		new_object.bytes = _bytes
		return new_object

	#name:string (required, key);
	func name() -> String:
		return get_string( get_subobj_position(0))

	#fields:[Field] (required);  // Sorted.
	func fields_count() -> int:
		return bytes.decode_u32( get_subobj_position(1) )

	func fields() -> FB_Array:
		return FB_Array.GetArray(get_subobj_position(1), bytes, FB_Field.GetField )

	#is_struct:bool = false;
	func is_struct() -> bool:
		return bytes.decode_u8( get_subobj_position(2) )

	#minalign:int;
	func minalign() -> int:
		return bytes.decode_s32( get_subobj_position(3) )

	#bytesize:int;  // For structs.
	func bytesize() -> int:
		return bytes.decode_s32( get_subobj_position(4) )

	#attributes:[KeyValue];
	func attributes_size() -> int:
		return bytes.decode_u32( get_subobj_position(5) )

	func attributes() -> FB_Array:
		return FB_Array.GetArray(get_subobj_position(5), bytes, FB_KeyValue.GetKeyValue )

	#documentation:[string];
	func documentation() -> String:
		return get_string( get_subobj_position(6))

	#/// File that this Object is declared in.
	#declaration_file: string;
	func declaration_file() -> String:
		return get_string( get_subobj_position(7))

	func _to_string() -> String:
		var value : String = "Object {\n"
		#name:string (required, key);
		value += "\tname: %s\n" % name()
		#fields:[Field] (required);  // Sorted.
		#is_struct:bool = false;
		#minalign:int;
		#bytesize:int;  // For structs.
		#attributes:[KeyValue];
		#documentation:[string];
		#/// File that this Object is declared in.
		#declaration_file: string;
		value += "}"
		return value

class FB_Enum:
	pass

class FB_Service:
	pass

class FB_AdvancedFeatures:
	pass

class FB_SchemaFile:
	pass

class FB_Field extends  GD_FlatBuffer:
	static func GetField( _start, _bytes ):
		return null

class FB_KeyValue extends GD_FlatBuffer:
	static func GetKeyValue( _start, _bytes ):
		return null

class FB_Schema extends GD_FlatBuffer:
	# Convenience to get the schema as a root object
	static func GetSchema( _bytes : PackedByteArray )->FB_Schema:
		var schema := FB_Schema.new()
		schema.bytes = _bytes
		schema.start = _bytes.decode_u32(0)
		return schema

	func objects_count() -> int:
		return bytes.decode_u32(get_subobj_position( 0 ))

	func objects() -> FB_Array:
		return FB_Array.GetArray( get_subobj_position( 0 ), bytes, FB_Object.GetObject )

	func enums() -> Array[FB_Enum]:
		#var array_start = get_subobj_position( 1 )
		return []

	func file_ident() -> String:
		return get_string( get_subobj_position( 2 ) )

	func file_ext() -> String:
		return get_string( get_subobj_position( 3 ) )

	func root_table() -> FB_Object:
		return FB_Object.GetObject( get_subobj_position( 4 ), bytes )

	func services() -> Array[FB_Service]:
		#var vtable_pos = 5
		return []

	func advanced_features() -> FB_AdvancedFeatures:
		#var vtable_pos = 6
		return null

	func fbs_files() -> Array[FB_SchemaFile]:
		#var vtable_pos = 7
		return []

	func _to_string() -> String:
		var value : String = "Schema {\n"
		#objects:[Object] (required);    // Sorted.
		var object_array = objects()
		for idx in range( objects_count() ):
			value += object_array.get_idx(idx).to_string()

		#enums:[Enum] (required);        // Sorted.
		#file_ident:string;
		#file_ext:string;
		#root_table:Object;
		#services:[Service];             // Sorted.
		#advanced_features:AdvancedFeatures;
		#/// All the files used in this compilation. Files are relative to where
		#/// flatc was invoked.
		#fbs_files:[SchemaFile];         // Sorted.
		value += "}"
		return value

var depth = ""

# Because the vtable can be different for each object, ( not that it would be efficient ),
# we should keep track of the memory locations that the vtable is from, so we can avoid parsing it twice if it is references again.
var decoded_vtables : Dictionary = {} # position : vtable


func _ready() -> void:
	var filename : String = "res://smol.bfbs"
	var bfbs : PackedByteArray = FileAccess.get_file_as_bytes( filename )

	print( depth, filename, ", size: ", bfbs.size() )
	print( depth, "data: ", bfbs )

	var schema = FB_Schema.GetSchema(bfbs)
	print("Object Count: ", schema.objects_count() )
	var fb_array = schema.objects()
	var first : FB_Object = fb_array.get_idx(0) as FB_Object
	print( "name: ", first.name() )
	print( schema )


# Dumping thebfbs using flatcc's tool to convert it to json and pretty pring provides the below structure.
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
