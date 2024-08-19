@tool
extends EditorScript

const INT8_MIN  = -128
const INT8_MAX = 127
const UINT8_MAX = 255 # (0xff)
const INT16_MIN = -32768
const INT16_MAX = 32767
const UINT16_MAX = 65535 #(0xffff)
const INT32_MIN = -2147483648
const INT32_MAX = 2147483647
const UINT32_MAX = 4294967295 #(0xffffffff)
const INT64_MIN = -2147483648
const INT64_MAX = 2147483647
const UINT64_MAX = 4294967295 #(0xffffffff)
const INT128_MIN = -9223372036854775808
#const INT128_MAX = 9223372036854775807
#const UINT128_MAX = 18446744073709551615 #(0xffffffffffffffff)

const FLT_EPSILON = 1.192092896e-07
const DBL_EPSILON = 2.2204460492503131e-016
#const FLT_MAX = 3.402823466e+38
const FLT_MAX = 3.402823466e+38
const DBL_MAX = 1.7976931348623158e+308
const FLT_MIN = 1.175494351e-38
const DBL_MIN = 2.2250738585072014e-308

const fb = preload('./FBTestScalarArrays_generated.gd')
var silent : bool = false

func _run() -> void:
	short_way()
	long_way()
	if not silent:
		print_rich( "\n[b]== Scalar Arrays ==[/b]\n" )
		for o in output: print( o )


func short_way():
	var builder = FlatBufferBuilder.new()

	var bytes_offset = builder.create_vector_int8( [INT8_MIN, INT8_MAX] )
	var ubytes_offset = builder.create_vector_uint8( [0, UINT8_MAX] )
	var shorts_offset = builder.create_vector_int16( [INT16_MIN, INT16_MAX] )
	var ushorts_offset = builder.create_vector_uint16( [0, UINT16_MAX] )
	var ints_offset = builder.create_vector_int32( [INT32_MIN, INT32_MAX] )
	var uints_offset = builder.create_vector_uint32( [0, UINT32_MAX] )
	var int64s_offset = builder.create_vector_int64( [INT64_MIN, INT64_MAX] )
	var uint64s_offset = builder.create_vector_uint64( [0, UINT64_MAX] )
	var floats_offset = builder.create_vector_float32( [FLT_MIN, FLT_MAX] )
	var doubles_offset = builder.create_vector_float64( [DBL_MIN, DBL_MAX] )

	var offset = fb.CreateRootTable(builder,
		bytes_offset, ubytes_offset,
		shorts_offset, ushorts_offset,
		ints_offset, uints_offset,
		int64s_offset, uint64s_offset,
		floats_offset, doubles_offset )
	builder.finish( offset )

	## This must be called after `Finish()`.
	var buf = builder.to_packed_byte_array()

	reconstruction( buf )


func long_way():
	var builder = FlatBufferBuilder.new()

	var bytes_offset = builder.create_vector_int8( [INT8_MIN, INT8_MAX] )
	var ubytes_offset = builder.create_vector_uint8( [0, UINT8_MAX] )
	var shorts_offset = builder.create_vector_int16( [INT16_MIN, INT16_MAX] )
	var ushorts_offset = builder.create_vector_uint16( [0, UINT16_MAX] )
	var ints_offset = builder.create_vector_int32( [INT32_MIN, INT32_MAX] )
	var uints_offset = builder.create_vector_uint32( [0, UINT32_MAX] )
	var int64s_offset = builder.create_vector_int64( [INT64_MIN, INT64_MAX] )
	var uint64s_offset = builder.create_vector_uint64( [0, UINT64_MAX] )
	var floats_offset = builder.create_vector_float32( [FLT_MIN, FLT_MAX] )
	var doubles_offset = builder.create_vector_float64( [DBL_MIN, DBL_MAX] )


	var root_builder = fb.RootTableBuilder.new( builder )
	root_builder.add_bytes_( bytes_offset )
	root_builder.add_ubytes( ubytes_offset )
	root_builder.add_shorts( shorts_offset )
	root_builder.add_ushorts( ushorts_offset )
	root_builder.add_ints( ints_offset )
	root_builder.add_uints( uints_offset )
	root_builder.add_int64s( int64s_offset )
	root_builder.add_uint64s( uint64s_offset )
	root_builder.add_floats( floats_offset )
	root_builder.add_doubles( doubles_offset )

	builder.finish( root_builder.finish() )

	## This must be called after `Finish()`.
	var buf = builder.to_packed_byte_array()

	reconstruction( buf )


func reconstruction( buffer : PackedByteArray ):
	var root_table := fb.GetRoot( buffer )
	output.append( "root_table: " + JSON.stringify( root_table.debug(), '\t', false ) )

	# bytes
	TEST_EQ( root_table.bytes__size(), 2, "bytes__size()")
	TEST_EQ( root_table.bytes__at(0), INT8_MIN, "bytes__at(0)")
	TEST_EQ( root_table.bytes__at(1), INT8_MAX, "bytes__at(1)")
	var bytes = root_table.bytes_()
	TEST_EQ( bytes.size(), 2, "bytes.size()" )
	TEST_EQ( bytes[0], INT8_MIN, "bytes[0]" )
	TEST_EQ( bytes[1], INT8_MAX, "bytes[1]" )

	# ubytes
	TEST_EQ( root_table.ubytes_size(), 2, "ubytes_size()" )
	TEST_EQ( root_table.ubytes_at(0), 0, "ubytes_at(0)" )
	TEST_EQ( root_table.ubytes_at(1), UINT8_MAX, "ubytes_at(1)" )
	var ubytes = root_table.ubytes()
	TEST_EQ( ubytes.size(), 2, "ubytes.size()" )
	TEST_EQ( ubytes[0], 0, "ubytes[0]" )
	TEST_EQ( ubytes[1], UINT8_MAX, "ubytes[1]" )

	# shorts
	TEST_EQ( root_table.shorts_size(), 2, "shorts_size()")
	TEST_EQ( root_table.shorts_at(0), INT16_MIN, "shorts_at(0)")
	TEST_EQ( root_table.shorts_at(1), INT16_MAX, "shorts_at(1)")
	var shorts = root_table.shorts()
	TEST_EQ( shorts.size(), 2, "shorts.size()" )
	TEST_EQ( shorts[0], INT16_MIN, "shorts[0]" )
	TEST_EQ( shorts[1], INT16_MAX, "shorts[1]" )

	# ushorts
	TEST_EQ( root_table.ushorts_size(), 2, "ushorts_size()" )
	TEST_EQ( root_table.ushorts_at(0), 0, "ushorts_at(0)" )
	TEST_EQ( root_table.ushorts_at(1), UINT16_MAX, "ushorts_at(1)" )
	var ushorts = root_table.ushorts()
	TEST_EQ( ushorts.size(), 2, "ushorts.size()" )
	TEST_EQ( ushorts[0], 0, "ushorts[0]" )
	TEST_EQ( ushorts[1], UINT16_MAX, "ushorts[1]" )

	# ints
	TEST_EQ( root_table.ints_size(), 2, "ints_size()")
	TEST_EQ( root_table.ints_at(0), INT32_MIN, "ints_at(0)")
	TEST_EQ( root_table.ints_at(1), INT32_MAX, "ints_at(1)")
	var ints = root_table.ints()
	TEST_EQ( ints.size(), 2, "ints.size()" )
	TEST_EQ( ints[0], INT32_MIN, "ints[0]" )
	TEST_EQ( ints[1], INT32_MAX, "ints[1]" )

	# uints
	TEST_EQ( root_table.uints_size(), 2, "uints_size()" )
	TEST_EQ( root_table.uints_at(0), 0, "uints_at(0)" )
	TEST_EQ( root_table.uints_at(1), UINT32_MAX, "uints_at(1)" )
	var uints = root_table.uints()
	TEST_EQ( uints.size(), 2, "uints.size()" )
	TEST_EQ( uints[0], 0, "uints[0]" )
	TEST_EQ( uints[1], UINT32_MAX, "uints[1]" )

	# int64s
	TEST_EQ( root_table.int64s_size(), 2, "int64s_size()")
	TEST_EQ( root_table.int64s_at(0), INT64_MIN, "int64s_at(0)")
	TEST_EQ( root_table.int64s_at(1), INT64_MAX, "int64s_at(1)")
	var int64s = root_table.int64s()
	TEST_EQ( int64s.size(), 2, "int64s.size()" )
	TEST_EQ( int64s[0], INT64_MIN, "int64s[0]" )
	TEST_EQ( int64s[1], INT64_MAX, "int64s[1]" )

	# uint64s
	TEST_EQ( root_table.uint64s_size(), 2, "uint64s_size()" )
	TEST_EQ( root_table.uint64s_at(0), 0, "uint64s_at(0)" )
	TEST_EQ( root_table.uint64s_at(1), UINT64_MAX, "uint64s_at(1)" )
	var uint64s = root_table.uint64s()
	TEST_EQ( uint64s.size(), 2, "uint64s.size()" )
	TEST_EQ( uint64s[0], 0, "uint64s[0]" )
	TEST_EQ( uint64s[1], UINT64_MAX, "uint64s[1]" )

	# floats
	TEST_EQ( root_table.floats_size(), 2, "floats_size()")
	TEST_EQ( root_table.floats_at(0), FLT_MIN, "floats_at(0)")
	TEST_EQ( root_table.floats_at(1), FLT_MAX, "floats_at(1)")
	var floats = root_table.floats()
	TEST_EQ( floats.size(), 2, "floats.size()" )
	TEST_EQ( floats[0], FLT_MIN, "floats[0]" )
	TEST_EQ( floats[1], FLT_MAX, "floats[1]" )

	# doubles
	TEST_EQ( root_table.doubles_size(), 2, "doubles_size()")
	TEST_EQ( root_table.doubles_at(0), DBL_MIN, "doubles_at(0)")
	TEST_EQ( root_table.doubles_at(1), DBL_MAX, "doubles_at(1)")
	var doubles = root_table.doubles()
	TEST_EQ( doubles.size(), 2, "doubles.size()" )
	TEST_EQ( doubles[0], DBL_MIN, "doubles[0]" )
	TEST_EQ( doubles[1], DBL_MAX, "doubles[1]" )


#region == Test Results ==
var retcode : int = OK
var output : PackedStringArray = []
func TEST_EQ( value1, value2, msg : String = "" ):
	if value1 == value2: return
	retcode |= FAILED
	output.append( "TEST_EQ: %s | got '%s' wanted '%s'" % [msg, value1, value2 ] )
#endregion
