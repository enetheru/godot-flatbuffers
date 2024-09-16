# TODO add all targets as separate configurations so they can be built all at the same time.
#   editor|template_release|template_debug

# Collect sources for flatbuffer schemas
#file( GLOB FBHEADERS builtin/*.h)
#message( "Found These Flatbuffer Generated Headers: \n${FBHEADERS}" )
configure_file( entry_point.cpp.in ${CMAKE_CURRENT_SOURCE_DIR}/entry_point.cpp )

target_sources( ${GDE_NAME}
    PRIVATE
        entry_point.cpp
        register_types.cpp
        register_types.hpp
        flatbuffer.cpp
        flatbuffer.hpp
        flatbufferbuilder.cpp
        flatbufferbuilder.hpp
        utils.hpp
        ${FBHEADERS}
)

configure_file( gdextension.in ${CMAKE_SOURCE_DIR}/project/addons/${GDE_NAME}/${GDE_NAME}.gdextension )

configure_file( builtin/godot.fbs ${CMAKE_SOURCE_DIR}/project/addons/${GDE_NAME}/godot.fbs )
