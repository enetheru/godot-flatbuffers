---

kanban-plugin: board

---

## gdextension

- [ ] cleanup source generation so that it is just a copy paste of the addons folder


## flatc Generator

- [ ] Check in Get* functions to check buffer size for at least minimum
- [ ] Create* functions need to be able to take the object, not the offset, ie string instead of int
- [ ] builder add_* function arguments need to be named with \_offset if they expect an offset instead of a value.
- [ ] Add an option to the settings to auto generate after a fbs file is changed.


## addon

- [ ] right click menu addition off screen
- [ ] reload script in editor after re-generation
- [ ] make failed compile popup
- [ ] move editor settings to project settings
- [ ] create custom allocator backed by PackedByteArray
- [ ] add filename to debug print
- [ ] add right click generate to code views
- [ ] Notify user if creation date of fbs file is different to generated file and could use a re-gen
- [ ] To get file extension recognition working I need to create a ResourceFormatLoader https://docs.godotengine.org/en/stable/classes/class_resourceformatloader.html


## syntax highlighting

- [ ] check names for collision
- [ ] parse includes for names
- [ ] keep track of field names and highlight duplicates


***

## Archive

- [ ] hide debug print
- [ ] FlatBuffersBuilder.new() crashes godot
- [ ] flatbuffers namespace == class name prefix
- [ ] new GetRoot function in gdscript to get root flatbuffer
- [ ] GetRoot needs to be a static function

%% kanban:settings
```
{"kanban-plugin":"board","list-collapse":[false,false,false,false]}
```
%%