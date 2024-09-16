### Cmake options to expose
set( CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "Generate compilation DB (`compile_commands.json`) for external tools")

# Compilation targets (editor|template_release|template_debug) default is Debug
# editor = Debug
# template_release = Release
# template_debug = RelWithDebugInfo

# So that I can condifgure for the flatc compiler, and not the extension.
set( BUILD_EXTENSION ON CACHE STRING "build the extension" )

## Target options
set( GDE_NAME "my_extension" CACHE STRING "The name of the extension library" )
set( GDE_SUFFIX "" CACHE STRING "an additional suffix you can append to builds" )
set( GDE_OUTPUT_NAME "" CACHE STRING "A custom output name, resulting binary will be: GDE_NAME.{editor|template_{release|debug}}[.GDE_SUFFIX].dll" )

### Information regarding the godot executable
set( GODOT_EXECUTABLE "" CACHE FILEPATH "Path to the godot executable you are targeting" )
set( GODOT_PROJECT_PATH "project" CACHE PATH "Path to a demo project that can test the gdextension" )

set( GODOT_CUSTOM_API_FILE "extension_api.json" CACHE FILEPATH
        "Location of extension_api.json, default is 'extension_api.json'" )

## Git repo info for fetching if there is no api dir set.
set( GODOT_CPP_GIT_URL "https://github.com/godotengine/godot-cpp.git" CACHE STRING "Location of the godot-cpp git respository" )
set( GODOT_CPP_GIT_TAG "" CACHE STRING "The git tag to use when pulling godot-cpp, will try to automatically detect based on godot.exe --version" )

### Options relating to the godot-cpp Extension Library
set( GODOT_CPP_DIR "${PROJECT_SOURCE_DIR}/lib/godot-cpp" CACHE PATH "Path to the directory containing the godot-cpp GDExtension library, if we're fetching then this is where it will go" )

## Configure options for godot-cpp
option( GODOT_CPP_SYSTEM_HEADERS   "Mark the godot-cpp header files as SYSTEM to suppress warnings from godot-cpp" OFF )
option( GODOT_CPP_WARNING_AS_ERROR "Treat any compilation warnings from godot-cpp as errors" ON )
option( GENERATE_TEMPLATE_GET_NODE "Generate a template version of the Node class's get_node." ON )
option( GODOT_DISABLE_EXCEPTIONS   "Force disabling exception handling code" ON)

set( FLOAT_PRECISION "single" CACHE STRING "Floating-point precision level (single|double)")
set_property( CACHE FLOAT_PRECISION PROPERTY STRINGS "single" "double" )


### Additional configure options because the default generation of the cmake is limited.
#TODO option( GDE_DOCS "Generate Documentation" OFF )
## Code Feature Options


# Build with hot reload support. Defaults to YES for Debug-builds and NO for Release-builds

set( GODOT_COMPILE_FLAGS "" CACHE STRING "" )

option( GODOT_CPP_TOOLS_ENABLED "Enable editor features" ON)

## Compilation and linking

### Options consumed by godot-cpp
# Explicitly mentioned in the documentation

# Android cmake arguments
# CMAKE_TOOLCHAIN_FILE:		The path to the android cmake toolchain ($ANDROID_NDK/build/cmake/android.toolchain.cmake)
# ANDROID_NDK:				The path to the android ndk root folder
# ANDROID_TOOLCHAIN_NAME:	The android toolchain (arm-linux-androideabi-4.9 or aarch64-linux-android-4.9 or x86-4.9 or x86_64-4.9)
# ANDROID_PLATFORM:			The android platform version (android-23)
# More info here: https://godot.readthedocs.io/en/latest/development/compiling/compiling_for_android.html

### used within the project but not cached or exposed as options
#set( BITS "" CACHE STRING INTERNAL "this is defaulted to the host system processor bits 32/64" )
#set_property( CACHE BITS PROPERTY STRINGS "32" "64" )

### Options that show up in scons but are missing from cmake
# Presets

# Code Features
# use_hot_reload: Enable the extra accounting required to support hot reload. (yes|no)
option( GODOT_ENABLE_HOT_RELOAD "Enable the extra accounting required to support hot reload" ON)

# godot-cpp scons : dev_build
# godot-cpp cmake: missing
# Developer build with dev-only debugging code (DEV_ENABLED) (ON|OFF)
# This option in the scons system works like a preset, and sets the defaults for other settings.
# sets 'opt_level' = 'none' # NOTE 'opt_level' = 'optimise'.
# sets 'debug_symbols' default value set to whatever dev_build is
# defines DEV_ENABLED, NOTE: This is not used in godot-cpp source code.
# appends '.dev' suffix to output filename
option( GODOT_CPP_DEV_BUILD "Developer build with dev-only debugging code (DEV_ENABLED)" OFF)

# Compiler and linker Options
# symbols_visibility: Symbols visibility on GNU platforms. Use 'auto' to apply the default value. (auto|visible|hidden)
option( GODOT_CPP_HIDE_SYMBOLS "Hide symbols visibility on GNU platforms" OFF )

# use_static_cpp: Link MinGW/MSVC C++ runtime libraries statically (yes|no)
option( GODOT_CPP_USE_STATIC_CPP "Link MinGW/MSVC C++ runtime libraries statically" ON )

# optimize: The desired optimization flags (none|custom|debug|speed|speed_trace|size) default: speed_trace
set( GODOT_CPP_OPTIMISATION_MODE "speed_trace" CACHE STRING "The desired optimization flags (none|custom|debug|speed|speed_trace|size)" )
set_property( CACHE GODOT_CPP_OPTIMISATION_MODE PROPERTY STRINGS "none" "custom" "debug" "speed" "speed_trace" "size" )

#TODO godot-cpp defines GDEXTENSION but it is not used in the sources.
#TODO debug_symbols: Build with debugging symbols (yes|no)  default: True

## Toolchain options include target platform and architecture
#TODO platform: Target platform (linux|macos|windows|android|ios|web)
#TODO arch: CPU architecture (|universal|x86_32|x86_64|arm32|arm64|rv64|ppc32|ppc64|wasm32)
#TODO use_llvm: Use the LLVM compiler - only effective when targeting Linux (yes|no)
#TODO use_mingw: Use the MinGW compiler instead of MSVC - only effective on Windows (yes|no)
#TODO use_clang_cl: Use the clang driver instead of MSVC - only effective on Windows (yes|no)

set( USE_LD "" CACHE STRING "which linker to use" )
set_property( CACHE USE_LD PROPERTY STRINGS "" "bfd" "lld" "gold" "mold" )

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
