@tool
class_name FlatBuffersPlugin extends EditorPlugin

const EDITOR_SETTINGS_BASE = &"plugin/FlatBuffers/"

var script_editor := EditorInterface.get_script_editor()
var settings = EditorInterface.get_editor_settings()
var fs := EditorInterface.get_resource_filesystem()

var fbs := EditorInterface.get_file_system_dock()
var fbs_rcm : PopupMenu
var fbs_tree : Tree

var highlighter : FlatBuffersHighlighter

func _enter_tree() -> void:
	highlighter = FlatBuffersHighlighter.new()

	change_editor_settings()
	enable_syntax_highlighter()
	enable_changes_to_fbs()


func _exit_tree() -> void:
	disable_changes_to_fbs()
	disable_syntax_highlighter()


func enable_syntax_highlighter():
	script_editor.register_syntax_highlighter( highlighter )


func disable_syntax_highlighter():
	script_editor.unregister_syntax_highlighter( highlighter )


func change_editor_settings():
	# TODO make these project settings
	# Editor Settings
	if not settings.get( EDITOR_SETTINGS_BASE + &"flatc_path" ):
		settings.set(EDITOR_SETTINGS_BASE + &"flatc_path", "")
		var property_info = {
			"name": EDITOR_SETTINGS_BASE + &"flatc_path",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_GLOBAL_FILE,
			"hint_string": "flatc.exe" # This will the filter string in the file dialog
		}
		settings.add_property_info(property_info)

	if not settings.get( EDITOR_SETTINGS_BASE + &"fbs_debug_print" ):
		settings.set(EDITOR_SETTINGS_BASE + &"fbs_debug_print", false )
		var property_info = {
			"name": EDITOR_SETTINGS_BASE + &"fbs_debug_print",
			"type": TYPE_BOOL,
		}
		settings.add_property_info(property_info)


func enable_changes_to_fbs():
	# get the tree
	# I dont like using find_children, but all the names are auto generated.
	fbs_tree = fbs.find_children( "", "Tree", true, false)[0]

	# Get the right click menu
	var menus = fbs.find_children( "", "PopupMenu", false, false )
		# I dont like this, but it appears that the second menu is typically the one
	fbs_rcm = menus[1]

	# Connect the signals to enable right click generate
	fbs_tree.item_mouse_selected.connect( append_fbs_rcm )
	fbs_rcm.id_pressed.connect( rcm_generate )


func disable_changes_to_fbs():
	fbs_tree.item_mouse_selected.disconnect( append_fbs_rcm )
	fbs_rcm.id_pressed.disconnect( rcm_generate )


# this is connected to the item_mouse_selected signal of the FileSystemDock Tree
func append_fbs_rcm( _position: Vector2, _mouse_button_index: int ):
	# Change the description depending on the selection.
	# TODO utilie EditorInterface.get_selected_paths() to determine whether to show the menu
	var current_path := EditorInterface.get_current_path()
	if current_path.ends_with(".fbs") or DirAccess.dir_exists_absolute( current_path ):
		fbs_rcm.add_separator()
		fbs_rcm.add_item("flatc Generate")
		var index = fbs_rcm.item_count -1
		# we have to add something to differentiate us from other menu items.
		fbs_rcm.set_item_metadata(index, "fbs")


# This function is connected to the is_pressed signal of the right click popup menu
func rcm_generate( id ):
	# do not proceed if the metadata of the click isnt 'fbs'
	var meta = fbs_rcm.get_item_metadata( id )
	if meta != "fbs": return

	var results : Dictionary = {'return_code':0}
	var current_path = EditorInterface.get_current_path()
	if DirAccess.dir_exists_absolute( current_path ):
		var dir = fs.get_filesystem_path( current_path )
		for i in dir.get_file_count():
			var file = dir.get_file_path(i)
			#FIXME detect teh filetype rather than the extension when the Resource Loader is created
			if file.ends_with('.fbs'):
				results = flatc( file )
				if results.return_code: print( results )

	else:
		results = flatc( current_path )
		if results.return_code: print( results )


func flatc( path : String ) -> Variant:
	# Make sure we have the flac compiler
	var flatc_path : String = settings.get( &"plugin/FlatBuffers/flatc_path")
	if flatc_path.is_empty():
		flatc_path = ProjectSettings.globalize_path("res://addons/gdflatbuffers/bin/flatc.exe")

	if not FileAccess.file_exists(flatc_path):
		return {'return_code':ERR_FILE_BAD_PATH, 'output': "Missing flatc compiler"}

	# TODO make this an editor setting that can be added to.
	var include_paths : Array = [ProjectSettings.globalize_path( "res://addons/gdflatbuffers/" )]

	var source_path = ProjectSettings.globalize_path( path )
	if not FileAccess.file_exists(source_path):
		return {'return_code':ERR_FILE_BAD_PATH, 'output': "Missing Schema File: %s" % source_path }

	var output_path = source_path.get_base_dir()

	var args : PackedStringArray = []
	for include in include_paths: args.append_array(["-I", include])
	args.append_array([ "--gdscript",  "-o", output_path, source_path, ])

	var output = []
	var result = OS.execute( flatc_path, args, output, true )
	#output = output.map(func(item : String): return item.c_unescape() )

	# This line refreshes the filesystem dock.
	EditorInterface.get_resource_filesystem().scan()

	#TODO Figure out a way to get the script in the editor to reload.
	return { 'return_code':result, 'output':output }
