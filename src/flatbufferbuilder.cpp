//
// Created by nicho on 7/05/2024.
//

#include "flatbufferbuilder.h"
#include <godot_cpp/core/class_db.hpp>

/*
 * Flatbuffer Builder wrapper for gdscript
 */
void FlatBufferBuilder::_bind_methods() {
	godot::ClassDB::bind_static_method("FlatBufferBuilder", godot::D_METHOD("create", "size"), &FlatBufferBuilder::Create);
	godot::ClassDB::bind_method(godot::D_METHOD("clear"), &FlatBufferBuilder::Clear);
	godot::ClassDB::bind_method(godot::D_METHOD("reset"), &FlatBufferBuilder::Reset);
	godot::ClassDB::bind_method(godot::D_METHOD("finished"), &FlatBufferBuilder::Finished);
	godot::ClassDB::bind_method(godot::D_METHOD("start_table"), &FlatBufferBuilder::StartTable);
	godot::ClassDB::bind_method(godot::D_METHOD("end_table", "start"), &FlatBufferBuilder::EndTable);

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
}