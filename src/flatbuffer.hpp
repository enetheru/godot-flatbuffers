#ifndef GODOT_FLATBUFFERS_EXTENSION_FLATBUFFER_HPP
#define GODOT_FLATBUFFERS_EXTENSION_FLATBUFFER_HPP

#include <godot_cpp/classes/ref_counted.hpp>

#include "flatbuffers/flatbuffers.h"

namespace godot_flatbuffers {

class FlatBuffer : public godot::RefCounted {
	GDCLASS(FlatBuffer, RefCounted) // NOLINT(*-use-auto)

  godot::PackedByteArray bytes; // I need to make this a reference somehow
	int64_t start{};

protected:
	static void _bind_methods();

public:
  //Debug
  godot::String get_memory_address();

	// Get and Set of properties
	void set_bytes( godot::PackedByteArray bytes_ );
	const godot::PackedByteArray & get_bytes();

	void set_start( int64_t start_);
	[[nodiscard]] int64_t get_start() const;

	// Field offset and position
	int64_t get_field_offset( int64_t vtable_offset );
	int64_t get_field_start( int64_t vtable_offset );

	// Array/Vector offset and position
	int64_t get_array_size( int64_t vtable_offset );
	int64_t get_array_element_start( int64_t array_start, int64_t idx  );

	// Decode Functions
	// AABB
	// Array
	// Basis
	// bool
	// Callable
	godot::Color decode_Color( int64_t start_ );
	// Dictionary
	// NodePath
	// Object
	godot::PackedByteArray decode_PackedByteArray( int64_t start_ );
	// PackedColorArray
	godot::PackedFloat32Array decode_PackedFloat32Array( int64_t start_ );
	godot::PackedFloat64Array decode_PackedFloat64Array( int64_t start_ );
	godot::PackedInt32Array decode_PackedInt32Array( int64_t start_ );
	godot::PackedInt64Array decode_PackedInt64Array( int64_t start_ );
	godot::PackedStringArray decode_PackedStringArray( int64_t start_ );
	// PackedVector2Array
	// PackedVector3Array
	// Plane
	// Projection
	// Quaternion
	// Rect2
	// Rect2i
	// RID
	// Signal
	godot::String decode_String( int64_t start_ );
	// StringName
	// Transform2D
	// Transform3D
	// Vector2
	// Vector2i
	godot::Vector3 decode_Vector3( int64_t start_ );
	godot::Vector3i decode_Vector3i( int64_t start_ );
	// Vector4
	// Vector4i
};

} //namespace godot_flatbuffers

#endif //GODOT_FLATBUFFERS_EXTENSION_FLATBUFFER_HPP