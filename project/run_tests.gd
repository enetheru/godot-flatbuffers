@tool
extends EditorScript


var fs := EditorInterface.get_resource_filesystem()
var test_dir : EditorFileSystemDirectory = fs.get_filesystem_path( 'res://tests/' )
var fbs_dir : EditorFileSystemDirectory = fs.get_filesystem_path( 'res://fbs_files/tests/' )

var results : Dictionary = {}

func _run() -> void:
	for i in test_dir.get_subdir_count():
		var subdir : EditorFileSystemDirectory = test_dir.get_subdir(i)
		var path = subdir.get_name().to_pascal_case()
		print_rich( "\n[b]== Test: %s ==[/b]\n" % path )
		for j in subdir.get_file_count():
			var filename = subdir.get_file(j)
			if subdir.get_file_type(j) == &'GDScript' and not filename.ends_with("generated.gd"):
				print( filename )
				var script = load( subdir.get_path() + filename )
				var instance = script.new()
				#instance._run()
				results[ "%s/%s" % [path,filename] ] = instance.result


	var rich_text : String = "\n[b]== Test Results ==[/b]\n"

	rich_text += "[table=3]"
	for key in results:
		rich_text += "[cell]%s[/cell]" % key
		rich_text += "[cell]:[/cell]"
		rich_text += "[cell]%s[/cell]" % results[key]
	rich_text += "[/table]"

	print_rich( rich_text )
