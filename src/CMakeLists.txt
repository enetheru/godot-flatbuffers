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

# Multi-Step .gdextension file configuration.
set( GDEXT_FILE_STRING [[
[configuration]
entry_symbol = "${GDE_NAME}_library_init"
compatibility_minimum = "${GODOT_VERSION_MAJOR}.${GODOT_VERSION_MINOR}"
reloadable = $<IF:$<BOOL:${GODOTCPP_USE_HOT_RELOAD}>,true,false>

[libraries]
]])

foreach( TARGET editor template_debug template_release )
  set( FLAGS "${GODOTCPP_PLATFORM}.${TARGET}.${GODOTCPP_ARCH}")
  set( LIB "bin/${GDE_NAME}.${FLAGS}.dll")

#  STRING( JOIN "."  FEATURES "${GODOTCPP_PLATFORM}" "${TARGET}" "${GODOTCPP_ARCH}" )
#  STRING( JOIN "\n" GDEXT_FILE_STRING "${GDEXT_FILE_STRING}" "${FEATURES} = \"bin/${GDE_NAME}.${FEATURES}.dll\"" )
    STRING( APPEND GDEXT_FILE_STRING "${FLAGS} = \"${LIB}\"\n")
endforeach()

# Replace variables with their content
string( CONFIGURE "${GDEXT_FILE_STRING}" GDEXT_FILE_STRING_CONFIGURED)

# use generate so generator expressions are evaluated.
file( GENERATE
        OUTPUT ${GDE_INSTALL_PATH}/${GDE_NAME}.gdextension
        CONTENT "${GDEXT_FILE_STRING_CONFIGURED}"
)
