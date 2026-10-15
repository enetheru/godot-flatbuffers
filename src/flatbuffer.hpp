#ifndef GODOT_FLATBUFFERS_EXTENSION_FLATBUFFER_HPP
#define GODOT_FLATBUFFERS_EXTENSION_FLATBUFFER_HPP

#include <godot_cpp/classes/ref_counted.hpp>

#include "flatbuffers/flatbuffers.h"
#include "flatbufferverifier.hpp"
#include "godot_cpp/variant/variant_internal.hpp"


namespace godot_flatbuffers {
class FlatBuffer final : public godot::RefCounted {
  GDCLASS(FlatBuffer, RefCounted) // NOLINT(*-use-auto)

  typedef int32_t  soffset_t;
  typedef uint16_t voffset_t;
  typedef uint32_t uoffset_t;

  // we re-interpret the raw bytes as a table to access functions.
  const flatbuffers::Table *table;

  // This is actually a PackedByteArray, but because of gdextension
  // we need to keep our data as a Variant to avoid value copies.
  godot::Variant variant;

  // This is a pointer to the variant, to allow modification of the data
  // across the plugin boundary, we need to pass by Variant,
  const godot::PackedByteArray *fb_bytes;

  // Starting position of the buffer.
  // because we're using packed byte arrays, i need the offset into the buffer
  // where we begin.
  int64_t fb_start{};

protected:
  static void _bind_methods();

public:
#ifdef DEBUG
  [[nodiscard]] godot::String get_memory_address() const;
#endif

  static godot::Ref<FlatBuffer> get_root( godot::Variant, const godot::Variant &);

  // Get and Set of properties
  [[nodiscard]] auto get_bytes() const -> godot::Variant { return variant; }
  auto set_bytes(const godot::Variant &new_var) -> void {
    fb_bytes      = godot::VariantInternal::get_byte_array(&new_var);
    variant = new_var;
  }

  [[nodiscard]] auto get_start() const -> int64_t { return fb_start; }
  auto set_start(const int64_t start_) -> void { fb_start = start_; }

  void assign_buffer( const godot::Variant &new_var, const int64_t offset) {
    variant = new_var;
    fb_bytes      = godot::VariantInternal::get_byte_array(&new_var);
    fb_start = offset;
    table = reinterpret_cast<const flatbuffers::Table *>( fb_bytes->ptr() + fb_start);
  }


  auto overwrite_bytes(godot::Variant source, int from, int dest, int size) const -> godot::Error;


  // MARK: Encode
  //  │ ___                 _        [br]
  //  │| __|_ _  __ ___  __| |___    [br]
  //  │| _|| ' \/ _/ _ \/ _` / -_)   [br]
  //  │|___|_||_\__\___/\__,_\___|   [br]
  //  ╰───────────────────────────── [br]
  //  Encode By-Line

  auto encode_variant(const int64_t start, const godot::Variant &value, godot::Variant::Type expected_type) -> void;


  // Template to simplify encoding godot types into bytes at start_
  // Very simple, performs a raw memcpy to the byte array after checking it has enough room.
  // Specialisations exist in the cpp file
  template< typename GType >
  auto encode_gtype(const int64_t start_, const GType &value) -> void {
    ERR_FAIL_INDEX_EDMSG(
            start_ - 1 + sizeof(GType), fb_bytes->size(),
            godot::vformat(
                    "Not enough room in the buffer to encode object\n"
                    "buf(%d)[%d] !<- [%d]",
                    fb_bytes->size(), start_, sizeof(GType)));
    const auto mem = const_cast< godot::PackedByteArray * >(fb_bytes)->ptrw() + start_;
    memcpy(mem, &value, sizeof(GType));
  }

  // MARK: Decode
  //  │ ___                 _        [br]
  //  │|   \ ___ __ ___  __| |___    [br]
  //  │| |) / -_) _/ _ \/ _` / -_)   [br]
  //  │|___/\___\__\___/\__,_\___|   [br]
  //  ╰───────────────────────────── [br]
  //  Decode By-Line

  godot::Variant decode_variant(int64_t start, godot::Variant::Type expected_type) const;

  // Template to simplify decoding godot data types from bytes
  // Very simple, checks we have enough data in the array and returns the bytes interpreted as the type
  // Specialisations exist in the cpp file
  template< typename GType >
  [[nodiscard]]
  auto decode_gtype(const int64_t start_) const -> GType {
    assert(start_ + sizeof(GType) <= fb_bytes->size());
    const auto p = const_cast< uint8_t * >(fb_bytes->ptr() + start_);
    return *reinterpret_cast< const GType * >(p);
  }
  // MARK:


  // MARK: Verification
  //  │__   __       _  __ _         _   _
  //  │\ \ / /__ _ _(_)/ _(_)__ __ _| |_(_)___ _ _
  //  │ \ V / -_) '_| |  _| / _/ _` |  _| / _ \ ' \
  //  │  \_/\___|_| |_|_| |_\__\__,_|\__|_\___/_||_|
  //  ╰───────────────────────────────────────────────

  /// Verify the vtable of this table.
  /// Call this once per table, followed by VerifyField once per field.
  bool verify_table_start(const FlatBufferVerifier *verifier) const {
    const auto v = verifier->getVerifier();
    return v->VerifyTableStart(fb_bytes->ptr() + fb_start);
  }

  bool verify_end_table(const FlatBufferVerifier *verifier) const {
    const auto v = verifier->getVerifier();
    return v->EndTable();
  }

  /// Verify a particular field.
  template< typename T >
  bool verify_field(const FlatBufferVerifier *verifier, const voffset_t field, const size_t align) const {
    const auto v = verifier->getVerifier();
    return table->VerifyField<T>(*v, field, align );
  }

  bool verify_variant(const FlatBufferVerifier *verifier, voffset_t field, godot::Variant::Type type) const;

  /// VerifyField for required fields.
  // template <typename T, bool B>
  // bool VerifyFieldRequired(const VerifierTemplate<B>& verifier, voffset_t field, size_t align);

  /// Versions for offsets.
  bool verify_offset(const FlatBufferVerifier *verifier, const voffset_t field) const {
    const auto v = verifier->getVerifier();
    return table->VerifyOffset(*v, field);
  }

  /// A required offset field must be present and point at a valid offset.
  bool verify_offset_required(const FlatBufferVerifier *verifier, const voffset_t field) const {
    const auto v = verifier->getVerifier();
    return table->VerifyOffsetRequired(*v, field);
  }

  // template <typename OffsetT = uoffset_t, bool B = false>
  // bool VerifyOffsetRequired(const VerifierTemplate<B>& verifier, voffset_t field);

  /// Verify a string that may have a default value.
  bool verify_string(const FlatBufferVerifier *verifier, const voffset_t field) const {
    const auto v = verifier->getVerifier();
    return table->VerifyStringWithDefault(*v, field);
  }

  /// Verify a vector that has a default empty value.
  template <typename P>
  bool verify_vector(const FlatBufferVerifier *verifier, const voffset_t field) const {
    const auto v = verifier->getVerifier();
    return table->VerifyVectorWithDefault<P>(*v, field );
  }
  // I actually think it might be simpler to write my own verify vector with a custom size as i cant use template
  // parameters to determine the width of the vector items.

  bool verify_vector2(const FlatBufferVerifier *verifier, const voffset_t field_offset, const size_t size, const bool required) const;

  bool verify_vector_of_variant(const FlatBufferVerifier *verifier, voffset_t field, godot::Variant::Type type) const;

  // MARK: Get
  //  │  ___     _      [br]
  //  │ / __|___| |_    [br]
  //  │| (_ / -_)  _|   [br]
  //  │ \___\___|\__|   [br]
  //  ╰──────────────── [br]
  //   Get By-Line

  // Field offset and position
  [[nodiscard]] int64_t get_field_offset(int64_t vtable_pos) const;

  [[nodiscard]] int64_t get_inline_field_start(int64_t vtable_pos) const;
  [[nodiscard]] int64_t get_offset_field_start(int64_t vtable_pos) const;

  // One call for an inline scalar. The vtable walk and the load stay here.
  [[nodiscard]] bool get_bool(int64_t vtable_pos, bool fallback) const;
  [[nodiscard]] int64_t get_s8(int64_t vtable_pos, int64_t fallback) const;
  [[nodiscard]] int64_t get_u8(int64_t vtable_pos, int64_t fallback) const;
  [[nodiscard]] int64_t get_s16(int64_t vtable_pos, int64_t fallback) const;
  [[nodiscard]] int64_t get_u16(int64_t vtable_pos, int64_t fallback) const;
  [[nodiscard]] int64_t get_s32(int64_t vtable_pos, int64_t fallback) const;
  [[nodiscard]] int64_t get_u32(int64_t vtable_pos, int64_t fallback) const;
  [[nodiscard]] int64_t get_s64(int64_t vtable_pos, int64_t fallback) const;
  [[nodiscard]] int64_t get_u64(int64_t vtable_pos, int64_t fallback) const;
  [[nodiscard]] double get_f32(int64_t vtable_pos, double fallback) const;
  [[nodiscard]] double get_f64(int64_t vtable_pos, double fallback) const;

  // One call for a string field. A missing field is an empty string.
  [[nodiscard]] godot::String get_string(int64_t vtable_pos) const;

  // list_at walked the vtable, then returned to GDScript for the length and
  // the element offset. The caller has a present vector and an index inside it.
  void read_vector_table_into(FlatBuffer *into, int64_t vtable_pos, int64_t index) const;

  // sibling() walked the vtable in GDScript and then constructed a reader.
  // The caller passes the reader it wants to keep. A zero slot means the field
  // is absent, and into is left where it was.
  bool read_inline_struct_into(FlatBuffer *into, int64_t vtable_pos) const;

  // -1 when this table's key is less than key, 0 when equal, 1 when greater.
  // kind is a FlatBufferBuilder::KeyKind value. A missing scalar uses key_default.
  [[nodiscard]] int key_compare(int field, int kind, const godot::Variant &key,
                                const godot::Variant &key_default) const;

  godot::Variant get_variant(int64_t field_start, godot::Variant::Type expected_type) const;
  godot::Variant get_variant_at(int64_t vtable_pos, uint32_t index, godot::Variant::Type expected_type) const;

  // Array/Vector offset and position
  [[nodiscard]] int64_t get_array_size(int64_t vtable_offset) const;

  [[nodiscard]] int64_t get_array_element_start(int64_t array_start, int64_t idx) const;
};

// Shared by lookup (one table against a value) and sort (two tables).
int compare_table_key(const flatbuffers::Table *table, int field, int kind,
                      const godot::Variant &key, const godot::Variant &key_default);
int compare_tables_by_key(const flatbuffers::Table *a, const flatbuffers::Table *b,
                          int field, int kind, const godot::Variant &key_default);

} // namespace godot_flatbuffers

#endif // GODOT_FLATBUFFERS_EXTENSION_FLATBUFFER_HPP
