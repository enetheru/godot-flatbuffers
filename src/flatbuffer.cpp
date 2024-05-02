#include "flatbuffer.h"
#include <godot_cpp/core/class_db.hpp>

namespace godot_flatbuffers {

/*
 * Base class which all generated gdscripts will inherit
 */
godot::PackedByteArray FlatBufferBase::Pack(const godot::Variant&) {
	return {};
}

void FlatBufferBase::_bind_methods() {
	godot::ClassDB::bind_static_method("FlatBuffer", godot::D_METHOD("Pack", "variant"), &FlatBufferBase::Pack);
}

/*
 * Flatbuffer Builder wrapper for gdscript
 */
void FlatBufferBuilder::_bind_methods() {
	godot::ClassDB::bind_method(godot::D_METHOD("clear"), &FlatBufferBuilder::Clear);
	godot::ClassDB::bind_method(godot::D_METHOD("reset"), &FlatBufferBuilder::Reset);
	godot::ClassDB::bind_method(godot::D_METHOD("finished"), &FlatBufferBuilder::Finished);
	godot::ClassDB::bind_method(godot::D_METHOD("start_table"), &FlatBufferBuilder::StartTable);
	godot::ClassDB::bind_method(godot::D_METHOD("clear", "start"), &FlatBufferBuilder::EndTable);
}

}// end namespace godot_flatbuffers