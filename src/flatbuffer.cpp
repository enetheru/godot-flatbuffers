#include "flatbuffer.hpp"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <utility>

namespace godot_flatbuffers {
void FlatBuffer::_bind_methods() {
  using namespace godot;

  //Debug
  ClassDB::bind_method( D_METHOD( "get_memory_address" ), &get_memory_address );

  //Properties
  ClassDB::bind_method( D_METHOD( "set_start", "start" ), &set_start );
  ClassDB::bind_method( D_METHOD( "get_start" ), &get_start );
  ADD_PROPERTY( PropertyInfo(Variant::INT, "start"), "set_start", "get_start" );

  ClassDB::bind_method( D_METHOD( "set_bytes", "bytes" ), &set_bytes );
  ClassDB::bind_method( D_METHOD( "get_bytes" ), &get_bytes );
  ADD_PROPERTY( PropertyInfo(Variant::PACKED_BYTE_ARRAY, "bytes"), "set_bytes", "get_bytes" );

  // Field Access Helpers
  ClassDB::bind_method( D_METHOD( "get_field_offset", "vtable_offset" ), &get_field_offset );
  ClassDB::bind_method( D_METHOD( "get_field_start", "field_offset" ), &get_field_start );

  //Array Access Helpers
  ClassDB::bind_method( D_METHOD( "get_array_size", "vtable_offset" ), &get_array_size );
  ClassDB::bind_method( D_METHOD( "get_array_element_start", "array_start", "idx" ), &get_array_element_start );

  //// decode atomic types
  // BOOL,
  // INT,
  // FLOAT,
  // STRING,
  ClassDB::bind_method( D_METHOD( "decode_String", "start_" ), &decode_String );

  //FIXME: Pretty sure the use of this template to copy the bytes completely breaks the endianness correction that could happen. so its a temporary hack.
  //// Decode math types
  // VECTOR2,
  ClassDB::bind_method( D_METHOD( "decode_Vector2", "start_" ), &decode_struct< Vector2 > );
  // VECTOR2I,
  ClassDB::bind_method( D_METHOD( "decode_Vector2i", "start_" ), &decode_struct< Vector2i > );
  // RECT2,
  ClassDB::bind_method( D_METHOD( "decode_Rect2", "start_" ), &decode_struct< Rect2 > );
  // RECT2I,
  ClassDB::bind_method( D_METHOD( "decode_Rect2i", "start_" ), &decode_struct< Rect2i > );
  // VECTOR3,
  ClassDB::bind_method( D_METHOD( "decode_Vector3", "start_" ), &decode_struct< Vector3 > );
  // VECTOR3I,
  ClassDB::bind_method( D_METHOD( "decode_Vector3i", "start_" ), &decode_struct< Vector3i > );
  // TRANSFORM2D,
  ClassDB::bind_method( D_METHOD( "decode_Transform2D", "start_" ), &decode_struct< Transform2D > );
  // VECTOR4,
  ClassDB::bind_method( D_METHOD( "decode_Vector4", "start_" ), &decode_struct< Vector4 > );
  // VECTOR4I,
  ClassDB::bind_method( D_METHOD( "decode_Vector4i", "start_" ), &decode_struct< Vector4i > );
  // PLANE,
  ClassDB::bind_method( D_METHOD( "decode_Plane", "start_" ), &decode_struct< Plane > );
  // QUATERNION,
  ClassDB::bind_method( D_METHOD( "decode_Quaternion", "start_" ), &decode_struct< Quaternion > );
  // AABB,
  ClassDB::bind_method( D_METHOD( "decode_AABB", "start_" ), &decode_struct< godot::AABB > );
  // BASIS,
  ClassDB::bind_method( D_METHOD( "decode_Basis", "start_" ), &decode_struct< godot::Basis > );
  // TRANSFORM3D,
  ClassDB::bind_method( D_METHOD( "GetTransform3D", "start_" ), &decode_struct< godot::Transform3D > );
  // PROJECTION,
  ClassDB::bind_method( D_METHOD( "decode_Projection", "start_" ), &decode_struct< Projection > );

  //// Decode misc types
  // COLOR,
  ClassDB::bind_method( D_METHOD( "decode_Color", "start_" ), &decode_struct< Color > );
  // STRING_NAME,
  // NODE_PATH,
  // RID,
  // OBJECT,
  // CALLABLE,
  // SIGNAL,
  // DICTIONARY,
  // ARRAY,

  // Decode typed arrays
  // PACKED_BYTE_ARRAY,
  ClassDB::bind_method( D_METHOD( "decode_PackedByteArray", "start_" ), &decode_PackedByteArray );
  // PACKED_INT32_ARRAY,
  ClassDB::bind_method( D_METHOD( "decode_PackedInt32Array", "start_" ), &decode_PackedInt32Array );
  // PACKED_INT64_ARRAY,
  ClassDB::bind_method( D_METHOD( "decode_PackedInt64Array", "start_" ), &decode_PackedInt64Array );
  // PACKED_FLOAT32_ARRAY,
  ClassDB::bind_method( D_METHOD( "decode_PackedFloat32Array", "start_" ), &decode_packed_float32_array );
  // PACKED_FLOAT64_ARRAY,
  ClassDB::bind_method( D_METHOD( "decode_PackedFloat64Array", "start_" ), &decode_packed_float64_array );
  // PACKED_STRING_ARRAY,
  ClassDB::bind_method( D_METHOD( "decode_PackedStringArray", "start_" ), &decode_PackedStringArray );
  // PACKED_VECTOR2_ARRAY,
  // PACKED_VECTOR3_ARRAY,
  // PACKED_COLOR_ARRAY,
  // PACKED_VECTOR4_ARRAY,
}

godot::String FlatBuffer::get_memory_address() const {
  const auto i = reinterpret_cast< std::uintptr_t >(bytes.ptr());
  return godot::vformat( "%X", i );
}

// Returns the field offset relative to 'start'.
// If this is a scalar or a struct, it will be where the data is
// If this is a table, or an array, it will be a relative offset to the position of the field.
int64_t FlatBuffer::get_field_offset( const int64_t vtable_offset ) const {
  // get vtable
  const int64_t vtable_pos = start - bytes.decode_s32( start );
  //int64_t table_size = bytes.decode_s16( vtable_pos + 2 ); Unnecessary

  // The vtable_pos being outside the range is not an error,
  // it simply means that the element is not present in the table.
  if( const int64_t vtable_size = bytes.decode_s16( vtable_pos ); vtable_offset >= vtable_size ) {
    return 0;
  }

  // decoding zero means that the field is not present.
  return bytes.decode_s16( vtable_pos + vtable_offset );
}

// returns offset from the zero of the bytes(PackedByteArray)
// This isn't necessary with structs and scalars, as the data is inline
int64_t FlatBuffer::get_field_start( const int64_t vtable_offset ) const {
  const int field_offset = get_field_offset( vtable_offset ); // NOLINT(*-narrowing-conversions)
  if( ! field_offset )
    return 0;
  return start + field_offset + bytes.decode_u32( start + field_offset );
}

int64_t FlatBuffer::get_array_size( const int64_t vtable_offset ) const {
  const int64_t foffset = get_field_offset( vtable_offset );
  if( ! foffset )
    return 0;
  const int64_t field_start = get_field_start( foffset );
  return bytes.decode_u32( field_start );
}

int64_t FlatBuffer::get_array_element_start( const int64_t array_start, const int64_t idx ) const {
  // TODO we could check for out of bounds here.
  //  int64_t array_size = bytes.decode_u32( array_start );

  const int64_t data    = array_start + 4;
  const int64_t element = data + idx * 4;
  const int64_t value   = bytes.decode_u32( element );

  return element + value;
}

// Property Get and Set Functions
void FlatBuffer::set_bytes( godot::PackedByteArray bytes_ ) {
  bytes = std::move( bytes_ );
}

const godot::PackedByteArray &FlatBuffer::get_bytes() {
  return bytes;
}

void FlatBuffer::set_start( const int64_t start_ ) {
  start = start_;
}

int64_t FlatBuffer::get_start() const {
  return start;
}

// Decode Functions

godot::PackedByteArray FlatBuffer::decode_PackedByteArray( const int64_t start_ ) const {
  const int64_t size        = bytes.decode_u32( start_ );
  const int64_t array_start = start_ + 4;
  return bytes.slice( array_start, array_start + size );
}

godot::PackedFloat32Array FlatBuffer::decode_packed_float32_array( const int64_t start_ ) const {
  const int64_t length      = bytes.decode_u32( start_ ) * sizeof( float ); // NOLINT(*-narrowing-conversions)
  const int64_t array_start = start_ + 4;
  return bytes.slice( array_start, array_start + length ).to_float32_array();
}

godot::PackedFloat64Array FlatBuffer::decode_packed_float64_array( const int64_t start_ ) const {
  const int64_t length      = bytes.decode_u32( start_ ) * sizeof( double ); // NOLINT(*-narrowing-conversions)
  const int64_t array_start = start_ + 4;
  return bytes.slice( array_start, array_start + length ).to_float64_array();
}

godot::PackedInt32Array FlatBuffer::decode_PackedInt32Array( const int64_t start_ ) const {
  const int64_t length      = bytes.decode_u32( start_ ) * sizeof( int32_t ); // NOLINT(*-narrowing-conversions)
  const int64_t array_start = start_ + 4;
  return bytes.slice( array_start, array_start + length ).to_int32_array();
}

godot::PackedInt64Array FlatBuffer::decode_PackedInt64Array( const int64_t start_ ) const {
  const int64_t length      = bytes.decode_u32( start_ ) * sizeof( int64_t ); // NOLINT(*-narrowing-conversions)
  const int64_t array_start = start_ + 4;
  return bytes.slice( array_start, array_start + length ).to_int64_array();
}

godot::PackedStringArray FlatBuffer::decode_PackedStringArray( const int64_t start_ ) const {
  const int64_t size = bytes.decode_u32( start_ );
  const int64_t data = start_ + sizeof( uint32_t ); // NOLINT(*-narrowing-conversions)

  godot::PackedStringArray string_array;
  for( int i = 0; i < size; ++i ) {
    const int64_t  element = data + i * sizeof( uint32_t ); // NOLINT(*-narrowing-conversions)
    const uint32_t offset  = bytes.decode_u32( element );
    string_array.append( decode_String( element + offset ) );
  }
  return string_array;
}

godot::String FlatBuffer::decode_String( const int64_t start_ ) const {
  return bytes.slice( start_ + 4, start_ + 4 + bytes.decode_u32( start_ ) ).get_string_from_utf8();
}

} // end namespace godot_flatbuffers
