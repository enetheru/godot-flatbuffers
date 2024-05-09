#ifndef GODOT_FLATBUFFERS_EXTENSION_FLATBUFFERARRAY_H
#define GODOT_FLATBUFFERS_EXTENSION_FLATBUFFERARRAY_H

#include "flatbuffers/flatbuffers.h"

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/core/object.hpp>

namespace godot_flatbuffers {

class FlatBufferArray : public godot::Object {
	GDCLASS(FlatBufferArray, Object) // NOLINT(*-use-auto)

	int start {};
	godot::PackedByteArray bytes{};
	godot::Callable constructor;

public:
	FlatBufferArray() = default;
	FlatBufferArray( int start_, godot::PackedByteArray bytes_, godot::Callable constructor_ );

protected:
	static void _bind_methods();

public:
	// Get and Set of properties
	void set_start(int start_){ start = start_; }
	int get_start(){ return start; }

	void set_bytes(godot::PackedByteArray bytes_){ bytes = bytes_; }
	godot::PackedByteArray get_bytes(){ return bytes; }

	void set_constructor(godot::Callable constructor_){ constructor = constructor_; }
	godot::Callable get_constructor(){ return constructor; }

	// Accessor Methods
	int count();
	godot::Variant get( int idx );
};

}

#endif //GODOT_FLATBUFFERS_EXTENSION_FLATBUFFERARRAY_H
