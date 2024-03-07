Godot GDExtension Template
==========================
My attempt at starting a cmake gdextension project that I like

## Features:

* Automatically pulls required dependencies using FetchContent
* Uses godot executable to dump api
* organised cmake files

## Goals

* Have at least feature parity with the scons script.
* Too make it easy to consume other libraries who also use modern cmake(most of them).
* I want to pull in features from Jason Turners cmake template project.
* Correctly use PRIVATE, INTERFACE, PUBLIC in godot-cpp to minimise configuration of our source

## Getting and compiling the project
```powershell
git clone https://gitlab.com/enetheru/godot-gde-template.git
cd godot-gde-template
cmake -B build -DCMAKE_EXECUTABLE=<path to godot.exe>
cmake --build build
```

### Looking up additional options
Assuming the above
```powershell
cmake build -LH
```

Notes
=====
I can only test on one setup right now, being Windows 11 with msys64/mingw64.
I would very much like help with other platforms and architectures, and cross compiling. 

editor/template_debug/template_release are not explicitly stated as yet,
instead they are derived from the options -DTOOLS_ENABLED=ON and if we are making a Debug build.

Because of the limited options in godot-cpp cmake project, 
I have resorted to clearing and re-writing the compile and link flag/options for godot-cpp.
I also dont know enough about which flags are PRIVATE,INTERFACE,PUBLIC so they are all PUBLIC for now.
If in the future it gets updated this can be deleted.

The python generated api in godot-cpp happens at configure time,
which prevents making proper targets for dumping the api.