@tool
extends EditorScript


var fs := EditorInterface.get_resource_filesystem()
var test_dir : EditorFileSystemDirectory = fs.get_filesystem_path( 'res://tests/' )
var fbs_dir : EditorFileSystemDirectory = fs.get_filesystem_path( 'res://fbs_files/tests/' )

var results : Dictionary = {}

func _run() -> void:
	for i in test_dir.get_subdir_count():
		var subdir : EditorFileSystemDirectory = test_dir.get_subdir(i)
		for j in subdir.get_file_count():
			var file_path = subdir.get_file_path(j)
			run_test( file_path )
	print_results()

func run_test( file_path : String ):
	if file_path.ends_with("generated.gd"): return;
	if not fs.get_file_type( file_path ) == &'GDScript': return
	var key = "%s/%s" % [file_path.get_base_dir().get_file().to_pascal_case(),file_path.get_file()]

	print_rich( "\n[b]== Test: %s ==[/b]\n" % [key] )
	var script : GDScript = load( file_path )
	if not script.can_instantiate():
		printerr("Unable to instantiate '%s'" % [key] )
		results[ key ] = FAILED
		return
	var instance = script.new()
	instance._run()
	results[ key ] = instance.retcode

func print_results():
	var rich_text : String = "\n[b]== Test Results ==[/b]\n"
	rich_text += "[table=3]"
	for key in results:
		rich_text += "[cell]%s[/cell]" % key
		rich_text += "[cell]:[/cell]"
		rich_text += "[cell]%s[/cell]" % ("[color=red]Failure[/color]" if results[key] else "[color=green]Success[/color]")
	rich_text += "[/table]"

	print_rich( rich_text )
