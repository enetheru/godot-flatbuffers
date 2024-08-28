#ifndef GODOT_FLATBUFFERS_EXTENSION_FLATBUFFER_HPP
#define GODOT_FLATBUFFERS_EXTENSION_FLATBUFFER_HPP

#include <godot_cpp/classes/ref_counted.hpp>

#include "flatbuffers/flatbuffers.h"

namespace godot_flatbuffers {
class FlatBuffer final : public godot::RefCounted {
  GDCLASS( FlatBuffer, RefCounted ) // NOLINT(*-use-auto)

  typedef int32_t  soffset_t;
  typedef uint16_t voffset_t;

  godot::PackedByteArray bytes; // I need to make this a reference somehow
  int64_t                start{};

protected:
  static void _bind_methods();

public:
  //Debug
  [[nodiscard]] godot::String get_memory_address() const;

  // Get and Set of properties
  void set_bytes( godot::PackedByteArray bytes_ );

  auto get_bytes() -> const godot::PackedByteArray &;

  void set_start( int64_t start_ );

  [[nodiscard]] auto get_start() const -> int64_t;

  // Field offset and position
  [[nodiscard]] int64_t get_field_offset( int64_t vtable_offset ) const;

  [[nodiscard]] int64_t get_field_start( int64_t vtable_offset ) const;

  // Array/Vector offset and position
  [[nodiscard]] int64_t get_array_size( int64_t vtable_offset ) const;

  [[nodiscard]] int64_t get_array_element_start( int64_t array_start, int64_t idx ) const;

  template< typename GodotStruct >
  [[nodiscard]] GodotStruct decode_struct( const int64_t start_ ) const {
    const auto p = const_cast< uint8_t * >(bytes.ptr() + start_);
    return *reinterpret_cast< GodotStruct * >(p);
  }

  [[nodiscard]] godot::String decode_String( int64_t start_ ) const;

  [[nodiscard]] godot::PackedByteArray decode_PackedByteArray( int64_t start_ ) const;

  [[nodiscard]] godot::PackedFloat32Array decode_packed_float32_array( int64_t start_ ) const;

  [[nodiscard]] godot::PackedFloat64Array decode_packed_float64_array( int64_t start_ ) const;

  [[nodiscard]] godot::PackedInt32Array decode_PackedInt32Array( int64_t start_ ) const;

  [[nodiscard]] godot::PackedInt64Array decode_PackedInt64Array( int64_t start_ ) const;

  [[nodiscard]] godot::PackedStringArray decode_PackedStringArray( int64_t start_ ) const;

};
} //namespace godot_flatbuffers

#endif //GODOT_FLATBUFFERS_EXTENSION_FLATBUFFER_HPP
