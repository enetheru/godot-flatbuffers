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

  ClassDB::bind_method( D_METHOD( "clear" ), &Clear );
  ClassDB::bind_method( D_METHOD( "reset" ), &Reset );
  ClassDB::bind_method( D_METHOD( "finish", "table_offset" ), &Finish );
  ClassDB::bind_method( D_METHOD( "start_table" ), &StartTable );
  ClassDB::bind_method( D_METHOD( "end_table", "start" ), &EndTable );
  ClassDB::bind_method( D_METHOD( "get_size" ), &GetSize );
  ClassDB::bind_method( D_METHOD( "to_packed_byte_array" ), &GetPackedByteArray );

  // == Add functions ==
  ClassDB::bind_method( D_METHOD( "add_offset", "voffset", "value" ), &AddOffset );
  ClassDB::bind_method( D_METHOD( "add_bytes", "voffset", "value" ), &AddBytes );

  ClassDB::bind_method( D_METHOD( "add_element_bool", "voffset", "value" ), &AddScalar< bool, uint8_t > );
  ClassDB::bind_method( D_METHOD( "add_element_byte", "voffset", "value" ), &AddScalar< int64_t, int8_t > );
  ClassDB::bind_method( D_METHOD( "add_element_ubyte", "voffset", "value" ), &AddScalar< uint64_t, uint8_t > );
  ClassDB::bind_method( D_METHOD( "add_element_short", "voffset", "value" ), &AddScalar< int64_t, int16_t > );
  ClassDB::bind_method( D_METHOD( "add_element_ushort", "voffset", "value" ), &AddScalar< uint64_t, uint16_t > );
  ClassDB::bind_method( D_METHOD( "add_element_int", "voffset", "value" ), &AddScalar< int64_t, int32_t > );
  ClassDB::bind_method( D_METHOD( "add_element_uint", "voffset", "value" ), &AddScalar< uint64_t, uint32_t > );
  ClassDB::bind_method( D_METHOD( "add_element_long", "voffset", "value" ), &AddScalar< int64_t, int64_t > );
  ClassDB::bind_method( D_METHOD( "add_element_ulong", "voffset", "value" ), &AddScalar< uint64_t, uint64_t > );
  ClassDB::bind_method( D_METHOD( "add_element_float", "voffset", "value" ), &AddScalar< double, float > );
  ClassDB::bind_method( D_METHOD( "add_element_double", "voffset", "value" ), &AddScalar< double, double > );

  ClassDB::bind_method(
      D_METHOD( "add_element_bool_default", "voffset", "value", "default" ), &AddScalarDefault< bool, uint8_t > );
  ClassDB::bind_method(
      D_METHOD( "add_element_byte_default", "voffset", "value", "default" ), &AddScalarDefault< int64_t, int8_t > );
  ClassDB::bind_method(
      D_METHOD( "add_element_ubyte_default", "voffset", "value", "default" ), &AddScalarDefault< uint64_t, uint8_t > );
  ClassDB::bind_method(
      D_METHOD( "add_element_short_default", "voffset", "value", "default" ), &AddScalarDefault< int64_t, int16_t > );
  ClassDB::bind_method(
      D_METHOD( "add_element_ushort_default", "voffset", "value", "default" ),
      &AddScalarDefault< uint64_t, uint16_t > );
  ClassDB::bind_method(
      D_METHOD( "add_element_int_default", "voffset", "value", "default" ), &AddScalarDefault< int64_t, int32_t > );
  ClassDB::bind_method(
      D_METHOD( "add_element_uint_default", "voffset", "value", "default" ), &AddScalarDefault< uint64_t, uint32_t > );
  ClassDB::bind_method(
      D_METHOD( "add_element_long_default", "voffset", "value", "default" ), &AddScalarDefault< int64_t, int64_t > );
  ClassDB::bind_method(
      D_METHOD( "add_element_ulong_default", "voffset", "value", "default" ), &AddScalarDefault< uint64_t, uint64_t > );
  ClassDB::bind_method(
      D_METHOD( "add_element_float_default", "voffset", "value", "default" ), &AddScalarDefault< double, float > );
  ClassDB::bind_method(
      D_METHOD( "add_element_double_default", "voffset", "value", "default" ), &AddScalarDefault< double, double > );

  // == Create Functions ==
  ClassDB::bind_method( D_METHOD( "create_vector_offset", "array" ), &CreateVectorOffset );
  ClassDB::bind_method( D_METHOD( "create_vector_table", "array", "constructor" ), &CreateVectorTable );

  ClassDB::bind_method( D_METHOD( "create_vector_int8", "array" ), &CreatePackedArray< int8_t > );
  ClassDB::bind_method( D_METHOD( "create_vector_uint8", "array" ), &CreatePackedArray< uint8_t > );
  ClassDB::bind_method( D_METHOD( "create_vector_int16", "array" ), &CreatePackedArray< int16_t > );
  ClassDB::bind_method( D_METHOD( "create_vector_uint16", "array" ), &CreatePackedArray< uint16_t > );
  ClassDB::bind_method( D_METHOD( "create_vector_int32", "array" ), &CreatePackedArray< int32_t > );
  ClassDB::bind_method( D_METHOD( "create_vector_uint32", "array" ), &CreatePackedArray< uint32_t > );
  ClassDB::bind_method( D_METHOD( "create_vector_int64", "array" ), &CreatePackedArray< int64_t > );
  ClassDB::bind_method( D_METHOD( "create_vector_uint64", "array" ), &CreatePackedArray< uint64_t > );
  ClassDB::bind_method( D_METHOD( "create_vector_float32", "array" ), &CreatePackedArray< float > );
  ClassDB::bind_method( D_METHOD( "create_vector_float64", "array" ), &CreatePackedArray< double > );

  //// atomic types
  // BOOL,
  // INT,
  // FLOAT,
  // STRING,
  ClassDB::bind_method( D_METHOD( "create_String", "string" ), &CreateString );

  //// math types
  // VECTOR2,
  ClassDB::bind_method( D_METHOD( "add_Vector2", "voffset", "vector2" ), &AddGodotStruct< godot::Vector2 > );
  ClassDB::bind_method( D_METHOD( "create_Vector2", "vector2" ), &CreateGodotStruct< godot::Vector2 > );
  // VECTOR2I,
  ClassDB::bind_method( D_METHOD( "add_Vector2i", "voffset", "vector2i" ), &AddGodotStruct< godot::Vector2i > );
  ClassDB::bind_method( D_METHOD( "create_Vector2i", "vector2i" ), &CreateGodotStruct< godot::Vector2i > );
  // RECT2,
  ClassDB::bind_method( D_METHOD( "add_Rect2", "rect2", "quaternion" ), &AddGodotStruct< godot::Rect2 > );
  ClassDB::bind_method( D_METHOD( "create_Rect2", "rect2" ), &CreateGodotStruct< godot::Rect2 > );
  // RECT2I,
  ClassDB::bind_method( D_METHOD( "add_Rect2i", "rect2i", "quaternion" ), &AddGodotStruct< godot::Rect2i > );
  ClassDB::bind_method( D_METHOD( "create_Rect2i", "rect2i" ), &CreateGodotStruct< godot::Rect2i > );
  // VECTOR3,
  ClassDB::bind_method( D_METHOD( "add_Vector3", "voffset", "vector3" ), &AddGodotStruct< godot::Vector3 > );
  ClassDB::bind_method( D_METHOD( "create_Vector3", "vector3" ), &CreateGodotStruct< godot::Vector3 > );
  // VECTOR3I,
  ClassDB::bind_method( D_METHOD( "add_Vector3i", "voffset", "vector3i" ), &AddGodotStruct< godot::Vector3i > );
  ClassDB::bind_method( D_METHOD( "create_Vector3i", "vector3i" ), &CreateGodotStruct< godot::Vector3i > );
  // TRANSFORM2D,
  ClassDB::bind_method(
      D_METHOD( "add_Transform2D", "voffset", "transform2d" ), &AddGodotStruct< godot::Transform2D > );
  ClassDB::bind_method( D_METHOD( "create_Transform2D", "transform2d" ), &CreateGodotStruct< godot::Transform2D > );
  // VECTOR4,
  ClassDB::bind_method( D_METHOD( "add_Vector4", "voffset", "vector4" ), &AddGodotStruct< godot::Vector4 > );
  ClassDB::bind_method( D_METHOD( "create_Vector4", "vector4" ), &CreateGodotStruct< godot::Vector4 > );
  // VECTOR4I,
  ClassDB::bind_method( D_METHOD( "add_Vector4i", "voffset", "vector4i" ), &AddGodotStruct< godot::Vector4i > );
  ClassDB::bind_method( D_METHOD( "create_Vector4i", "vector4i" ), &CreateGodotStruct< godot::Vector4i > );
  // PLANE,
  ClassDB::bind_method( D_METHOD( "add_Plane", "voffset", "plane" ), &AddGodotStruct< godot::Plane > );
  ClassDB::bind_method( D_METHOD( "create_Plane", "plane" ), &CreateGodotStruct< godot::Plane > );
  // QUATERNION,
  ClassDB::bind_method( D_METHOD( "add_Quaternion", "voffset", "quaternion" ), &AddGodotStruct< godot::Quaternion > );
  ClassDB::bind_method( D_METHOD( "create_Quaternion", "quaternion" ), &CreateGodotStruct< godot::Quaternion > );
  // AABB,
  ClassDB::bind_method( D_METHOD( "add_AABB", "voffset", "aabb" ), &AddGodotStruct< godot::AABB > );
  ClassDB::bind_method( D_METHOD( "create_AABB", "aabb" ), &CreateGodotStruct< godot::AABB > );
  // BASIS,
  ClassDB::bind_method( D_METHOD( "add_Basis", "basis" ), &AddGodotStruct< godot::Basis > );
  ClassDB::bind_method( D_METHOD( "create_Basis", "basis" ), &CreateGodotStruct< godot::Basis > );
  // TRANSFORM3D,
  ClassDB::bind_method(
      D_METHOD( "add_Transform3D", "voffset", "transform3d" ), &AddGodotStruct< godot::Transform3D > );
  ClassDB::bind_method( D_METHOD( "create_Transform3D", "transform3d" ), &CreateGodotStruct< godot::Transform3D > );
  // PROJECTION,
  ClassDB::bind_method( D_METHOD( "add_Projection", "voffset", "projection" ), &AddGodotStruct< godot::Projection > );
  ClassDB::bind_method( D_METHOD( "create_Projection", "projection" ), &CreateGodotStruct< godot::Projection > );

  //// misc types
  // COLOR,
  ClassDB::bind_method( D_METHOD( "add_Color", "color" ), &AddGodotStruct< godot::Color > );
  ClassDB::bind_method( D_METHOD( "create_Color", "color" ), &CreateGodotStruct< godot::Color > );
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
  ClassDB::bind_method( D_METHOD( "create_PackedByteArray", "array" ), &CreatePackedArray< uint8_t > );
  // PACKED_INT32_ARRAY,
  ClassDB::bind_method( D_METHOD( "create_PackedInt32Array", "array" ), &CreatePackedArray< uint32_t > );
  // PACKED_INT64_ARRAY,
  ClassDB::bind_method( D_METHOD( "create_PackedInt64Array", "array" ), &CreatePackedArray< uint64_t > );
  // PACKED_FLOAT32_ARRAY,
  ClassDB::bind_method( D_METHOD( "create_PackedFloat32Array", "array" ), &CreatePackedArray< float > );
  // PACKED_FLOAT64_ARRAY,
  ClassDB::bind_method( D_METHOD( "create_PackedFloat64Array", "array" ), &CreatePackedArray< double > );
  // PACKED_STRING_ARRAY,
  ClassDB::bind_method( D_METHOD( "create_PackedStringArray", "array" ), &CreatePackedStringArray );

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

FlatBufferBuilder::uoffset_t FlatBufferBuilder::CreateString( const godot::String &string ) const {
  const auto str = string.utf8();
  return builder->CreateString( str.ptr(), str.size() ).o;
}
} //end namespace
