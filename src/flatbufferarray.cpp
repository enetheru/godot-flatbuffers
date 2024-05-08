#include <godot_cpp/core/class_db.hpp>

#include "flatbufferarray.h"

namespace godot_flatbuffers {

FlatBufferArray::FlatBufferArray(int start_, godot::PackedByteArray bytes_, godot::Callable constructor_):
		start(start_), bytes( bytes_ ), constructor( constructor_ ) {}

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

int FlatBufferArray::count() {
	return bytes.decode_u32( start );
}

godot::Variant FlatBufferArray::get(int idx) {
	//func get_idx( idx ):
	//	# what do we need to do here? decode the offset for the object from the array, and then pass it tothe interpretor.
	//	var offset = bytes.decode_u32( start + 4 + (idx * 4) )
	//	var pos = start + 4 + (idx * 4) + offset
	//	return interpreter.call( pos, bytes )
	return godot::Variant();
}

}// end namespace godot_flatbuffers