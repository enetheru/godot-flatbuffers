#ifndef GODOT_FLATBUFFERS_EXTENSION_FLATBUFFERBUILDER_H
#define GODOT_FLATBUFFERS_EXTENSION_FLATBUFFERBUILDER_H

#include "flatbuffers/flatbuffer_builder.h"
#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot_flatbuffers {

class FlatBufferBuilder : public godot::RefCounted {
	GDCLASS(FlatBufferBuilder, RefCounted) // NOLINT(*-use-auto)

	std::unique_ptr<flatbuffers::FlatBufferBuilder> builder;

protected:
	static FlatBufferBuilder *Create(int size) {
		auto fbb = memnew( FlatBufferBuilder );
		fbb->builder = std::make_unique<flatbuffers::FlatBufferBuilder>( size );
		return fbb;
	}

	static void _bind_methods();

public:
	explicit FlatBufferBuilder();
	~FlatBufferBuilder() override;

	using uoffset_t = flatbuffers::uoffset_t;
	using Offset = flatbuffers::Offset<>;

	void Clear() { builder->Clear(); }
	void Reset() { builder->Reset(); }

	// Scalar add functions
	template<typename in, typename out>
	void add_scalar( uint16_t voffset, in value ){ builder->AddElement<out>( voffset, value); }

	uoffset_t StartTable() { return builder->StartTable(); }
	uoffset_t EndTable(uoffset_t start) { return builder->EndTable(start); }

	void Finish( uint32_t root );

	int64_t GetSize() { return builder->GetSize(); }
	godot::PackedByteArray GetPackedByteArray();
};

}
#endif //GODOT_FLATBUFFERS_EXTENSION_FLATBUFFERBUILDER_H
