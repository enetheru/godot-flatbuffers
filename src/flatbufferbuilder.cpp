//
// Created by nicho on 7/05/2024.
//

#include "flatbufferbuilder.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

/*
 * Flatbuffer Builder wrapper for gdscript
 */
void godot_flatbuffers::FlatBufferBuilder::_bind_methods() {
	godot::ClassDB::bind_static_method("FlatBufferBuilder", godot::D_METHOD("create", "size"), &FlatBufferBuilder::Create);
	godot::ClassDB::bind_method(godot::D_METHOD("clear"), &FlatBufferBuilder::Clear);
	godot::ClassDB::bind_method(godot::D_METHOD("reset"), &FlatBufferBuilder::Reset);

	godot::ClassDB::bind_method(godot::D_METHOD("add_element_bool", "voffset", "value"), &FlatBufferBuilder::add_scalar<bool, uint8_t >);
	godot::ClassDB::bind_method(godot::D_METHOD("add_element_byte", "voffset", "value"), &FlatBufferBuilder::add_scalar<int64_t, int8_t >);
	godot::ClassDB::bind_method(godot::D_METHOD("add_element_ubyte", "voffset", "value"), &FlatBufferBuilder::add_scalar<uint64_t, uint8_t >);
	godot::ClassDB::bind_method(godot::D_METHOD("add_element_short", "voffset", "value"), &FlatBufferBuilder::add_scalar<int64_t, int16_t >);
	godot::ClassDB::bind_method(godot::D_METHOD("add_element_ushort", "voffset", "value"), &FlatBufferBuilder::add_scalar<uint64_t, uint16_t >);
	godot::ClassDB::bind_method(godot::D_METHOD("add_element_int", "voffset", "value"), &FlatBufferBuilder::add_scalar<int64_t, int32_t >);
	godot::ClassDB::bind_method(godot::D_METHOD("add_element_uint", "voffset", "value"), &FlatBufferBuilder::add_scalar<uint64_t, uint32_t >);
	godot::ClassDB::bind_method(godot::D_METHOD("add_element_long", "voffset", "value"), &FlatBufferBuilder::add_scalar<int64_t, int64_t >);
	godot::ClassDB::bind_method(godot::D_METHOD("add_element_ulong", "voffset", "value"), &FlatBufferBuilder::add_scalar<uint64_t, uint64_t >);
	godot::ClassDB::bind_method(godot::D_METHOD("add_element_float", "voffset", "value"), &FlatBufferBuilder::add_scalar<double, float >);
	godot::ClassDB::bind_method(godot::D_METHOD("add_element_double", "voffset", "value"), &FlatBufferBuilder::add_scalar<double, double >);

	godot::ClassDB::bind_method(godot::D_METHOD("start_table"), &FlatBufferBuilder::StartTable);
	godot::ClassDB::bind_method(godot::D_METHOD("end_table", "start"), &FlatBufferBuilder::EndTable);

	godot::ClassDB::bind_method(godot::D_METHOD("create_string", "string"), &FlatBufferBuilder::CreateString);

	godot::ClassDB::bind_method(godot::D_METHOD("finish", "root"), &FlatBufferBuilder::Finish);

	godot::ClassDB::bind_method(godot::D_METHOD("get_size"), &FlatBufferBuilder::GetSize);
	godot::ClassDB::bind_method(godot::D_METHOD("to_packed_byte_array"), &FlatBufferBuilder::GetPackedByteArray );
}


godot_flatbuffers::FlatBufferBuilder::FlatBufferBuilder() {
	godot::UtilityFunctions::print("FlatBufferBuilder(): Constructor");
}


godot_flatbuffers::FlatBufferBuilder::~FlatBufferBuilder() {
	godot::UtilityFunctions::print("~FlatBufferBuilder(): Destructor");
}


void godot_flatbuffers::FlatBufferBuilder::Finish(uint32_t root){
	Offset offset = root;
	builder-> Finish( offset, nullptr );
}


godot::PackedByteArray godot_flatbuffers::FlatBufferBuilder::GetPackedByteArray() {
	int64_t size = builder->GetSize();
	auto bytes = godot::PackedByteArray();
	bytes.resize( size );
	std::memcpy( bytes.ptrw(), builder->GetBufferPointer(), size );
	return bytes;
}

godot_flatbuffers::FlatBufferBuilder::uoffset_t godot_flatbuffers::FlatBufferBuilder::CreateString(const godot::String& string) {
	//FIXME this creates a copy, dumb.
	auto str = string.utf8();
	return builder->CreateString( str.ptr(), str.size()  ).o;
}
