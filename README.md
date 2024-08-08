Godot Flatbuffers
=================
Serialise to, and from, flatbuffer objects.

The project consists of three main areas.
* The modifications to the flatc compiler which generates the gdscript interface
* The gdextension binary plugin which provides the builder API and generates the binary data
* The gdscript addon plugin to provide rudimentary syntax highlighting, and editor interface changes to help use flatbuffers.

Idealistically there should be CI/CD, test coverage, performance metrics, etc, but there isn't sorry.

### Upstream
* https://flatbuffers.dev/index.html
* https://github.com/google/flatbuffers