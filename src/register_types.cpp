/* godot-cpp integration testing project.
 *
 * This is free and unencumbered software released into the public domain.
 */

#include "register_types.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>

#include "example.h"
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

	ClassDB::register_class<ExampleMin>();
	ClassDB::register_class<Example>();
	ClassDB::register_class<ExampleVirtual>(true);
	ClassDB::register_abstract_class<ExampleAbstractBase>();
	ClassDB::register_class<ExampleConcrete>();
	ClassDB::register_class<ExampleRef>();
}

void uninitialize_module(godot::ModuleInitializationLevel p_level) {
	if (p_level != godot::MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
}
