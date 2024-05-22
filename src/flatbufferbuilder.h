#ifndef GODOT_FLATBUFFERS_EXTENSION_FLATBUFFERBUILDER_H
#define GODOT_FLATBUFFERS_EXTENSION_FLATBUFFERBUILDER_H

#include "flatbuffers/flatbuffer_builder.h"
#include <godot_cpp/classes/object.hpp>



class FlatBufferBuilder : public godot::Object {
	GDCLASS(FlatBufferBuilder, Object) // NOLINT(*-use-auto)

	flatbuffers::FlatBufferBuilder *builder;

protected:
	static FlatBufferBuilder *Create( int size ){
		auto fbb = memnew(FlatBufferBuilder);
		fbb->builder = new flatbuffers::FlatBufferBuilder( size );
		return fbb;
	}

	static void _bind_methods();

public:
	explicit FlatBufferBuilder() = default;
	~FlatBufferBuilder() override = default;

	//FIXME delete the builder

	using uoffset_t = flatbuffers::uoffset_t;
	void Clear() { builder->Clear(); }
	void Reset() { builder->Reset(); }
	void Finished() { builder->Finished(); }
	uoffset_t StartTable() { return builder->StartTable(); }
	uoffset_t EndTable(uoffset_t start) { return builder->EndTable(start); }

	// Scalar add functions
	template<typename in, typename out>
	void add_scalar( uint16_t voffset, in value ){ builder->AddElement<out>( voffset, value); }
};

#endif //GODOT_FLATBUFFERS_EXTENSION_FLATBUFFERBUILDER_H
