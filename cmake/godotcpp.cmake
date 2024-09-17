# At this point godot-cpp has been configured using our cached variables, but it's not enough to enable some features.
# We need to figure out and override things like build and link flags because the godot-cpp cmake project
# doesn't have feature parity with the scons build.

# Scrub the options so we can start again.
get_target_property( GODOTCPP_INCLUDES godot-cpp INTERFACE_SYSTEM_INCLUDE_DIRECTORIES )
set_target_properties( godot-cpp
        PROPERTIES
        COMPILE_OPTIONS ""
        COMPILE_FLAGS ""
        LINK_OPTIONS ""
        LINK_FLAGS ""
)

## Definitions
set( TARGET "" )
#set( DEBUG_FEATURES $<IN_LIST:TARGET,editor;template_debug> )
set( DEBUG_FEATURES $<OR:$<CONFIG:Debug>,$<BOOL:GODOT_CPP_TOOLS_ENABLED>> )
target_compile_definitions( godot-cpp
        PUBLIC
        WINDOWS_ENABLED
        THREADS_ENABLED
        GDEXTENSION

        # Tools Enabled
        $<$<BOOL:GODOT_CPP_TOOLS_ENABLED>:TOOLS_ENABLED>

        # Debug Enabled
        $<IF:$<BOOL:DEBUG_FEATURES>,DEBUG_ENABLED DEBUG_METHODS_ENABLED,NDEBUG>

        # Double precision floats
        $<$<STREQUAL:FLOAT_PRECISION,double>:REAL_T_IS_DOUBLE>

        #Hot Reload
        $<$<BOOL:GODOT_ENABLE_HOT_RELOAD>:HOT_RELOAD_ENABLED>
)

if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC") # using Visual Studio C++
    include( cmake/msvc.cmake )
elseif (CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
    include( cmake/gcc.cmake )
else ()
    message(FATAL_ERROR "${CMAKE_CXX_COMPILER_ID} Compiler is not supported")
endif ()
