#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <utility>

#include "flatbufferarray.h"

namespace godot_flatbuffers {

FlatBufferArray::FlatBufferArray() {
	godot::UtilityFunctions::print("FlatBufferArray(): Constructor");
}

FlatBufferArray::FlatBufferArray(int start_, godot::PackedByteArray bytes_, godot::Callable constructor_):
		start(start_), bytes(std::move( bytes_ )), constructor(std::move( constructor_ )) {
	godot::UtilityFunctions::print("FlatBufferArray(): Constructor");
}

FlatBufferArray::~FlatBufferArray() {
	godot::UtilityFunctions::print("~FlatBufferArray(): Destructor");
}

void FlatBufferArray::_bind_methods() {
	using namespace godot;

	//Properties
	ClassDB::bind_method(D_METHOD("set_start", "start"), &FlatBufferArray::set_start );
	ClassDB::bind_method(D_METHOD("get_start"), &FlatBufferArray::get_start );
	ADD_PROPERTY(PropertyInfo(Variant::INT, "start"), "set_start", "get_start");

	ClassDB::bind_method(D_METHOD("set_bytes", "bytes"), &FlatBufferArray::set_bytes );
	ClassDB::bind_method(D_METHOD("get_bytes"), &FlatBufferArray::get_bytes );
	ADD_PROPERTY(PropertyInfo(Variant::PACKED_BYTE_ARRAY, "bytes"), "set_bytes", "get_bytes");

	ClassDB::bind_method(D_METHOD("set_constructor", "constructor_"), &FlatBufferArray::set_constructor );
	ClassDB::bind_method(D_METHOD("get_constructor"), &FlatBufferArray::get_constructor );
	ADD_PROPERTY(PropertyInfo(Variant::PACKED_BYTE_ARRAY, "constructor"), "set_constructor", "get_constructor");

	// Access Helpers
	ClassDB::bind_method(D_METHOD("count"), &FlatBufferArray::count );
	ClassDB::bind_method(D_METHOD("get", "idx"), &FlatBufferArray::get );
}

int64_t FlatBufferArray::count() {
	return bytes.decode_u32( start );
}

godot::Variant FlatBufferArray::get(int idx) {
	// decode the offset for the object from the array, and then pass it to the constructor.
	int64_t offset = bytes.decode_u32( start + 4 + (idx * 4) );
	int64_t pos = start + 4 + (idx * 4) + offset;
	return constructor.call( pos, bytes );
}

}// end namespace godot_flatbuffers
