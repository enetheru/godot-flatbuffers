#include "flatbuffer.hpp"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <utility>

namespace godot_flatbuffers {


void FlatBuffer::_bind_methods() {
  using namespace godot;

  //Debug
  ClassDB::bind_method( D_METHOD( "get_memory_address" ), &FlatBuffer::get_memory_address );

  //Properties
  ClassDB::bind_method( D_METHOD( "set_start", "start" ), &FlatBuffer::set_start );
  ClassDB::bind_method( D_METHOD( "get_start" ), &FlatBuffer::get_start );
  ADD_PROPERTY( PropertyInfo(Variant::INT, "start"), "set_start", "get_start" );

  ClassDB::bind_method( D_METHOD( "set_bytes", "bytes" ), &FlatBuffer::set_bytes );
  ClassDB::bind_method( D_METHOD( "get_bytes" ), &FlatBuffer::get_bytes );
  ADD_PROPERTY( PropertyInfo(Variant::PACKED_BYTE_ARRAY, "bytes"), "set_bytes", "get_bytes" );

  // Field Access Helpers
  ClassDB::bind_method( D_METHOD( "get_field_offset", "vtable_offset" ), &FlatBuffer::get_field_offset );
  ClassDB::bind_method( D_METHOD( "get_field_start", "field_offset" ), &FlatBuffer::get_field_start );

  //Array Access Helpers
  ClassDB::bind_method( D_METHOD( "get_array_size", "vtable_offset" ), &FlatBuffer::get_array_size );
  ClassDB::bind_method( D_METHOD( "get_array_element_start", "array_start", "idx" ), &FlatBuffer::get_array_element_start );

  //// decode atomic types
  // BOOL,
  // INT,
  // FLOAT,
  // STRING,
  ClassDB::bind_method( D_METHOD( "decode_String", "start_" ), &FlatBuffer::decode_String );

  //// Decode math types
  BindGetStructMethod<Vector2>("Vector2");
  BindGetStructMethod<Vector2i>("Vector2i");
  BindGetStructMethod<Rect2>("Rect2");
  BindGetStructMethod<Rect2i>("Rect2i");
  BindGetStructMethod<Vector3>("Vector3");
  BindGetStructMethod<Vector3i>("Vector3i");
  BindGetStructMethod<Transform2D>("Transform2D");
  BindGetStructMethod<Vector4>("Vector4");
  BindGetStructMethod<Vector4i>("Vector4i");
  BindGetStructMethod<Plane>("Plane");
  BindGetStructMethod<Quaternion>("Quaternion");
  BindGetStructMethod<AABB>("AABB");
  BindGetStructMethod<Basis>("Basis");
  BindGetStructMethod<Transform3D>("Transform3D");
  BindGetStructMethod<Projection>("Projection");

  //// Decode misc types
  BindGetStructMethod<Color>("Color");
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
  ClassDB::bind_method( D_METHOD( "decode_PackedByteArray", "start_" ), &FlatBuffer::decode_PackedByteArray );
  // PACKED_INT32_ARRAY,
  ClassDB::bind_method( D_METHOD( "decode_PackedInt32Array", "start_" ), &FlatBuffer::decode_PackedInt32Array );
  // PACKED_INT64_ARRAY,
  ClassDB::bind_method( D_METHOD( "decode_PackedInt64Array", "start_" ), &FlatBuffer::decode_PackedInt64Array );
  // PACKED_FLOAT32_ARRAY,
  ClassDB::bind_method( D_METHOD( "decode_PackedFloat32Array", "start_" ), &FlatBuffer::decode_packed_float32_array );
  // PACKED_FLOAT64_ARRAY,
  ClassDB::bind_method( D_METHOD( "decode_PackedFloat64Array", "start_" ), &FlatBuffer::decode_packed_float64_array );
  // PACKED_STRING_ARRAY,
  ClassDB::bind_method( D_METHOD( "decode_PackedStringArray", "start_" ), &FlatBuffer::decode_PackedStringArray );
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
