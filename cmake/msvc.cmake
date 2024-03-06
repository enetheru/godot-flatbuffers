# using Visual Studio C++
target_compile_options( godot-cpp PUBLIC "/WX" "/DTYPED_METHOD_BIND" )

if(CMAKE_BUILD_TYPE MATCHES Debug)
    target_compile_options( godot-cpp PUBLIC "/MDd" )# /Od /RTC1 /Zi
else()
    target_compile_options( godot-cpp PUBLIC "/MD /O2" )# # /Oy /GL /Gy
    # I have no idea what this means, but considering that compile_optons is a list, surely we can use
    # list functions to search for items and replace them
    # FIXME STRING(REGEX REPLACE "/RTC(su|[1su])" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    # FIXME string(REPLACE "/RTC1" "" CMAKE_CXX_FLAGS_DEBUG ${CMAKE_CXX_FLAGS_DEBUG})
endif()

# Disable conversion warning, truncation, unreferenced var, signed mismatch
target_compile_options( godot-cpp PUBLIC "/wd4244" "/wd4305" "/wd4101" "/wd4018" "/wd4267" )

target_compile_definitions( godot-cpp PRIVATE "-DNOMINMAX" )

# Unkomment for warning level 4
#if(CMAKE_CXX_FLAGS MATCHES "/W[0-4]")
#	string(REGEX REPLACE "/W[0-4]" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
#endif()

if( GODOT_DISABLE_EXCEPTIONS )
    target_compile_options( godot-cpp "-D_HAS_EXCEPTIONS=0")
else()
    target_compile_options( godot-cpp "/EHsc")
endif()

# TODO Taken from the scons script, needs to be translated into cmake
# Set optimize and debug_symbols flags.
# "custom" means do nothing and let users set their own optimization flags.
#if env.get("is_msvc", False):
#if env["debug_symbols"]:
#env.Append(CCFLAGS=["/Zi", "/FS"])
#env.Append(LINKFLAGS=["/DEBUG:FULL"])
#
#if env["optimize"] == "speed":
#env.Append(CCFLAGS=["/O2"])
#env.Append(LINKFLAGS=["/OPT:REF"])
#elif env["optimize"] == "speed_trace":
#env.Append(CCFLAGS=["/O2"])
#env.Append(LINKFLAGS=["/OPT:REF", "/OPT:NOICF"])
#elif env["optimize"] == "size":
#env.Append(CCFLAGS=["/O1"])
#env.Append(LINKFLAGS=["/OPT:REF"])
#elif env["optimize"] == "debug" or env["optimize"] == "none":
#env.Append(CCFLAGS=["/Od"])
