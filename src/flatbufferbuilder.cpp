#include "flatbufferbuilder.h"
#include "builtin/godot_generated.h"
#include "utils.h"
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

	ClassDB::bind_method(D_METHOD("add_offset", "voffset", "value"), &FlatBufferBuilder::add_offset);

	ClassDB::bind_method(D_METHOD("add_element_bool", "voffset", "value"), &FlatBufferBuilder::add_scalar<bool, uint8_t>);
	ClassDB::bind_method(D_METHOD("add_element_byte", "voffset", "value"), &FlatBufferBuilder::add_scalar<int64_t, int8_t>);
	ClassDB::bind_method(D_METHOD("add_element_ubyte", "voffset", "value"), &FlatBufferBuilder::add_scalar<uint64_t, uint8_t>);
	ClassDB::bind_method(D_METHOD("add_element_short", "voffset", "value"), &FlatBufferBuilder::add_scalar<int64_t, int16_t>);
	ClassDB::bind_method(D_METHOD("add_element_ushort", "voffset", "value"), &FlatBufferBuilder::add_scalar<uint64_t, uint16_t>);
	ClassDB::bind_method(D_METHOD("add_element_int", "voffset", "value"), &FlatBufferBuilder::add_scalar<int64_t, int32_t>);
	ClassDB::bind_method(D_METHOD("add_element_uint", "voffset", "value"), &FlatBufferBuilder::add_scalar<uint64_t, uint32_t>);
	ClassDB::bind_method(D_METHOD("add_element_long", "voffset", "value"), &FlatBufferBuilder::add_scalar<int64_t, int64_t>);
	ClassDB::bind_method(D_METHOD("add_element_ulong", "voffset", "value"), &FlatBufferBuilder::add_scalar<uint64_t, uint64_t>);
	ClassDB::bind_method(D_METHOD("add_element_float", "voffset", "value"), &FlatBufferBuilder::add_scalar<double, float>);
	ClassDB::bind_method(D_METHOD("add_element_double", "voffset", "value"), &FlatBufferBuilder::add_scalar<double, double>);

	ClassDB::bind_method(D_METHOD("add_element_bool_default", "voffset", "value", "default"), &FlatBufferBuilder::add_scalar_default<bool, uint8_t>);
	ClassDB::bind_method(D_METHOD("add_element_byte_default", "voffset", "value", "default"), &FlatBufferBuilder::add_scalar_default<int64_t, int8_t>);
	ClassDB::bind_method(D_METHOD("add_element_ubyte_default", "voffset", "value", "default"), &FlatBufferBuilder::add_scalar_default<uint64_t, uint8_t>);
	ClassDB::bind_method(D_METHOD("add_element_short_default", "voffset", "value", "default"), &FlatBufferBuilder::add_scalar_default<int64_t, int16_t>);
	ClassDB::bind_method(D_METHOD("add_element_ushort_default", "voffset", "value", "default"), &FlatBufferBuilder::add_scalar_default<uint64_t, uint16_t>);
	ClassDB::bind_method(D_METHOD("add_element_int_default", "voffset", "value", "default"), &FlatBufferBuilder::add_scalar_default<int64_t, int32_t>);
	ClassDB::bind_method(D_METHOD("add_element_uint_default", "voffset", "value", "default"), &FlatBufferBuilder::add_scalar_default<uint64_t, uint32_t>);
	ClassDB::bind_method(D_METHOD("add_element_long_default", "voffset", "value", "default"), &FlatBufferBuilder::add_scalar_default<int64_t, int64_t>);
	ClassDB::bind_method(D_METHOD("add_element_ulong_default", "voffset", "value", "default"), &FlatBufferBuilder::add_scalar_default<uint64_t, uint64_t>);
	ClassDB::bind_method(D_METHOD("add_element_float_default", "voffset", "value", "default"), &FlatBufferBuilder::add_scalar_default<double, float>);
	ClassDB::bind_method(D_METHOD("add_element_double_default", "voffset", "value", "default"), &FlatBufferBuilder::add_scalar_default<double, double>);

	ClassDB::bind_method(D_METHOD("add_Vector3", "voffset", "value" ), &FlatBufferBuilder::add_Vector3 );
	ClassDB::bind_method(D_METHOD("add_Vector3i", "voffset", "value" ), &FlatBufferBuilder::add_Vector3i );

	ClassDB::bind_method(D_METHOD("start_table"), &FlatBufferBuilder::StartTable);
	ClassDB::bind_method(D_METHOD("end_table", "start"), &FlatBufferBuilder::EndTable);

	ClassDB::bind_method(D_METHOD("create_Color", "color"), &FlatBufferBuilder::CreateColor);
	ClassDB::bind_method(D_METHOD("create_String", "string"), &FlatBufferBuilder::CreateString);
	ClassDB::bind_method(D_METHOD("create_Vector3", "vector3"), &FlatBufferBuilder::CreateVector3);

	ClassDB::bind_method(D_METHOD("create_PackedByteArray", "array"), &FlatBufferBuilder::CreatePackedArray<uint8_t>);
	ClassDB::bind_method(D_METHOD("create_PackedInt32Array", "array"), &FlatBufferBuilder::CreatePackedArray<uint32_t>);
	ClassDB::bind_method(D_METHOD("create_PackedInt64Array", "array"), &FlatBufferBuilder::CreatePackedArray<uint64_t>);
	ClassDB::bind_method(D_METHOD("create_PackedFloat32Array", "array"), &FlatBufferBuilder::CreatePackedArray<float>);
	ClassDB::bind_method(D_METHOD("create_PackedFloat64Array", "array"), &FlatBufferBuilder::CreatePackedArray<double>);
	ClassDB::bind_method(D_METHOD("create_PackedStringArray", "array"), &FlatBufferBuilder::CreatePackedStringArray);

	ClassDB::bind_method(D_METHOD("create_Vector_int8", "array"), &FlatBufferBuilder::CreatePackedArray<int8_t>);
	ClassDB::bind_method(D_METHOD("create_Vector_uint8", "array"), &FlatBufferBuilder::CreatePackedArray<uint8_t>);
	ClassDB::bind_method(D_METHOD("create_Vector_int16", "array"), &FlatBufferBuilder::CreatePackedArray<int16_t>);
	ClassDB::bind_method(D_METHOD("create_Vector_uint16", "array"), &FlatBufferBuilder::CreatePackedArray<uint16_t>);
	ClassDB::bind_method(D_METHOD("create_Vector_int32", "array"), &FlatBufferBuilder::CreatePackedArray<int32_t>);
	ClassDB::bind_method(D_METHOD("create_Vector_uint32", "array"), &FlatBufferBuilder::CreatePackedArray<uint32_t>);
	ClassDB::bind_method(D_METHOD("create_Vector_int64", "array"), &FlatBufferBuilder::CreatePackedArray<int64_t>);
	ClassDB::bind_method(D_METHOD("create_Vector_uint64", "array"), &FlatBufferBuilder::CreatePackedArray<uint64_t>);

	ClassDB::bind_method(D_METHOD("create_Vector_float32", "array"), &FlatBufferBuilder::CreatePackedArray<float>);
	ClassDB::bind_method(D_METHOD("create_Vector_float64", "array"), &FlatBufferBuilder::CreatePackedArray<double>);

	ClassDB::bind_method(D_METHOD("finish", "root"), &FlatBufferBuilder::Finish);

	ClassDB::bind_method(D_METHOD("get_size"), &FlatBufferBuilder::GetSize);
	ClassDB::bind_method(D_METHOD("to_packed_byte_array"), &FlatBufferBuilder::GetPackedByteArray);
}

// TODO Use this 'flatbuffers::FlatBufferBuilder(size, allocator, ...)'
//  to add a custom allocator so that we can create directly into a PackedByteArray
//  This will make the need to copy the data after construction unnecessary
FlatBufferBuilder::FlatBufferBuilder() {
//	godot::UtilityFunctions::print("FlatBufferBuilder(): Constructor");
	builder = std::make_unique<flatbuffers::FlatBufferBuilder>();
}

FlatBufferBuilder::FlatBufferBuilder( int size ) {
//	godot::UtilityFunctions::print("FlatBufferBuilder(): Constructor");
	builder = std::make_unique<flatbuffers::FlatBufferBuilder>(size );
}

FlatBufferBuilder::~FlatBufferBuilder() {
//	godot::UtilityFunctions::print("~FlatBufferBuilder(): Destructor");
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

FlatBufferBuilder::uoffset_t FlatBufferBuilder::CreateColor( const godot::Color &value ) {
	//FIXME this creates a copy, dumb.
	Color col( value.r, value.g, value.b, value.a );
	return builder->CreateStruct( col ).o;
}

FlatBufferBuilder::uoffset_t FlatBufferBuilder::CreatePackedStringArray( const godot::PackedStringArray &value ) {
	std::vector<flatbuffers::Offset<>> offsets(value.size() );

	uint32_t index = 0;
	for( const auto &string : value ){
		offsets[index] = CreateString( string );
		index++;
	}
	uoffset_t offset = builder->CreateVector( offsets ).o;
	return offset;
}

FlatBufferBuilder::uoffset_t FlatBufferBuilder::CreateString( const godot::String &string ) {
	auto str = string.utf8(); //FIXME this creates a copy, dumb.
	auto offset = builder->CreateString( str.ptr(), str.size());
	return offset.o;
}

FlatBufferBuilder::uoffset_t FlatBufferBuilder::CreateVector3(const godot::Vector3 &value) {
	// FIXME This creates a copy
	Vector3 vec( value.x, value.y, value.z );
	return builder->CreateStruct( vec ).o;
}

void FlatBufferBuilder::add_offset( uint16_t voffset, uint64_t value ) {
	builder->AddOffset(voffset, Offset(value) );
}

void FlatBufferBuilder::add_Vector3( uint16_t voffset, godot::Vector3 vector3 ) {
	auto builtin = Vector3(vector3.x, vector3.y, vector3.z);
	builder->AddStruct( voffset, &builtin );
}

void FlatBufferBuilder::add_Vector3i( uint16_t voffset, godot::Vector3i vector3i ) {
	auto builtin = Vector3i(vector3i.x, vector3i.y, vector3i.z);

	// This appears to do nothing.
	builder->AddStruct( voffset, &builtin );
}

} //end namespace