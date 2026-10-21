### Create godot documentation xml files
# Running the editor with the --doctool flag will scan the project for classes and generate XML documentation files.
# For GDExtensions, this will generate XML files for the registered classes.

if( GODOT_EXECUTABLE )
    add_custom_target( godot-docs
            COMMAND ${GODOT_EXECUTABLE} --headless --doctool ${CMAKE_CURRENT_SOURCE_DIR} --gdextension-docs --no-docbase
            WORKING_DIRECTORY ${GODOT_DEMO_PATH}
            COMMENT "Generating Godot documentation XML files for the project."
            VERBATIM
    )
endif ()
