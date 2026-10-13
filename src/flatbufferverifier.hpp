#ifndef GODOT_FLATBUFFERS_FLATBUFFERVERIFIER_HPP
#define GODOT_FLATBUFFERS_FLATBUFFERVERIFIER_HPP

#include <memory>
#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include "flatbuffers/buffer.h"
#include "flatbuffers/verifier.h"
#include <godot_cpp/variant/string.hpp>
#include "godot_cpp/variant/variant_internal.hpp"

namespace godot_flatbuffers {

  /*
   * There are a few factors that went in to my descision to re-implement the verifier
   * 1. changing the data - i dont want to have to allocate a new object for
   *    every buffer that needs verifying.
   * 2. We cannot derive the size of a field using template specialisation.
   */
class FlatBufferVerifier final : public godot::RefCounted {
  GDCLASS( FlatBufferVerifier, RefCounted ) // NOLINT(*-use-auto)

  using uoffset_t = flatbuffers::uoffset_t;
  using soffset_t = flatbuffers::soffset_t;
  using voffset_t = flatbuffers::voffset_t;

  std::unique_ptr<flatbuffers::Verifier> verifier;

  // the buffer is wrapped by a variant so that it is not duplicated.
  godot::Variant variant;

  // This is a pointer to the variant, to allow modification of the data
  // across the plugin boundary, we need to pass by Variant,
  const godot::PackedByteArray *buffer;


protected:
  static void _bind_methods(){
    using godot::ClassDB;
    using godot::D_METHOD;

    // All of the functions are called via the c++ interface from the
    // FlatBuffer, This object is used to replicate the interface of the parent project.
    ClassDB::bind_method( D_METHOD( "buffer_has_identifier", "file_identifier"), &FlatBufferVerifier::buffer_has_identifier );
    ClassDB::bind_method( D_METHOD( "set_buffer", "byte_array"), &FlatBufferVerifier::set_buffer );
  }

public:
  explicit FlatBufferVerifier() : buffer(nullptr) {}

  // Keeping a reference to the variant will hopefully keep the untouched
  // byte array around, because its COW I think this will work.
  // but it probably doesnt when the byte array is re-sized.
  void set_buffer( const godot::Variant &new_var ) {
    variant  = new_var;
    // Point at the stored variant. The argument dies when this call returns.
    buffer   = godot::VariantInternal::get_byte_array( &variant );
    // create a new verifier pointing to the bytes.
    verifier = std::make_unique< flatbuffers::Verifier >( buffer->ptr(), buffer->size());
  }

  // True when the 4 bytes after the root offset match file_identifier.
  // A missing buffer, a short buffer, or any other length is false.
  bool buffer_has_identifier( const godot::String &file_identifier ) const {
    if( buffer == nullptr ) {
      return false;
    }
    const godot::CharString utf8 = file_identifier.utf8();
    if( utf8.length() != flatbuffers::kFileIdentifierLength ) {
      return false;
    }
    const size_t need = sizeof( flatbuffers::uoffset_t ) + flatbuffers::kFileIdentifierLength;
    if( static_cast< size_t >( buffer->size() ) < need ) {
      return false;
    }
    return flatbuffers::BufferHasIdentifier( buffer->ptr(), utf8.get_data() );
  }

  flatbuffers::Verifier *getVerifier() const {
    return verifier.get();
  }
};

}  // namespace godot_flatbuffers
#endif //GODOT_FLATBUFFERS_FLATBUFFERVERIFIER_HPP
