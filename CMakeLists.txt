cmake_minimum_required(VERSION 3.28)

# The name of the project is used for the build target
project( godot-flatbuffers-extension
        VERSION 1.0
        DESCRIPTION ""
        LANGUAGES CXX)

cmake_policy(SET CMP0077 NEW ) # don't let option(...) to reset my values
# FIXME this only appears to work for my own code, not the imported code from godot-cpp.
if( CMAKE_C_COMPILER )
    #Do nothing, just shut up the build because clion adds this from the toolchain
endif ()

### Independent Global CMake options
list( APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/" )
include(FetchContent)
include(CMakePrintHelpers)
include(PreventInSourceBuilds)
include(options.cmake)


### Global options
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
# Output Directory
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/${GODOT_PROJECT_PATH}/addons/${GDE_NAME}/bin )

### Add Flatbuffers as a sub project
FetchContent_Declare( FlatBuffers
        GIT_REPOSITORY "https://github.com/enetheru/flatbuffers.git"
        GIT_TAG "gdscript"
        SOURCE_DIR "${PROJECT_SOURCE_DIR}/flatbuffers"
        UPDATE_DISCONNECTED ON
)
FetchContent_MakeAvailable( FlatBuffers )

# If we dont want to build the extension then we can stop here
# This does break any other targets for this configuration
# so currently only useful for building flatc.
if( NOT BUILD_EXTENSION )
    return()
endif ()

### Generate target name
include(cmake/naming.cmake)
message( STATUS "Configuration:" )
message( "\tTarget Platform: ${GDE_TARGET_PLATFORM}")
message( "\tTarget Architecture: ${GDE_TARGET_ARCH}")
message( "\tTools Enabled: ${GODOT_CPP_TOOLS_ENABLED}")
message( "\tOutput Filename: ${GDE_OUTPUT_NAME}\n")

### Verify contents of GDExtension Directory
# TODO if the gdextension directory is specified then we dont need to dump-api
# This means I probably need to have a separate target for the files involved that can be satisfied either way

# Specify godot executable to pull version information from
# TODO Split this out into its own find-godot.cmake script
# Compiling godot from source appears to produce the following name:
# godot.<platform>.<target>[.dev][.double].<arch>[.custom_suffix][.console].exe
# so in my case its:
#   godot.windows.editor.x86_64.exe
#   godot.windows.editor.x86_64.console.exe
# Godot find paths
# TODO Find godot automatically if not specified.
# - installed locally
# - installed by steam
list( APPEND GODOT_FIND_NAMES ${GODOT_EXECUTABLE_NAME} )
list( APPEND GODOT_FIND_NAMES "godot.windows.opt.tools.64.exe" ) #steam exe name
list( APPEND GODOT_FIND_PATHS "/Program Files/ (x86)/Steam/steamapps/common/Godot\ Engine") #steam exe path
list( APPEND GODOT_FIND_PATHS "/git/godot/bin")

# This does not run if CMAKE_EXECUTABLE is already set.
if( GODOT_EXECUTABLE STREQUAL "" )
    unset( GODOT_EXECUTABLE CACHE )
endif()

find_program( GODOT_EXECUTABLE
        NAMES ${GODOT_FIND_NAMES}
        PATHS ${GODOT_FIND_PATHS} )

if (NOT GODOT_EXECUTABLE)
    message( WARNING "Missing Godot Executable: ${GODOT_EXECUTABLE}")
    message( FATAL_ERROR "Specify godot.exe on the commandline by adding -DGODOT_EXECUTABLE=<path to godot.exe>")
else ()
    # Determine the godot version using the executable.
    include( godot-version )
endif ()

### Dump extension-api and gdextension-interface
include( godot-dump )

### We add the dump target so that the sources can be relied upon. if it weren't for the fact that the generation of
# the api in godot-cpp was constructed at configure time I could use add_custom_command
add_custom_target(dump_api DEPENDS
        ${GODOT_GDEXTENSION_DIR}/gdextension_interface.h
        ${GODOT_CUSTOM_API_FILE})

### Fetch and configure Godot C++ GDExtension interface(godot-cpp)
# TODO optionally use the GODOT_CPP_DIR and dont fetch

# We need git to perform some actions so make sure we have it.
find_program(GIT_EXECUTABLE NAMES "git" DOC "" NO_CACHE REQUIRED)
if( NOT EXISTS "${GIT_EXECUTABLE}" )
    message( FATAL_ERROR "Unable to find Git at: '${GIT_EXECUTABLE}'")
endif()

# if we dont have a tag specified, try to match up our godot.exe version and the remote godot-cpp repo.
if( GODOT_CPP_GIT_TAG STREQUAL "" )
    include( godot-cpp-git-tag )
endif()

message( STATUS "Fetching ${GODOT_CPP_GIT_URL} : ${GODOT_CPP_GIT_TAG}")
FetchContent_Declare(godot-cpp
        GIT_REPOSITORY "${GODOT_CPP_GIT_URL}"
        GIT_TAG "${GODOT_CPP_GIT_TAG}"
        GIT_SHALLOW ON
        SOURCE_DIR "${GODOT_CPP_DIR}"
)

if(NOT godot-cpp_POPULATED)
    FetchContent_Populate(godot-cpp)

    set(GODOT_CPP_SYSTEM_HEADERS ON CACHE INTERNAL "Mark the header files as SYSTEM. This may be useful to supress warnings in projects including this one." )
    set(GODOT_CPP_WARNING_AS_ERROR ON CACHE INTERNAL "Treat any warnings as errors" )
    set(GODOT_CUSTOM_API_FILE ${PROJECT_SOURCE_DIR}/gdextension/extension_api.json CACHE INTERNAL "Path to a custom GDExtension API JSON file (takes precedence over `gdextension_dir`)" )
    set(FLOAT_PRECISION "single" CACHE INTERNAL "docstring" )

    add_subdirectory(godot-cpp)
endif()
# TODO add any additional godot-cpp definitions here.
# TODO unset any exclusively godot-cpp variable here.
# Add dependency to dump_api
add_dependencies(godot-cpp dump_api)

# At this point godot-cpp has been configured using our cached variables, but it's not enough to enable some features.
# We need to figure out and override things like build and link flags because the godot-cpp cmake project
# doesn't have feature parity with the scons build.

# Scrub the options so we can start again.
set_target_properties( godot-cpp
        PROPERTIES
#        COMPILE_OPTIONS ""
#        COMPILE_FLAGS ""
        LINK_OPTIONS ""
        LINK_FLAGS ""
)

if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC") # using Visual Studio C++
    include(cmake/msvc.cmake)
elseif (CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
    include(cmake/gcc.cmake)
else ()
    message(FATAL_ERROR "${CMAKE_CXX_COMPILER_ID} Compiler is not supported")
endif ()

### Platform
# TODO properly separate out these things.
# platforms = ("linux", "macos", "windows", "android", "ios", "web")

### Code Features
#TODO move these compile definitions to the targets so they dont pollute other packages that we might want.
add_compile_definitions("GDEXTENSION")
target_compile_definitions( godot-cpp PRIVATE "GDEXTENSION" )

if (CMAKE_BUILD_TYPE MATCHES Debug)
    # DEBUG_ENABLED enables debugging *features* and debug-only code, which is intended
    # to give *users* extra debugging information for their game development.
    # DEBUG_METHODS_ENABLED is added to typedefs.h in Godot when DEBUG_ENABLED is set.
    add_compile_definitions("DEBUG_ENABLED" "DEBUG_METHODS_ENABLED")
else ()
    # define NDEBUG to disable assert() for production targets (only used in third-party code)
    add_compile_definitions("NDEBUG")
endif ()

# if editor tools are intended to be enabled.
# Analogous to the target=editor from scons
if (GODOT_CPP_TOOLS_ENABLED)
    target_compile_definitions(godot-cpp PUBLIC "TOOLS_ENABLED")
endif ()

# Hot reload
# TODO, the original logic was if unspecified enable in debug and editor builds
if (GODOT_ENABLE_HOT_RELOAD)
    target_compile_definitions(godot-cpp PUBLIC "HOT_RELOAD_ENABLED")
endif ()

if (FLOAT_PRECISION STREQUAL "double" )
    add_compile_definitions("REAL_T_IS_DOUBLE")
endif ()

### separate CMakeLists for our gdextension sources.
add_library( ${GDE_NAME} SHARED )

add_subdirectory(src)

target_include_directories( ${GDE_NAME} SYSTEM PUBLIC godot-cpp FlatBuffers::FlatBuffers )
target_link_libraries( ${GDE_NAME} PUBLIC godot-cpp FlatBuffers::FlatBuffers )

set_target_properties( ${GDE_NAME}
        PROPERTIES
        OUTPUT_NAME "${GDE_OUTPUT_NAME}"
)

## Add a dummy target for when I need to debug from clion.
## This needs additional configuration from the clion side of things to make it work
# * The executable to run
# * The command line options ie -e --path
add_custom_target(demo_project DEPENDS ${GDE_NAME})
