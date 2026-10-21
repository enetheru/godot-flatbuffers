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

# Empty: cmake --install writes <source>/install.
# A Godot project (directory with project.godot): the addon goes under addons/.
set( GODOT_PROJECT_PATH "" CACHE PATH
        "Godot project to install the addon into. Empty installs under <source>/install." )

set( AUTHOR_TAG "Enetheru")
string( TOLOWER "${AUTHOR_TAG}" AUTHOR_TAG_LOWER )

## Target options
set( GDE_NAME "flatbuffers" )
set( GDE_INSTALL_NAME "${AUTHOR_TAG_LOWER}.${GDE_NAME}-extension" )

# Doctool still has a demo tree. Install does not use it unless it is the path above.
if( GODOT_PROJECT_PATH )
    set( GODOT_DEMO_PATH "${GODOT_PROJECT_PATH}" )
else()
    set( GODOT_DEMO_PATH "${CMAKE_CURRENT_SOURCE_DIR}/project" )
endif()

#[==============================[ Dependencies ]==============================]
include(FetchContent)
include(CMakePrintHelpers)

include(cmake/findGodotExecutable.cmake)
include(cmake/godot-dump.cmake)
include(cmake/godot-docs.cmake)
include(cmake/gdextension_install.cmake)

find_package(Python3 3.4 REQUIRED) # pathlib should be present

#[==============[ Git ]==============]
find_program(GIT_EXECUTABLE NAMES "git" DOC "" NO_CACHE REQUIRED)
if( NOT EXISTS "${GIT_EXECUTABLE}" )
    message( FATAL_ERROR "Unable to find Git at: '${GIT_EXECUTABLE}'")
endif()

# godot-cpp calls project() before this file does, and that claims
# CMAKE_INSTALL_PREFIX (Program Files/<project name>). Set it first.
if( GODOT_PROJECT_PATH )
    set( _gdfb_install_root "${GODOT_PROJECT_PATH}" )
else()
    set( _gdfb_install_root "${CMAKE_CURRENT_SOURCE_DIR}/install" )
endif()
set( _gdfb_cached_prefix "" )
if( DEFINED CACHE{CMAKE_INSTALL_PREFIX} )
    set( _gdfb_cached_prefix "$CACHE{CMAKE_INSTALL_PREFIX}" )
endif()
set( _gdfb_prefix_applied "" )
if( DEFINED CACHE{GDFB_INSTALL_ROOT_APPLIED} )
    set( _gdfb_prefix_applied "$CACHE{GDFB_INSTALL_ROOT_APPLIED}" )
endif()
set( _gdfb_prefix_stolen FALSE )
if( _gdfb_cached_prefix MATCHES "/Program Files( \\(x86\\))?/(FlatBuffers|godot-cpp|stduuid)$" )
    set( _gdfb_prefix_stolen TRUE )
endif()
if( NOT _gdfb_cached_prefix OR _gdfb_prefix_stolen
        OR _gdfb_cached_prefix STREQUAL _gdfb_prefix_applied )
    set( CMAKE_INSTALL_PREFIX "${_gdfb_install_root}" CACHE PATH
            "Install root. A Godot project (has project.godot) receives addons/${GDE_INSTALL_NAME}."
            FORCE )
    set( GDFB_INSTALL_ROOT_APPLIED "${_gdfb_install_root}" CACHE INTERNAL
            "Install root last written by this project." FORCE )
endif()

# MARK: godot-cpp
# ╒════════════════════════════════════════════════════════════════════════════╕
# │  ██████   ██████  ██████   ██████  ████████     ██████ ██████  ██████      │
# │ ██       ██    ██ ██   ██ ██    ██    ██       ██      ██   ██ ██   ██     │
# │ ██   ███ ██    ██ ██   ██ ██    ██    ██ █████ ██      ██████  ██████      │
# │ ██    ██ ██    ██ ██   ██ ██    ██    ██       ██      ██      ██          │
# │  ██████   ██████  ██████   ██████     ██        ██████ ██      ██          │
# ╘════════════════════════════════════════════════════════════════════════════╛

set( GODOTCPP_GIT_URL "https://github.com/godotengine/godot-cpp.git" CACHE STRING "Location of the godot-cpp git repository" )
# godot-4.5-stable. A commit, so the tag moving does not move this build.
set( GODOTCPP_GIT_TAG "e83fd0904c13356ed1d4c3d09f8bb9132bdc6b77" CACHE STRING
        "godot-cpp commit to fetch. Default is the godot-4.5-stable tag." )
if( GODOTCPP_GIT_TAG STREQUAL "godot-4.5-stable" )
    set( GODOTCPP_GIT_TAG "e83fd0904c13356ed1d4c3d09f8bb9132bdc6b77" CACHE STRING
            "godot-cpp commit to fetch. Default is the godot-4.5-stable tag." FORCE )
endif()

set( GODOTCPP_TARGET "editor" CACHE STRING "")
set( GODOTCPP_BUILD_PROFILE "${CMAKE_CURRENT_SOURCE_DIR}/src/godot-cpp.build_profile.json")
set( GODOTCPP_USE_HOT_RELOAD ON)

#if( GODOT_GIT_TAG STREQUAL "" )
#    include( godot-cpp-git-tag )
#endif()

# Later configures must not contact the remote. A new commit has to already
# be in this clone, or lib/godot-cpp has to be removed so the clone runs again.
set( FETCHCONTENT_UPDATES_DISCONNECTED_GODOT-CPP ON )

FetchContent_Declare( godot-cpp
        GIT_REPOSITORY  "${GODOTCPP_GIT_URL}"
        GIT_TAG         "${GODOTCPP_GIT_TAG}"
        SOURCE_DIR      "${CMAKE_CURRENT_SOURCE_DIR}/lib/godot-cpp"
        SYSTEM
        EXCLUDE_FROM_ALL
)
if( BUILD_EXTENSION )
    FetchContent_MakeAvailable( godot-cpp )
endif()

### Get useful properties of the library
if( BUILD_EXTENSION )
    get_target_property( GODOTCPP_SUFFIX godot-cpp GODOTCPP_SUFFIX_GENEX )
    get_target_property( GODOTCPP_PLATFORM godot-cpp GODOTCPP_PLATFORM )
    get_target_property( GODOTCPP_TARGET godot-cpp GODOTCPP_TARGET )
    get_target_property( GODOTCPP_ARCH godot-cpp GODOTCPP_ARCH )
endif()

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

# MARK: flatbuffs
# ╒════════════════════════════════════════════════════════════════════════════╕
# │ ███████ ██       █████  ████████ ██████  ██    ██ ███████ ███████ ███████  │
# │ ██      ██      ██   ██    ██    ██   ██ ██    ██ ██      ██      ██       │
# │ █████   ██      ███████    ██    ██████  ██    ██ █████   █████   ███████  │
# │ ██      ██      ██   ██    ██    ██   ██ ██    ██ ██      ██           ██  │
# │ ██      ███████ ██   ██    ██    ██████   ██████  ██      ██      ███████  │
# ╘════════════════════════════════════════════════════════════════════════════╛

# Submodule, not FetchContent. The parent records the commit. CMake does not fetch it.
set( _flatbuffers_dir "${CMAKE_CURRENT_SOURCE_DIR}/lib/flatbuffers" )
if( NOT EXISTS "${_flatbuffers_dir}/CMakeLists.txt" )
    message( FATAL_ERROR
            "lib/flatbuffers is not checked out. From the extension repo: git submodule update --init lib/flatbuffers" )
endif()

set( FLATBUFFERS_BUILD_FLATHASH     NO )
set( FLATBUFFERS_BUILD_SHAREDLIB    NO )
set( FLATBUFFERS_BUILD_TESTS        NO )
set( FLATBUFFERS_INSTALL            NO )
set( FLATBUFFERS_STATIC_FLATC      YES )
set( FLATBUFFERS_BUILD_FLATC       YES )
set( FLATBUFFERS_CPP_STD            17 )
set( FLATBUFFERS_BUILD_CPP17       YES )

add_subdirectory( lib/flatbuffers EXCLUDE_FROM_ALL SYSTEM )

set_target_properties(
        flatc
        PROPERTIES
        EXCLUDE_FROM_ALL OFF
        OUTPUT_NAME "flatc$<$<CONFIG:Debug,RelWithDebInfo>:.$<LOWER_CASE:$<CONFIG>>>"
        RUNTIME_OUTPUT_DIRECTORY "$<1:${CMAKE_BINARY_DIR}/bin>"
)

# MARK: extension
# ╒════════════════════════════════════════════════════════════════════════════╕
# │ Extension                                                                  │
# ╘════════════════════════════════════════════════════════════════════════════╛

# If we dont want to build the extension then we can stop here
# This does break any other targets for this configuration
# so currently only useful for building flatc.
if( NOT BUILD_EXTENSION )
    return()
endif ()

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

# Printed at startup so a loaded editor binary can be told apart from another build.
target_compile_definitions( "godot-flatbuffers"
        PRIVATE
        "FLATBUFFERS_BUILD_TARGET=${GODOTCPP_TARGET}"
        "FLATBUFFERS_BUILD_CONFIG=$<CONFIG>"
)

set_target_properties( "godot-flatbuffers"
        PROPERTIES
        FOLDER "godot-flatbuffers"
        # The build stays in the build tree. cmake --install copies it.
        # $<1:> keeps multi-config generators from adding a per-config directory.
        RUNTIME_OUTPUT_DIRECTORY "$<1:${CMAKE_BINARY_DIR}/bin>"
        LIBRARY_OUTPUT_DIRECTORY "$<1:${CMAKE_BINARY_DIR}/bin>"
        OUTPUT_NAME "${GDE_NAME}.${GODOTCPP_SUFFIX}$<$<CONFIG:Debug,RelWithDebInfo>:.$<LOWER_CASE:$<CONFIG>>>"
        PREFIX ""
)

gdextension_install()
