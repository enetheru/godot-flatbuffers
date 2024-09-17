cmake_minimum_required(VERSION 3.28)

# The name of the project is used for the build target
project( godot-flatbuffers-extension
        VERSION 1.0
        DESCRIPTION ""
        LANGUAGES CXX)

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
        SOURCE_DIR "${PROJECT_SOURCE_DIR}/lib/flatbuffers"
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
endif()

add_subdirectory( ${GODOT_CPP_DIR} )
include( cmake/godotcpp.cmake )

# Add dependency to dump_api
add_dependencies(godot-cpp dump_api)

### separate CMakeLists for our gdextension sources.
add_library( ${GDE_NAME} SHARED )

add_subdirectory(src)

target_include_directories( ${GDE_NAME} SYSTEM PUBLIC godot-cpp FlatBuffers::FlatBuffers )
target_link_libraries( ${GDE_NAME} PUBLIC godot-cpp FlatBuffers::FlatBuffers )

set_target_properties( ${GDE_NAME}
        PROPERTIES
        OUTPUT_NAME "${GDE_OUTPUT_NAME}"
)
