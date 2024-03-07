function(godot_cpp_git_tag)
    message( "Using Git:  ${GIT_EXECUTABLE}" )
    execute_process(
            COMMAND ${GIT_EXECUTABLE} ls-remote --tags ${GEL_GIT_URL}
            OUTPUT_VARIABLE GEL_GIT_TAGS
            COMMAND_ERROR_IS_FATAL ANY)
    string(REGEX MATCHALL "godot-[0-9]+.[0-9]+(.[0-9]+)?-[a-z]+" GEL_GIT_TAGS "${GEL_GIT_TAGS}")

    list(FIND GEL_GIT_TAGS "godot-${GODOT_VERSION_MAJOR}.${GODOT_VERSION_MINOR}.${GODOT_VERSION_POINT}" GEL_GIT_TAG)

    if (GEL_GIT_TAG EQUAL -1)
        message("unable to get exact matching tag for godot version: ${GODOT_VERSION_MAJOR}.${GODOT_VERSION_MINOR}.${GODOT_VERSION_POINT}, attempting minor version")
        list(FIND GEL_GIT_TAGS "godot-${GODOT_VERSION_MAJOR}.${GODOT_VERSION_MINOR}-stable" GEL_GIT_TAG)
    endif ()

    if (GEL_GIT_TAG EQUAL -1)
        message(WARNING "Unable to determine git tag to clone")
        message("Available Tags:")
        foreach (tag ${GEL_GIT_TAGS})
            message("${tag}")
        endforeach ()
        message("Add '-DGEL_GIT_TAG=<git-tag>' to your cmake configuration")
        message(FATAL_ERROR "Unable to clone godot-cpp")
    else ()
        list(GET GEL_GIT_TAGS ${GEL_GIT_TAG} GEL_GIT_TAG)
        message("Found godot-cpp Tag for Godot Version: ${GEL_GIT_TAG}")
    endif ()

endfunction()

godot_cpp_git_tag()