cmake_minimum_required(VERSION 3.28)

# The name of the project is used for the build target
project( gdexample
        VERSION 1.0
        DESCRIPTION ""
        LANGUAGES CXX)

cmake_policy(SET CMP0077 NEW ) # don't let option(...) to reset my values TODO this needs testing.

### Independent Global CMake options
list( APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/" )
include(CMakePrintHelpers)
include(PreventInSourceBuilds)
include(options.cmake)


### Global options
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
# Output Directory
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/${GODOT_PROJECT_PATH}/bin )

### Generate target name
include(cmake/naming.cmake)
message("Target Platform: ${GDE_TARGET_PLATFORM}")
message("Target Architecture: ${GDE_TARGET_ARCH}")
message("Output Filename: ${GDE_OUTPUT_NAME}")

### Verify contents of GDExtension Directory
# TODO if the gdextension directory is specified then we dont need to dump-api
# This means I probably need to have a separate target for the files involved that can be satisfied either way

# Specify godot executable to pull version information from
# Godot's compile name appears to be
# godot.<platform>.<target>[.dev][.double].<arch>[.custom_suffix][.console].exe
# so in my case its:
#   godot.windows.editor.x86_64.exe
#   godot.windows.editor.x86_64.console.exe
# Godot find paths
# TODO Find godot automatically if not specified.
# - installed locally
# - installed by steam

set(GODOT_FIND_NAMES "") # FIXME generate a list of names
set(GODOT_FIND_PATHS "") # FIXME Add a list of common locations

# This does not run if CMAKE_EXECUTABLE is already set.
find_program(GODOT_EXECUTABLE NAMES ${GODOT_FIND_NAMES} PATHS ${GODOT_FIND_PATHS} DOC "" NO_CACHE REQUIRED)

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
# the api in godot-cpp was constructed at configure time I could use add_custom_command above instead of execute process
add_custom_target(dump_api DEPENDS
        ${PROJECT_SOURCE_DIR}/${GODOT_DUMP_DIR}/gdextension_interface.h
        ${GODOT_API_JSON})

### Fetch and configure Godot C++ GDExtension interface(godot-cpp)
# TODO optionally use the GEL_DIR and dont fetch

# We need git to perform some actions so make sure we have it.
find_program(GIT_EXECUTABLE NAMES "git" DOC "" NO_CACHE REQUIRED)
if( NOT EXISTS "${GIT_EXECUTABLE}" )
    message( FATAL_ERROR "Unable to find Git at: '${GIT_EXECUTABLE}'")
endif()

# if we dont have a tag specified, try to match up our godot.exe version and the remote godot-cpp repo.
if( GEL_GIT_TAG STREQUAL "" )
    include( godot-cpp-git-tag )
endif()

include(FetchContent)
FetchContent_Declare(godot-cpp
        GIT_REPOSITORY "${GEL_GIT_URL}"
        GIT_TAG "${GEL_GIT_TAG}"
        GIT_SHALLOW ${GEL_GIT_SHALLOW}
        SOURCE_DIR "${PROJECT_SOURCE_DIR}/${GEL_DIR}"
)
FetchContent_MakeAvailable(godot-cpp)
# Add dependency to dump_api
add_dependencies(godot-cpp dump_api)

# At this point godot-cpp has been configured using our cached variables, but it's not enough to enable some features.
# We need to figure out and override things like build and link flags because the godot-cpp cmake project
# doesn't have feature parity with the scons build.

# Scrub the options so we can start again.
set_target_properties( godot-cpp
        PROPERTIES
        COMPILE_OPTIONS ""
        COMPILE_FLAGS ""
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
#TODO move these compile definitions to the tagets so they dont polute other packages thay we might want.
add_compile_definitions("GDEXTENSION")

if (CMAKE_BUILD_TYPE MATCHES Debug)
    # DEBUG_ENABLED enables debugging *features* and debug-only code, which is intended
    # to give *users* extra debugging information for their game development.
    # DEBUG_METHODS_ENABLED is added to typedefs.h in Godot when DEBUG_ENABLED is set.
    add_compile_definitions("DEBUG_ENABLED" "DEBUG_METHODS_ENABLED")
endif ()

# DEV_ENABLED enables *engine developer* code which should only be compiled for those working on the engine itself.
if (DEV_ENABLED)
    add_compile_definitions("DEV_ENABLED")
else ()
    # define NDEBUG to disable assert() for production targets (only used in third-party code)
    add_compile_definitions("NDEBUG")
endif ()

# if editor tools are intended to be enabled.
# Analogous to the target=editor from scons
if (TOOLS_ENABLED)
    add_compile_definitions("TOOLS_ENABLED")
endif ()

# Hot reload
# TODO, the original logic was if unspecified enable in debug and editor builds
if (USE_HOT_RELOAD)
    add_compile_definitions("HOT_RELOAD_ENABLED")
endif ()

if (FLOAT_DOUBLE)
    add_compile_definitions("REAL_T_IS_DOUBLE")
endif ()

### separate CMakeLists for our gdextension sources.
add_subdirectory(src)

# TODO add all targets as separate configurations
#   editor|template_release|template_debug

## Add a dummy target for when I need to debug from clion.
## This needs additional configuration from the clion side of things to make it work
# * The executable to run
# * The command line options ie -e --path
add_custom_target(copy_lib DEPENDS ${PROJECT_NAME})
add_custom_command(TARGET copy_lib COMMAND "") # TODO copy build artifact to demo project folder
add_custom_target(demo_project DEPENDS ${PROJECT_NAME})
