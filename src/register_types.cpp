/* godot-cpp integration testing project.
 *
 * This is free and unencumbered software released into the public domain.
 */

#include "register_types.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>

#include "example.h"

void initialize_module(godot::ModuleInitializationLevel p_level) {
	if (p_level != godot::MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	godot::ClassDB::register_class<FlatBuffer>();
	ClassDB::register_class<ExampleMin>();
	ClassDB::register_class<Example>();
	ClassDB::register_class<ExampleVirtual>(true);
	// ClassDB::register_abstract_class<ExampleAbstractBase>();
	ClassDB::register_class<ExampleConcrete>();
}

void uninitialize_module(godot::ModuleInitializationLevel p_level) {
	if (p_level != godot::MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
}
