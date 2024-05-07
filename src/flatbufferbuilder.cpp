//
// Created by nicho on 7/05/2024.
//

#include "flatbufferbuilder.h"
#include <godot_cpp/core/class_db.hpp>

/*
 * Flatbuffer Builder wrapper for gdscript
 */
void FlatBufferBuilder::_bind_methods() {
	godot::ClassDB::bind_method(godot::D_METHOD("clear"), &FlatBufferBuilder::Clear);
	godot::ClassDB::bind_method(godot::D_METHOD("reset"), &FlatBufferBuilder::Reset);
	godot::ClassDB::bind_method(godot::D_METHOD("finished"), &FlatBufferBuilder::Finished);
	godot::ClassDB::bind_method(godot::D_METHOD("start_table"), &FlatBufferBuilder::StartTable);
	godot::ClassDB::bind_method(godot::D_METHOD("clear", "start"), &FlatBufferBuilder::EndTable);
}