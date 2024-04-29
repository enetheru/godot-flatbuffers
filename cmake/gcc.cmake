
### Default flags for all permutations
target_compile_options( godot-cpp PUBLIC "-fPIC" "-g" "-Wwrite-strings" )
target_link_options( godot-cpp PUBLIC "-Wl,--no-undefined" )

### Pull in dependencies statically
if( GODOT_CPP_USE_STATIC_CPP )
    target_link_options( godot-cpp
        PUBLIC
            "-static" "-static-libgcc" "-static-libstdc++" "-Wl,-R,'$$ORIGIN'")
endif()

### Disable exception handling.
# Godot doesn't use exceptions anywhere, and this saves around 20% of binary size and very significant build time (GH-80513).
if( GODOT_CPP_DISABLE_EXCEPTIONS )
    target_compile_options(godot-cpp PUBLIC
            "-fno-exceptions")
endif()

### Set optimize and debug_symbols flags.
# "custom" means do nothing and let users set their own optimization flags.
if( CMAKE_BUILD_TYPE MATCHES "Debug" )
    target_compile_options(godot-cpp PUBLIC
            "-fno-omit-frame-pointer" "-O0" "-Og")
    # Adding dwarf-4 explicitly makes stacktraces work with clang builds,
    # otherwise addr2line doesn't understand them.
    target_compile_options(godot-cpp PUBLIC  "-gdwarf-4")
    if( GODOT_CPP_DEV_BUILD )
        target_compile_options(godot-cpp PUBLIC  "-g3")
    else()
        target_compile_options(godot-cpp PUBLIC  "-g2")
    endif()
else()
    # Strip binaries
    if (CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
        # Apple Clang, its linker doesn't like -s.
        target_link_options( godot-cpp PUBLIC "-Wl,-S" "-Wl,-x" "-Wl,-dead_strip" )
    else()
        target_link_options( godot-cpp PUBLIC "-s" )
    endif()
endif()

# TODO wasnt this supposed to be for gnu platforms only ie linux?
if( GODOT_CPP_HIDE_SYMBOLS )
    target_compile_options( godot-cpp PUBLIC "-fvisibility=hidden" )
    target_link_options( godot-cpp PUBLIC "-fvisibility=hidden" )
endif()

### Optimisation level
if( GODOT_CPP_OPTIMISATION_MODE MATCHES "speed" )
    target_compile_options( godot-cpp PUBLIC "-fvisibility=hidden" )
    target_compile_options( godot-cpp PUBLIC "-O3" )
elseif( GODOT_CPP_OPTIMISATION_MODE STREQUAL "speed_trace" )
    # `-O2` is friendlier to debuggers than `-O3`, leading to better crash backtraces.
    target_compile_options( godot-cpp PUBLIC "-O2" )
elseif( GODOT_CPP_OPTIMISATION_MODE STREQUAL "size" )
    target_compile_options( godot-cpp PUBLIC "-Os" )
elseif( GODOT_CPP_OPTIMISATION_MODE STREQUAL "debug" )
    target_compile_options( godot-cpp PUBLIC "-Og" )
elseif( GODOT_CPP_OPTIMISATION_MODE STREQUAL "none" )
    target_compile_options( godot-cpp PUBLIC "-O0" )
endif()

#Linker to use
if( USE_LD )
    add_link_options( "-fuse-ld=${USE_LD}" )
endif()
