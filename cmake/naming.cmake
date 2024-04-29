# Construct the output names

function( gde_name_arch )
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
    return( PROPAGATE GDE_TARGET_ARCH )
endfunction()
gde_name_arch()

function( gde_name_platform )
    # Target Platform
    string( TOLOWER ${CMAKE_SYSTEM_NAME} GDE_TARGET_PLATFORM ) # AKA Platform
    return( PROPAGATE GDE_TARGET_PLATFORM )
endfunction()
gde_name_platform()

function( gde_name_preset )
    # Target Platform
    if (GODOT_CPP_TOOLS_ENABLED)
        set( GDE_TARGET_PRESET "editor")
    elseif (CMAKE_BUILD_TYPE MATCHES "Debug")
        set( GDE_TARGET_PRESET "template_debug")
    else ()
        set( GDE_TARGET_PRESET "template_release")
    endif ()
    return( PROPAGATE GDE_TARGET_PRESET )
endfunction()
gde_name_preset()

function( godot_executable_name )
    # look for godot executable with these names
    set(NAME_PARTS "godot")
    list(APPEND NAME_PARTS "${GDE_TARGET_PLATFORM}")
    list(APPEND NAME_PARTS "editor") # we dont need preset here, we always want the editor

    if (${GODOT_CPP_DEV_BUILD})
        list(APPEND NAME_PARTS "dev")
    endif ()

    if(${GODOT_CPP_FLOAT_DOUBLE})
        list(APPEND NAME_PARTS "double")
    endif ()

    list(APPEND NAME_PARTS "${GDE_TARGET_ARCH}") # AKA arch

    if (NOT GDE_CUSTOM_SUFFIX STREQUAL "")
        list(APPEND NAME_PARTS "${GDE_CUSTOM_SUFFIX}")
    endif ()

    list(APPEND NAME_PARTS "exe")


    list(JOIN NAME_PARTS "." GODOT_EXECUTABLE_NAME)
    return( PROPAGATE GODOT_EXECUTABLE_NAME )
endfunction()
godot_executable_name()

# Output Library Name
# godot.<platform>.<target>[.dev][.double].<arch>[.custom_suffix][.console].exe
function( gde_names_gdextension )
    # Output gdextension library name
    set(NAME_PARTS ${PROJECT_NAME})

    list(APPEND NAME_PARTS "${GDE_TARGET_PLATFORM}")
    list(APPEND NAME_PARTS "${GDE_TARGET_PRESET}")

    if (${GODOT_CPP_DEV_BUILD})
        list(APPEND NAME_PARTS "dev")
    endif ()

    if (${GODOT_CPP_FLOAT_DOUBLE})
        list(APPEND NAME_PARTS "double")
    endif ()

    list(APPEND NAME_PARTS "${GDE_TARGET_ARCH}") # AKA arch

    if (NOT GDE_CUSTOM_SUFFIX STREQUAL "")
        list(APPEND NAME_PARTS "${GDE_CUSTOM_SUFFIX}")
    endif ()

    list(JOIN NAME_PARTS "." GDE_OUTPUT_NAME)

    return( PROPAGATE GDE_OUTPUT_NAME )
endfunction()

gde_names_gdextension()
