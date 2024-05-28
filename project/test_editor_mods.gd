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

	# This is not reliable as on startup there are no items in any of the menus.
	#for menu : PopupMenu in menus:
		#if menu.item_count > 0:
			#rcm = menu

	# I dont like this, but it appears that the second menu is typically the one
	rcm = menus[1]

	# Connect the tree signals to something
	# this is not needed
	#tree.cell_selected.connect(
		#func():
			#var tree_item := tree.get_selected()
			#print( tree_item.get_text(0) )
	#)

	# this is not needed
	#tree.empty_clicked.connect( func( position: Vector2, mouse_button_index: int ):
		#print( "empty_clicked(%s, %s)" % [position, mouse_button_index] )
	#)

	tree.item_mouse_selected.connect( func( position: Vector2, mouse_button_index: int ):
		# Check that we have a *.fbs file
		# I wrote the below before I found the get_current_path function
		#var tree_item := tree.get_selected()
		#var item_text = tree_item.get_text(0)
		#print( "TreeItem = ", item_text  )
		var current_path := EditorInterface.get_current_path()
		if not current_path.ends_with(".fbs"): return
		rcm.add_separator()
		rcm.add_item("flatc Generate")
		var index = rcm.item_count -1
		# we have to add something to differentiate us from other menu items.
		rcm.set_item_metadata(index, "fbs")
		rcm.add_item
	)

	# Connect the right click signals to something:
	rcm.id_pressed.connect( func( id ):
		var meta = rcm.get_item_metadata( id )
		if meta != "fbs": return
		print( "generate was clicked")

		# Double check we have the right filetype.
		# This is not necessary after I found get_current_path()
		#var tree_item := tree.get_selected()
		#var item_text = tree_item.get_text(0)
		#if not item_text.ends_with(".fbs"): return


		# We need to know the full path to be able to run flatc on our file.
		# This is no longer necessary as we have get_current_path
		#var parent : TreeItem
		#var path : String = item_text
		#parent = tree_item.get_parent()
		#while parent:
			#path = parent.get_text(0) + "/" + path
			#parent = parent.get_parent()
		#print( path )
		# This gives us a path relative to /res://

		print( ProjectSettings.globalize_path(EditorInterface.get_current_path()) )

		# OS.execute( flatc path )
	)
