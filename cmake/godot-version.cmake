
function(get_godot_version)
    if( NOT EXISTS ${GODOT_EXECUTABLE} )
        message( FATAL_ERROR "Unable to find godot executable at location: ${GODOT_EXECUTABLE}" )
    endif()

    execute_process(COMMAND ${GODOT_EXECUTABLE} --version
            OUTPUT_VARIABLE GODOT_VERSION
            COMMAND_ECHO STDOUT
            ERROR_QUIET)
    if( GODOT_VERSION STREQUAL "" )
        message( FATAL_ERROR "Godot executable did not produce an understandable version string: ${GODOT_EXECUTABLE}" )
    endif ()
    message(STATUS "Godot Version: ${GODOT_VERSION}")

    string(REPLACE "." ";" GODOT_VERSION_LIST ${GODOT_VERSION})
    list(POP_FRONT GODOT_VERSION_LIST GODOT_VERSION_MAJOR)
    list(POP_FRONT GODOT_VERSION_LIST GODOT_VERSION_MINOR)
    list(POP_FRONT GODOT_VERSION_LIST GODOT_VERSION_POINT)

    message("Godot Version Base: ${GODOT_VERSION_MAJOR}.${GODOT_VERSION_MINOR}.${GODOT_VERSION_POINT}")

    return( PROPAGATE GODOT_VERSION GODOT_VERSION_MAJOR GODOT_VERSION_MINOR GODOT_VERSION_POINT )
endfunction()

get_godot_version()
