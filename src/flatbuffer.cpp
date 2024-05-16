#include "flatbuffer.h"
#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot_flatbuffers {

void FlatBuffer::_bind_methods() {
	using namespace godot;

	//Properties
	ClassDB::bind_method(D_METHOD("set_start", "start"), &FlatBuffer::set_start );
	ClassDB::bind_method(D_METHOD("get_start"), &FlatBuffer::get_start );
	ADD_PROPERTY(PropertyInfo(Variant::INT, "start"), "set_start", "get_start");

	ClassDB::bind_method(D_METHOD("set_bytes", "bytes"), &FlatBuffer::set_bytes );
	ClassDB::bind_method(D_METHOD("get_bytes"), &FlatBuffer::get_bytes );
	ADD_PROPERTY(PropertyInfo(Variant::PACKED_BYTE_ARRAY, "bytes"), "set_bytes", "get_bytes");

	// Field Access Helpers
	ClassDB::bind_method(D_METHOD("get_field_offset", "vtable_offset"), &FlatBuffer::get_field_offset );
	ClassDB::bind_method(D_METHOD("get_field_start", "field_offset"), &FlatBuffer::get_field_start );

	//Array Access Helpers
	ClassDB::bind_method(D_METHOD("get_array", "start_", "constructor_"), &FlatBuffer::get_array );
	ClassDB::bind_method(D_METHOD("get_array_count", "vtable_offset"), &FlatBuffer::get_array_count );
	ClassDB::bind_method(D_METHOD("get_array_element_start", "array_start", "idx"), &FlatBuffer::get_array_element_start );

	// Decode Functions
	ClassDB::bind_method(D_METHOD("decode_string", "start_" ), &FlatBuffer::decode_string );
}

// Returns the field offset relative to 'start'.
// If this is a scalar or a struct it will be where the data is
// If this is a table, or an array, it will be a relative offset to the position of the field.
int FlatBuffer::get_field_offset(int vtable_offset) {
	// get vtable
	int vtable_pos = start - bytes.decode_s32(start);
	int vtable_size = bytes.decode_s16( vtable_pos );
	int table_size = bytes.decode_s16( vtable_pos + 2 );

	//The vtable_pos being outside the range is not an error,
	// it simply means that the element is not present in the table.
	if( vtable_offset >= vtable_size) {
		return 0;
	}

	//decoding zero means that the field is not present.
	return bytes.decode_s16(vtable_pos + vtable_offset );
}

// returns offset from the zero of the bytes(PackedByteArray)
// This isn't necessary with structs and scalars, as the data is inline with the
int FlatBuffer::get_field_start(int field_offset) {
	return start + field_offset + bytes.decode_u32(start + field_offset);
}

FlatBufferArray *FlatBuffer::get_array(int start_, godot::Callable constructor_) {
	auto new_array = memnew( FlatBufferArray( start_, bytes, constructor_ ) );
	return new_array;
}

int FlatBuffer::get_array_count( int vtable_offset ) {
	int foffset = get_field_offset( vtable_offset );
	if( !foffset )return 0;
	int field_start = get_field_start( foffset );
	return bytes.decode_u32( field_start );
}

int FlatBuffer::get_array_element_start(int array_start, int idx) {
	int offset = array_start + 4 + (idx * 4);
	return offset + bytes.decode_u32( offset );
}

// Property Get and Set Functions
void FlatBuffer::set_bytes( godot::PackedByteArray bytes_) {
	bytes = bytes_;
}

godot::PackedByteArray FlatBuffer::get_bytes() {
	return bytes;
}

void FlatBuffer::set_start(int start_) {
	start = start_;
}
int FlatBuffer::get_start() {
	return start;
}

// Decode Functions
godot::String FlatBuffer::decode_string( int start_ ) {
	return bytes.slice(start_ + 4, start_ + 4 + bytes.decode_u32(start_) ).get_string_from_utf8();
}

}// end namespace godot_flatbuffers


