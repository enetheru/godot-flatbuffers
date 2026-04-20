cmake_minimum_required(VERSION 3.30.5)

#[=======================[ Global CMake Configuration ]=======================]
if( CMAKE_C_COMPILER )
    #Do nothing, just shut up the build because clion adds this from the toolchain
endif ()

set( FETCHCONTENT_UPDATES_DISCONNECTED OFF CACHE BOOL "Stop updating every configure")

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

### Cmake options to expose
option( CMAKE_EXPORT_COMPILE_COMMANDS
        "Generate compilation DB (`compile_commands.json`) for external tools"
        ON )

# So that I can condifgure for the flatc compiler, and not the extension.
option( BUILD_EXTENSION "build the extension" ON)

### Information regarding the godot executable
if( NOT GODOT_EXECUTABLE )
    if( GODOT )
        set( GODOT_EXECUTABLE "${GODOT}" CACHE FILEPATH "Path to the godot executable you are targeting" )
    elseif( DEFINED ENV{GODOT} )
        set( GODOT_EXECUTABLE "$ENV{GODOT}" CACHE FILEPATH "Path to the godot executable you are targeting" )
    endif()
endif()

# This is a fallback to allow the user to still set it via -DGODOT_EXECUTABLE
set( GODOT_EXECUTABLE "${GODOT_EXECUTABLE}" CACHE FILEPATH "Path to the godot executable you are targeting" )

set( GODOT_PROJECT_PATH "${CMAKE_CURRENT_SOURCE_DIR}/project" CACHE PATH
        "Path to a demo project that can test the godot-extension" )

set( AUTHOR_TAG "Enetheru")
string( TOLOWER "${AUTHOR_TAG}" AUTHOR_TAG_LOWER )

## Target options
set( GDE_NAME "flatbuffers" )

set( GODOT_PROJECT_PATH "${CMAKE_CURRENT_SOURCE_DIR}/project" )
set( GDE_INSTALL_NAME "${AUTHOR_TAG_LOWER}.${GDE_NAME}-extension" )
set( GDE_INSTALL_PATH "${GODOT_PROJECT_PATH}/addons/${GDE_INSTALL_NAME}")

#[==============================[ Dependencies ]==============================]
include(FetchContent)
include(CMakePrintHelpers)

include(cmake/findGodotExecutable.cmake)
include(cmake/godot-dump.cmake)
include(cmake/godot-docs.cmake)

find_package(Python3 3.4 REQUIRED) # pathlib should be present

#[==============[ Git ]==============]
find_program(GIT_EXECUTABLE NAMES "git" DOC "" NO_CACHE REQUIRED)
if( NOT EXISTS "${GIT_EXECUTABLE}" )
    message( FATAL_ERROR "Unable to find Git at: '${GIT_EXECUTABLE}'")
endif()

# MARK: flatbuffs
# ╒════════════════════════════════════════════════════════════════════════════╕
# │ ███████ ██       █████  ████████ ██████  ██    ██ ███████ ███████ ███████  │
# │ ██      ██      ██   ██    ██    ██   ██ ██    ██ ██      ██      ██       │
# │ █████   ██      ███████    ██    ██████  ██    ██ █████   █████   ███████  │
# │ ██      ██      ██   ██    ██    ██   ██ ██    ██ ██      ██           ██  │
# │ ██      ███████ ██   ██    ██    ██████   ██████  ██      ██      ███████  │
# ╘════════════════════════════════════════════════════════════════════════════╛

set( FLATBUFFERS_GIT_URL "https://github.com/enetheru/flatbuffers.git"
        CACHE STRING "Location of the godot-cpp git repository" )
set( FLATBUFFERS_GIT_TAG "gdscript"
        CACHE STRING "git hash, branch or tag to fetch" )

# Configuration Options
set( FLATBUFFERS_BUILD_FLATHASH     NO )
set( FLATBUFFERS_BUILD_SHAREDLIB    NO )
set( FLATBUFFERS_BUILD_TESTS        NO )
set( FLATBUFFERS_INSTALL            NO )
set( FLATBUFFERS_STATIC_FLATC      YES )
set( FLATBUFFERS_BUILD_FLATC       YES )
set( FLATBUFFERS_CPP_STD            17 )
set( FLATBUFFERS_BUILD_CPP17       YES )


FetchContent_Declare( FlatBuffers
        GIT_REPOSITORY  "${FLATBUFFERS_GIT_URL}"
        GIT_TAG         "${FLATBUFFERS_GIT_TAG}"
        SOURCE_DIR      "${CMAKE_CURRENT_SOURCE_DIR}/lib/flatbuffers"
        SYSTEM
        EXCLUDE_FROM_ALL
)
FetchContent_MakeAvailable( FlatBuffers )

set_target_properties(
        flatc
        PROPERTIES
        EXCLUDE_FROM_ALL OFF
        OUTPUT_NAME "flatc$<$<CONFIG:Debug,RelWithDebInfo>:.$<LOWER_CASE:$<CONFIG>>>"
        RUNTIME_OUTPUT_DIRECTORY "$<1:${GDE_INSTALL_PATH}/bin>"
)

# If we dont want to build the extension then we can stop here
# This does break any other targets for this configuration
# so currently only useful for building flatc.
if( NOT BUILD_EXTENSION )
    return()
endif ()

# MARK: godot-cpp
# ╒════════════════════════════════════════════════════════════════════════════╕
# │  ██████   ██████  ██████   ██████  ████████     ██████ ██████  ██████      │
# │ ██       ██    ██ ██   ██ ██    ██    ██       ██      ██   ██ ██   ██     │
# │ ██   ███ ██    ██ ██   ██ ██    ██    ██ █████ ██      ██████  ██████      │
# │ ██    ██ ██    ██ ██   ██ ██    ██    ██       ██      ██      ██          │
# │  ██████   ██████  ██████   ██████     ██        ██████ ██      ██          │
# ╘════════════════════════════════════════════════════════════════════════════╛

set( GODOTCPP_GIT_URL "https://github.com/godotengine/godot-cpp.git" CACHE STRING "Location of the godot-cpp git repository" )
set( GODOTCPP_GIT_TAG "godot-4.5-stable" CACHE STRING "git hash, branch or tag to fetch" )

set( GODOTCPP_TARGET "editor" CACHE STRING "")
set( GODOTCPP_BUILD_PROFILE "${CMAKE_CURRENT_SOURCE_DIR}/src/godot-cpp.build_profile.json")
set( GODOTCPP_USE_HOT_RELOAD ON)

#if( GODOT_GIT_TAG STREQUAL "" )
#    include( godot-cpp-git-tag )
#endif()

FetchContent_Declare( godot-cpp
        GIT_REPOSITORY  "${GODOTCPP_GIT_URL}"
        GIT_TAG         "${GODOTCPP_GIT_TAG}"
        SOURCE_DIR      "${CMAKE_CURRENT_SOURCE_DIR}/lib/godot-cpp"
        SYSTEM
        EXCLUDE_FROM_ALL
)
FetchContent_MakeAvailable( godot-cpp )

### Get useful properties of the library
get_target_property( GODOTCPP_SUFFIX godot-cpp GODOTCPP_SUFFIX_GENEX )
get_target_property( GODOTCPP_PLATFORM godot-cpp GODOTCPP_PLATFORM )
get_target_property( GODOTCPP_TARGET godot-cpp GODOTCPP_TARGET )
get_target_property( GODOTCPP_ARCH godot-cpp GODOTCPP_ARCH )

# MARK: project
# ╒════════════════════════════════════════════════════════════════════════════╕
# │ ██████  ██████   ██████       ██ ███████  ██████ ████████                  │
# │ ██   ██ ██   ██ ██    ██      ██ ██      ██         ██                     │
# │ ██████  ██████  ██    ██      ██ █████   ██         ██                     │
# │ ██      ██   ██ ██    ██ ██   ██ ██      ██         ██                     │
# │ ██      ██   ██  ██████   █████  ███████  ██████    ██                     │
# ╘════════════════════════════════════════════════════════════════════════════╛

project( godot-flatbuffers-extension
        VERSION 1.0
        DESCRIPTION ""
        LANGUAGES CXX)

### Global options
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_subdirectory( src )

add_library( "godot-flatbuffers" SHARED )

target_sources( "godot-flatbuffers"
    PRIVATE
        ${SOURCES}
        ${DOC_SOURCE_PATH}
)

# conditionally add doc data to compile output
if(GODOTCPP_TARGET MATCHES "editor|template_debug")
    file(GLOB_RECURSE DOC_XML LIST_DIRECTORIES NO CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/doc_classes/*.xml")
    target_doc_sources( "godot-flatbuffers" "${DOC_XML}" )
endif()

target_link_libraries( "godot-flatbuffers" PRIVATE godot-cpp FlatBuffers::FlatBuffers)

set_target_properties( "godot-flatbuffers"
        PROPERTIES
        FOLDER "godot-flatbuffers"
        #The generator expression here prevents a subdir from being created.
        RUNTIME_OUTPUT_DIRECTORY "$<1:${GDE_INSTALL_PATH}/bin>"
        OUTPUT_NAME "${GDE_NAME}.${GODOTCPP_SUFFIX}$<$<CONFIG:Debug,RelWithDebInfo>:.$<LOWER_CASE:$<CONFIG>>>"
        PREFIX ""
)
