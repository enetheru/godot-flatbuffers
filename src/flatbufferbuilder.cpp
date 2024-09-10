#include "flatbufferbuilder.hpp"
#include "utils.hpp"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

/*
 * Flatbuffer Builder wrapper for gdscript
 */
namespace godot_flatbuffers {
void FlatBufferBuilder::_bind_methods() {
  using namespace godot;

  ClassDB::bind_static_method( "FlatBufferBuilder", D_METHOD( "create", "size" ), &Create );

  ClassDB::bind_method( D_METHOD( "clear" ), &FlatBufferBuilder::Clear );
  ClassDB::bind_method( D_METHOD( "reset" ), &FlatBufferBuilder::Reset );
  ClassDB::bind_method( D_METHOD( "finish", "table_offset" ), &FlatBufferBuilder::Finish );
  ClassDB::bind_method( D_METHOD( "start_table" ), &FlatBufferBuilder::StartTable );
  ClassDB::bind_method( D_METHOD( "end_table", "start" ), &FlatBufferBuilder::EndTable );
  ClassDB::bind_method( D_METHOD( "get_size" ), &FlatBufferBuilder::GetSize );
  ClassDB::bind_method( D_METHOD( "to_packed_byte_array" ), &FlatBufferBuilder::GetPackedByteArray );

  // == Add functions ==
  ClassDB::bind_method( D_METHOD( "add_offset", "voffset", "value" ), &FlatBufferBuilder::AddOffset );
  ClassDB::bind_method( D_METHOD( "add_bytes", "voffset", "value" ), &FlatBufferBuilder::AddBytes );

  ClassDB::bind_method( D_METHOD( "add_element_bool", "voffset", "value" ), &FlatBufferBuilder::AddScalar< bool, uint8_t > );
  ClassDB::bind_method( D_METHOD( "add_element_byte", "voffset", "value" ), &FlatBufferBuilder::AddScalar< int64_t, int8_t > );
  ClassDB::bind_method( D_METHOD( "add_element_ubyte", "voffset", "value" ), &FlatBufferBuilder::AddScalar< uint64_t, uint8_t > );
  ClassDB::bind_method( D_METHOD( "add_element_short", "voffset", "value" ), &FlatBufferBuilder::AddScalar< int64_t, int16_t > );
  ClassDB::bind_method( D_METHOD( "add_element_ushort", "voffset", "value" ), &FlatBufferBuilder::AddScalar< uint64_t, uint16_t > );
  ClassDB::bind_method( D_METHOD( "add_element_int", "voffset", "value" ), &FlatBufferBuilder::AddScalar< int64_t, int32_t > );
  ClassDB::bind_method( D_METHOD( "add_element_uint", "voffset", "value" ), &FlatBufferBuilder::AddScalar< uint64_t, uint32_t > );
  ClassDB::bind_method( D_METHOD( "add_element_long", "voffset", "value" ), &FlatBufferBuilder::AddScalar< int64_t, int64_t > );
  ClassDB::bind_method( D_METHOD( "add_element_ulong", "voffset", "value" ), &FlatBufferBuilder::AddScalar< uint64_t, uint64_t > );
  ClassDB::bind_method( D_METHOD( "add_element_float", "voffset", "value" ), &FlatBufferBuilder::AddScalar< double, float > );
  ClassDB::bind_method( D_METHOD( "add_element_double", "voffset", "value" ), &FlatBufferBuilder::AddScalar< double, double > );

  ClassDB::bind_method(
      D_METHOD( "add_element_bool_default", "voffset", "value", "default" ), &FlatBufferBuilder::AddScalarDefault< bool, uint8_t > );
  ClassDB::bind_method(
      D_METHOD( "add_element_byte_default", "voffset", "value", "default" ), &FlatBufferBuilder::AddScalarDefault< int64_t, int8_t > );
  ClassDB::bind_method(
      D_METHOD( "add_element_ubyte_default", "voffset", "value", "default" ), &FlatBufferBuilder::AddScalarDefault< uint64_t, uint8_t > );
  ClassDB::bind_method(
      D_METHOD( "add_element_short_default", "voffset", "value", "default" ), &FlatBufferBuilder::AddScalarDefault< int64_t, int16_t > );
  ClassDB::bind_method(
      D_METHOD( "add_element_ushort_default", "voffset", "value", "default" ),
      &FlatBufferBuilder::AddScalarDefault< uint64_t, uint16_t > );
  ClassDB::bind_method(
      D_METHOD( "add_element_int_default", "voffset", "value", "default" ), &FlatBufferBuilder::AddScalarDefault< int64_t, int32_t > );
  ClassDB::bind_method(
      D_METHOD( "add_element_uint_default", "voffset", "value", "default" ), &FlatBufferBuilder::AddScalarDefault< uint64_t, uint32_t > );
  ClassDB::bind_method(
      D_METHOD( "add_element_long_default", "voffset", "value", "default" ), &FlatBufferBuilder::AddScalarDefault< int64_t, int64_t > );
  ClassDB::bind_method(
      D_METHOD( "add_element_ulong_default", "voffset", "value", "default" ), &FlatBufferBuilder::AddScalarDefault< uint64_t, uint64_t > );
  ClassDB::bind_method(
      D_METHOD( "add_element_float_default", "voffset", "value", "default" ), &FlatBufferBuilder::AddScalarDefault< double, float > );
  ClassDB::bind_method(
      D_METHOD( "add_element_double_default", "voffset", "value", "default" ), &FlatBufferBuilder::AddScalarDefault< double, double > );

  // == Create Functions ==
  ClassDB::bind_method( D_METHOD( "create_vector_offset", "array" ), &FlatBufferBuilder::CreateVectorOffset );
  ClassDB::bind_method( D_METHOD( "create_vector_table", "array", "constructor" ), &FlatBufferBuilder::CreateVectorTable );

  ClassDB::bind_method( D_METHOD( "create_vector_int8", "array" ), &FlatBufferBuilder::CreatePackedArray< int8_t > );
  ClassDB::bind_method( D_METHOD( "create_vector_uint8", "array" ), &FlatBufferBuilder::CreatePackedArray< uint8_t > );
  ClassDB::bind_method( D_METHOD( "create_vector_int16", "array" ), &FlatBufferBuilder::CreatePackedArray< int16_t > );
  ClassDB::bind_method( D_METHOD( "create_vector_uint16", "array" ), &FlatBufferBuilder::CreatePackedArray< uint16_t > );
  ClassDB::bind_method( D_METHOD( "create_vector_int32", "array" ), &FlatBufferBuilder::CreatePackedArray< int32_t > );
  ClassDB::bind_method( D_METHOD( "create_vector_uint32", "array" ), &FlatBufferBuilder::CreatePackedArray< uint32_t > );
  ClassDB::bind_method( D_METHOD( "create_vector_int64", "array" ), &FlatBufferBuilder::CreatePackedArray< int64_t > );
  ClassDB::bind_method( D_METHOD( "create_vector_uint64", "array" ), &FlatBufferBuilder::CreatePackedArray< uint64_t > );
  ClassDB::bind_method( D_METHOD( "create_vector_float32", "array" ), &FlatBufferBuilder::CreatePackedArray< float > );
  ClassDB::bind_method( D_METHOD( "create_vector_float64", "array" ), &FlatBufferBuilder::CreatePackedArray< double > );

  //// atomic types
  // BOOL,
  // INT,
  // FLOAT,
  // STRING,
  ClassDB::bind_method( D_METHOD( "create_String", "string" ), &FlatBufferBuilder::CreateString );

  //// math types
  // VECTOR2,
  ClassDB::bind_method( D_METHOD( "add_Vector2", "voffset", "vector2" ), &FlatBufferBuilder::AddGodotStruct< godot::Vector2 > );
  ClassDB::bind_method( D_METHOD( "create_Vector2", "vector2" ), &FlatBufferBuilder::CreateGodotStruct< godot::Vector2 > );
  // VECTOR2I,
  ClassDB::bind_method( D_METHOD( "add_Vector2i", "voffset", "vector2i" ), &FlatBufferBuilder::AddGodotStruct< godot::Vector2i > );
  ClassDB::bind_method( D_METHOD( "create_Vector2i", "vector2i" ), &FlatBufferBuilder::CreateGodotStruct< godot::Vector2i > );
  // RECT2,
  ClassDB::bind_method( D_METHOD( "add_Rect2", "rect2", "quaternion" ), &FlatBufferBuilder::AddGodotStruct< godot::Rect2 > );
  ClassDB::bind_method( D_METHOD( "create_Rect2", "rect2" ), &FlatBufferBuilder::CreateGodotStruct< godot::Rect2 > );
  // RECT2I,
  ClassDB::bind_method( D_METHOD( "add_Rect2i", "rect2i", "quaternion" ), &FlatBufferBuilder::AddGodotStruct< godot::Rect2i > );
  ClassDB::bind_method( D_METHOD( "create_Rect2i", "rect2i" ), &FlatBufferBuilder::CreateGodotStruct< godot::Rect2i > );
  // VECTOR3,
  ClassDB::bind_method( D_METHOD( "add_Vector3", "voffset", "vector3" ), &FlatBufferBuilder::AddGodotStruct< godot::Vector3 > );
  ClassDB::bind_method( D_METHOD( "create_Vector3", "vector3" ), &FlatBufferBuilder::CreateGodotStruct< godot::Vector3 > );
  // VECTOR3I,
  ClassDB::bind_method( D_METHOD( "add_Vector3i", "voffset", "vector3i" ), &FlatBufferBuilder::AddGodotStruct< godot::Vector3i > );
  ClassDB::bind_method( D_METHOD( "create_Vector3i", "vector3i" ), &FlatBufferBuilder::CreateGodotStruct< godot::Vector3i > );
  // TRANSFORM2D,
  ClassDB::bind_method(
      D_METHOD( "add_Transform2D", "voffset", "transform2d" ), &FlatBufferBuilder::AddGodotStruct< godot::Transform2D > );
  ClassDB::bind_method( D_METHOD( "create_Transform2D", "transform2d" ), &FlatBufferBuilder::CreateGodotStruct< godot::Transform2D > );
  // VECTOR4,
  ClassDB::bind_method( D_METHOD( "add_Vector4", "voffset", "vector4" ), &FlatBufferBuilder::AddGodotStruct< godot::Vector4 > );
  ClassDB::bind_method( D_METHOD( "create_Vector4", "vector4" ), &FlatBufferBuilder::CreateGodotStruct< godot::Vector4 > );
  // VECTOR4I,
  ClassDB::bind_method( D_METHOD( "add_Vector4i", "voffset", "vector4i" ), &FlatBufferBuilder::AddGodotStruct< godot::Vector4i > );
  ClassDB::bind_method( D_METHOD( "create_Vector4i", "vector4i" ), &FlatBufferBuilder::CreateGodotStruct< godot::Vector4i > );
  // PLANE,
  ClassDB::bind_method( D_METHOD( "add_Plane", "voffset", "plane" ), &FlatBufferBuilder::AddGodotStruct< godot::Plane > );
  ClassDB::bind_method( D_METHOD( "create_Plane", "plane" ), &FlatBufferBuilder::CreateGodotStruct< godot::Plane > );
  // QUATERNION,
  ClassDB::bind_method( D_METHOD( "add_Quaternion", "voffset", "quaternion" ), &FlatBufferBuilder::AddGodotStruct< godot::Quaternion > );
  ClassDB::bind_method( D_METHOD( "create_Quaternion", "quaternion" ), &FlatBufferBuilder::CreateGodotStruct< godot::Quaternion > );
  // AABB,
  ClassDB::bind_method( D_METHOD( "add_AABB", "voffset", "aabb" ), &FlatBufferBuilder::AddGodotStruct< godot::AABB > );
  ClassDB::bind_method( D_METHOD( "create_AABB", "aabb" ), &FlatBufferBuilder::CreateGodotStruct< godot::AABB > );
  // BASIS,
  ClassDB::bind_method( D_METHOD( "add_Basis", "basis" ), &FlatBufferBuilder::AddGodotStruct< godot::Basis > );
  ClassDB::bind_method( D_METHOD( "create_Basis", "basis" ), &FlatBufferBuilder::CreateGodotStruct< godot::Basis > );
  // TRANSFORM3D,
  ClassDB::bind_method(
      D_METHOD( "add_Transform3D", "voffset", "transform3d" ), &FlatBufferBuilder::AddGodotStruct< godot::Transform3D > );
  ClassDB::bind_method( D_METHOD( "create_Transform3D", "transform3d" ), &FlatBufferBuilder::CreateGodotStruct< godot::Transform3D > );
  // PROJECTION,
  ClassDB::bind_method( D_METHOD( "add_Projection", "voffset", "projection" ), &FlatBufferBuilder::AddGodotStruct< godot::Projection > );
  ClassDB::bind_method( D_METHOD( "create_Projection", "projection" ), &FlatBufferBuilder::CreateGodotStruct< godot::Projection > );

  //// misc types
  // COLOR,
  ClassDB::bind_method( D_METHOD( "add_Color", "color" ), &FlatBufferBuilder::AddGodotStruct< godot::Color > );
  ClassDB::bind_method( D_METHOD( "create_Color", "color" ), &FlatBufferBuilder::CreateGodotStruct< godot::Color > );
  // STRING_NAME,
  // NODE_PATH,
  // RID,
  // OBJECT,
  // CALLABLE,
  // SIGNAL,
  // DICTIONARY,
  // ARRAY,

  //// typed arrays
  // PACKED_BYTE_ARRAY,
  ClassDB::bind_method( D_METHOD( "create_PackedByteArray", "array" ), &FlatBufferBuilder::CreatePackedArray< uint8_t > );
  // PACKED_INT32_ARRAY,
  ClassDB::bind_method( D_METHOD( "create_PackedInt32Array", "array" ), &FlatBufferBuilder::CreatePackedArray< uint32_t > );
  // PACKED_INT64_ARRAY,
  ClassDB::bind_method( D_METHOD( "create_PackedInt64Array", "array" ), &FlatBufferBuilder::CreatePackedArray< uint64_t > );
  // PACKED_FLOAT32_ARRAY,
  ClassDB::bind_method( D_METHOD( "create_PackedFloat32Array", "array" ), &FlatBufferBuilder::CreatePackedArray< float > );
  // PACKED_FLOAT64_ARRAY,
  ClassDB::bind_method( D_METHOD( "create_PackedFloat64Array", "array" ), &FlatBufferBuilder::CreatePackedArray< double > );
  // PACKED_STRING_ARRAY,
  ClassDB::bind_method( D_METHOD( "create_PackedStringArray", "array" ), &FlatBufferBuilder::CreatePackedStringArray );

  // PACKED_VECTOR2_ARRAY,
  // PACKED_VECTOR3_ARRAY,
  // PACKED_COLOR_ARRAY,
  // PACKED_VECTOR4_ARRAY,
}

FlatBufferBuilder::FlatBufferBuilder() {
  builder = std::make_unique< flatbuffers::FlatBufferBuilder >();
}

FlatBufferBuilder::FlatBufferBuilder( int size ) {
  builder = std::make_unique< flatbuffers::FlatBufferBuilder >( size );
}

void FlatBufferBuilder::Finish( const uint32_t root ) const {
  const Offset offset = root;
  builder->Finish( offset, nullptr );
}

godot::PackedByteArray FlatBufferBuilder::GetPackedByteArray() const {
  const int64_t size  = builder->GetSize();
  auto          bytes = godot::PackedByteArray();
  bytes.resize( size );
  std::memcpy( bytes.ptrw(), builder->GetBufferPointer(), size );
  return bytes;
}

// == Add Functions ==
void FlatBufferBuilder::AddOffset( const uint16_t voffset, const uint64_t value ) const {
  builder->AddOffset( voffset, Offset( value ) );
}


void FlatBufferBuilder::AddBytes( const uint16_t voffset, const godot::PackedByteArray &bytes ) const {
  if( bytes.is_empty() )
    return; // Default, don't store.
  builder->Align( bytes.size() );
  builder->PushBytes( bytes.ptr(), bytes.size() );
  builder->TrackField( voffset, builder->GetSize() );
}

// == Create Functions
FlatBufferBuilder::uoffset_t FlatBufferBuilder::CreateVectorOffset( const godot::PackedInt32Array &array ) const {
  builder->StartVector< Offset >( array.size() );
  for( auto i = array.size(); i > 0; ) {
    builder->PushElement( static_cast< Offset >(array[ --i ]) );
  }
  return builder->EndVector( array.size() );
}

FlatBufferBuilder::uoffset_t FlatBufferBuilder::CreateVectorTable(
    const godot::Array &   array,
    const godot::Callable &constructor ) const {
  builder->StartVector< Offset >( array.size() );
  for( auto i = array.size(); i > 0; ) {
    uoffset_t offset = constructor.call( array[ --i ] );
    enetheru::print( "c++: constructor.call = {0}", offset );
    builder->PushElement( static_cast< Offset >(offset) );
  }
  return builder->EndVector( array.size() );
}

FlatBufferBuilder::uoffset_t FlatBufferBuilder::CreatePackedStringArray( const godot::PackedStringArray &value ) const {
  std::vector< Offset > offsets( value.size() );
  for( int i = 0; i < value.size(); ++i ) {
    offsets[ i ] = CreateString( value[ i ] );
  }
  const uoffset_t offset = builder->CreateVector( offsets ).o;
  return offset;
}

FlatBufferBuilder::uoffset_t FlatBufferBuilder::
CreatePackedVector2Array( const godot::PackedVector2Array &value ) const {
  return 0;
  godot::PackedVector4Array values( value );
  values.ptrw();
}

FlatBufferBuilder::uoffset_t FlatBufferBuilder::CreateString( const godot::String &string ) const {
  const auto str = string.utf8();
  return builder->CreateString( str.ptr(), str.size() ).o;
}
} //end namespace
