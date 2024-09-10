I need to figure out the options that exist within the repo and see if I can solve the problem for compiling for the three main release candidates.
```c
CMAKE_BUILD_TYPE
"Compilation target (Debug or Release defaults to Debug)"
    default : Debug 
    if Debug:
        GODOT_ENABLE_HOT_RELOAD = ON
        GODOT_COMPILE_FLAGS +=  '-fno-omit-frame-pointer -O0 -g'
        definitions +=
            DEBUG_ENABLED  
            DEBUG_METHODS_ENABLED  
    else:
        GODOT_ENABLE_HOT_RELOAD = OFF
        GODOT_COMPILE_FLAGS +=  '-O3'


GODOT_ENABLE_HOT_RELOAD
"Build with hot reload support. Defaults to YES for Debug-builds and NO for Release-builds"
    default : ""
    if ON:
        GODOT_COMPILE_FLAGS += HOT_RELOAD_ENABLED


FLOAT_PRECISION
"Floating-point precision level ('single', 'double')"
    default value: ""
    if 'double':
        definitions += REAL_T_IS_DOUBLE


GENERATE_TEMPLATE_GET_NODE
"Generate a template version of the Node class's get_node."
    default : ON

GODOT_GDEXTENSION_DIR
"Path to the directory containing GDExtension interface header and API JSON file"
    default : "gdextension"

GODOT_CUSTOM_API_FILE
"Path to a custom GDExtension API JSON file (takes precedence over `gdextension_dir`)"
    default : ""

GODOT_GDEXTENSION_API_FILE
# This is used in source generation.
# Is completely overridden by GODOT_CUSTOM_API_FILE if it exists.
    default: GODOT_GDEXTENSION_DIR + "/extension_api.json"

GODOT_COMPILE_FLAGS
# Enetheru: for MSVC the first argument set the flag to /utf-8 so it cannot be specified in the cache beforehand
    default : ""
    MSVC: GODOT_COMPILE_FLAGS = "/utf-8"         | "/GF /MP"
        Debug: GODOT_COMPILE_FLAGS += "/MDd"     | "/Od /RTC1 /Zi"
        else:
            GODOT_COMPILE_FLAGS += "/MD /O2"     | "/Oy /GL /Gy"
            STRING(REGEX REPLACE "/RTC(su|[1su])" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
            STRING(REPLACE "/RTC1" "" CMAKE_CXX_FLAGS_DEBUG ${CMAKE_CXX_FLAGS_DEBUG})
    else: // GCC/Clang 
        Debug: GODOT_COMPILE_FLAGS += "-fno-omit-frame-pointer -O0 -g"
        else: GODOT_COMPILE_FLAGS += "-O3"


GODOT_DISABLE_EXCEPTIONS
"Force disabling exception handling code"
# Disable exception handling. Godot doesn't use exceptions anywhere, and this
# saves around 20% of binary size and very significant build time (GH-80513)
    default : ON
    if ON:
        MSVC: GODOT_COMPILE_FLAGS += "-D_HAS_EXCEPTIONS=0"
        else: GODOT_COMPILE_FLAGS += "-fno-exceptions"
    else:
        MSVC: GODOT_COMPILE_FLAGS += "/EHsc"

BITS
# This is used by python for the source generation, (wants 32 | 64)
    default : ""
    if undefined: (64 if CMAKE_SIZEOF_VOID_P EQUAL else 32)

GODOT_CPP_SYSTEM_HEADERS
"Expose headers as SYSTEM"
# Mark the header files as SYSTEM. This may be useful to suppress warnings in projects including this one
    default : ON

GODOT_CPP_WARNING_AS_ERROR
"Treating warnings as errors"
    default = OFF
    if ON:
        CMAKE_VERSION VERSION_GREATER_EQUAL "3.24":
            set_target_properties( "godot-cpp"  
                PROPERTIES
                    COMPILE_WARNING_AS_ERROR ON  
            )  
        else:  
            target_compile_options( "godot-cpp"  
                PRIVATE
                    $<${compiler_is_msvc}:/WX>  
                    $<$<OR:${compiler_is_clang},${compiler_is_gnu}>:-Werror>  
            )  

```

```python
# Android cmake arguments  
# CMAKE_TOOLCHAIN_FILE:    The path to the android cmake toolchain ($ANDROID_NDK/build/cmake/android.toolchain.cmake)  
# ANDROID_NDK:           The path to the android ndk root folder  
# ANDROID_TOOLCHAIN_NAME:   The android toolchain (arm-linux-androideabi-4.9 or aarch64-linux-android-4.9 or x86-4.9 or x86_64-4.9)  
# ANDROID_PLATFORM:       The android platform version (android-23)  
# More info here: https://godot.readthedocs.io/en/latest/development/compiling/compiling_for_android.html  
  
execute_process(COMMAND "${Python3_EXECUTABLE}" "-c" "import binding_generator; binding_generator.print_file_list(\"${GODOT_GDEXTENSION_API_FILE}\", \"${CMAKE_CURRENT_BINARY_DIR}\", headers=True, sources=True)"  
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}  
    OUTPUT_VARIABLE GENERATED_FILES_LIST  
    OUTPUT_STRIP_TRAILING_WHITESPACE  
)  
  
add_custom_command(OUTPUT ${GENERATED_FILES_LIST}  
       COMMAND "${Python3_EXECUTABLE}" "-c" "import binding_generator; binding_generator.generate_bindings(\"${GODOT_GDEXTENSION_API_FILE}\", \"${GENERATE_BINDING_PARAMETERS}\", \"${BITS}\", \"${FLOAT_PRECISION}\", \"${CMAKE_CURRENT_BINARY_DIR}\")"  
       VERBATIM  
       WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}  
       MAIN_DEPENDENCY ${GODOT_GDEXTENSION_API_FILE}  
       DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/binding_generator.py  
       COMMENT "Generating bindings"  
)  
  
include(GodotCompilerWarnings)  
  
target_compile_features(${PROJECT_NAME}  
    PRIVATE       cxx_std_17  
)  
  
target_compile_definitions(${PROJECT_NAME} PUBLIC  
    $<$<CONFIG:Debug>:  
       DEBUG_ENABLED  
       DEBUG_METHODS_ENABLED  
    >  
    $<${compiler_is_msvc}:  
       TYPED_METHOD_BIND  
    >  
)  
  
target_link_options(${PROJECT_NAME} PRIVATE  
    $<$<NOT:${compiler_is_msvc}>:  
       -static-libgcc  
       -static-libstdc++  
       -Wl,-R,'$$ORIGIN'  
    >  
)  
  
# Optionally mark headers as SYSTEM  
set(GODOT_CPP_SYSTEM_HEADERS_ATTRIBUTE "")  
if (GODOT_CPP_SYSTEM_HEADERS)  
    set(GODOT_CPP_SYSTEM_HEADERS_ATTRIBUTE SYSTEM)  
endif ()  
  
target_include_directories(${PROJECT_NAME} ${GODOT_CPP_SYSTEM_HEADERS_ATTRIBUTE} PUBLIC  
    include  
    ${CMAKE_CURRENT_BINARY_DIR}/gen/include  
    ${GODOT_GDEXTENSION_DIR}  
)  
  
# Add the compile flags  
set_property(TARGET ${PROJECT_NAME} APPEND_STRING PROPERTY COMPILE_FLAGS ${GODOT_COMPILE_FLAGS})  
  
# Create the correct name (godot.os.build_type.system_bits)  
string(TOLOWER "${CMAKE_SYSTEM_NAME}" SYSTEM_NAME)  
string(TOLOWER "${CMAKE_BUILD_TYPE}" BUILD_TYPE)  
  
if(ANDROID)  
    # Added the android abi after system name  
    set(SYSTEM_NAME ${SYSTEM_NAME}.${ANDROID_ABI})

    # Android does not have the bits at the end if you look at the main godot repo build  
    set(OUTPUT_NAME "godot-cpp.${SYSTEM_NAME}.${BUILD_TYPE}")  
else()  
    set(OUTPUT_NAME "godot-cpp.${SYSTEM_NAME}.${BUILD_TYPE}.${BITS}")  
endif()  
  
set_target_properties(${PROJECT_NAME}  
    PROPERTIES       
        CXX_EXTENSIONS OFF  
        POSITION_INDEPENDENT_CODE ON  
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/bin"  
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/bin"  
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/bin"  
        OUTPUT_NAME "${OUTPUT_NAME}"  
)
```


godot compiler warnings
```python
# Add warnings based on compiler & version  
# Set some helper variables for readability  
set( compiler_less_than_v8 "$<VERSION_LESS:$<CXX_COMPILER_VERSION>,8>" )  
set( compiler_greater_than_or_equal_v9 "$<VERSION_GREATER_EQUAL:$<CXX_COMPILER_VERSION>,9>" )  
set( compiler_greater_than_or_equal_v11 "$<VERSION_GREATER_EQUAL:$<CXX_COMPILER_VERSION>,11>" )  
set( compiler_less_than_v11 "$<VERSION_LESS:$<CXX_COMPILER_VERSION>,11>" )  
set( compiler_greater_than_or_equal_v12 "$<VERSION_GREATER_EQUAL:$<CXX_COMPILER_VERSION>,12>" )  
  
# These compiler options reflect what is in godot/SConstruct.  
target_compile_options( ${PROJECT_NAME} PRIVATE  
    # MSVC only  
    $<${compiler_is_msvc}:  
        /W4  
  
        # Disable warnings which we don't plan to fix.  
        /wd4100  # C4100 (unreferenced formal parameter): Doesn't play nice with polymorphism.  
        /wd4127  # C4127 (conditional expression is constant)  
        /wd4201  # C4201 (non-standard nameless struct/union): Only relevant for C89.  
        /wd4244  # C4244 C4245 C4267 (narrowing conversions): Unavoidable at this scale.  
        /wd4245  
        /wd4267  
        /wd4305  # C4305 (truncation): double to float or real_t, too hard to avoid.  
        /wd4514  # C4514 (unreferenced inline function has been removed)  
        /wd4714  # C4714 (function marked as __forceinline not inlined)  
        /wd4820  # C4820 (padding added after construct)  
    >  
  
    # Clang and GNU common options  
    $<$<OR:${compiler_is_clang},${compiler_is_gnu}>:  
        -Wall  
        -Wctor-dtor-privacy  
        -Wextra  
        -Wno-unused-parameter  
        -Wnon-virtual-dtor  
        -Wwrite-strings  
    >  
  
    # Clang only  
    $<${compiler_is_clang}:  
        -Wimplicit-fallthrough  
        -Wno-ordered-compare-function-pointers  
    >  
  
    # GNU only  
    $<${compiler_is_gnu}:  
        -Walloc-zero  
        -Wduplicated-branches  
        -Wduplicated-cond  
        -Wno-misleading-indentation  
        -Wplacement-new=1  
        -Wshadow-local  
        -Wstringop-overflow=4  
    >  
    $<$<AND:${compiler_is_gnu},${compiler_less_than_v8}>:  
        # Bogus warning fixed in 8+.  
        -Wno-strict-overflow  
    >  
    $<$<AND:${compiler_is_gnu},${compiler_greater_than_or_equal_v9}>:  
        -Wattribute-alias=2  
    >  
    $<$<AND:${compiler_is_gnu},${compiler_greater_than_or_equal_v11}>:  
        # Broke on MethodBind templates before GCC 11.  
        -Wlogical-op  
    >  
    $<$<AND:${compiler_is_gnu},${compiler_less_than_v11}>:  
        # Regression in GCC 9/10, spams so much in our variadic templates that we need to outright disable it.  
        -Wno-type-limits  
    >  
    $<$<AND:${compiler_is_gnu},${compiler_greater_than_or_equal_v12}>:  
        # False positives in our error macros, see GH-58747.  
        -Wno-return-type  
    >  
)  
```