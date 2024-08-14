//
// Created by nicho on 25/05/2024.
//

#ifndef GODOT_FLATBUFFERS_EXTENSION_UTILS_H
#define GODOT_FLATBUFFERS_EXTENSION_UTILS_H

#include <godot_cpp/variant/utility_functions.hpp>


namespace enetheru {

template <typename... Args>
static inline void print(const godot::String &fmt_string, Args &&...args) {
	godot::UtilityFunctions::print(fmt_string.format(godot::Array::make(std::forward<Args>(args)...)));
}
}

#endif //GODOT_FLATBUFFERS_EXTENSION_UTILS_H
