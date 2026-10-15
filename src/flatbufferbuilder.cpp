#include "flatbufferbuilder.hpp"
#include <godot_cpp/core/binder_common.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include "flatbuffer.hpp"

#include <algorithm>
#include <vector>

VARIANT_ENUM_CAST(godot_flatbuffers::FlatBufferBuilder::KeyKind);

/*
 * Flatbuffer Builder wrapper for gdscript
 */
namespace godot_flatbuffers {
void FlatBufferBuilder::_bind_methods() {
  // using namespace godot;
  using godot::ClassDB;
  using godot::D_METHOD;

  ClassDB::bind_static_method("FlatBufferBuilder", D_METHOD("create", "size"), &Create, 1024);

  ClassDB::bind_method(D_METHOD("clear"), &FlatBufferBuilder::Clear);
  ClassDB::bind_method(D_METHOD("reset"), &FlatBufferBuilder::Reset);
  ClassDB::bind_method(D_METHOD("finish", "table_offset", "file_identifier"), &FlatBufferBuilder::Finish, "");
  ClassDB::bind_method(D_METHOD("start_table"), &FlatBufferBuilder::StartTable);
  ClassDB::bind_method(D_METHOD("end_table", "start"), &FlatBufferBuilder::EndTable);
  ClassDB::bind_method(D_METHOD("required", "table", "field"), &FlatBufferBuilder::Required);
  ClassDB::bind_method(D_METHOD("get_size"), &FlatBufferBuilder::GetSize);
  ClassDB::bind_method(D_METHOD("get_buffer"), &FlatBufferBuilder::GetPackedByteArray);

  // MARK: Create
  //  │  ___              _          [br]
  //  │ / __|_ _ ___ __ _| |_ ___    [br]
  //  │| (__| '_/ -_) _` |  _/ -_)   [br]
  //  │ \___|_| \___\__,_|\__\___|   [br]
  //  ╰───────────────────────────── [br]
  //  Create is used when the data is offset from the table or struct or vector.

  ClassDB::bind_method(
          D_METHOD("create_variant", "value", "type"), &FlatBufferBuilder::CreateVariant,
          godot::Variant::Type::VARIANT_MAX);

  // == Create Vectors of Offset(uint32_t) ==
  ClassDB::bind_method(D_METHOD("create_vector_offset", "array"), &FlatBufferBuilder::CreateVectorOfOffset);
  ClassDB::bind_method(
          D_METHOD("create_vector_of_sorted_tables", "offsets", "key_field", "key_kind", "key_default"),
          &FlatBufferBuilder::CreateVectorOfSortedTables);
  BIND_ENUM_CONSTANT(KEY_STRING);
  BIND_ENUM_CONSTANT(KEY_BOOL);
  BIND_ENUM_CONSTANT(KEY_BYTE);
  BIND_ENUM_CONSTANT(KEY_UBYTE);
  BIND_ENUM_CONSTANT(KEY_SHORT);
  BIND_ENUM_CONSTANT(KEY_USHORT);
  BIND_ENUM_CONSTANT(KEY_INT);
  BIND_ENUM_CONSTANT(KEY_UINT);
  BIND_ENUM_CONSTANT(KEY_LONG);
  BIND_ENUM_CONSTANT(KEY_ULONG);
  BIND_ENUM_CONSTANT(KEY_FLOAT);
  BIND_ENUM_CONSTANT(KEY_DOUBLE);

  // == Create Vectors of Scalars ==
  ClassDB::bind_method(D_METHOD("create_vector_int8", "array"), &FlatBufferBuilder::CreateVectorOfScalar< int8_t >);
  ClassDB::bind_method(D_METHOD("create_vector_uint8", "array"), &FlatBufferBuilder::CreateVectorOfScalar< uint8_t >);
  ClassDB::bind_method(D_METHOD("create_vector_int16", "array"), &FlatBufferBuilder::CreateVectorOfScalar< int16_t >);
  ClassDB::bind_method(D_METHOD("create_vector_uint16", "array"), &FlatBufferBuilder::CreateVectorOfScalar< uint16_t >);
  ClassDB::bind_method(D_METHOD("create_vector_int32", "array"), &FlatBufferBuilder::CreateVectorOfScalar< int32_t >);
  ClassDB::bind_method(D_METHOD("create_vector_uint32", "array"), &FlatBufferBuilder::CreateVectorOfScalar< uint32_t >);
  ClassDB::bind_method(D_METHOD("create_vector_int64", "array"), &FlatBufferBuilder::CreateVectorOfScalar< int64_t >);
  ClassDB::bind_method(D_METHOD("create_vector_uint64", "array"), &FlatBufferBuilder::CreateVectorOfScalar< uint64_t >);
  ClassDB::bind_method(D_METHOD("create_vector_float32", "array"), &FlatBufferBuilder::CreateVectorOfScalar< float >);
  ClassDB::bind_method(D_METHOD("create_vector_float64", "array"), &FlatBufferBuilder::CreateVectorOfScalar< double >);


  ClassDB::bind_method(
          D_METHOD("create_vector_of_custom_struct", "array", "element_size"),
          &FlatBufferBuilder::CreateVectorOfCustomStructs);

  ClassDB::bind_method(
          D_METHOD("create_vector_of_table", "array", "create_func"),
          &FlatBufferBuilder::CreateVectorOfTable);

  ClassDB::bind_method(
          D_METHOD("create_vector_of_union", "array", "create_func"),
          &FlatBufferBuilder::CreateVectorOfUnion);

  // MARK: Add
  //  │   _      _    _    [br]
  //  │  /_\  __| |__| |   [br]
  //  │ / _ \/ _` / _` |   [br]
  //  │/_/ \_\__,_\__,_|   [br]
  //  ╰─────────────────── [br]
  //  Add is used when the data is inline with the table or struct

  // == Add functions ==
  ClassDB::bind_method(D_METHOD("add_offset", "voffset", "value"), &FlatBufferBuilder::AddOffset);
  ClassDB::bind_method(D_METHOD("add_bytes", "voffset", "value"), &FlatBufferBuilder::AddBytes);

  ClassDB::bind_method(
          D_METHOD("add_element_bool", "voffset", "value"), &FlatBufferBuilder::AddScalar< bool, uint8_t >);
  ClassDB::bind_method(
          D_METHOD("add_element_byte", "voffset", "value"), &FlatBufferBuilder::AddScalar< int64_t, int8_t >);
  ClassDB::bind_method(
          D_METHOD("add_element_ubyte", "voffset", "value"), &FlatBufferBuilder::AddScalar< uint64_t, uint8_t >);
  ClassDB::bind_method(
          D_METHOD("add_element_short", "voffset", "value"), &FlatBufferBuilder::AddScalar< int64_t, int16_t >);
  ClassDB::bind_method(
          D_METHOD("add_element_ushort", "voffset", "value"), &FlatBufferBuilder::AddScalar< uint64_t, uint16_t >);
  ClassDB::bind_method(
          D_METHOD("add_element_int", "voffset", "value"), &FlatBufferBuilder::AddScalar< int64_t, int32_t >);
  ClassDB::bind_method(
          D_METHOD("add_element_uint", "voffset", "value"), &FlatBufferBuilder::AddScalar< uint64_t, uint32_t >);
  ClassDB::bind_method(
          D_METHOD("add_element_long", "voffset", "value"), &FlatBufferBuilder::AddScalar< int64_t, int64_t >);
  ClassDB::bind_method(
          D_METHOD("add_element_ulong", "voffset", "value"), &FlatBufferBuilder::AddScalar< uint64_t, uint64_t >);
  ClassDB::bind_method(
          D_METHOD("add_element_float", "voffset", "value"), &FlatBufferBuilder::AddScalar< double, float >);
  ClassDB::bind_method(
          D_METHOD("add_element_double", "voffset", "value"), &FlatBufferBuilder::AddScalar< double, double >);

  ClassDB::bind_method(
          D_METHOD("add_element_bool_default", "voffset", "value", "default"),
          &FlatBufferBuilder::AddScalar< bool, uint8_t, true >);
  ClassDB::bind_method(
          D_METHOD("add_element_byte_default", "voffset", "value", "default"),
          &FlatBufferBuilder::AddScalar< int64_t, int8_t, true >);
  ClassDB::bind_method(
          D_METHOD("add_element_ubyte_default", "voffset", "value", "default"),
          &FlatBufferBuilder::AddScalar< uint64_t, uint8_t, true >);
  ClassDB::bind_method(
          D_METHOD("add_element_short_default", "voffset", "value", "default"),
          &FlatBufferBuilder::AddScalar< int64_t, int16_t, true >);
  ClassDB::bind_method(
          D_METHOD("add_element_ushort_default", "voffset", "value", "default"),
          &FlatBufferBuilder::AddScalar< uint64_t, uint16_t, true >);
  ClassDB::bind_method(
          D_METHOD("add_element_int_default", "voffset", "value", "default"),
          &FlatBufferBuilder::AddScalar< int64_t, int32_t, true >);
  ClassDB::bind_method(
          D_METHOD("add_element_uint_default", "voffset", "value", "default"),
          &FlatBufferBuilder::AddScalar< uint64_t, uint32_t, true >);
  ClassDB::bind_method(
          D_METHOD("add_element_long_default", "voffset", "value", "default"),
          &FlatBufferBuilder::AddScalar< int64_t, int64_t, true >);
  ClassDB::bind_method(
          D_METHOD("add_element_ulong_default", "voffset", "value", "default"),
          &FlatBufferBuilder::AddScalar< uint64_t, uint64_t, true >);
  ClassDB::bind_method(
          D_METHOD("add_element_float_default", "voffset", "value", "default"),
          &FlatBufferBuilder::AddScalar< double, float, true >);
  ClassDB::bind_method(
          D_METHOD("add_element_double_default", "voffset", "value", "default"),
          &FlatBufferBuilder::AddScalar< double, double, true >);

  // Convenience functo to add or create godot type's
  ClassDB::bind_method(
          D_METHOD("add_variant", "voffset", "value", "type"), &FlatBufferBuilder::AddGodotVariant,
          godot::Variant::Type::VARIANT_MAX);
}

FlatBufferBuilder::FlatBufferBuilder() { builder = std::make_unique< flatbuffers::FlatBufferBuilder >(); }

FlatBufferBuilder::FlatBufferBuilder(int size) { builder = std::make_unique< flatbuffers::FlatBufferBuilder >(size); }

bool FlatBufferBuilder::Required(
        const uoffset_t table_offset, const flatbuffers::voffset_t field_offset) const {
  // FlatBufferBuilder::Required asserts, and that assert is compiled out of
  // Release. Report the miss and let the generated finish() return 0.
  if (table_offset == 0 || table_offset > builder->GetSize()) {
    ERR_FAIL_V_MSG(false, "Required field check was given a bad table offset.");
  }
  const uint8_t *base = builder->GetCurrentBufferPointer();
  const auto *table_ptr = reinterpret_cast<const flatbuffers::Table *>(
      base + static_cast<flatbuffers::uoffset_t>(builder->GetSize() - table_offset));
  const bool present = table_ptr->GetOptionalFieldOffset(field_offset) != 0;
  ERR_FAIL_COND_V_MSG(
      !present, false, "A required field was not set before the table was finished.");
  return true;
}


void FlatBufferBuilder::Finish(const uint32_t root, const godot::String &file_identifier) const {
  const Offset offset = root;
  if (file_identifier.is_empty()) {
    builder->Finish(offset, nullptr);
    return;
  }
  const godot::CharString utf8 = file_identifier.utf8();
  ERR_FAIL_COND_MSG(
      utf8.length() != flatbuffers::kFileIdentifierLength,
      "file_identifier must be exactly 4 characters");
  builder->Finish(offset, utf8.get_data());
}

godot::PackedByteArray FlatBufferBuilder::GetPackedByteArray() const {
  const int64_t size  = builder->GetSize();
  auto          bytes = godot::PackedByteArray();
  bytes.resize(size);
  std::memcpy(bytes.ptrw(), builder->GetBufferPointer(), size);
  return bytes;
}

FlatBufferBuilder::uoffset_t FlatBufferBuilder::CreateVariant(
        const godot::Variant &value, godot::Variant::Type expected_type = godot::Variant::Type::VARIANT_MAX) const {

  if( expected_type == godot::Variant::Type::VARIANT_MAX ) {
    expected_type = value.get_type();
  } else {
    ERR_FAIL_COND_V_MSG(expected_type != value.get_type(),0, godot::vformat(
      "given type(%s) does not match expected type(%s)",
      godot::Variant::get_type_name(expected_type),
      godot::Variant::get_type_name(value.get_type()) ));
  }


  switch( expected_type ) {
    case godot::Variant::NIL:
      break;
    case godot::Variant::BOOL: {
      ERR_FAIL_V_MSG(
              0, "Invalid type(bool) given as value. Only structs, tables, and vector"
                 " are allowed. You probably want to use add_variant instead.");
    }
    case godot::Variant::INT: {
      ERR_FAIL_V_MSG(
              0, "Invalid type(int) given as value. Only structs, tables, and vector"
                 " are allowed. You probably want to use add_variant instead.");
    }
    case godot::Variant::FLOAT: {
      ERR_FAIL_V_MSG(
              0, "Invalid type(float) given as value. Only structs, tables, and"
                 " vector are allowed. You probably want to use add_variant instead.");
    }
    case godot::Variant::STRING: {
      const auto v   = static_cast< godot::String >(value);
      const auto str = v.utf8();
      return builder->CreateString(str.ptr(), str.length()).o;
    }
    case godot::Variant::VECTOR2: {
      const auto v = static_cast< godot::Vector2 >(value);
      return builder->CreateStruct(&v).o;
    }
    case godot::Variant::VECTOR2I: {
      const auto v = static_cast< godot::Vector2i >(value);
      return builder->CreateStruct(&v).o;
    }
    case godot::Variant::RECT2: {
      const auto v = static_cast< godot::Rect2 >(value);
      return builder->CreateStruct(&v).o;
    }
    case godot::Variant::RECT2I: {
      const auto v = static_cast< godot::Rect2i >(value);
      return builder->CreateStruct(&v).o;
    }
    case godot::Variant::VECTOR3: {
      const auto v = static_cast< godot::Vector3 >(value);
      return builder->CreateStruct(&v).o;
    }
    case godot::Variant::VECTOR3I: {
      const auto v = static_cast< godot::Vector3i >(value);
      return builder->CreateStruct(&v).o;
    }
    case godot::Variant::TRANSFORM2D: {
      const auto v = static_cast< godot::Transform2D >(value);
      return builder->CreateStruct(&v).o;
    }
    case godot::Variant::VECTOR4: {
      const auto v = static_cast< godot::Vector4 >(value);
      return builder->CreateStruct(&v).o;
    }
    case godot::Variant::VECTOR4I: {
      const auto v = static_cast< godot::Vector4i >(value);
      return builder->CreateStruct(&v).o;
    }
    case godot::Variant::PLANE: {
      const auto v = static_cast< godot::Plane >(value);
      return builder->CreateStruct(&v).o;
    }
    case godot::Variant::QUATERNION: {
      const auto v = static_cast< godot::Quaternion >(value);
      return builder->CreateStruct(&v).o;
    }
    case godot::Variant::AABB: {
      const auto v = static_cast< godot::AABB >(value);
      return builder->CreateStruct(&v).o;
    }
    case godot::Variant::BASIS: {
      const auto v = static_cast< godot::Basis >(value);
      return builder->CreateStruct(&v).o;
    }
    case godot::Variant::TRANSFORM3D: {
      const auto v = static_cast< godot::Transform3D >(value);
      return builder->CreateStruct(&v).o;
    }
    case godot::Variant::PROJECTION: {
      const auto v = static_cast< godot::Projection >(value);
      return builder->CreateStruct(&v).o;
    }
    case godot::Variant::COLOR: {
      const auto v = static_cast< godot::Color >(value);
      return builder->CreateStruct(&v).o;
    }
    case godot::Variant::STRING_NAME: {
      const godot::String v   = static_cast< godot::StringName >(value);
      const auto          str = v.utf8();
      return builder->CreateString(str.ptr(), str.length()).o;
    }
    case godot::Variant::NODE_PATH: {
      const godot::String v   = static_cast< godot::NodePath >(value);
      const auto          str = v.utf8();
      return builder->CreateString(str.ptr(), str.length()).o;
    }
    case godot::Variant::RID: {
      ERR_FAIL_V_MSG(0, "Unsupported type(RID) given as value.");
    }
    case godot::Variant::OBJECT: {
      ERR_FAIL_V_MSG(0, "TODO: Objects can be tables, or structs");
    }
    case godot::Variant::CALLABLE: {
      ERR_FAIL_V_MSG(0, "Unsupported type(Callable) given as value.");
    }
    case godot::Variant::SIGNAL: {
      ERR_FAIL_V_MSG(0, "Unsupported type(Signal) given as value.");
    }
    case godot::Variant::DICTIONARY: {
      const auto v = static_cast< godot::Dictionary >(value);
      ERR_FAIL_V_MSG(0, "Unsupported type(Dictionary) given as value.");
    }
    case godot::Variant::ARRAY: {
      const auto v = static_cast< godot::Array >(value);
      ERR_FAIL_V_MSG(0, "Unsupported type(Array) given as value.");
    }
    case godot::Variant::PACKED_BYTE_ARRAY: {
      const auto v = static_cast< godot::PackedByteArray >(value);
      builder->StartVector< uint8_t >(v.size());
      for( auto i = v.size(); i > 0; ) {
        builder->PushElement(v[ --i ]);
      }
      return builder->EndVector(v.size());
    }
    case godot::Variant::PACKED_INT32_ARRAY: {
      const auto v = static_cast< godot::PackedInt32Array >(value);
      builder->StartVector< int32_t >(v.size());
      for( auto i = v.size(); i > 0; ) {
        builder->PushElement(v[ --i ]);
      }
      return builder->EndVector(v.size());
    }
    case godot::Variant::PACKED_INT64_ARRAY: {
      const auto v = static_cast< godot::PackedInt64Array >(value);
      builder->StartVector< int64_t >(v.size());
      for( auto i = v.size(); i > 0; ) {
        builder->PushElement(v[ --i ]);
      }
      return builder->EndVector(v.size());
    }
    case godot::Variant::PACKED_FLOAT32_ARRAY: {
      const auto v = static_cast< godot::PackedFloat32Array >(value);
      builder->StartVector< float >(v.size());
      for( auto i = v.size(); i > 0; ) {
        builder->PushElement(v[ --i ]);
      }
      return builder->EndVector(v.size());
    }
    case godot::Variant::PACKED_FLOAT64_ARRAY: {
      const auto v = static_cast< godot::PackedFloat64Array >(value);
      builder->StartVector< double >(v.size());
      for( auto i = v.size(); i > 0; ) {
        builder->PushElement(v[ --i ]);
      }
      return builder->EndVector(v.size());
    }
    case godot::Variant::PACKED_STRING_ARRAY: {
      const auto            v = static_cast< godot::PackedStringArray >(value);
      std::vector< Offset > offsets(v.size());
      for( int i = 0; i < v.size(); ++i ) {
        const auto str = v[ i ].utf8();
        offsets[ i ]   = builder->CreateString(str.ptr(), str.length()).o;
      }
      const uoffset_t offset = builder->CreateVector(offsets).o;
      return offset;
    }
    case godot::Variant::PACKED_VECTOR2_ARRAY: {
      const auto v = static_cast< godot::PackedVector2Array >(value);
      return builder->CreateVectorOfStructs(v.ptr(), v.size()).o;
    }
    case godot::Variant::PACKED_VECTOR3_ARRAY: {
      const auto v = static_cast< godot::PackedVector3Array >(value);
      return builder->CreateVectorOfStructs(v.ptr(), v.size()).o;
    }
    case godot::Variant::PACKED_COLOR_ARRAY: {
      const auto v = static_cast< godot::PackedColorArray >(value);
      return builder->CreateVectorOfStructs(v.ptr(), v.size()).o;
    }
    case godot::Variant::PACKED_VECTOR4_ARRAY: {
      const auto v = static_cast< godot::PackedVector4Array >(value);
      return builder->CreateVectorOfStructs(v.ptr(), v.size()).o;
    }
    case godot::Variant::VARIANT_MAX:
      break;
  }
  ERR_FAIL_V_MSG(0, "This should be impossible.");
}


// == Create Functions
FlatBufferBuilder::uoffset_t FlatBufferBuilder::CreateVectorOfOffset(const godot::PackedInt32Array &array) const {
  builder->StartVector< Offset >(array.size());
  for( auto i = array.size(); i > 0; ) {
    builder->PushElement(static_cast< Offset >(array[ --i ]));
  }
  return builder->EndVector(array.size());
}


FlatBufferBuilder::uoffset_t FlatBufferBuilder::CreateVectorOfSortedTables(
        const godot::PackedInt32Array &offsets, int key_field, int key_kind,
        const godot::Variant &key_default) const {
  if (key_field < 0 || key_field > 0xFFFF || key_kind < KEY_STRING || key_kind > KEY_DOUBLE) {
    ERR_FAIL_V_MSG(0, "sorted table vector was given a bad field or key kind.");
  }
  const auto buf_size = builder->GetSize();
  std::vector< uoffset_t > ordered;
  ordered.reserve(static_cast< size_t >(offsets.size()));
  for (int64_t i = 0; i < offsets.size(); ++i) {
    const int64_t raw = offsets[ i ];
    if (raw <= 0 || static_cast< uint64_t >(raw) > buf_size) {
      ERR_FAIL_V_MSG(0, "sorted table vector was given an offset that is not a table.");
    }
    ordered.push_back(static_cast< uoffset_t >(raw));
  }

  // Offsets are distances from the buffer end. Same formula as Required().
  const auto table_at = [&](uoffset_t offset) -> const flatbuffers::Table * {
    return reinterpret_cast< const flatbuffers::Table * >(
            builder->GetCurrentBufferPointer() + (builder->GetSize() - offset));
  };
  std::stable_sort(ordered.begin(), ordered.end(), [&](uoffset_t a, uoffset_t b) {
    return compare_tables_by_key(table_at(a), table_at(b), key_field, key_kind, key_default) < 0;
  });

  builder->StartVector< Offset >(ordered.size());
  for (auto i = ordered.size(); i > 0;) {
    builder->PushElement(static_cast< Offset >(ordered[ --i ]));
  }
  return builder->EndVector(ordered.size());
}


FlatBufferBuilder::uoffset_t
FlatBufferBuilder::CreateVectorOfCustomStructs(const godot::Array &value, const size_t elem_size) const {
  const size_t num_elements = value.size();
  uint8_t     *buf;
  const auto   offset =
          builder->CreateUninitializedVector(num_elements, elem_size, flatbuffers::AlignOf< uoffset_t >(), &buf);

  // Now we have the raw buffer we can paste our objects into it.
  // There are going to be two types of objects. the well defined godot ones, and the custom ones made from byte arrays.
  // this should allow me to write arbitrary data into the buffer of any type. But its not very satisfying.
  // For now I will ignore builtin ones, because they are sort of handled by the packed byte arrays.
  // Holy shitballs it works first try.
  for( godot::Object *v : value ) {
    const FlatBuffer      *fb    = Object::cast_to< FlatBuffer >(v);
    godot::PackedByteArray bytes = fb->get_bytes();
    std::memcpy(buf, bytes.ptrw(), std::min(elem_size, static_cast< size_t >(bytes.size())));
    buf += elem_size;
  }
  return offset;
}


FlatBufferBuilder::uoffset_t
FlatBufferBuilder::CreateVectorOfTable(const godot::Array &array, const godot::Callable &creator_func) const {
  std::vector< uint32_t > offsets(array.size());
  for( int i = 0; i < array.size(); ++i ) {
    offsets[ i ] = creator_func.call(this, array[ i ]);
  }
  // add the vector of table offsets to the builder and return its offset.
  builder->StartVector< Offset >(offsets.size());
  for( auto i = array.size(); i > 0; ) {
    builder->PushElement(static_cast< Offset >(offsets[ --i ]));
  }
  return builder->EndVector(array.size());
}


// Takes an array and a callable that packs each union into an offset and a type.
// An empty array is still two vectors of length 0. Offset 0 would leave the
// fields absent, which is a different buffer than a present empty vector.
godot::PackedInt32Array
FlatBufferBuilder::CreateVectorOfUnion(const godot::Array &array, const godot::Callable &creator_func) const {
  ERR_FAIL_COND_V_MSG(creator_func.get_argument_count() < 2, {},
      godot::vformat( "The Callable takes %s arguments, it must take at least two.",
          creator_func.get_argument_count()));

  std::vector< uint32_t > value_offsets(array.size());
  std::vector< uint8_t > type_offsets(array.size());
  // FIXME, union value type may be different than uint8_t

  if (array.size() != 0) {
    auto check_variant = creator_func.call(this, array[0]);
    ERR_FAIL_COND_V_MSG(check_variant.get_type() != godot::Variant::Type::PACKED_INT32_ARRAY,
      {}, godot::vformat( "The callable returned (%s) instead of a PackedInt32Array",
        godot::Variant::get_type_name(check_variant.get_type()) ));
    const godot::PackedInt32Array *check_array = godot::VariantInternal::get_int32_array(&check_variant);
    ERR_FAIL_COND_V_MSG(check_array->size() != 2, {}, "callable result must contain exactly two elements( offset, type ) ");

    for( int i = 0; i < array.size(); ++i ) {
      auto temp = creator_func.call(this, array[ i ]);
      godot::PackedInt32Array *func_ret = godot::VariantInternal::get_int32_array(&temp);
      value_offsets[i] = (*func_ret)[0];
      type_offsets[i] = (*func_ret)[1];
    }
  }

  // add the vector of table offsets to the builder and return its offset.
  builder->StartVector< Offset >(value_offsets.size());
  for( auto i = array.size(); i > 0; ) {
    builder->PushElement(static_cast< Offset >(value_offsets[ --i ]));
  }

  godot::PackedInt32Array ret{0,0};
  ret[0] = builder->EndVector(array.size());
  ret[1] = builder->CreateVector(type_offsets).o;
  return ret;
}

// == Add Functions ==
void FlatBufferBuilder::AddBytes(const uint16_t voffset, const godot::PackedByteArray &bytes) const {
  if( bytes.is_empty() ) {
    return; // Default, don't store.
  }
  builder->Align(bytes.size());
  builder->PushBytes(bytes.ptr(), bytes.size());
  builder->TrackField(voffset, builder->GetSize());
}


void FlatBufferBuilder::AddGodotVariant(
        uint16_t voffset, const godot::Variant &value,
        godot::Variant::Type expected_type = godot::Variant::Type::VARIANT_MAX) const {
  if( expected_type == godot::Variant::Type::VARIANT_MAX ) {
    expected_type = value.get_type();
  } else {
    ERR_FAIL_COND_MSG(expected_type != value.get_type(), godot::vformat(
      "given type(%s) does not match expected type(%s)",
      godot::Variant::get_type_name(expected_type),
      godot::Variant::get_type_name(value.get_type()) ));

  }

  switch( expected_type ) {
    case godot::Variant::NIL:
      break;
    case godot::Variant::BOOL: {
      builder->AddElement< bool >(voffset, value);
      break;
    }
    case godot::Variant::INT: {
      builder->AddElement< int64_t >(voffset, value);
      break;
    }
    case godot::Variant::FLOAT: {
      builder->AddElement< double >(voffset, value);
      break;
    }
    case godot::Variant::STRING: {
      ERR_FAIL_MSG(
              "Invalid type(String) given as value. Only offsets, scalars, structs, and fixed arrays are allowed."
              "You probably forgot to create the String ahead of time to get its offset which you would add here.");
    }
    case godot::Variant::VECTOR2: {
      const auto v = static_cast< godot::Vector2 >(value);
      builder->AddStruct(voffset, &v);
      break;
    }
    case godot::Variant::VECTOR2I: {
      const auto v = static_cast< godot::Vector2i >(value);
      builder->AddStruct(voffset, &v);
      break;
    }
    case godot::Variant::RECT2: {
      const auto v = static_cast< godot::Rect2 >(value);
      builder->AddStruct(voffset, &v);
      break;
    }
    case godot::Variant::RECT2I: {
      const auto v = static_cast< godot::Rect2i >(value);
      builder->AddStruct(voffset, &v);
      break;
    }
    case godot::Variant::VECTOR3: {
      const auto v = static_cast< godot::Vector3 >(value);
      builder->AddStruct(voffset, &v);
      break;
    }
    case godot::Variant::VECTOR3I: {
      const auto v = static_cast< godot::Vector3i >(value);
      builder->AddStruct(voffset, &v);
      break;
    }
    case godot::Variant::TRANSFORM2D: {
      const auto v = static_cast< godot::Transform2D >(value);
      builder->AddStruct(voffset, &v);
      break;
    }
    case godot::Variant::VECTOR4: {
      const auto v = static_cast< godot::Vector4 >(value);
      builder->AddStruct(voffset, &v);
      break;
    }
    case godot::Variant::VECTOR4I: {
      const auto v = static_cast< godot::Vector4i >(value);
      builder->AddStruct(voffset, &v);
      break;
    }
    case godot::Variant::PLANE: {
      const auto v = static_cast< godot::Plane >(value);
      builder->AddStruct(voffset, &v);
      break;
    }
    case godot::Variant::QUATERNION: {
      const auto v = static_cast< godot::Quaternion >(value);
      builder->AddStruct(voffset, &v);
      break;
    }
    case godot::Variant::AABB: {
      const auto v = static_cast< godot::AABB >(value);
      builder->AddStruct(voffset, &v);
      break;
    }
    case godot::Variant::BASIS: {
      const auto v = static_cast< godot::Basis >(value);
      builder->AddStruct(voffset, &v);
      break;
    }
    case godot::Variant::TRANSFORM3D: {
      const auto v = static_cast< godot::Transform3D >(value);
      builder->AddStruct(voffset, &v);
      break;
    }
    case godot::Variant::PROJECTION: {
      const auto v = static_cast< godot::Projection >(value);
      builder->AddStruct(voffset, &v);
      break;
    }
    case godot::Variant::COLOR: {
      const auto v = static_cast< godot::Color >(value);
      builder->AddStruct(voffset, &v);
      break;
    }
    case godot::Variant::STRING_NAME: {
      ERR_FAIL_MSG(
              "Invalid type(StringName) given as value. Only offsets, scalars, structs, and fixed arrays are allowed."
              "You probably forgot to create the StringName ahead of time to get its offset which you would add here.");
    }
    case godot::Variant::NODE_PATH: {
      ERR_FAIL_MSG(
              "Invalid type(NodePath) given as value. Only offsets, scalars, structs, and fixed arrays are allowed."
              "You probably forgot to create the NodePath ahead of time to get its offset which you would add here.");
    }
    case godot::Variant::RID: {
      ERR_FAIL_MSG("Unsupported type(RID) given as value.");
    }
    case godot::Variant::OBJECT:
      break;
    case godot::Variant::CALLABLE: {
      ERR_FAIL_MSG("Unsupported type(Callable) given as value.");
    }
    case godot::Variant::SIGNAL: {
      ERR_FAIL_MSG("Unsupported type(Signal) given as value.");
    }
    case godot::Variant::DICTIONARY:
    case godot::Variant::ARRAY:
    case godot::Variant::PACKED_BYTE_ARRAY:
    case godot::Variant::PACKED_INT32_ARRAY:
    case godot::Variant::PACKED_INT64_ARRAY:
    case godot::Variant::PACKED_FLOAT32_ARRAY:
    case godot::Variant::PACKED_FLOAT64_ARRAY:
    case godot::Variant::PACKED_STRING_ARRAY:
    case godot::Variant::PACKED_VECTOR2_ARRAY:
    case godot::Variant::PACKED_VECTOR3_ARRAY:
    case godot::Variant::PACKED_COLOR_ARRAY:
    case godot::Variant::PACKED_VECTOR4_ARRAY: {
      ERR_FAIL_MSG(
              "Invalid type(Array or Array like) given as value. Only offsets, scalars, structs, and fixed arrays are "
              "allowed."
              "You probably forgot to create the Array like type ahead of time to get its offset which you would add "
              "here.");
    }
    default: {
      ERR_FAIL_MSG("This should be impossible.");
    }
  }
}

}  // namespace godot_flatbuffers
