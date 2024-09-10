There are four major templates for use in godot.
- default aka editor
- template_release
- template_debug
- dev_build

Each of them express a different set of build commands. I guess my goal would be to enumerate them and list them out here.

Lets just start with the single option the default one, gcc and clang on msys ucrt64, clang64

I collated into a table but that was shit, lets do it manually.

File Names:
```
scons-gcc:   libgodot-cpp.windows.template_debug.x86_64.a
cmake-gcc:   libgodot-cpp.windows.debug.64.a
cmake-clang: libgodot-cpp.windows.debug.64.a
```

File Size:
```
scons-gcc:   76MB
cmake-gcc:   494MB
cmake-clang: 204MB
```

Defines
```
scons-gcc                | cmake-gcc                  | cmake-clang
WINDOWS_ENABLED
THREADS_ENABLED
HOT_RELOAD_ENABLED         HOT_RELOAD_ENABLED           HOT_RELOAD_ENABLED
DEBUG_ENABLED              DEBUG_ENABLED                DEBUG_ENABLED
DEBUG_METHODS_ENABLED      DEBUG_METHODS_ENABLED        DEBUG_METHODS_ENABLED
NDEBUG
GDEXTENSION
```

Flags
```
scons-gcc                | cmake-gcc                  | cmake-clang
-c                        -isystem \<path\>             -isystem \<path\>
-std=c++17                -g                            -g
-fno-exceptions           -fdiagnostics-color=always    -fansi-escape-codes
-Wwrite-strings           -fno-omit-frame-pointer       -fcolor-diagnostics
-fvisibility=hidden       -O0                           -fno-omit-frame-pointer
-O2                       -g                            -O0
-I\<path\>                -Wall                         -g
                          -Wctor-dtor-privacy           -Wall
                          -Wextra                       -Wctor-dtor-privacy
                          -Wno-unused-parameter         -Wextra
                          -Wnon-virtual-dtor            -Wno-unused-parameter
                          -Wwrite-strings               -Wnon-virtual-dtor
                          -Walloc-zero                  -Wwrite-strings
                          -Wduplicated-branches         -Wimplicit-fallthrough
                          -Wduplicated-cond             -Wno-ordered-compare-function-pointers
                          -Wno-misleading-indentation   -MD
                          -Wplacement-new=1
                          -Wshadow-local
                          -Wstringop-overflow=4
                          -Wattribute-alias=2
                          -Wlogical-op
                          -Wno-return-type
                          -MD
                          -MT
```
