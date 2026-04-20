/* godot-cpp integration testing project.
 *
 * This is free and unencumbered software released into the public domain.
 */

#include "register_types.hpp"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>

#include "flatbuffer.hpp"
#include "flatbufferbuilder.hpp"
#include "flatbufferverifier.hpp"

void initialize_module( const godot::ModuleInitializationLevel p_level ) {
  if( p_level != godot::MODULE_INITIALIZATION_LEVEL_SCENE ) {
    return;
  }

  using namespace godot_flatbuffers;
  godot::ClassDB::register_class< FlatBuffer >();
  godot::ClassDB::register_class< FlatBufferBuilder >();
  godot::ClassDB::register_class< FlatBufferVerifier >();
  godot::UtilityFunctions::print( "godot-flatbuffers initialised" );
}

void terminate_module( const godot::ModuleInitializationLevel p_level ) {
  if( p_level != godot::MODULE_INITIALIZATION_LEVEL_SCENE ) {
    return;
  }
  godot::UtilityFunctions::print( "godot-flatbuffers terminated" );
}
