/* godot-cpp integration testing project.
 *
 * This is free and unencumbered software released into the public domain.
 */

#ifndef EXAMPLE_REGISTER_TYPES_HPP
#define EXAMPLE_REGISTER_TYPES_HPP

#include <godot_cpp/core/class_db.hpp>

void initialize_module( godot::ModuleInitializationLevel p_level );

void terminate_module( godot::ModuleInitializationLevel p_level );

#endif // EXAMPLE_REGISTER_TYPES_HPP
