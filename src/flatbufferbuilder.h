//
// Created by nicho on 7/05/2024.
//

#ifndef GODOT_FLATBUFFERS_EXTENSION_FLATBUFFERBUILDER_H
#define GODOT_FLATBUFFERS_EXTENSION_FLATBUFFERBUILDER_H

#include "flatbuffers/flatbuffer_builder.h"
#include <godot_cpp/classes/object.hpp>


class FlatBufferBuilder : public godot::Object {
	GDCLASS(FlatBufferBuilder, Object) // NOLINT(*-use-auto)

	flatbuffers::FlatBufferBuilder *builder;

protected:
	static void _bind_methods();

public:
	explicit FlatBufferBuilder() { builder = new flatbuffers::FlatBufferBuilder(); }
	~FlatBufferBuilder() override = default;

	using uoffset_t = flatbuffers::uoffset_t;
	void Clear() { builder->Clear(); }
	void Reset() { builder->Reset(); }
	void Finished() { builder->Finished(); }
	uoffset_t StartTable() { return builder->StartTable(); }
	uoffset_t EndTable(uoffset_t start) { return builder->EndTable(start); }
};

#endif //GODOT_FLATBUFFERS_EXTENSION_FLATBUFFERBUILDER_H
