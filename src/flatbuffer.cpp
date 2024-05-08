#include "flatbuffer.h"
#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/core/class_db.hpp>

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

	// Access Helpers
	ClassDB::bind_method(D_METHOD("get_field_offset", "vtable_offset"), &FlatBuffer::get_field_offset );
	ClassDB::bind_method(D_METHOD("get_field_start", "field_offset"), &FlatBuffer::get_field_start );

	// TODO FlatBuffer_Array get_array( int vtable_offset, Callable interpreter  );
	ClassDB::bind_method(D_METHOD("get_array", "start_", "constructor_"), &FlatBuffer::get_array );
	ClassDB::bind_method(D_METHOD("get_array_count", "vtable_offset"), &FlatBuffer::get_array_count );
	ClassDB::bind_method(D_METHOD("get_array_element_start", "array_start", "idx"), &FlatBuffer::get_array_element_start );


	// Decode Functions
	ClassDB::bind_method(D_METHOD("decode_bool", "start_" ), &FlatBuffer::decode_bool );
	ClassDB::bind_method(D_METHOD("decode_char", "start_" ), &FlatBuffer::decode_char );
	ClassDB::bind_method(D_METHOD("decode_uchar", "start_" ), &FlatBuffer::decode_uchar );
	ClassDB::bind_method(D_METHOD("decode_short", "start_" ), &FlatBuffer::decode_short );
	ClassDB::bind_method(D_METHOD("decode_ushort", "start_" ), &FlatBuffer::decode_ushort );
	ClassDB::bind_method(D_METHOD("decode_int", "start_" ), &FlatBuffer::decode_int );
	ClassDB::bind_method(D_METHOD("decode_uint", "start_" ), &FlatBuffer::decode_uint );
	ClassDB::bind_method(D_METHOD("decode_long", "start_" ), &FlatBuffer::decode_long );
	ClassDB::bind_method(D_METHOD("decode_ulong", "start_" ), &FlatBuffer::decode_ulong );
	ClassDB::bind_method(D_METHOD("decode_float", "start_" ), &FlatBuffer::decode_float );
	ClassDB::bind_method(D_METHOD("decode_double", "start_" ), &FlatBuffer::decode_double );
	ClassDB::bind_method(D_METHOD("decode_string", "start_" ), &FlatBuffer::decode_string );
}

int FlatBuffer::get_field_offset(int vtable_offset) {
	// get vtable
	int vtable_pos = start - bytes.decode_s32(start);
	int vtable_size = bytes.decode_s16( vtable_pos );
	int table_size = bytes.decode_s16( vtable_pos + 2 );

	//The vtable_pos being outside the range is not an error,
	// it simply means that the element is not present in the table.
	if( vtable_offset > vtable_size) {
		return 0;
	}

	//decoding zero means that the field is not present.
	return bytes.decode_s16(vtable_pos + vtable_offset );
}


int FlatBuffer::get_field_start(int field_offset) {
	return start + field_offset + bytes.decode_u32(start + field_offset);
}

FlatBufferArray *FlatBuffer::get_array(int start_, godot::Callable constructor_) {
	FlatBufferArray new_array( start_, bytes, constructor_ );
	return &new_array;
}

int FlatBuffer::get_array_count(int vtable_offset) {
	int foffset = get_field_offset( vtable_offset );
	if( foffset ) return 0;
	return bytes.decode_u32( get_field_start(foffset) );
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


