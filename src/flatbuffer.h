#ifndef GODOT_FLATBUFFERS_EXTENSION_FLATBUFFER_H
#define GODOT_FLATBUFFERS_EXTENSION_FLATBUFFER_H

#include "flatbuffers/flatbuffers.h"

#include <godot_cpp/classes/object.hpp>

namespace godot_flatbuffers {

class FlatBuffer : public godot::Object {
	GDCLASS(FlatBuffer, Object) // NOLINT(*-use-auto)

	godot::PackedByteArray bytes;
	int start;

protected:
	static void _bind_methods();

public:
	// Get and Set of properties
	void set_bytes( godot::PackedByteArray bytes_ );
	godot::PackedByteArray get_bytes();
	void set_start( int start_);
	int get_start();

	// Field offset and position
	int get_field_offset( int vtable_offset );
	int get_field_start( int field_offset );

	// Array/Vector offset and position
	// FlatBuffer_Array get_array( int vtable_offset, Callable interpreter  );
	int get_array_count( int vtable_offset );
	int get_array_element_start( int array_start, int idx  );


	// Decode Functions
	// ? decode_utype( int start_, godot::PackedByteArray bytes_  = [] );
	bool decode_bool( int start_, godot::PackedByteArray bytes_  = {} );
	int decode_char( int start_, godot::PackedByteArray bytes_  = {} );
	int decode_uchar( int start_, godot::PackedByteArray bytes_  = {} );
	int decode_short( int start_, godot::PackedByteArray bytes_  = {} );
	int decode_ushort( int start_, godot::PackedByteArray bytes_  = {} );
	int decode_int( int start_, godot::PackedByteArray bytes_  = {} );
	int decode_uint( int start_, godot::PackedByteArray bytes_  = {} );
	int decode_long( int start_, godot::PackedByteArray bytes_  = {} );
	int decode_ulong( int start_, godot::PackedByteArray bytes_  = {} );
	float decode_float( int start_, godot::PackedByteArray bytes_  = {} );
	float decode_double( int start_, godot::PackedByteArray bytes_  = {} );
	godot::String decode_string( int start_, godot::PackedByteArray bytes_  = {} );
	// ? decode_vector( int start_, PackedByteArray bytes_  = [] );
	// ? decode_vector64( int start_, PackedByteArray bytes_  = [] );
	// ? decode_struct( int start_, PackedByteArray bytes_  = [] );
	// ? decode_union( int start_, PackedByteArray bytes_  = [] );
	// ? decode_array( int start_, PackedByteArray bytes_  = [] );
};

} //namespace godot_flatbuffers

#endif //GODOT_FLATBUFFERS_EXTENSION_FLATBUFFER_H
