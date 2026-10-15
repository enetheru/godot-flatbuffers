#include "flatbuffer.hpp"
#include "flatbufferbuilder.hpp"

#include <godot_cpp/core/class_db.hpp>

#include "utils.hpp"

#ifdef DEBUG
#include <utility>

godot::String FlatBuffer::get_memory_address() const {
  const auto i = reinterpret_cast< std::uintptr_t >(bytes->ptr());
  return godot::vformat( "%X", i );
}
#endif

#include <source_location>


#include "godot_cpp/variant/variant_internal.hpp"

namespace godot_flatbuffers {

namespace {

using flatbuffers::uoffset_t;
using flatbuffers::voffset_t;

template <typename T>
int cmp_less(T a, T b) {
  return static_cast<int>(a > b) - static_cast<int>(a < b);
}

int64_t variant_i64(const godot::Variant &v) {
  if (v.get_type() == godot::Variant::NIL) return 0;
  return static_cast<int64_t>(v);
}

double variant_f64(const godot::Variant &v) {
  if (v.get_type() == godot::Variant::NIL) return 0.0;
  return static_cast<double>(v);
}

int cmp_strings(const char *a, uoffset_t a_size, const char *b, uoffset_t b_size) {
  if (flatbuffers::StringLessThan(a, a_size, b, b_size)) return -1;
  if (flatbuffers::StringLessThan(b, b_size, a, a_size)) return 1;
  return 0;
}

// A missing string sorts after a present one, matching flatc.
int cmp_string_fields(const flatbuffers::Table *a, const flatbuffers::Table *b, voffset_t field) {
  const auto *as = a->GetPointer<const flatbuffers::String *>(field);
  const auto *bs = b->GetPointer<const flatbuffers::String *>(field);
  if (as && bs) return cmp_strings(as->data(), as->size(), bs->data(), bs->size());
  if (as) return -1;
  if (bs) return 1;
  return 0;
}

int cmp_string_value(const flatbuffers::Table *table, voffset_t field, const godot::Variant &key) {
  const godot::String text = key.get_type() == godot::Variant::NIL
      ? godot::String()
      : static_cast<godot::String>(key);
  const godot::CharString utf8 = text.utf8();
  const auto *fs = table->GetPointer<const flatbuffers::String *>(field);
  const char *fdata = fs ? fs->data() : "";
  const auto fsize = fs ? static_cast<uoffset_t>(fs->size()) : 0;
  const char *kdata = utf8.get_data() ? utf8.get_data() : "";
  const auto ksize = static_cast<uoffset_t>(utf8.length());
  return cmp_strings(fdata, fsize, kdata, ksize);
}

template <typename T>
T narrow_int(const godot::Variant &v) {
  return static_cast<T>(variant_i64(v));
}

bool known_key_kind(int kind) {
  switch (kind) {
    case FlatBufferBuilder::KEY_STRING:
    case FlatBufferBuilder::KEY_BOOL:
    case FlatBufferBuilder::KEY_BYTE:
    case FlatBufferBuilder::KEY_UBYTE:
    case FlatBufferBuilder::KEY_SHORT:
    case FlatBufferBuilder::KEY_USHORT:
    case FlatBufferBuilder::KEY_INT:
    case FlatBufferBuilder::KEY_UINT:
    case FlatBufferBuilder::KEY_LONG:
    case FlatBufferBuilder::KEY_ULONG:
    case FlatBufferBuilder::KEY_FLOAT:
    case FlatBufferBuilder::KEY_DOUBLE:
      return true;
    default:
      return false;
  }
}

voffset_t key_voffset(int field) {
  return static_cast<voffset_t>(field);
}

}  // namespace

int compare_tables_by_key(const flatbuffers::Table *a, const flatbuffers::Table *b,
                          int field, int kind, const godot::Variant &key_default) {
  if (a == nullptr || b == nullptr) return 0;
  const voffset_t vt = key_voffset(field);
  switch (kind) {
    case FlatBufferBuilder::KEY_STRING:
      return cmp_string_fields(a, b, vt);
    case FlatBufferBuilder::KEY_BOOL:
    case FlatBufferBuilder::KEY_UBYTE:
      return cmp_less(a->GetField<uint8_t>(vt, narrow_int<uint8_t>(key_default)),
                      b->GetField<uint8_t>(vt, narrow_int<uint8_t>(key_default)));
    case FlatBufferBuilder::KEY_BYTE:
      return cmp_less(a->GetField<int8_t>(vt, narrow_int<int8_t>(key_default)),
                      b->GetField<int8_t>(vt, narrow_int<int8_t>(key_default)));
    case FlatBufferBuilder::KEY_SHORT:
      return cmp_less(a->GetField<int16_t>(vt, narrow_int<int16_t>(key_default)),
                      b->GetField<int16_t>(vt, narrow_int<int16_t>(key_default)));
    case FlatBufferBuilder::KEY_USHORT:
      return cmp_less(a->GetField<uint16_t>(vt, narrow_int<uint16_t>(key_default)),
                      b->GetField<uint16_t>(vt, narrow_int<uint16_t>(key_default)));
    case FlatBufferBuilder::KEY_INT:
      return cmp_less(a->GetField<int32_t>(vt, narrow_int<int32_t>(key_default)),
                      b->GetField<int32_t>(vt, narrow_int<int32_t>(key_default)));
    case FlatBufferBuilder::KEY_UINT:
      return cmp_less(a->GetField<uint32_t>(vt, narrow_int<uint32_t>(key_default)),
                      b->GetField<uint32_t>(vt, narrow_int<uint32_t>(key_default)));
    case FlatBufferBuilder::KEY_LONG:
      return cmp_less(a->GetField<int64_t>(vt, variant_i64(key_default)),
                      b->GetField<int64_t>(vt, variant_i64(key_default)));
    case FlatBufferBuilder::KEY_ULONG:
      return cmp_less(a->GetField<uint64_t>(vt, static_cast<uint64_t>(variant_i64(key_default))),
                      b->GetField<uint64_t>(vt, static_cast<uint64_t>(variant_i64(key_default))));
    case FlatBufferBuilder::KEY_FLOAT:
      return cmp_less(a->GetField<float>(vt, static_cast<float>(variant_f64(key_default))),
                      b->GetField<float>(vt, static_cast<float>(variant_f64(key_default))));
    case FlatBufferBuilder::KEY_DOUBLE:
      return cmp_less(a->GetField<double>(vt, variant_f64(key_default)),
                      b->GetField<double>(vt, variant_f64(key_default)));
    default:
      return 0;
  }
}

int compare_table_key(const flatbuffers::Table *table, int field, int kind,
                      const godot::Variant &key, const godot::Variant &key_default) {
  if (table == nullptr) return 0;
  const voffset_t vt = key_voffset(field);
  switch (kind) {
    case FlatBufferBuilder::KEY_STRING:
      return cmp_string_value(table, vt, key);
    case FlatBufferBuilder::KEY_BOOL:
    case FlatBufferBuilder::KEY_UBYTE:
      return cmp_less(table->GetField<uint8_t>(vt, narrow_int<uint8_t>(key_default)),
                      narrow_int<uint8_t>(key));
    case FlatBufferBuilder::KEY_BYTE:
      return cmp_less(table->GetField<int8_t>(vt, narrow_int<int8_t>(key_default)),
                      narrow_int<int8_t>(key));
    case FlatBufferBuilder::KEY_SHORT:
      return cmp_less(table->GetField<int16_t>(vt, narrow_int<int16_t>(key_default)),
                      narrow_int<int16_t>(key));
    case FlatBufferBuilder::KEY_USHORT:
      return cmp_less(table->GetField<uint16_t>(vt, narrow_int<uint16_t>(key_default)),
                      narrow_int<uint16_t>(key));
    case FlatBufferBuilder::KEY_INT:
      return cmp_less(table->GetField<int32_t>(vt, narrow_int<int32_t>(key_default)),
                      narrow_int<int32_t>(key));
    case FlatBufferBuilder::KEY_UINT:
      return cmp_less(table->GetField<uint32_t>(vt, narrow_int<uint32_t>(key_default)),
                      narrow_int<uint32_t>(key));
    case FlatBufferBuilder::KEY_LONG:
      return cmp_less(table->GetField<int64_t>(vt, variant_i64(key_default)), variant_i64(key));
    case FlatBufferBuilder::KEY_ULONG:
      return cmp_less(table->GetField<uint64_t>(vt, static_cast<uint64_t>(variant_i64(key_default))),
                      static_cast<uint64_t>(variant_i64(key)));
    case FlatBufferBuilder::KEY_FLOAT:
      return cmp_less(table->GetField<float>(vt, static_cast<float>(variant_f64(key_default))),
                      static_cast<float>(variant_f64(key)));
    case FlatBufferBuilder::KEY_DOUBLE:
      return cmp_less(table->GetField<double>(vt, variant_f64(key_default)), variant_f64(key));
    default:
      return 0;
  }
}

int FlatBuffer::key_compare(int field, int kind, const godot::Variant &key,
                            const godot::Variant &key_default) const {
  if (table == nullptr) {
    ERR_FAIL_V_MSG(0, "key_compare was called on an empty table.");
  }
  if (field < 0 || field > 0xFFFF || !known_key_kind(kind)) {
    ERR_FAIL_V_MSG(0, "key_compare was given a bad field or key kind.");
  }
  return compare_table_key(table, field, kind, key, key_default);
}

// Value, Variant::Type, c++ type
#define GODOT_TYPES_SCALAR(TD) \
TD(  0, godot::Variant::NIL,                   nullptr) \
TD(  1, godot::Variant::BOOL,                  bool) \
TD(  2, godot::Variant::INT,                   int) \
TD(  3, godot::Variant::FLOAT,                 float)
#define GODOT_TYPES_STRING(TD) \
TD(  4, godot::Variant::STRING,                godot::String) \
TD( 21, godot::Variant::STRING_NAME,           godot::StringName) \
TD( 22, godot::Variant::NODE_PATH,             godot::NodePath)
#define GODOT_TYPES_STRUCT(TD) \
TD(  5, godot::Variant::VECTOR2,               godot::Vector2) \
TD(  6, godot::Variant::VECTOR2I,              godot::Vector2i) \
TD(  7, godot::Variant::RECT2,                 godot::Rect2) \
TD(  8, godot::Variant::RECT2I,                godot::Rect2i) \
TD(  9, godot::Variant::VECTOR3,               godot::Vector3) \
TD( 10, godot::Variant::VECTOR3I,              godot::Vector3i) \
TD( 11, godot::Variant::TRANSFORM2D,           godot::Transform2D) \
TD( 12, godot::Variant::VECTOR4,               godot::Vector4) \
TD( 13, godot::Variant::VECTOR4I,              godot::Vector4i) \
TD( 14, godot::Variant::PLANE,                 godot::Plane) \
TD( 15, godot::Variant::QUATERNION,            godot::Quaternion) \
TD( 16, godot::Variant::AABB,                  godot::AABB) \
TD( 17, godot::Variant::BASIS,                 godot::Basis) \
TD( 18, godot::Variant::TRANSFORM3D,           godot::Transform3D) \
TD( 19, godot::Variant::PROJECTION,            godot::Projection) \
TD( 20, godot::Variant::COLOR,                 godot::Color)
#define GODOT_TYPES_ARRAY(TD) \
TD( 29, godot::Variant::PACKED_BYTE_ARRAY,     godot::PackedByteArray) \
TD( 30, godot::Variant::PACKED_INT32_ARRAY,    godot::PackedInt32Array) \
TD( 31, godot::Variant::PACKED_INT64_ARRAY,    godot::PackedInt64Array) \
TD( 32, godot::Variant::PACKED_FLOAT32_ARRAY,  godot::PackedFloat32Array) \
TD( 33, godot::Variant::PACKED_FLOAT64_ARRAY,  godot::PackedFloat64Array) \
TD( 34, godot::Variant::PACKED_STRING_ARRAY,   godot::PackedStringArray) \
TD( 35, godot::Variant::PACKED_VECTOR2_ARRAY,  godot::PackedVector2Array) \
TD( 36, godot::Variant::PACKED_VECTOR3_ARRAY,  godot::PackedVector3Array) \
TD( 37, godot::Variant::PACKED_COLOR_ARRAY,    godot::PackedColorArray) \
TD( 38, godot::Variant::PACKED_VECTOR4_ARRAY,  godot::PackedVector4Array)
#define GODOT_TYPES_OTHER(TD) \
TD( 23, godot::Variant::RID,                   godot::Rid) \
TD( 24, godot::Variant::OBJECT,                godot::Object) \
TD( 25, godot::Variant::CALLABLE,              godot::Callable) \
TD( 26, godot::Variant::SIGNAL,                godot::Signal) \
TD( 27, godot::Variant::DICTIONARY,            godot::Dictionary) \
TD( 28, godot::Variant::ARRAY,                 godot::Array) \
TD( 39, godot::Variant::VARIANT_MAX,           nullptr)

#define GODOT_TYPES(TD) \
GODOT_TYPES_SCALAR(TD) \
GODOT_TYPES_STRING(TD) \
GODOT_TYPES_STRUCT(TD) \
GODOT_TYPES_ARRAY(TD) \
GODOT_TYPES_OTHER(TD)

// Get the size of the godot variant types as they are expressed in the
// flatbuffer.
static size_t get_variant_struct_size(const godot::Variant::Type type ) {
  switch( type ) {
    //Struct Types
#define GODOT_TD(INT, ENUM, TYPE) \
case ENUM: return sizeof(TYPE);
    GODOT_TYPES_STRUCT(GODOT_TD)
#undef GODOT_TD
    default:;
  }
  return -1;
}


template< typename T > [[nodiscard]]
static T decode_gtype2( const godot::PackedByteArray *bytes, const uint32_t start ) {
  assert(start + sizeof( T ) <= bytes->size() );
  const auto p = const_cast< uint8_t * >(bytes->ptr() + start);
  T t = *reinterpret_cast< T * >(p);
  return t;
}


/// slice() allocated a PackedByteArray on every string read, then
/// get_string_from_utf8 decoded that copy. name(), location(), and packed
/// string arrays all come through here. The length prefix is already in the
/// buffer, so this loads it and decodes those bytes in place.
///
/// The span is the caller's responsibility. verify_string is where a bad
/// range is rejected. A check here would run again on every read.
[[nodiscard]] static godot::String string_from_buffer(const godot::PackedByteArray *bytes, const int64_t start) {
  const uint8_t *base = bytes->ptr() + start;
  const uint32_t count = flatbuffers::ReadScalar<uint32_t>(base);
  return godot::String::utf8(reinterpret_cast<const char *>(base + sizeof(uint32_t)), count);
}


template<typename C, typename E > [[nodiscard]]
static auto decode_packed_string( const godot::PackedByteArray *bytes, const int64_t start ) -> C {
  const int num_elements = bytes->decode_u32( start );
  const int64_t data_start = start + sizeof(uint32_t);

  C packed_array;
  packed_array.resize(num_elements);
  for (int i = 0; i < num_elements; ++i) {
    const int64_t element_pos = data_start + i * sizeof(uint32_t);
    const uint32_t offset = bytes->decode_u32(element_pos);
    const int64_t string_pos = element_pos + offset;
    packed_array.set(i, string_from_buffer(bytes, string_pos));
  }
  return packed_array;
}

template<typename C, typename E> [[nodiscard]]
static auto decode_packed_struct( const godot::PackedByteArray *bytes, const int64_t start ) -> C {
  const uint32_t num_elements = bytes->decode_u32(start);
  const int64_t data_start = start + sizeof(uint32_t);
  const size_t element_size = sizeof(E);

  C packed_array;
  packed_array.resize(num_elements);
  const uint8_t *src_ptr = bytes->ptr() + data_start;
  const auto     dest_ptr = reinterpret_cast<uint8_t *>(packed_array.ptrw());
  memcpy(dest_ptr, src_ptr, num_elements * element_size);

  return packed_array;
}


static godot::PackedByteArray
slice_packed_bytes(const godot::PackedByteArray *bytes, uint32_t start, const size_t element_size) {
  const uint32_t num_elements = bytes->decode_u32(start);
  enetheru::print("bytes_size: %d", bytes->size());
  enetheru::print("start: %d", start);
  enetheru::print("num_elements: %d", num_elements);
  enetheru::print("end: %d", start + element_size * num_elements);
  start += sizeof(uint32_t);
  ERR_FAIL_COND_V_MSG(
    start + num_elements * element_size > bytes->size(),{},
    "decoded array bounds are larger than byte data.");
  return bytes->slice(start, start + num_elements * element_size);
}


// MARK: Specialisation
// ║ ___              _      _ _          _   _
// ║/ __|_ __  ___ __(_)__ _| (_)___ __ _| |_(_)___ _ _
// ║\__ \ '_ \/ -_) _| / _` | | (_-</ _` |  _| / _ \ ' \
// ║|___/ .__/\___\__|_\__,_|_|_/__/\__,_|\__|_\___/_||_|
// ╙────|_|──────────────────────────────────────────────

template<> [[nodiscard]]
auto FlatBuffer::decode_gtype( const int64_t start_ ) const -> godot::PackedByteArray {
  const int64_t size        = fb_bytes->decode_u32( start_ );
  const int64_t array_start = start_ + 4;
  return fb_bytes->slice( array_start, array_start + size );
}


template<> [[nodiscard]]
auto FlatBuffer::decode_gtype( const int64_t start_ ) const -> godot::String{
  return string_from_buffer(fb_bytes, start_);
}


template<> [[nodiscard]]
auto FlatBuffer::decode_gtype( const int64_t start_ ) const -> godot::PackedStringArray {
  const int64_t size = fb_bytes->decode_u32( start_ );
  const int64_t data = start_ + sizeof( uint32_t ); // NOLINT(*-narrowing-conversions)

  godot::PackedStringArray string_array;
  for( int i = 0; i < size; ++i ) {
    const int64_t  element = data + i * sizeof( uint32_t ); // NOLINT(*-narrowing-conversions)
    const uint32_t offset  = fb_bytes->decode_u32( element );
    string_array.append( decode_gtype<godot::String>( element + offset ) );
  }
  return string_array;
}

// MARK: Bind Methods
// ║ ___ _         _   __  __     _   _            _
// ║| _ |_)_ _  __| | |  \/  |___| |_| |_  ___  __| |___
// ║| _ \ | ' \/ _` | | |\/| / -_)  _| ' \/ _ \/ _` (_-<
// ║|___/_|_||_\__,_| |_|  |_\___|\__|_||_\___/\__,_/__/
// ╙───────────────────────────────────────────────────────────────────────────
void FlatBuffer::_bind_methods() {
  using godot::ClassDB;
  using godot::PropertyInfo;
  using godot::D_METHOD;

  //Debug
#ifdef DEBUG
  ClassDB::bind_method( D_METHOD( "get_memory_address" ), &FlatBuffer::get_memory_address );
#endif

  ClassDB::bind_static_method("FlatBuffer", D_METHOD("get_root", "buffer", "script" ), &FlatBuffer::get_root);

  ClassDB::bind_method( D_METHOD( "assign_buffer", "bytes", "offset" ), &FlatBuffer::assign_buffer );

  ClassDB::bind_method( D_METHOD( "set_bytes", "bytes" ), &FlatBuffer::set_bytes );
  ClassDB::bind_method( D_METHOD( "get_bytes" ), &FlatBuffer::get_bytes );
  ADD_PROPERTY( PropertyInfo(godot::Variant::PACKED_BYTE_ARRAY, "_fb_bytes"), "set_bytes", "get_bytes" );

  //Properties
  ClassDB::bind_method( D_METHOD( "set_start", "start" ), &FlatBuffer::set_start );
  ClassDB::bind_method( D_METHOD( "get_start" ), &FlatBuffer::get_start );
  ADD_PROPERTY( PropertyInfo(godot::Variant::INT, "_fb_start"), "set_start", "get_start" );

  // Field Access Helpers
  ClassDB::bind_method( D_METHOD( "get_field_offset", "vtable_pos" ), &FlatBuffer::get_field_offset );
  ClassDB::bind_method( D_METHOD( "get_inline_field_start", "vtable_pos" ), &FlatBuffer::get_inline_field_start );
  ClassDB::bind_method( D_METHOD( "get_offset_field_start", "vtable_pos" ), &FlatBuffer::get_offset_field_start );
  ClassDB::bind_method( D_METHOD( "get_bool", "vtable_pos", "fallback" ), &FlatBuffer::get_bool );
  ClassDB::bind_method( D_METHOD( "get_s8", "vtable_pos", "fallback" ), &FlatBuffer::get_s8 );
  ClassDB::bind_method( D_METHOD( "get_u8", "vtable_pos", "fallback" ), &FlatBuffer::get_u8 );
  ClassDB::bind_method( D_METHOD( "get_s16", "vtable_pos", "fallback" ), &FlatBuffer::get_s16 );
  ClassDB::bind_method( D_METHOD( "get_u16", "vtable_pos", "fallback" ), &FlatBuffer::get_u16 );
  ClassDB::bind_method( D_METHOD( "get_s32", "vtable_pos", "fallback" ), &FlatBuffer::get_s32 );
  ClassDB::bind_method( D_METHOD( "get_u32", "vtable_pos", "fallback" ), &FlatBuffer::get_u32 );
  ClassDB::bind_method( D_METHOD( "get_s64", "vtable_pos", "fallback" ), &FlatBuffer::get_s64 );
  ClassDB::bind_method( D_METHOD( "get_u64", "vtable_pos", "fallback" ), &FlatBuffer::get_u64 );
  ClassDB::bind_method( D_METHOD( "get_f32", "vtable_pos", "fallback" ), &FlatBuffer::get_f32 );
  ClassDB::bind_method( D_METHOD( "get_f64", "vtable_pos", "fallback" ), &FlatBuffer::get_f64 );
  ClassDB::bind_method( D_METHOD( "get_string", "vtable_pos" ), &FlatBuffer::get_string );
  ClassDB::bind_method(
      D_METHOD( "read_vector_table_into", "into", "vtable_pos", "index" ),
      &FlatBuffer::read_vector_table_into );
  ClassDB::bind_method(
      D_METHOD( "read_inline_struct_into", "into", "vtable_pos" ),
      &FlatBuffer::read_inline_struct_into );
  ClassDB::bind_method(
      D_METHOD( "key_compare", "field", "kind", "key", "key_default" ),
      &FlatBuffer::key_compare );

  //Array Access Helpers
  ClassDB::bind_method( D_METHOD( "get_array_size", "vtable_offset" ), &FlatBuffer::get_array_size );
  ClassDB::bind_method( D_METHOD( "get_array_element_start", "array_start", "idx" ), &FlatBuffer::get_array_element_start );

  //Overwrite Bytes
  ClassDB::bind_method( D_METHOD( "overwrite_bytes", "source", "from", "to", "size" ), &FlatBuffer::overwrite_bytes );

  ClassDB::bind_method(
    D_METHOD( "encode_variant", "start_", "value", "expected_type" ),
    &FlatBuffer::encode_variant, godot::Variant::Type::VARIANT_MAX);

  ClassDB::bind_method(
    D_METHOD( "get_variant_at", "vt_enum", "index", "expected_type" ),
    &FlatBuffer::get_variant_at);

  ClassDB::bind_method(
    D_METHOD( "decode_variant", "start", "expected_type" ),
    &FlatBuffer::decode_variant);


  //MARK: Verification Bindings
  ClassDB::bind_method( D_METHOD( "verify_table_start", "verifier" ), &FlatBuffer::verify_table_start );
  ClassDB::bind_method( D_METHOD( "verify_end_table", "verifier" ), &FlatBuffer::verify_end_table );

  // field verifiers
  ClassDB::bind_method( D_METHOD( "verify_field_u8", "verifier", "field", "align" ), &FlatBuffer::verify_field<uint8_t> );
  ClassDB::bind_method( D_METHOD( "verify_field_s8", "verifier", "field", "align" ), &FlatBuffer::verify_field<int8_t> );
  ClassDB::bind_method( D_METHOD( "verify_field_u16", "verifier", "field", "align" ), &FlatBuffer::verify_field<uint16_t> );
  ClassDB::bind_method( D_METHOD( "verify_field_s16", "verifier", "field", "align" ), &FlatBuffer::verify_field<int16_t> );
  ClassDB::bind_method( D_METHOD( "verify_field_u32", "verifier", "field", "align" ), &FlatBuffer::verify_field<uint32_t> );
  ClassDB::bind_method( D_METHOD( "verify_field_s32", "verifier", "field", "align" ), &FlatBuffer::verify_field<int32_t> );
  ClassDB::bind_method( D_METHOD( "verify_field_u64", "verifier", "field", "align" ), &FlatBuffer::verify_field<uint64_t> );
  ClassDB::bind_method( D_METHOD( "verify_field_s64", "verifier", "field", "align" ), &FlatBuffer::verify_field<int64_t> );
  ClassDB::bind_method( D_METHOD( "verify_field_float", "verifier", "field", "align" ), &FlatBuffer::verify_field<float> );
  ClassDB::bind_method( D_METHOD( "verify_field_double", "verifier", "field", "align" ), &FlatBuffer::verify_field<double> );
  ClassDB::bind_method( D_METHOD( "verify_variant", "verifier", "field", "type" ), &FlatBuffer::verify_variant);
  ClassDB::bind_method( D_METHOD( "verify_offset", "verifier", "field" ), &FlatBuffer::verify_offset );
  ClassDB::bind_method( D_METHOD( "verify_offset_required", "verifier", "field" ), &FlatBuffer::verify_offset_required );
  ClassDB::bind_method( D_METHOD( "verify_string", "verifier", "field" ), &FlatBuffer::verify_string );

  ClassDB::bind_method( D_METHOD( "verify_vector_s8", "verifier", "field" ), &FlatBuffer::verify_vector<int8_t>);
  ClassDB::bind_method( D_METHOD( "verify_vector_s16", "verifier", "field" ), &FlatBuffer::verify_vector<int16_t>);
  ClassDB::bind_method( D_METHOD( "verify_vector_s32", "verifier", "field" ), &FlatBuffer::verify_vector<int32_t>);
  ClassDB::bind_method( D_METHOD( "verify_vector_s64", "verifier", "field" ), &FlatBuffer::verify_vector<int64_t>);

  ClassDB::bind_method( D_METHOD( "verify_vector_u8", "verifier", "field" ), &FlatBuffer::verify_vector<uint8_t>);
  ClassDB::bind_method( D_METHOD( "verify_vector_u16", "verifier", "field" ), &FlatBuffer::verify_vector<uint16_t>);
  ClassDB::bind_method( D_METHOD( "verify_vector_u32", "verifier", "field" ), &FlatBuffer::verify_vector<uint32_t>);
  ClassDB::bind_method( D_METHOD( "verify_vector_u64", "verifier", "field" ), &FlatBuffer::verify_vector<uint64_t>);

  ClassDB::bind_method( D_METHOD( "verify_vector_float", "verifier", "field" ), &FlatBuffer::verify_vector<float>);
  ClassDB::bind_method( D_METHOD( "verify_vector_double", "verifier", "field" ), &FlatBuffer::verify_vector<double>);

  ClassDB::bind_method( D_METHOD( "verify_vector_of_variant", "verifier", "field", "type" ), &FlatBuffer::verify_vector_of_variant);
  ClassDB::bind_method( D_METHOD( "verify_vector", "verifier", "field_offset", "size", "required" ), &FlatBuffer::verify_vector2);
}

/// Static factory for fetching the buffer as root. takes a variant so that we
/// the variant internal packed byte array is not copied.
godot::Ref< FlatBuffer > FlatBuffer::get_root( godot::Variant buffer, const godot::Variant &script) {
  godot::Ref root = memnew(FlatBuffer);
  root->set_script(script);
  root->assign_buffer(buffer, godot::VariantInternal::get_byte_array(&buffer)->decode_u32(0));
  return root;
}

// MARK: Function Definitions
// ║ ___               ___       __
// ║| __|  _ _ _  __  |   \ ___ / _|___
// ║| _| || | ' \/ _| | |) / -_)  _(_-<
// ║|_| \_,_|_||_\__| |___/\___|_| /__/
// ╙───────────────────────────────────

auto FlatBuffer::overwrite_bytes(godot::Variant source, const int from, const int dest, const int size) const
        -> godot::Error {
  ERR_FAIL_COND_V_EDMSG(
          source.get_type() != godot::Variant::PACKED_BYTE_ARRAY, godot::ERR_INVALID_PARAMETER,
          "overwrite_bytes source must be a PackedByteArray");
  ERR_FAIL_INDEX_V_EDMSG(
          dest + size, fb_bytes->size(), godot::ERR_INVALID_PARAMETER, "Not enough memory for overwrite_bytes");

  const auto source_bytes = godot::VariantInternal::get_byte_array(&source)->ptr();
  const auto dest_bytes   = const_cast< godot::PackedByteArray * >(fb_bytes)->ptrw();
  memcpy(dest_bytes + dest, source_bytes + from, size);
  return godot::OK;
}

void FlatBuffer::encode_variant(const int64_t start, const godot::Variant &value, godot::Variant::Type expected_type) {
  if( expected_type == godot::Variant::Type::VARIANT_MAX ) {
    expected_type = value.get_type();
  } else {

    ERR_FAIL_COND_MSG(expected_type != value.get_type(), godot::vformat(
      "given type(%s) does not match expected type(%s)",
      godot::Variant::get_type_name(expected_type),
      godot::Variant::get_type_name(value.get_type()) ));
  }

  switch( expected_type ) {
    case godot::Variant::NIL: break;
    case godot::Variant::BOOL:break;
    case godot::Variant::INT:break;
    case godot::Variant::FLOAT:break;
    case godot::Variant::STRING: {
      const auto v = static_cast< godot::String >(value);
      encode_gtype(start, v);
      break;
    }
      // Struct Types
#define GODOT_TD(INT, ENUM, TYPE) \
case ENUM: { \
      const auto v = static_cast< TYPE >(value); \
      encode_gtype(start, v); \
      break; }
      GODOT_TYPES_STRUCT(GODOT_TD)
#undef GODOT_TD

    case godot::Variant::STRING_NAME: {
      // Convert to String first.
      const godot::String v = static_cast< godot::StringName >(value);
      encode_gtype(start, v);
      break;
    }
    case godot::Variant::NODE_PATH: {
      // Convert to String first.
      const godot::String v = static_cast< godot::NodePath >(value);
      encode_gtype(start, v);
      break;
    }
    case godot::Variant::RID:                 { ERR_FAIL_MSG("Unsupported type(RID) given as value."); }
    case godot::Variant::OBJECT:              { ERR_FAIL_MSG("Unsupported type(OBJECT) given as value."); }
    case godot::Variant::CALLABLE:            { ERR_FAIL_MSG("Unsupported type(CALLABLE) given as value."); }
    case godot::Variant::SIGNAL:              { ERR_FAIL_MSG("Unsupported type(SIGNAL) given as value."); }
    case godot::Variant::DICTIONARY:          { ERR_FAIL_MSG("Unsupported type(DICTIONARY) given as value."); }
    case godot::Variant::ARRAY:               { ERR_FAIL_MSG("Unsupported type(ARRAY) given as value."); }
#define GODOT_TD(INT, ENUM, TYPE) \
case ENUM: { ERR_FAIL_MSG("Unsupported type(" #TYPE ") given as value."); }
      GODOT_TYPES_ARRAY(GODOT_TD)
#undef GODOT_TD
    case godot::Variant::VARIANT_MAX: break;
    default: break;
  }
}


godot::Variant FlatBuffer::decode_variant(int64_t start, const godot::Variant::Type expected_type) const {
  ERR_FAIL_COND_V_MSG(expected_type == godot::Variant::Type::VARIANT_MAX, nullptr, "An expected type is required.");

  switch( expected_type ) {
    case godot::Variant::NIL:         return nullptr;
    case godot::Variant::BOOL:        return static_cast< bool >(fb_bytes->decode_s8(start));
    case godot::Variant::INT:         return fb_bytes->decode_s64(start);
    case godot::Variant::FLOAT:       return fb_bytes->decode_double(start);
    case godot::Variant::STRING:
      return string_from_buffer(fb_bytes, start);
#define GODOT_TD(INT, ENUM, TYPE) \
case ENUM: return decode_gtype2<TYPE>(fb_bytes, start);
      GODOT_TYPES_STRUCT(GODOT_TD)
#undef GODOT_TD
    case godot::Variant::STRING_NAME:
      return godot::StringName(string_from_buffer(fb_bytes, start));
    case godot::Variant::NODE_PATH:
      return godot::NodePath(string_from_buffer(fb_bytes, start));
    case godot::Variant::RID:        { ERR_FAIL_V_MSG(nullptr, "Unsupported type(RID) given as value."); }
    case godot::Variant::OBJECT:     { ERR_FAIL_V_MSG(nullptr, "Unsupported type(OBJECT) given as value."); }
    case godot::Variant::CALLABLE:   { ERR_FAIL_V_MSG(nullptr, "Unsupported type(CALLABLE) given as value."); }
    case godot::Variant::SIGNAL:     { ERR_FAIL_V_MSG(nullptr, "Unsupported type(SIGNAL) given as value."); }
    case godot::Variant::DICTIONARY: { ERR_FAIL_V_MSG(nullptr, "Unsupported type(DICTIONARY) given as value."); }
    case godot::Variant::ARRAY:      { ERR_FAIL_V_MSG(nullptr, "Unsupported type(ARRAY) given as value."); }
    case godot::Variant::PACKED_BYTE_ARRAY:    return slice_packed_bytes(fb_bytes, start, sizeof(uint8_t));
    case godot::Variant::PACKED_INT32_ARRAY:   return slice_packed_bytes(fb_bytes, start, sizeof(int32_t)).to_int32_array();
    case godot::Variant::PACKED_INT64_ARRAY:   return slice_packed_bytes(fb_bytes, start, sizeof(int64_t)).to_int64_array();
    case godot::Variant::PACKED_FLOAT32_ARRAY: return slice_packed_bytes(fb_bytes, start, sizeof(float  )).to_float32_array();
    case godot::Variant::PACKED_FLOAT64_ARRAY: return slice_packed_bytes(fb_bytes, start, sizeof(double )).to_float64_array();
    case godot::Variant::PACKED_STRING_ARRAY:  return decode_packed_string< godot::PackedStringArray,  godot::String >(fb_bytes, start);
    case godot::Variant::PACKED_VECTOR2_ARRAY: return decode_packed_struct< godot::PackedVector2Array, godot::Vector2 >(fb_bytes, start);
    case godot::Variant::PACKED_VECTOR3_ARRAY: return decode_packed_struct< godot::PackedVector3Array, godot::Vector3 >(fb_bytes, start);
    case godot::Variant::PACKED_COLOR_ARRAY:   return decode_packed_struct< godot::PackedColorArray,   godot::Color >(fb_bytes, start);
    case godot::Variant::PACKED_VECTOR4_ARRAY: return decode_packed_struct< godot::PackedVector4Array, godot::Vector4 >(fb_bytes, start);
    default:;
  }
  return nullptr;
}

// MARK: Verification
//  │__   __       _  __ _         _   _
//  │\ \ / /__ _ _(_)/ _(_)__ __ _| |_(_)___ _ _
//  │ \ V / -_) '_| |  _| / _/ _` |  _| / _ \ ' \
//  │  \_/\___|_| |_|_| |_\__\__,_|\__|_\___/_||_|
//  ╰───────────────────────────────────────────────

bool FlatBuffer::verify_variant(
        const FlatBufferVerifier *verifier, const voffset_t field, const godot::Variant::Type type) const {
  // the alignment is known for the variant types so it doesnt need to be passed to this function.
  // double precision alignment would be 8, i might have to double check things.
  const auto v = verifier->getVerifier();
  switch( type ) {
      // Scalar types
    case godot::Variant::NIL:{ ERR_FAIL_V_MSG(false, "Unsupported type(NIL) given as value."); }
    case godot::Variant::BOOL:        return table->VerifyField< uint8_t >(*v, field, 1);
    case godot::Variant::INT:         return table->VerifyField< int64_t >(*v, field, 8);
    case godot::Variant::FLOAT:       return table->VerifyField< double >(*v, field, 8);

      //Struct Types
#define GODOT_TD(INT, ENUM, TYPE) \
case ENUM: return table->VerifyField<TYPE>(*v, field, 4);
      GODOT_TYPES_STRUCT(GODOT_TD)
#undef GODOT_TD

      // String Types
#define GODOT_TD(INT, ENUM, TYPE) \
case ENUM: return verify_string(verifier, field);
      GODOT_TYPES_STRING(GODOT_TD)
#undef GODOT_TD

    case godot::Variant::RID:         { ERR_FAIL_V_MSG(false, "Unsupported type(RID) given as value."); }
    case godot::Variant::OBJECT:      { ERR_FAIL_V_MSG(false, "Unsupported type(OBJECT) given as value."); }
    case godot::Variant::CALLABLE:    { ERR_FAIL_V_MSG(false, "Unsupported type(CALLABLE) given as value."); }
    case godot::Variant::SIGNAL:      { ERR_FAIL_V_MSG(false, "Unsupported type(SIGNAL) given as value."); }
    case godot::Variant::DICTIONARY:  { ERR_FAIL_V_MSG(false, "Unsupported type(DICTIONARY) given as value."); }
    case godot::Variant::ARRAY:       { ERR_FAIL_V_MSG(false, "Unsupported type(ARRAY) given as value."); }

#define GODOT_TD(INT, ENUM, TYPE) \
case ENUM: { ERR_FAIL_V_MSG(false, "Unsupported type(" #TYPE ") given as value."); }
      GODOT_TYPES_ARRAY(GODOT_TD)
#undef GODOT_TD
    case godot::Variant::VARIANT_MAX:
      break;
  }
  return false;
}


bool FlatBuffer::verify_vector2(
        const FlatBufferVerifier *verifier, const voffset_t field_offset, const size_t size,
        const bool required) const {
  const auto v = verifier->getVerifier();
  const auto p = table->GetPointer< const uint8_t * >(field_offset);
  if( required && ! p ) {
    return false;
  }
  return ! p || v->VerifyVectorOrString(p, size);
}


bool FlatBuffer::verify_vector_of_variant(
        const FlatBufferVerifier *verifier, const voffset_t field, const godot::Variant::Type type) const {
  // the alignment is known for the variant types so it doesnt need to be passed to this function.
  // double precision alignment would be 8, i might have to double check things.
  const auto v = verifier->getVerifier();
  switch( type ) {
    case godot::Variant::NIL:{ ERR_FAIL_V_MSG(false, "Unsupported type(NIL) given as value."); }
    case godot::Variant::BOOL:{ ERR_FAIL_V_MSG(false, "Unsupported type(BOOL) given as value."); }
    case godot::Variant::INT:{ ERR_FAIL_V_MSG(false, "Unsupported type(INT) given as value."); }
    case godot::Variant::FLOAT:{ ERR_FAIL_V_MSG(false, "Unsupported type(FLOAT) given as value."); }
    case godot::Variant::STRING: {
      const auto strings = table->GetPointer<const ::flatbuffers::Vector<::flatbuffers::Offset<::flatbuffers::String>> *>(field);
      return v->VerifyVectorOfStrings(strings);
    }
#define GODOT_TD(INT, ENUM, TYPE) \
case ENUM: return table->VerifyVectorWithDefault<TYPE>(*v, field);
      GODOT_TYPES_STRUCT(GODOT_TD)
#undef GODOT_TD
    case godot::Variant::STRING_NAME: { ERR_FAIL_V_MSG(false, "Unsupported type(STRING_NAME) given as value."); }
    case godot::Variant::NODE_PATH:   { ERR_FAIL_V_MSG(false, "Unsupported type(NODE_PATH) given as value."); }
    case godot::Variant::RID:         { ERR_FAIL_V_MSG(false, "Unsupported type(RID) given as value."); }
    case godot::Variant::OBJECT:      { ERR_FAIL_V_MSG(false, "Unsupported type(OBJECT) given as value."); }
    case godot::Variant::CALLABLE:    { ERR_FAIL_V_MSG(false, "Unsupported type(CALLABLE) given as value."); }
    case godot::Variant::SIGNAL:      { ERR_FAIL_V_MSG(false, "Unsupported type(SIGNAL) given as value."); }
    case godot::Variant::DICTIONARY:  { ERR_FAIL_V_MSG(false, "Unsupported type(DICTIONARY) given as value."); }
    case godot::Variant::ARRAY:       { ERR_FAIL_V_MSG(false, "Unsupported type(ARRAY) given as value."); }
#define GODOT_TD(INT, ENUM, TYPE) \
case ENUM: { ERR_FAIL_V_MSG(false, "Unsupported type(" #TYPE ") given as value."); }
      GODOT_TYPES_ARRAY(GODOT_TD)
#undef GODOT_TD
    case godot::Variant::VARIANT_MAX:
      break;
  }
  return false;
}


/// decode_s32 and decode_s16 cross into the engine. Every table field pays
/// that, and the vtable is already in this buffer, so the soffset, the
/// vtable size, and the slot are plain loads. A position below 4, a slot
/// past the vtable, or a zero slot means the field is absent.
int64_t FlatBuffer::get_field_offset(const int64_t vtable_pos) const {
  if( vtable_pos < 4 ) {
    return 0;
  }

  const uint8_t *base = fb_bytes->ptr();
  const int32_t soffset = flatbuffers::ReadScalar<int32_t>(base + fb_start);
  const uint8_t *vtable = base + fb_start - soffset;
  const int64_t vtable_size = flatbuffers::ReadScalar<int16_t>(vtable);
  if( vtable_pos >= vtable_size ) {
    return 0;
  }
  return flatbuffers::ReadScalar<int16_t>(vtable + vtable_pos);
}

/// get_inline_field_start handed the offset back to GDScript, which then called
/// PackedByteArray.decode_*. That second call is the whole cost of a scalar
/// field. The bytes are already here, so the load happens in the same call.
/// A zero start means the field is absent. The fallback is returned as the
/// caller passed it. Narrowing it would turn a float default of 5.3 into the
/// float32 rounding of 5.3.
bool FlatBuffer::get_bool(const int64_t vtable_pos, const bool fallback) const {
  const int64_t start = get_inline_field_start(vtable_pos);
  if (start == 0) {
    return fallback;
  }
  return flatbuffers::ReadScalar<uint8_t>(fb_bytes->ptr() + start) != 0;
}

int64_t FlatBuffer::get_s8(const int64_t vtable_pos, const int64_t fallback) const {
  const int64_t start = get_inline_field_start(vtable_pos);
  if (start == 0) return fallback;
  return flatbuffers::ReadScalar<int8_t>(fb_bytes->ptr() + start);
}
int64_t FlatBuffer::get_u8(const int64_t vtable_pos, const int64_t fallback) const {
  const int64_t start = get_inline_field_start(vtable_pos);
  if (start == 0) return fallback;
  return flatbuffers::ReadScalar<uint8_t>(fb_bytes->ptr() + start);
}
int64_t FlatBuffer::get_s16(const int64_t vtable_pos, const int64_t fallback) const {
  const int64_t start = get_inline_field_start(vtable_pos);
  if (start == 0) return fallback;
  return flatbuffers::ReadScalar<int16_t>(fb_bytes->ptr() + start);
}
int64_t FlatBuffer::get_u16(const int64_t vtable_pos, const int64_t fallback) const {
  const int64_t start = get_inline_field_start(vtable_pos);
  if (start == 0) return fallback;
  return flatbuffers::ReadScalar<uint16_t>(fb_bytes->ptr() + start);
}
int64_t FlatBuffer::get_s32(const int64_t vtable_pos, const int64_t fallback) const {
  const int64_t start = get_inline_field_start(vtable_pos);
  if (start == 0) return fallback;
  return flatbuffers::ReadScalar<int32_t>(fb_bytes->ptr() + start);
}
int64_t FlatBuffer::get_u32(const int64_t vtable_pos, const int64_t fallback) const {
  const int64_t start = get_inline_field_start(vtable_pos);
  if (start == 0) return fallback;
  return flatbuffers::ReadScalar<uint32_t>(fb_bytes->ptr() + start);
}
int64_t FlatBuffer::get_s64(const int64_t vtable_pos, const int64_t fallback) const {
  const int64_t start = get_inline_field_start(vtable_pos);
  if (start == 0) return fallback;
  return flatbuffers::ReadScalar<int64_t>(fb_bytes->ptr() + start);
}
int64_t FlatBuffer::get_u64(const int64_t vtable_pos, const int64_t fallback) const {
  const int64_t start = get_inline_field_start(vtable_pos);
  if (start == 0) return fallback;
  return static_cast<int64_t>(flatbuffers::ReadScalar<uint64_t>(fb_bytes->ptr() + start));
}
double FlatBuffer::get_f32(const int64_t vtable_pos, const double fallback) const {
  const int64_t start = get_inline_field_start(vtable_pos);
  if (start == 0) return fallback;
  return flatbuffers::ReadScalar<float>(fb_bytes->ptr() + start);
}
double FlatBuffer::get_f64(const int64_t vtable_pos, const double fallback) const {
  const int64_t start = get_inline_field_start(vtable_pos);
  if (start == 0) return fallback;
  return flatbuffers::ReadScalar<double>(fb_bytes->ptr() + start);
}

// returns offset from the start of the buffer to the inline field.
int64_t FlatBuffer::get_inline_field_start(const int64_t vtable_pos) const {
  const int field_offset = get_field_offset(vtable_pos); // NOLINT(*-narrowing-conversions)
  if( ! field_offset ) {
    return 0;
}
  return fb_start + field_offset;
}

// returns offset from the start of the buffer to the offset field.
int64_t FlatBuffer::get_offset_field_start(const int64_t vtable_pos) const {
  const int field_offset = get_field_offset(vtable_pos); // NOLINT(*-narrowing-conversions)
  if( ! field_offset ) {
    return 0;
}
  const uint8_t *field = fb_bytes->ptr() + fb_start + field_offset;
  return fb_start + field_offset + flatbuffers::ReadScalar<uint32_t>(field);
}

/// name() and location() called get_offset_field_start and then decode_variant.
/// Both enter the extension, and the second call only reads bytes this object
/// already holds. A zero offset means the field is absent.
godot::String FlatBuffer::get_string(const int64_t vtable_pos) const {
  const int64_t start = get_offset_field_start(vtable_pos);
  if (start == 0) {
    return {};
  }
  return string_from_buffer(fb_bytes, start);
}

/// list_at did the vtable walk here, then two PackedByteArray.decode_u32 calls,
/// then assign_buffer. The element slot is a uoffset relative to itself.
/// The caller already knows the vector is present and the index is in range.
void FlatBuffer::read_vector_table_into(
    FlatBuffer *into, const int64_t vtable_pos, const int64_t index) const {
  const int64_t vector_start = get_offset_field_start(vtable_pos);
  const uint8_t *slot = fb_bytes->ptr() + vector_start + 4 + index * 4;
  const auto relative = flatbuffers::ReadScalar<uint32_t>(slot);
  into->assign_buffer(variant, static_cast<int64_t>(slot - fb_bytes->ptr()) + relative);
}

/// sibling() did this vtable walk in GDScript, then constructed a reader.
/// The caller passes the reader it wants to keep. A zero slot means the field
/// is absent, so into stays on whatever span it already had.
bool FlatBuffer::read_inline_struct_into(
    FlatBuffer *into, const int64_t vtable_pos) const {
  const int64_t start = get_inline_field_start(vtable_pos);
  if (start == 0) {
    return false;
  }
  into->assign_buffer(variant, start);
  return true;
}


// Template to simplify getting the type from
godot::Variant FlatBuffer::get_variant(const int64_t field_start, const godot::Variant::Type expected_type) const {
  return decode_variant(field_start, expected_type);
}

// template for struct array access
godot::Variant FlatBuffer::get_variant_at(
        const int64_t vtable_pos, const uint32_t index, const godot::Variant::Type expected_type) const {
  const uoffset_t elements_start = get_offset_field_start(vtable_pos) + sizeof(uint32_t);
  if( not elements_start ) {
    return {};
}

  const uint64_t element_start = elements_start + index * get_variant_struct_size(expected_type);
  return decode_variant(element_start, expected_type);
}

int64_t FlatBuffer::get_array_size(const int64_t vtable_offset) const {
  const int64_t field_start = get_offset_field_start(vtable_offset);
  if( ! field_start ) {
    return 0;
}
  return fb_bytes->decode_u32(field_start);
}


int64_t FlatBuffer::get_array_element_start(const int64_t array_start, const int64_t idx) const {
#ifdef DEBUG_ENABLED
  [[maybe_unused]] const int64_t array_size = fb_bytes->decode_u32(array_start);
  assert(array_start < fb_bytes->size() - 4);
  assert(idx < array_size);
  assert(array_start + array_size * 4 < fb_bytes->size());
#endif

  const int64_t data    = array_start + 4;
  const int64_t element = data + idx * 4;
  const int64_t value   = fb_bytes->decode_u32(element);

  return element + value;
}


} // end namespace godot_flatbuffers
