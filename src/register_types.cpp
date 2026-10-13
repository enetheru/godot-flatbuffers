/* godot-cpp integration testing project.
 *
 * This is free and unencumbered software released into the public domain.
 */

#include "register_types.hpp"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/variant/variant.hpp>

#include "flatbuffer.hpp"
#include "flatbufferbuilder.hpp"
#include "flatbufferverifier.hpp"

#ifndef FLATBUFFERS_BUILD_TARGET
#define FLATBUFFERS_BUILD_TARGET unknown
#endif
#ifndef FLATBUFFERS_BUILD_CONFIG
#define FLATBUFFERS_BUILD_CONFIG unknown
#endif

#define GODOT_FB_STRINGIFY( x ) #x
#define GODOT_FB_TOSTRING( x ) GODOT_FB_STRINGIFY( x )

void initialize_module( const godot::ModuleInitializationLevel p_level ) {
  if( p_level != godot::MODULE_INITIALIZATION_LEVEL_SCENE ) {
    return;
  }

  using namespace godot_flatbuffers; // NOLINT(*-build-using-namespace)
  godot::ClassDB::register_class< FlatBuffer >();
  godot::ClassDB::register_class< FlatBufferBuilder >();
  godot::ClassDB::register_class< FlatBufferVerifier >();

  godot::String library_path;
  if( godot::internal::gdextension_interface_get_library_path != nullptr
      && godot::internal::library != nullptr ) {
    godot::internal::gdextension_interface_get_library_path(
        godot::internal::library, library_path._native_ptr() );
  }
  godot::UtilityFunctions::print( godot::vformat(
      "godot-flatbuffers initialised target=%s config=%s built=%s %s path=%s",
      godot::String( GODOT_FB_TOSTRING( FLATBUFFERS_BUILD_TARGET ) ),
      godot::String( GODOT_FB_TOSTRING( FLATBUFFERS_BUILD_CONFIG ) ),
      godot::String( __DATE__ ),
      godot::String( __TIME__ ),
      library_path ) );
}

void terminate_module( const godot::ModuleInitializationLevel p_level ) {
  if( p_level != godot::MODULE_INITIALIZATION_LEVEL_SCENE ) {
    return;
  }
  godot::UtilityFunctions::print( "godot-flatbuffers terminated" );
}
