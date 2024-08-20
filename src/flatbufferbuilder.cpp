#include "flatbufferbuilder.hpp"
#include "builtin/godot_generated.h"
#include "utils.hpp"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

/*
 * Flatbuffer Builder wrapper for gdscript
 */
namespace godot_flatbuffers {

void FlatBufferBuilder::_bind_methods() {
	using namespace godot;

	ClassDB::bind_static_method("FlatBufferBuilder", D_METHOD("create", "size"), &FlatBufferBuilder::Create);

	ClassDB::bind_method(D_METHOD("clear"), &FlatBufferBuilder::Clear);
	ClassDB::bind_method(D_METHOD("reset"), &FlatBufferBuilder::Reset);
	ClassDB::bind_method(D_METHOD("finish", "table_offset"), &FlatBufferBuilder::Finish);
	ClassDB::bind_method(D_METHOD("start_table"), &FlatBufferBuilder::StartTable);
	ClassDB::bind_method(D_METHOD("end_table", "start"), &FlatBufferBuilder::EndTable);
	ClassDB::bind_method(D_METHOD("get_size"), &FlatBufferBuilder::GetSize);
	ClassDB::bind_method(D_METHOD("to_packed_byte_array"), &FlatBufferBuilder::GetPackedByteArray);

	// == Add functions ==
	ClassDB::bind_method(D_METHOD("add_offset", "voffset", "value"), &FlatBufferBuilder::AddOffset);
  ClassDB::bind_method(D_METHOD("add_bytes", "voffset", "value"), &FlatBufferBuilder::AddBytes);

	ClassDB::bind_method(D_METHOD("add_element_bool", "voffset", "value"), &FlatBufferBuilder::AddScalar<bool, uint8_t>);
	ClassDB::bind_method(D_METHOD("add_element_byte", "voffset", "value"), &FlatBufferBuilder::AddScalar<int64_t, int8_t>);
	ClassDB::bind_method(D_METHOD("add_element_ubyte", "voffset", "value"), &FlatBufferBuilder::AddScalar<uint64_t, uint8_t>);
	ClassDB::bind_method(D_METHOD("add_element_short", "voffset", "value"), &FlatBufferBuilder::AddScalar<int64_t, int16_t>);
	ClassDB::bind_method(D_METHOD("add_element_ushort", "voffset", "value"), &FlatBufferBuilder::AddScalar<uint64_t, uint16_t>);
	ClassDB::bind_method(D_METHOD("add_element_int", "voffset", "value"), &FlatBufferBuilder::AddScalar<int64_t, int32_t>);
	ClassDB::bind_method(D_METHOD("add_element_uint", "voffset", "value"), &FlatBufferBuilder::AddScalar<uint64_t, uint32_t>);
	ClassDB::bind_method(D_METHOD("add_element_long", "voffset", "value"), &FlatBufferBuilder::AddScalar<int64_t, int64_t>);
	ClassDB::bind_method(D_METHOD("add_element_ulong", "voffset", "value"), &FlatBufferBuilder::AddScalar<uint64_t, uint64_t>);
	ClassDB::bind_method(D_METHOD("add_element_float", "voffset", "value"), &FlatBufferBuilder::AddScalar<double, float>);
	ClassDB::bind_method(D_METHOD("add_element_double", "voffset", "value"), &FlatBufferBuilder::AddScalar<double, double>);

	ClassDB::bind_method(D_METHOD("add_element_bool_default", "voffset", "value", "default"), &FlatBufferBuilder::AddScalarDefault<bool, uint8_t>);
	ClassDB::bind_method(D_METHOD("add_element_byte_default", "voffset", "value", "default"), &FlatBufferBuilder::AddScalarDefault<int64_t, int8_t>);
	ClassDB::bind_method(D_METHOD("add_element_ubyte_default", "voffset", "value", "default"), &FlatBufferBuilder::AddScalarDefault<uint64_t, uint8_t>);
	ClassDB::bind_method(D_METHOD("add_element_short_default", "voffset", "value", "default"), &FlatBufferBuilder::AddScalarDefault<int64_t, int16_t>);
	ClassDB::bind_method(D_METHOD("add_element_ushort_default", "voffset", "value", "default"), &FlatBufferBuilder::AddScalarDefault<uint64_t, uint16_t>);
	ClassDB::bind_method(D_METHOD("add_element_int_default", "voffset", "value", "default"), &FlatBufferBuilder::AddScalarDefault<int64_t, int32_t>);
	ClassDB::bind_method(D_METHOD("add_element_uint_default", "voffset", "value", "default"), &FlatBufferBuilder::AddScalarDefault<uint64_t, uint32_t>);
	ClassDB::bind_method(D_METHOD("add_element_long_default", "voffset", "value", "default"), &FlatBufferBuilder::AddScalarDefault<int64_t, int64_t>);
	ClassDB::bind_method(D_METHOD("add_element_ulong_default", "voffset", "value", "default"), &FlatBufferBuilder::AddScalarDefault<uint64_t, uint64_t>);
	ClassDB::bind_method(D_METHOD("add_element_float_default", "voffset", "value", "default"), &FlatBufferBuilder::AddScalarDefault<double, float>);
	ClassDB::bind_method(D_METHOD("add_element_double_default", "voffset", "value", "default"), &FlatBufferBuilder::AddScalarDefault<double, double>);

	// == Create Functions ==
	ClassDB::bind_method(D_METHOD("create_vector_offset", "array"), &FlatBufferBuilder::CreateVectorOffset);
	ClassDB::bind_method(D_METHOD("create_vector_table", "array", "constructor"), &FlatBufferBuilder::CreateVectorTable);

	ClassDB::bind_method(D_METHOD("create_vector_int8", "array"), &FlatBufferBuilder::CreatePackedArray<int8_t>);
	ClassDB::bind_method(D_METHOD("create_vector_uint8", "array"), &FlatBufferBuilder::CreatePackedArray<uint8_t>);
	ClassDB::bind_method(D_METHOD("create_vector_int16", "array"), &FlatBufferBuilder::CreatePackedArray<int16_t>);
	ClassDB::bind_method(D_METHOD("create_vector_uint16", "array"), &FlatBufferBuilder::CreatePackedArray<uint16_t>);
	ClassDB::bind_method(D_METHOD("create_vector_int32", "array"), &FlatBufferBuilder::CreatePackedArray<int32_t>);
	ClassDB::bind_method(D_METHOD("create_vector_uint32", "array"), &FlatBufferBuilder::CreatePackedArray<uint32_t>);
	ClassDB::bind_method(D_METHOD("create_vector_int64", "array"), &FlatBufferBuilder::CreatePackedArray<int64_t>);
	ClassDB::bind_method(D_METHOD("create_vector_uint64", "array"), &FlatBufferBuilder::CreatePackedArray<uint64_t>);
	ClassDB::bind_method(D_METHOD("create_vector_float32", "array"), &FlatBufferBuilder::CreatePackedArray<float>);
	ClassDB::bind_method(D_METHOD("create_vector_float64", "array"), &FlatBufferBuilder::CreatePackedArray<double>);

	// Create methods for Builtin Classes
  ClassDB::bind_method(D_METHOD("add_Color", "color"), &FlatBufferBuilder::AddGodotStruct<godot::Color>);
  ClassDB::bind_method(D_METHOD("create_Color", "color"), &FlatBufferBuilder::CreateGodotStruct<godot::Color>);

	ClassDB::bind_method(D_METHOD("create_PackedStringArray", "array"), &FlatBufferBuilder::CreatePackedStringArray);
	ClassDB::bind_method(D_METHOD("create_String", "string"), &FlatBufferBuilder::CreateString);

  ClassDB::bind_method(D_METHOD("add_Vector3", "voffset", "vector3" ), &FlatBufferBuilder::AddGodotStruct<godot::Vector3>);
	ClassDB::bind_method(D_METHOD("create_Vector3", "vector3"), &FlatBufferBuilder::CreateGodotStruct<godot::Vector3>);

  ClassDB::bind_method(D_METHOD("add_Vector3i", "voffset", "vector3i" ), &FlatBufferBuilder::AddGodotStruct<godot::Vector3i>);
	ClassDB::bind_method(D_METHOD("create_Vector3i", "vector3i"), &FlatBufferBuilder::CreateGodotStruct<godot::Vector3i>);


	ClassDB::bind_method(D_METHOD("create_PackedByteArray", "array"), &FlatBufferBuilder::CreatePackedArray<uint8_t>);
	ClassDB::bind_method(D_METHOD("create_PackedInt32Array", "array"), &FlatBufferBuilder::CreatePackedArray<uint32_t>);
	ClassDB::bind_method(D_METHOD("create_PackedInt64Array", "array"), &FlatBufferBuilder::CreatePackedArray<uint64_t>);
	ClassDB::bind_method(D_METHOD("create_PackedFloat32Array", "array"), &FlatBufferBuilder::CreatePackedArray<float>);
	ClassDB::bind_method(D_METHOD("create_PackedFloat64Array", "array"), &FlatBufferBuilder::CreatePackedArray<double>);
}

FlatBufferBuilder::FlatBufferBuilder() {
	builder = std::make_unique<flatbuffers::FlatBufferBuilder>();
}

FlatBufferBuilder::FlatBufferBuilder( int size ) {
	builder = std::make_unique<flatbuffers::FlatBufferBuilder>(size );
}

void FlatBufferBuilder::Finish(uint32_t root) {
	Offset offset = root;
	builder->Finish(offset, nullptr);
}

godot::PackedByteArray FlatBufferBuilder::GetPackedByteArray() {
	int64_t size = builder->GetSize();
	auto bytes = godot::PackedByteArray();
	bytes.resize(size);
	std::memcpy(bytes.ptrw(), builder->GetBufferPointer(), size);
	return bytes;
}

// == Add Functions ==
void FlatBufferBuilder::AddOffset( uint16_t voffset, uint64_t value ) {
	builder->AddOffset(voffset, Offset(value) );
}


void FlatBufferBuilder::AddBytes( uint16_t voffset, const godot::PackedByteArray& bytes ) {
  if( bytes.is_empty() ) return;  // Default, don't store.
  builder->Align(bytes.size() );
  builder->PushBytes( bytes.ptr(), bytes.size());
  builder->TrackField(voffset, builder->GetSize() );
}

// == Create Functions
FlatBufferBuilder::uoffset_t FlatBufferBuilder::CreateVectorOffset( const godot::PackedInt32Array &array ) {
	builder->StartVector< Offset >( array.size() );
	for( auto i= array.size(); i > 0; ) {
		builder->PushElement( static_cast< Offset > ( array[--i] ) );
	}
	return builder->EndVector( array.size() );
}

FlatBufferBuilder::uoffset_t FlatBufferBuilder::CreateVectorTable(const godot::Array &array, const godot::Callable& constructor) {
	builder->StartVector< Offset >( array.size() );
	for( auto i= array.size(); i > 0; ) {
		uoffset_t offset = constructor.call( array[--i] );
		enetheru::print("c++: constructor.call = {0}", offset );
		builder->PushElement( static_cast< Offset > ( offset ) );
	}
	return builder->EndVector( array.size() );
}

FlatBufferBuilder::uoffset_t FlatBufferBuilder::CreatePackedStringArray( const godot::PackedStringArray &value ) {
	std::vector<Offset> offsets(value.size() );
  for( int i = 0; i < value.size(); ++i ){
    offsets[i] = CreateString( value[i] );
  }
	uoffset_t offset = builder->CreateVector( offsets ).o;
	return offset;
}

FlatBufferBuilder::uoffset_t FlatBufferBuilder::CreateString( const godot::String &string ) {
  auto str = string.utf8();
	return builder->CreateString( str.ptr(), str.size()).o;
}

} //end namespace