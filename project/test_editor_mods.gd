@tool
extends EditorScript

func _run() -> void:
	change_editor_settings()
	add_syntax_highlighter()
	changes_to_fbs()


func add_syntax_highlighter():
	var script_editor := EditorInterface.get_script_editor()
	script_editor.register_syntax_highlighter( FlatBuffersHighlighter.new() )

func change_editor_settings():
	# Editor Settings
	const PATH = &"plugin/FlatBuffers/"
	var settings = EditorInterface.get_editor_settings()
	settings.set(PATH + &"flatc_path", "")

	var property_info = {
		"name": PATH + &"flatc_path",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_GLOBAL_FILE,
		"hint_string": "flatc.exe" # This will the filter string in the file dialog
	}

	settings.add_property_info(property_info)

func changes_to_fbs():
	# Get the FileSystemDock
	var fbs := EditorInterface.get_file_system_dock()

	# get the tree
	# I dont like using find_children, but all the names are auto generated.
	var tree : Tree = fbs.find_children( "", "Tree", true, false)[0]

	# Get the right click menu
	var rcm : PopupMenu
	var menus = fbs.find_children( "", "PopupMenu", false, false )

	# I dont like this, but it appears that the second menu is typically the one
	rcm = menus[1]

	tree.item_mouse_selected.connect( func( _position: Vector2, _mouse_button_index: int ):
		var current_path := EditorInterface.get_current_path()
		if not current_path.ends_with(".fbs"): return
		rcm.add_separator()
		rcm.add_item("flatc Generate")
		var index = rcm.item_count -1
		# we have to add something to differentiate us from other menu items.
		rcm.set_item_metadata(index, "fbs")
	)

	# Connect the right click signals to something:
	rcm.id_pressed.connect( func( id ):
		var meta = rcm.get_item_metadata( id )
		if meta != "fbs": return

		var settings = EditorInterface.get_editor_settings()
		var flatc_path : String = settings.get( &"plugin/FlatBuffers/flatc_path")
		if flatc_path.is_empty():
			printerr( " Please specify the location of flatc in EditorSettings->Plugins->FlatBuffers")
			return

		var source_path = ProjectSettings.globalize_path(EditorInterface.get_current_path())
		var output_path = ProjectSettings.globalize_path(EditorInterface.get_current_directory())

		var args : PackedStringArray = [
			"-o", output_path,
			"--gdscript", source_path]

		var output = []
		var result = OS.execute( flatc_path, args, output, true )
		if not output.is_empty():
			if result: printerr( output )
			else: print( output )

		EditorInterface.get_resource_filesystem().scan()
	)
