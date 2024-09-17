
### Default flags for all permutations
target_compile_options( godot-cpp
        PUBLIC
        -fPIC
        -Wwrite-strings

        # Disable Exceptions
        $<$<BOOL:GODOT_CPP_DISABLE_EXCEPTIONS>:-fno-exceptions>

        # for gnu platforms where symbols are visible by default
        $<$<BOOL:GODOT_CPP_HIDE_SYMBOLS>:-fvisibility=hidden>

        # Debug
        $<$<CONFIG:Debug>:-fno-omit-frame-pointer -gdwarf-4>

        # if Dev_Build -g3 else -g2
        $<IF:$<BOOL:GODOT_CPP_DEV_BUILD>,-g3,-g2>

        # Optimisation Level
        $<$<STREQUAL:GODOT_CPP_OPTIMISATION_MODE,speed>:-O3>
        $<$<STREQUAL:GODOT_CPP_OPTIMISATION_MODE,speed_trace>:-O2>
        $<$<STREQUAL:GODOT_CPP_OPTIMISATION_MODE,size>:-Os>
        $<$<STREQUAL:GODOT_CPP_OPTIMISATION_MODE,debug>:-Og>
        $<$<STREQUAL:GODOT_CPP_OPTIMISATION_MODE,none>:-O0>
)

### Strip the binary if in release mode
if (CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
    target_compile_options( godot-cpp
            PUBLIC
            $<NOT:$<CONFIG:Debug>,-Wl,-S -Wl,-x -Wl,-dead_strip>
    )
else ()
    target_compile_options( godot-cpp
            PUBLIC
            $<$<NOT:$<CONFIG:Debug>>:-s>
    )
endif ()

### Link Options
target_link_options( godot-cpp
        PUBLIC
        -Wl,--no-undefined

        # Static Link
        $<$<BOOL:GODOT_CPP_USE_STATIC_CPP>:-static -static-libgcc -static-libstdc++ -Wl,-R,'$$ORIGIN'>

        # Use another linker
        $<$<BOOL:${USE_LD}>:-fuse-ld=${USE_LD}>
)
