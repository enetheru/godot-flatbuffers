#ifndef GODOT_FLATBUFFERS_EXTENSION_FLATBUFFERBUILDER_H
#define GODOT_FLATBUFFERS_EXTENSION_FLATBUFFERBUILDER_H

#include "flatbuffers/flatbuffer_builder.h"
#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot_flatbuffers {

class FlatBufferBuilder : public godot::RefCounted {
	GDCLASS(FlatBufferBuilder, RefCounted) // NOLINT(*-use-auto)

	std::unique_ptr<flatbuffers::FlatBufferBuilder> builder;

protected:
	static FlatBufferBuilder *Create( int size ) {
		auto fbb = memnew( FlatBufferBuilder( size ) );
		fbb->builder = std::make_unique<flatbuffers::FlatBufferBuilder>( size );
		// TODO Use this 'flatbuffers::FlatBufferBuilderImpl(...)' to add a custom allocator so that we can create directly into a PackedByteArray
		//  This will make the need to copy the data after construction unnecessary
		return fbb;
	}

	static void _bind_methods();

public:
	explicit FlatBufferBuilder();
	explicit FlatBufferBuilder( int size );

	using uoffset_t = flatbuffers::uoffset_t;
	using Offset = flatbuffers::Offset<>;

	int64_t GetSize() { return builder->GetSize(); }
	godot::PackedByteArray GetPackedByteArray();

	void Clear() { builder->Clear(); }
	void Reset() { builder->Reset(); }
	void Finish( uint32_t root );

	uoffset_t StartTable() { return builder->StartTable(); }
	uoffset_t EndTable(uoffset_t start) { return builder->EndTable(start); }

	// == Add functions for scalars ==
	void AddOffset( uint16_t voffset, uint64_t value );

  void AddBytes( uint16_t voffset, const godot::PackedByteArray& bytes );

	template<typename in, typename out>
	void AddScalar( uint16_t voffset, in value ){ builder->AddElement<out>( voffset, value ); }

	template<typename in, typename out>
	void AddScalarDefault( uint16_t voffset, in value, in default_ ){ builder->AddElement<out>( voffset, value, default_ ); }

	// == Add functions for builtin structs ==
	void AddVector3( uint16_t voffset, godot::Vector3 );
	void AddVector3i( uint16_t voffset, godot::Vector3i );

	// == Create functions ==
	uoffset_t CreateVectorOffset( const godot::PackedInt32Array &array );

	// PackedByteArray
	// PackedInt32Array
	// PackedInt64Array
	// PackedFloat32Array
	// PackedFloat64Array
	template<typename T>
	uoffset_t CreatePackedArray( const godot::Array& v ) {
		builder->StartVector< T >( v.size() );
		for (auto i= v.size(); i > 0;) {
			builder->PushElement( static_cast< T > ( v[--i] ) );
		}
		return builder->EndVector( v.size() );
	}

	// Godot Variant Types
	// AABB
	// Array
	// Basis
	// bool
	// Callable
	// Color
	uoffset_t CreateColor( const godot::Color& value );
	// Dictionary
	// NodePath
	// Object
	// PackedColorArray
	// PackedStringArray
	uoffset_t CreatePackedStringArray( const godot::PackedStringArray& value );
	// PackedVector2Array
	// PackedVector3Array
	// Plane
	// Projection
	// Quaternion
	// Rect2
	// Rect2i
	// RID
	// Signal
	// String
	uoffset_t CreateString( const godot::String& string );
	// StringName
	// Transform2D
	// Transform3D
	// Vector2
	// Vector2i
	// Vector3
	uoffset_t CreateVector3( const godot::Vector3& value );
	uoffset_t CreateVector3i( const godot::Vector3i& value );
	// Vector3i
	// Vector4
	// Vector4i

	// Custom Class to Table Creators
	uoffset_t CreateVectorTable( const godot::Array&array, const godot::Callable& constructor );
};

}
#endif //GODOT_FLATBUFFERS_EXTENSION_FLATBUFFERBUILDER_H
