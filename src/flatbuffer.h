#ifndef GODOT_FLATBUFFERS_EXTENSION_FLATBUFFER_H
#define GODOT_FLATBUFFERS_EXTENSION_FLATBUFFER_H

#include <godot_cpp/classes/object.hpp>

#include "flatbuffers/flatbuffers.h"

#include "flatbufferarray.h"

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
	FlatBufferArray *get_array( int start_, godot::Callable constructor_ );
	int get_array_count( int vtable_offset );
	int get_array_element_start( int array_start, int idx  );

	// Decode Functions
	godot::String decode_string( int start_ );
};

} //namespace godot_flatbuffers

#endif //GODOT_FLATBUFFERS_EXTENSION_FLATBUFFER_H
