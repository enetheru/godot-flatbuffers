# Install-time merge of one build into flatbuffers.gdextension.
#
# Called from install(CODE). The build tree never writes this file.
# Each install adds this build's library line, or replaces that same line.
# Every other library line stays.
#
# Destination:
#   CMAKE_INSTALL_PREFIX contains project.godot
#     -> <prefix>/addons/<GDE_INSTALL_NAME>/
#   otherwise the prefix is the addon folder (the default is <source>/install)
#
# The library key is the Godot feature list for this binary. A Debug or
# RelWithDebInfo filename suffix, and the Tracy ".tracy" tag, stay in the
# path and are not part of the key, so they replace the same slot.

if( NOT GDE_LIB_SRC OR NOT EXISTS "${GDE_LIB_SRC}" )
    message( FATAL_ERROR "gdextension install: library missing (${GDE_LIB_SRC})" )
endif()

cmake_path( GET GDE_LIB_SRC FILENAME _filename )
# STEM without LAST_ONLY stops at the first dot, so
# flatbuffers.windows.editor.x86_64.dll would become "flatbuffers".
cmake_path( GET _filename STEM LAST_ONLY _stem )
string( LENGTH "${GDE_NAME}." _prefix_len )
string( LENGTH "${_stem}" _stem_len )
if( _stem_len LESS _prefix_len )
    message( FATAL_ERROR "gdextension install: '${_filename}' does not start with ${GDE_NAME}." )
endif()
string( SUBSTRING "${_stem}" 0 ${_prefix_len} _prefix )
if( NOT _prefix STREQUAL "${GDE_NAME}." )
    message( FATAL_ERROR "gdextension install: '${_filename}' does not start with ${GDE_NAME}." )
endif()
string( SUBSTRING "${_stem}" ${_prefix_len} -1 _key )
# Config and Tracy tags share the Godot feature slot. .nothreads stays:
# it is a real feature and it is trailing, so it must not be in this list.
foreach( _unused RANGE 0 3 )
    if( _key MATCHES "\\.(debug|relwithdebinfo|tracy)$" )
        string( REGEX REPLACE "\\.(debug|relwithdebinfo|tracy)$" "" _key "${_key}" )
    endif()
endforeach()

set( _root "${CMAKE_INSTALL_PREFIX}" )
if( EXISTS "${_root}/project.godot" )
    set( _dest "${_root}/addons/${GDE_INSTALL_NAME}" )
else()
    set( _dest "${_root}" )
endif()

file( INSTALL "${GDE_LIB_SRC}" DESTINATION "${_dest}/bin" )
if( GDE_FLATC_SRC AND EXISTS "${GDE_FLATC_SRC}" )
    file( INSTALL "${GDE_FLATC_SRC}" DESTINATION "${_dest}/bin" )
endif()

set( _file "${_dest}/${GDE_NAME}.gdextension" )
set( _line "${_key} = \"bin/${_filename}\"" )

if( NOT EXISTS "${_file}" )
    file( WRITE "${_file}"
"[configuration]
entry_symbol = \"${GDE_ENTRY}\"
compatibility_minimum = \"${GDE_COMPAT}\"
reloadable = ${GDE_RELOADABLE}

[libraries]
${_line}
" )
    message( STATUS "Created ${_file}" )
    return()
endif()

file( READ "${_file}" _text )
set( _nl "\n" )
if( _text MATCHES "\r\n" )
    set( _nl "\r\n" )
endif()
string( REPLACE "\r\n" "\n" _text "${_text}" )
string( REPLACE "\r" "\n" _text "${_text}" )

string( REPLACE "." "\\." _key_re "${_key}" )
if( _text MATCHES "(^|\n)[ \t]*${_key_re}[ \t]*=" )
    string( REGEX REPLACE "(^|\n)[ \t]*${_key_re}[ \t]*=[^\n]*" "\\1${_line}" _text "${_text}" )
else()
    string( FIND "${_text}" "[libraries]" _lib_at )
    if( _lib_at EQUAL -1 )
        if( NOT _text MATCHES "\n$" )
            string( APPEND _text "\n" )
        endif()
        string( APPEND _text "\n[libraries]\n${_line}\n" )
    else()
        string( LENGTH "[libraries]" _lib_len )
        math( EXPR _after "${_lib_at} + ${_lib_len}" )
        string( SUBSTRING "${_text}" ${_after} -1 _tail )
        string( FIND "${_tail}" "\n[" _next )
        if( _next EQUAL -1 )
            if( NOT _text MATCHES "\n$" )
                string( APPEND _text "\n" )
            endif()
            string( APPEND _text "${_line}\n" )
        else()
            math( EXPR _at "${_after} + ${_next}" )
            string( SUBSTRING "${_text}" 0 ${_at} _head )
            string( SUBSTRING "${_text}" ${_at} -1 _rest )
            # Drop blank lines at the end of [libraries], then one blank line
            # before the next section.
            string( REGEX REPLACE "\n+$" "" _head "${_head}" )
            set( _text "${_head}\n${_line}\n${_rest}" )
        endif()
    endif()
endif()

if( NOT _text MATCHES "\n$" )
    string( APPEND _text "\n" )
endif()
if( _nl STREQUAL "\r\n" )
    string( REPLACE "\n" "\r\n" _text "${_text}" )
endif()
file( WRITE "${_file}" "${_text}" )
message( STATUS "gdextension ${_file}: ${_key}" )
