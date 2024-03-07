### Cmake options to expose
set( CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "Generate compilation DB (`compile_commands.json`) for external tools")
# TODO set( GDE_COMPILE_COMMANDS_PATH "" CACHE STRING "Path to a custom `compile_commands.json` file ( /path/to/compiledb_file )" )
# Currently cmake does not support changing the path of the compile commands file.

### Our own options can go here
option( MY_BOOL "docstring" OFF )
set( MY_PATH "default_value" CACHE PATH "docstring" )
set( MY_SELECTION "" CACHE STRING "docstring: valid options are{'first','second','third'}")
set_property( CACHE MY_SELECTION PROPERTY STRINGS "first" "second" "third" )

set( USE_LD "" CACHE STRING "which linker to use" )
set_property( CACHE USE_LD PROPERTY STRINGS "" "bfd" "lld" "gold" "mold" )

### godot-cpp Option Rationale
# Rather than expose the options for the consumed godot-cpp library, I have chosen to abstract them behind top level
# options to keep them grouped together
## GODOT_   Godot executable and related
## GEL_     Godot Extension Library aka godot-cpp
## GDE_     GDExtension AKA this project

## Target options
set( GDE_CUSTOM_SUFFIX "" CACHE STRING "an additional suffix you can append to builds" )
set( GDE_OUTPUT_NAME "" CACHE STRING "A custom output name, resulting binary will be: OUTPUT_NAME[.CUSTOM_SUFFIX].dll" )

### Information regarding the godot executable
set( GODOT_EXECUTABLE "" CACHE PATH "Path to the godot executable you are targeting" )
set( GODOT_PROJECT_PATH "project" CACHE STRING "Path to a demo project that can test the gdextension" )
### Path information for the gdextension_interface.h and the extension_api.json
set( GODOT_DUMP_DIR "gdextension" CACHE PATH "Path to the api.json and headers exported from the godot executable, if we're generating this is where they will go" )
set( GODOT_API_JSON "${PROJECT_SOURCE_DIR}/${GODOT_DUMP_DIR}/extension_api.json" CACHE PATH "Location of extension_api.json, default is '${GODOT_DUMP_DIR}/extension_api.json'" )

### Options relating to the godot-cpp Extension Library
set(    GEL_DIR "godot-cpp" CACHE PATH "Path to the directory containing the godot-cpp GDExtension library, if we're fetching then this is where it will go" )

## Git repo info for fetching if there is no api dir set.
set(    GEL_GIT_URL "https://github.com/godotengine/godot-cpp.git" CACHE STRING "Location of the godot-cpp git respository" )
set(    GEL_GIT_TAG "" CACHE STRING "The git tag to use when pulling godot-cpp, will try to automatically detect based on godot.exe --version" )
option( GEL_GIT_SHALLOW "" ON)

## Configure options for godot-cpp - Copied to the equivalent cmake options
option( GEL_HEADERS_AS_SYSTEM   "Mark the godot-cpp header files as SYSTEM to suppress warnings from godot-cpp" ON )
option( GEL_WARNING_AS_ERROR    "Treat any compilation warnings from godot-cpp as errors" OFF )
option( GEL_GENERATE_TEMPLATE_GET_NODE "Generate a template version of the Node class's get_node." ON )
option( GEL_DISABLE_EXCEPTIONS "Force disabling exception handling code" ON)
set(    GEL_FLOAT_PRECISION "single" CACHE STRING "Floating-point precision level ('single', 'double')" )
set_property( CACHE GEL_FLOAT_PRECISION PROPERTY STRINGS "single" "double" )

### Additional configure options because the default generation of the cmake is limited.
#TODO option( GDE_DOCS "Generate Documentation" OFF )
## Code Feature Options
option( GEL_DEV_BUILD "Developer build with dev-only debugging code" OFF)
option( GEL_HOT_RELOAD "Enable the extra accounting required to support hot reload" ON)
option( GEL_TOOLS_ENABLED "Enable editor features" OFF)

## Compilation and linking
option( GEL_HIDE_SYMBOLS "Hide symbols visibility on GNU platforms" OFF )
option( GEL_USE_STATIC_CPP "Link MinGW/MSVC C++ runtime libraries statically" ON)
option( GEL_DEBUG_SYMBOLS "Build with debugging symbols" ON) # TODO This might be able to be handled by cmake

set(    GEL_OPTIMISATION_MODE "speed_trace" CACHE STRING "The desired optimization flags (none|custom|debug|speed|speed_trace|size)" )
set_property( CACHE GEL_OPTIMISATION_MODE PROPERTY STRINGS "none" "custom" "debug" "speed" "speed_trace" "size" )

### Options consumed by godot-cpp
# Explicitly mentioned in the documentation
# CMAKE_BUILD_TYPE:			Compilation target (Debug or Release defaults to Debug)
set( GODOT_GDEXTENSION_DIR "${GODOT_DUMP_DIR}" CACHE INTERNAL "Path to the directory containing GDExtension interface header and API JSON file")
set( GODOT_CPP_SYSTEM_HEADERS ${GEL_HEADERS_AS_SYSTEM} CACHE INTERNAL "Mark the header files as SYSTEM. This may be useful to supress warnings in projects including this one")
set( GODOT_CPP_WARNING_AS_ERROR	${GEL_WARNING_AS_ERROR} INTERNAL "Treat any warnings as errors" )
set( GODOT_CUSTOM_API_FILE "${GODOT_API_JSON}" CACHE  INTERNAL "Path to a custom GDExtension API JSON file (takes precedence over `gdextension_dir`" )
set( FLOAT_PRECISION "${GEL_FLOAT_PRECISION}" CACHE  INTERNAL "Floating-point precision level ('single', 'double')" )

# Android cmake arguments
# CMAKE_TOOLCHAIN_FILE:		The path to the android cmake toolchain ($ANDROID_NDK/build/cmake/android.toolchain.cmake)
# ANDROID_NDK:				The path to the android ndk root folder
# ANDROID_TOOLCHAIN_NAME:	The android toolchain (arm-linux-androideabi-4.9 or aarch64-linux-android-4.9 or x86-4.9 or x86_64-4.9)
# ANDROID_PLATFORM:			The android platform version (android-23)
# More info here: https://godot.readthedocs.io/en/latest/development/compiling/compiling_for_android.html

### additional explicitly stated as a cached set or option command but not listed in the docstring at the top
set(GENERATE_TEMPLATE_GET_NODE ${GEL_GENERATE_TEMPLATE_GET_NODE} CACHE INTERNAL "Generate a template version of the Node class's get_node." )
set(GODOT_DISABLE_EXCEPTIONS ${GEL_DISABLE_EXCEPTIONS} CACHE INTERNAL "Force disabling exception handling code" )

### used within the project but not cached or exposed as options
#set( BITS "" CACHE STRING INTERNAL "this is defaulted to the host system processor bits 32/64" )
#set_property( CACHE BITS PROPERTY STRINGS "32" "64" )
#set( GODOT_GDEXTENSION_API_FILE "${GODOT_GDEXTENSION_DIR}/extension_api.json" CACHE PATH INTERNAL "Location of extension_api.json")

### Options that show up in scons but are missing from cmake
# Presets
#TODO target: Compilation target (editor|template_release|template_debug)

# Code Features
#TODO use_hot_reload: Enable the extra accounting required to support hot reload. (yes|no)
#TODO dev_build: Developer build with dev-only debugging code (DEV_ENABLED) (yes|no)

# Compiler and linker Options
#TODO symbols_visibility: Symbols visibility on GNU platforms. Use 'auto' to apply the default value. (auto|visible|hidden)
#TODO use_static_cpp: Link MinGW/MSVC C++ runtime libraries statically (yes|no)
#TODO optimize: The desired optimization flags (none|custom|debug|speed|speed_trace|size) default: speed_trace
#TODO debug_symbols: Build with debugging symbols (yes|no)  default: True

## Toolchain options include target platform and architecture
#TODO platform: Target platform (linux|macos|windows|android|ios|web)
#TODO arch: CPU architecture (|universal|x86_32|x86_64|arm32|arm64|rv64|ppc32|ppc64|wasm32)
#TODO use_llvm: Use the LLVM compiler - only effective when targeting Linux (yes|no)
#TODO use_mingw: Use the MinGW compiler instead of MSVC - only effective on Windows (yes|no)
#TODO use_clang_cl: Use the clang driver instead of MSVC - only effective on Windows (yes|no)

## Build configuration
#TODO generate_bindings: Force GDExtension API bindings generation. Auto-detected by default. (yes|no)
#TODO build_library: Build the godot-cpp library. (yes|no)
#TODO compiledb_file: Path to a custom `compile_commands.json` file ( /path/to/compiledb_file )

# Mac development
#TODO macos_deployment_target: macOS deployment target
#TODO macos_sdk_path: macOS SDK path

# ios development
#TODO ios_simulator: Target iOS Simulator (yes|no)
#TODO ios_min_version: Target minimum iphoneos/iphonesimulator version
#TODO IOS_TOOLCHAIN_PATH: Path to iOS toolchain default: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
#TODO IOS_SDK_PATH: Path to the iOS SDK

# android development
#TODO android_api_level: Target Android API level
#TODO ANDROID_HOME: Path to your Android SDK installation. By default, uses ANDROID_HOME from your defined environment variables.