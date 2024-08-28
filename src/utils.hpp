//
// Created by nicho on 25/05/2024.
//

#ifndef GODOT_FLATBUFFERS_EXTENSION_UTILS_HPP
#define GODOT_FLATBUFFERS_EXTENSION_UTILS_HPP

#include <godot_cpp/variant/utility_functions.hpp>


namespace enetheru {
template< typename... Args >
static void print(const godot::String &fmt_string, Args &&... args) {
  auto msg = godot::vformat( fmt_string, std::forward< Args >(args)... );
  godot::UtilityFunctions::print(msg);
}
}

#endif //GODOT_FLATBUFFERS_EXTENSION_UTILS_HPP
