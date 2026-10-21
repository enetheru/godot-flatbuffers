# Registers the install() rules for the extension.
# gdextension_merge.cmake runs at install time and edits the descriptor.

# Inside the function, CMAKE_CURRENT_LIST_DIR is the caller. Capture it here.
set( GDE_MERGE_SCRIPT "${CMAKE_CURRENT_LIST_DIR}/gdextension_merge.cmake" )

function( gdextension_install )
    if( GODOTCPP_USE_HOT_RELOAD )
        set( _reloadable "true" )
    else()
        set( _reloadable "false" )
    endif()

    file( TO_CMAKE_PATH "${GDE_MERGE_SCRIPT}" _merge )

    install( CODE "
        set( GDE_NAME \"${GDE_NAME}\" )
        set( GDE_INSTALL_NAME \"${GDE_INSTALL_NAME}\" )
        set( GDE_ENTRY \"${GDE_NAME}_library_init\" )
        set( GDE_COMPAT \"${GODOT_VERSION_MAJOR}.${GODOT_VERSION_MINOR}\" )
        set( GDE_RELOADABLE \"${_reloadable}\" )
        set( GDE_LIB_SRC \"$<TARGET_FILE:godot-flatbuffers>\" )
        set( GDE_FLATC_SRC \"$<TARGET_FILE:flatc>\" )
        include( \"${_merge}\" )
    " )
endfunction()
