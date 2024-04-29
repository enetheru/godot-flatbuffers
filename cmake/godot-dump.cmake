### Dump extension-api and gdextension-interface
function(godot_dump_api)
    # TODO --dump-extension-api-with-docs
    if (NOT EXISTS "${PROJECT_SOURCE_DIR}/${GODOT_DUMP_DIR}")
        message(STATUS "Creating ${GODOT_DUMP_DIR}")
        execute_process(
                COMMAND mkdir ${GODOT_DUMP_DIR} #TODO Customise this per platform
                WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
                COMMAND_ERROR_IS_FATAL ANY
        )
    endif ()
    if (NOT EXISTS "${PROJECT_SOURCE_DIR}/${GODOT_DUMP_DIR}/gdextension_interface.h")
        execute_process(
                COMMAND ${GODOT_EXECUTABLE} --headless --dump-gdextension-interface
                WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/${GODOT_DUMP_DIR}
                COMMAND_ECHO STDOUT
                COMMAND_ERROR_IS_FATAL ANY
        )
    endif ()
    if (NOT EXISTS "${PROJECT_SOURCE_DIR}/${GODOT_DUMP_DIR}/extension_api.json")
        execute_process(
                COMMAND ${GODOT_EXECUTABLE} --headless --dump-extension-api
                WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/${GODOT_DUMP_DIR}
                COMMAND_ECHO STDOUT
                COMMAND_ERROR_IS_FATAL ANY
        )
    endif ()
endfunction()

godot_dump_api()