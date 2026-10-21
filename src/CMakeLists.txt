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
        ${CMAKE_CURRENT_SOURCE_DIR}/flatbufferverifier.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/flatbufferverifier.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/utils.hpp
        ${FBHEADERS}
        PARENT_SCOPE
)
