#ifndef GODOT_FLATBUFFERS_EXTENSION_FLATBUFFERARRAY_H
#define GODOT_FLATBUFFERS_EXTENSION_FLATBUFFERARRAY_H

#include "flatbuffers/flatbuffers.h"

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/core/object.hpp>
#include <utility>

namespace godot_flatbuffers {

class FlatBufferArray : public godot::Object {
	GDCLASS(FlatBufferArray, Object) // NOLINT(*-use-auto)

	int64_t start {};
	godot::PackedByteArray bytes{};
	godot::Callable constructor;

public:
	explicit FlatBufferArray();
	FlatBufferArray( int start_, godot::PackedByteArray bytes_, godot::Callable constructor_ );
	~FlatBufferArray() override;

protected:
	static void _bind_methods();

public:
	// Get and Set of properties
	void set_start(int start_){ start = start_; }
	[[nodiscard]] int64_t get_start() const{ return start; }

	void set_bytes(godot::PackedByteArray bytes_){ bytes = std::move(bytes_); }
	godot::PackedByteArray get_bytes(){ return bytes; }

	void set_constructor(godot::Callable constructor_){ constructor = std::move(constructor_); }
	godot::Callable get_constructor(){ return constructor; }

	// Accessor Methods
	int64_t count();
	godot::Variant get( int idx );
};

}

#endif //GODOT_FLATBUFFERS_EXTENSION_FLATBUFFERARRAY_H
