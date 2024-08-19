@tool
extends TestBase

const schema = preload('./includes_generated.gd')

#region == Testing Setup ==
# testing variables

var test_object
#endregion

func _run() -> void:
	# Setup Persistent data
	# ...

	# Generate the flatbuffer using the three methods of creations
	reconstruct( manual() )
	#reconstruct( create() )
	#reconstruct( create2() )
	if not silent:
		print_rich( "\n[b]== Monster ==[/b]\n" )
		for o in output: print( o )

func manual() -> PackedByteArray:
	# create new builder
	var builder = FlatBufferBuilder.new()

	# create all the composite objects here
	# var offset : int = schema.Create<Type>( builder, element, ... )
	# ...

	# Start the root object builder
	var root_builder = schema.RootTableBuilder.new( builder )

	# Add all the root object items
	# root_builder.add_<field_name>( inline object )
	# root_builder.add_<field_name>( offset )
	# ...

	# Finish the root builder
	var root_offset = root_builder.finish()

	# Finalise the builder
	builder.finish( root_offset )

	# export data
	return builder.to_packed_byte_array()


func create():
	# create new builder
	var builder = FlatBufferBuilder.new()

	# create all the composite objects here
	# var offset : int = schema.Create<Type>( builder, element, ... )
	# ...

	#var offset : int = schema.CreateRootTable( builder, element, ... )
	var offset : int

	# finalise flatbuffer builder
	builder.finish( offset )

	# export data
	return builder.to_packed_byte_array()


func create2():
	# create new builder
	var builder = FlatBufferBuilder.new()

	# This call generates the root table using test_object properties
	#var offset = schema.CreateRootTable2( builder, test_object )
	var offset : int

	# Finalise flatbuffer builder
	builder.finish( offset )

	# export data
	return builder.to_packed_byte_array()


func reconstruct( buffer : PackedByteArray ):
	var root_table : FlatBuffer = schema.GetRoot( buffer )
	output.append( "root_table: " + JSON.stringify( root_table.debug(), '\t', false ) )

	# Perform testing on the reconstructed flatbuffer.
	#TEST_EQ( <value>, <value>, "Test description if failed")
