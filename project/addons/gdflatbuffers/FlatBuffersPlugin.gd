@tool
class_name FlatBuffersPlugin extends EditorPlugin

const EDITOR_SETTINGS_BASE := &"plugin/FlatBuffers/"
const debug_verbosity := EDITOR_SETTINGS_BASE + &"fbs_debug_verbosity"
const flatc_path := EDITOR_SETTINGS_BASE + &"flatc_path"

var script_editor := EditorInterface.get_script_editor()
static var settings := EditorInterface.get_editor_settings()
var fs := EditorInterface.get_resource_filesystem()
var editor_log : RichTextLabel

var fbs := EditorInterface.get_file_system_dock()
var fbs_rcm : PopupMenu
var fbs_tree : Tree

var highlighter : FlatBuffersHighlighter

func _enter_tree() -> void:
	highlighter = FlatBuffersHighlighter.new()

	change_editor_settings()
	enable_syntax_highlighter()
	enable_changes_to_fbs()
	connect_to_output_meta()


func _exit_tree() -> void:
	disable_changes_to_fbs()
	disable_syntax_highlighter()
	disconnect_from_output_meta()


func _on_meta_clicked( meta ):
	print( meta )
	#if ResourceLoader.exists( meta ):
		#print( "Path exists: ", meta)
	#else:
		#printerr( "Path does not exists: ", meta)
	#print( test )
	#if test:
		#load( meta.test )._run()

func connect_to_output_meta() -> void:
	var logs : Array[Node] = EditorInterface.get_base_control().find_children('', 'EditorLog', true, false )
	for item : Node in logs:
		editor_log = item.find_children('','RichTextLabel', true, false ).front()
		editor_log.meta_clicked.connect( _on_meta_clicked )


func disconnect_from_output_meta() -> void:
	editor_log.meta_clicked.disconnect( _on_meta_clicked )


func enable_syntax_highlighter() -> void:
	script_editor.register_syntax_highlighter( highlighter )


func disable_syntax_highlighter() -> void:
	script_editor.unregister_syntax_highlighter( highlighter )


func change_editor_settings() -> void:
	# TODO make these project settings
	# Editor Settings
	if not settings.get( flatc_path ):
		settings.set( flatc_path, "")
		var property_info := {
			"name": flatc_path,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_GLOBAL_FILE,
			"hint_string": "flatc.exe" # This will the filter string in the file dialog
		}
		settings.add_property_info(property_info)

	if not settings.get( debug_verbosity ):
		settings.set(debug_verbosity, false )
		var property_info := {
			"name": debug_verbosity,
			"type": TYPE_INT,
		}
		settings.add_property_info(property_info)


func enable_changes_to_fbs():
	# get the tree
	# I dont like using find_children, but all the names are auto generated.
	fbs_tree = fbs.find_children( "", "Tree", true, false)[0]

	# Get the right click menu
	var menus : Array[Node] = fbs.find_children( "", "PopupMenu", false, false )
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
		var index : int = fbs_rcm.item_count -1
		# we have to add something to differentiate us from other menu items.
		fbs_rcm.set_item_metadata(index, "fbs")


# This function is connected to the is_pressed signal of the right click popup menu
func rcm_generate( id ) -> void:
	# do not proceed if the metadata of the click isnt 'fbs'
	var meta = fbs_rcm.get_item_metadata( id )
	if meta != "fbs": return

	var results : Dictionary = {'retcode':OK}
	var current_path : String= EditorInterface.get_current_path()
	if DirAccess.dir_exists_absolute( current_path ):
		var dir: EditorFileSystemDirectory = fs.get_filesystem_path( current_path )
		for i in dir.get_file_count():
			var file: String = dir.get_file_path(i)
			#TODO detect teh filetype rather than the extension when the Resource Loader is created
			if file.ends_with('.fbs'):
				results = FlatBuffersPlugin.flatc_generate( file )
	else:
		results = FlatBuffersPlugin.flatc_generate( current_path )

	if results.retcode: print_results( results )


static func flatc_generate( path : String ) -> Variant:
	# Make sure we have the flac compiler
	var flatc_path : String = settings.get( flatc_path )
	if flatc_path.is_empty():
		flatc_path = "res://addons/gdflatbuffers/bin/flatc.exe"

	flatc_path = flatc_path.replace('res://', './')

	if not FileAccess.file_exists(flatc_path):
		return {'return_code':ERR_FILE_BAD_PATH, 'output': "Missing flatc compiler"}

	# TODO make this an editor setting that can be added to.
	var include_paths : Array = ["res://addons/gdflatbuffers/"]
	for i in include_paths.size():
		include_paths[i] = include_paths[i].replace('res://', './')

	var source_path : String = path.replace('res://', './')
	if not FileAccess.file_exists(source_path):
		return {'return_code':ERR_FILE_BAD_PATH, 'output': "Missing Schema File: %s" % source_path }

	var output_path : String = source_path.get_base_dir()

	var args : PackedStringArray = []
	for include in include_paths: args.append_array(["-I", include])
	args.append_array([ "--gdscript",  "-o", output_path, source_path, ])

	var result : Dictionary = {
		'flatc_path':flatc_path,
		'args':args,
	}
	var output : Array = []
	result['retcode'] = OS.execute( flatc_path, args, output, true )
	result['output'] = output

	#TODO Figure out a way to get the script in the editor to reload.
	#  the only reliable way I have found to refresh the script in the editor
	#  is to change the focus away from Godot and back again.

	# This line refreshes the filesystem dock.
	EditorInterface.get_resource_filesystem().scan()
	return result

func print_results( result : Dictionary ):
	if result.retcode:
		var output = result.get('output')
		result.erase('output')
		printerr( "flatc_generate result: ", JSON.stringify( result, '\t', false ) )
		for o in output: print( o )
