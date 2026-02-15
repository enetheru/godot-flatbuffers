# TODO add all targets as separate configurations so they can be built all at the same time.
#   editor|template_release|template_debug

# Collect sources for flatbuffer schemas
#file( GLOB FBHEADERS builtin/*.h)
#message( "Found These Flatbuffer Generated Headers: \n${FBHEADERS}" )
configure_file( entry_point.cpp.in ${CMAKE_CURRENT_SOURCE_DIR}/entry_point.cpp )

set( SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/entry_point.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/register_types.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/register_types.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/flatbuffer.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/flatbuffer.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/flatbufferbuilder.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/flatbufferbuilder.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/flexbuffer.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/flexbuffer.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/utils.hpp
        ${FBHEADERS}
        PARENT_SCOPE
)

# Multi-Step .gdextension file configuration.

# First is to load the file into a variable
file( READ gdextension.in GDEXT_FILE_STRING )

# Replace variables with their content
string( CONFIGURE "${GDEXT_FILE_STRING}" GDEXT_FILE_STRING_CONFIGURED)

# use generate so generator expressions are evaluated.
file( GENERATE
        OUTPUT ${CMAKE_SOURCE_DIR}/project/addons/${GDE_NAME}/${GDE_NAME}.gdextension
        CONTENT "${GDEXT_FILE_STRING_CONFIGURED}"
)

# TODO, modify godot.fbs to cater to double precision builds
configure_file( builtin/godot.fbs ${CMAKE_SOURCE_DIR}/project/addons/${GDE_NAME}/godot.fbs )
