#ifndef GODOT_FLATBUFFERS_EXTENSION_FLATBUFFER_H
#define GODOT_FLATBUFFERS_EXTENSION_FLATBUFFER_H

#include <godot_cpp/classes/ref_counted.hpp>

#include "flatbuffers/flatbuffers.h"

#include "flatbufferarray.h"

namespace godot_flatbuffers {

class FlatBuffer : public godot::RefCounted {
	GDCLASS(FlatBuffer, RefCounted) // NOLINT(*-use-auto)

	godot::PackedByteArray bytes;
	int64_t start{};

protected:
	static void _bind_methods();

public:
	explicit FlatBuffer();
	~FlatBuffer() override;

	// Get and Set of properties
	void set_bytes( godot::PackedByteArray bytes_ );
	godot::PackedByteArray get_bytes();
	void set_start( int64_t start_);
	[[nodiscard]] int64_t get_start() const;

	// Field offset and position
	int64_t get_field_offset( int64_t vtable_offset );
	int64_t get_field_start( int64_t field_offset );

	// Array/Vector offset and position
	FlatBufferArray *get_array( int64_t start_, godot::Callable constructor_ );
	int64_t get_array_count( int64_t vtable_offset );
	int64_t get_array_element_start( int64_t array_start, int64_t idx  );

	// Decode Functions
	godot::String decode_string( int64_t start_ );
};

} //namespace godot_flatbuffers

#endif //GODOT_FLATBUFFERS_EXTENSION_FLATBUFFER_H
