# TODO add all targets as separate configurations
#   editor|template_release|template_debug
add_library( ${PROJECT_NAME} SHARED)
target_sources( ${PROJECT_NAME}
        PRIVATE
            example.cpp example.h
            register_types.cpp register_types.h
            tests.h)

target_include_directories( ${PROJECT_NAME} PUBLIC godot-cpp )
target_link_libraries( ${PROJECT_NAME} PUBLIC godot-cpp )
set_target_properties( ${PROJECT_NAME}
    PROPERTIES
        #PREFIX "lib"
        OUTPUT_NAME "${GDE_OUTPUT_NAME}"
        SUFFIX ""
)