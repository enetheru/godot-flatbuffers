/* godot-cpp integration testing project.
 *
 * This is free and unencumbered software released into the public domain.
 */

#include "register_types.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>

#include "flatbuffer.h"
#include "flatbufferbuilder.h"

void initialize_module(godot::ModuleInitializationLevel p_level) {
	if (p_level != godot::MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	using namespace godot_flatbuffers;
	godot::ClassDB::register_class<FlatBuffer>();
	godot::ClassDB::register_class<FlatBufferBuilder>();
	godot::ClassDB::register_class<FlatBufferArray>();
}

void uninitialize_module(godot::ModuleInitializationLevel p_level) {
	if (p_level != godot::MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
}
