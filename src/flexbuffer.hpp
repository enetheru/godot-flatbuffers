#ifndef GODOT_FLATBUFFERS_EXTENSION_FLEXBUFFER_HPP
#define GODOT_FLATBUFFERS_EXTENSION_FLEXBUFFER_HPP

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/variant.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>

#include "flatbuffers/flexbuffers.h"

namespace godot_flatbuffers {

class FlexBuffer final : public godot::RefCounted {
  GDCLASS(FlexBuffer, RefCounted)

protected:
  static void _bind_methods();

public:
  FlexBuffer() = default;
  ~FlexBuffer() override = default;

  static godot::PackedByteArray encode(const godot::Variant &p_variant);
  static godot::Variant decode(const godot::PackedByteArray &p_bytes);

  static godot::PackedByteArray var_to_flex(const godot::Variant &p_variant) { return encode(p_variant); }
  static godot::Variant flex_to_var(const godot::PackedByteArray &p_bytes) { return decode(p_bytes); }

private:
  static void _encode_variant(flexbuffers::Builder &fbb, const godot::Variant &p_variant);
  static godot::Variant _decode_reference(const flexbuffers::Reference &ref);
};

} // namespace godot_flatbuffers

#endif // GODOT_FLATBUFFERS_EXTENSION_FLEXBUFFER_HPP
