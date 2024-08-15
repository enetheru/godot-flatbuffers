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
const FLT_MAX = 3.402823466e+38
const DBL_MAX = 1.7976931348623158e+308
const FLT_MIN = 1.175494351e-38
const DBL_MIN = 2.2250738585072014e-308

const fb = preload('./FBTestScalarArrays_generated.gd')

var pp := FlatBufferPrinter.new()

var result = "Success"

func _run() -> void:
	print("== Test String ==")
	short_way()
	long_way()


func short_way():
	print("# Short Way")

	var builder = FlatBufferBuilder.new()
	var offset = fb.CreateRootTable(builder,
		[INT8_MIN, INT8_MAX],
		[0, UINT8_MAX],
		[INT16_MIN,
		INT16_MAX],
		[0, UINT16_MAX],
		[INT32_MIN, INT32_MAX],
		[0, UINT32_MAX],
		[INT64_MIN, INT64_MAX],
		[0, UINT64_MAX],
		[FLT_MIN, FLT_MAX],
		[DBL_MIN, DBL_MAX],
		)
	builder.finish( offset )

	## This must be called after `Finish()`.
	var buf = builder.to_packed_byte_array()
	print( " - size:%s\n - data: %s" % [ builder.get_size(), buf] )

	reconstruction( buf )


func long_way():
	print("# Long Way")
	var builder = FlatBufferBuilder.new()

	var bytes_offset = builder.create_Vector_int8( [INT8_MIN, INT8_MAX] )
	var ubytes_offset = builder.create_Vector_uint8( [0, UINT8_MAX] )
	var shorts_offset = builder.create_Vector_int16( [INT16_MIN, INT16_MAX] )
	var ushorts_offset = builder.create_Vector_uint16( [0, UINT16_MAX] )
	var ints_offset = builder.create_Vector_int32( [INT32_MIN, INT32_MAX] )
	var uints_offset = builder.create_Vector_uint32( [0, UINT32_MAX] )
	var int64s_offset = builder.create_Vector_int64( [INT64_MIN, INT64_MAX] )
	var uint64s_offset = builder.create_Vector_uint64( [0, UINT64_MAX] )
	var floats_offset = builder.create_Vector_float32( [FLT_MIN, FLT_MAX] )
	var doubles_offset = builder.create_Vector_float64( [DBL_MIN, DBL_MAX] )


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
	print("# Final Buffer")
	var buf = builder.to_packed_byte_array()
	print( " - size:%s\n - data: %s" % [ builder.get_size(), buf] )

	reconstruction( buf )


func reconstruction( buffer : PackedByteArray ):
	print("# Reconstruction")
	var root_table := fb.GetRoot( buffer )
	pp.print( root_table )
