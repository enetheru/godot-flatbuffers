#include "flatbuffer.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <utility>

namespace godot_flatbuffers {

FlatBuffer::FlatBuffer() {
	godot::UtilityFunctions::print("FlatBuffer(): Constructor");

}
FlatBuffer::~FlatBuffer() {
	godot::UtilityFunctions::print("~FlatBuffer(): Destructor");
}

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
	ClassDB::bind_method(D_METHOD("decode_color", "start_" ), &FlatBuffer::decode_color );
	ClassDB::bind_method(D_METHOD("decode_string", "start_" ), &FlatBuffer::decode_string );
	ClassDB::bind_method(D_METHOD("decode_vector3", "start_" ), &FlatBuffer::decode_vector3 );
}

// Returns the field offset relative to 'start'.
// If this is a scalar or a struct, it will be where the data is
// If this is a table, or an array, it will be a relative offset to the position of the field.
int64_t FlatBuffer::get_field_offset(int64_t vtable_offset) {
	// get vtable
	int64_t vtable_pos = start - bytes.decode_s32(start);
	int64_t vtable_size = bytes.decode_s16( vtable_pos );
	//int64_t table_size = bytes.decode_s16( vtable_pos + 2 ); Unnecessary

	//The vtable_pos being outside the range is not an error,
	// it simply means that the element is not present in the table.
	if( vtable_offset >= vtable_size) {
		return 0;
	}

	//decoding zero means that the field is not present.
	return bytes.decode_s16(vtable_pos + vtable_offset );
}

// returns offset from the zero of the bytes(PackedByteArray)
// This isn't necessary with structs and scalars, as the data is inline
int64_t FlatBuffer::get_field_start(int64_t field_offset) {
	return start + field_offset + bytes.decode_u32(start + field_offset);
}

FlatBufferArray *FlatBuffer::get_array(int64_t start_, godot::Callable constructor_) {
	auto new_array = memnew( FlatBufferArray( start_, bytes, std::move(constructor_) ) );
	return new_array;
}

int64_t FlatBuffer::get_array_count( int64_t vtable_offset ) {
	int64_t foffset = get_field_offset( vtable_offset );
	if( !foffset )return 0;
	int64_t field_start = get_field_start( foffset );
	return bytes.decode_u32( field_start );
}

int64_t FlatBuffer::get_array_element_start(int64_t array_start, int64_t idx) {
	int64_t offset = array_start + 4 + (idx * 4);
	return offset + bytes.decode_u32( offset );
}

// Property Get and Set Functions
void FlatBuffer::set_bytes( godot::PackedByteArray bytes_) {
	bytes = std::move(bytes_);
}

godot::PackedByteArray FlatBuffer::get_bytes() {
	return bytes;
}

void FlatBuffer::set_start(int64_t start_) {
	start = start_;
}
int64_t FlatBuffer::get_start() const {
	return start;
}

// Decode Functions

godot::Color FlatBuffer::decode_color( int64_t start_ ) {
	return {
		(real_t)bytes.decode_float(start_),
		(real_t)bytes.decode_float(start_ + 4),
		(real_t)bytes.decode_float(start_ + 8),
		(real_t)bytes.decode_float(start_ + 12)
	};
}


godot::String FlatBuffer::decode_string( int64_t start_ ) {
	return bytes.slice(start_ + 4, start_ + 4 + bytes.decode_u32(start_) ).get_string_from_utf8();
}


godot::Vector3 FlatBuffer::decode_vector3( int64_t start_) {
	// FIXME too much munging for what i want.
	return {
		(real_t)bytes.decode_float(start_),
		(real_t)bytes.decode_float(start_ + 4),
		(real_t)bytes.decode_float(start_ + 8)
	};
}

}// end namespace godot_flatbuffers


