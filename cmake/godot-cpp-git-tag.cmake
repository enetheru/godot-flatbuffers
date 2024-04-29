function(godot_cpp_git_tag)
    message(STATUS  "Using Git:  ${GIT_EXECUTABLE}" )
    execute_process(
            COMMAND ${GIT_EXECUTABLE} ls-remote --tags ${GODOT_CPP_GIT_URL}
            OUTPUT_VARIABLE GODOT_CPP_GIT_TAGS
            COMMAND_ERROR_IS_FATAL ANY)

    # Turn the out put into a cmake list.
    string( REGEX REPLACE "\n" ";" TEMP "${GODOT_CPP_GIT_TAGS}" )

    list(FILTER TEMP INCLUDE REGEX "godot-${GODOT_VERSION_MAJOR}.${GODOT_VERSION_MINOR}.${GODOT_VERSION_POINT}-stable$")
    if (NOT TEMP )
        message(STATUS "unable to get exact matching tag for godot version: ${GODOT_VERSION_MAJOR}.${GODOT_VERSION_MINOR}.${GODOT_VERSION_POINT}, attempting minor version")
        list(FILTER TEMP INCLUDE REGEX "godot-${GODOT_VERSION_MAJOR}.${GODOT_VERSION_MINOR}-stable$")
    endif ()

    # Get the tag hash
    string( REGEX REPLACE "([a-z0-9]+).*$" "\\1" GODOT_CPP_GIT_TAG "${TEMP}")

    if (NOT GODOT_CPP_GIT_TAG )
        message(WARNING "Unable to determine git tag to clone")
        message("Run \"git ls-remote --tags ${GODOT_CPP_GIT_URL}\" ")
        message("Add '-DGODOT_CPP_GIT_TAG=<git-tag>' to your cmake configuration")
        message(FATAL_ERROR "Unable to determine which tag from godot-cpp to clone")
    endif ()

    message(STATUS "Found godot-cpp commit hash: ${GODOT_CPP_GIT_TAG}")
    set( GODOT_CPP_GIT_TAG ${GODOT_CPP_GIT_TAG} PARENT_SCOPE)

endfunction()

godot_cpp_git_tag()