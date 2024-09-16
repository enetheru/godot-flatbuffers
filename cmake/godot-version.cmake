
function(get_godot_version)
    if( NOT EXISTS ${GODOT_EXECUTABLE} )
        message( FATAL_ERROR "Unable to find godot executable at location: ${GODOT_EXECUTABLE}" )
    endif()

    execute_process(COMMAND ${GODOT_EXECUTABLE} --version
            OUTPUT_VARIABLE GODOT_VERSION
            ERROR_QUIET)
    string(STRIP ${GODOT_VERSION} GODOT_VERSION)
    if( GODOT_VERSION STREQUAL "" )
        message( FATAL_ERROR "Godot executable did not produce an understandable version string: ${GODOT_EXECUTABLE}" )
    endif ()

    string(REPLACE "." ";" GODOT_VERSION_LIST ${GODOT_VERSION})
    list(POP_FRONT GODOT_VERSION_LIST GODOT_VERSION_MAJOR)
    list(POP_FRONT GODOT_VERSION_LIST GODOT_VERSION_MINOR)
    list(POP_FRONT GODOT_VERSION_LIST GODOT_VERSION_POINT)

    return( PROPAGATE GODOT_VERSION GODOT_VERSION_MAJOR GODOT_VERSION_MINOR GODOT_VERSION_POINT )
endfunction()

get_godot_version()
