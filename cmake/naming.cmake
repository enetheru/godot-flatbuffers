# Construct the output name
# godot.<platform>.<target>[.dev][.double].<arch>[.custom_suffix][.console].exe
function( gde_generate_names )
    # Target Architecture
    string( TOLOWER ${CMAKE_SYSTEM_PROCESSOR} GDE_TARGET_ARCH )
    if( GDE_TARGET_ARCH MATCHES "x64|amd64" )
        set( GDE_TARGET_ARCH "x86_64")
    elseif( GDE_TARGET_ARCH MATCHES "armv7" )
        set( GDE_TARGET_ARCH "arm32")
    elseif( GDE_TARGET_ARCH MATCHES "armv8|arm64v8|aarch64" )
        set( GDE_TARGET_ARCH "arm64")
    elseif( GDE_TARGET_ARCH MATCHES "rv|riscv|riscv64" )
        set( GDE_TARGET_ARCH "rv64")
    elseif( GDE_TARGET_ARCH MATCHES "ppcle|ppc" )
        set( GDE_TARGET_ARCH "ppc32")
    elseif( GDE_TARGET_ARCH MATCHES "ppc64le" )
        set( GDE_TARGET_ARCH "ppc64")
    else()
        set( GDE_TARGET_ARCH ${CMAKE_SYSTEM_PROCESSOR} )
    endif()

    # Target Platform
    string( TOLOWER ${CMAKE_SYSTEM_NAME} GDE_TARGET_PLATFORM ) # AKA Platform

    # Output Filename
    set(NAME_PARTS ${PROJECT_NAME})

    list(APPEND NAME_PARTS "${GDE_TARGET_PLATFORM}")

    if (TOOLS_ENABLED)
        list(APPEND NAME_PARTS "editor")
    elseif (CMAKE_BUILD_TYPE MATCHES "Debug")
        list(APPEND NAME_PARTS "template_debug")
    else ()
        list(APPEND NAME_PARTS "template_release")
    endif ()

    if (DEV_BUILD)
        list(APPEND NAME_PARTS "dev")
    endif ()

    if (FLOAT_DOUBLE)
        list(APPEND NAME_PARTS "double")
    endif ()

    list(APPEND NAME_PARTS "${GDE_TARGET_ARCH}") # AKA arch

    if (NOT GDE_CUSTOM_SUFFIX STREQUAL "")
        list(APPEND NAME_PARTS "${GDE_CUSTOM_SUFFIX}")
    endif ()

    list( APPEND NAME_PARTS "dll" )

    list(JOIN NAME_PARTS "." GDE_OUTPUT_NAME)

    return( PROPAGATE GDE_OUTPUT_NAME GDE_TARGET_ARCH GDE_TARGET_PLATFORM )
endfunction()

gde_generate_names()
