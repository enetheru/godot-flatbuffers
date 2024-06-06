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
	// AABB
	// Array
	// Basis
	// bool
	// Callable
	// Color
	godot::Color decode_color( int64_t start_ );

	// Dictionary
	// NodePath
	// Object
	// PackedByteArray
	// PackedColorArray
	// PackedFloat32Array
	// PackedFloat64Array
	// PackedInt32Array
	// PackedInt64Array
	// PackedStringArray
	// PackedVector2Array
	// PackedVector3Array
	// Plane
	// Projection
	// Quaternion
	// Rect2
	// Rect2i
	// RID
	// Signal
	// String
	godot::String decode_string( int64_t start_ );
	// StringName
	// Transform2D
	// Transform3D
	// Vector2
	// Vector2i
	// Vector3
	godot::Vector3 decode_vector3( int64_t start_ );
	// Vector3i
	// Vector4
	// Vector4i

};

} //namespace godot_flatbuffers

#endif //GODOT_FLATBUFFERS_EXTENSION_FLATBUFFER_H
