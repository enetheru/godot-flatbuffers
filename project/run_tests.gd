@tool
extends EditorScript

var fs := EditorInterface.get_resource_filesystem()
var test_dir : EditorFileSystemDirectory = fs.get_filesystem_path( 'res://tests/' )
var fbs_dir : EditorFileSystemDirectory = fs.get_filesystem_path( 'res://fbs_files/tests/' )


func _run() -> void:
	print_rich( "\n[b]== GDFlatbuffer Plugin Testing ==[/b]\n" )
	var schemas = []
	var tests = []
	for i in test_dir.get_subdir_count():
		var subdir : EditorFileSystemDirectory = test_dir.get_subdir(i)
		for j in subdir.get_file_count():
			var file_path = subdir.get_file_path(j)
			if file_path.ends_with( '_generated.gd' ): continue;
			if file_path.ends_with( '.fbs' ):
				schemas.append( file_path )
			if file_path.ends_with( '.gd' ):
				tests.append( file_path )

	#print( "Schemas : ", JSON.stringify( schemas, '\t', false ) )
	#print( "Tests : ", JSON.stringify( tests, '\t', false ) )

	print_rich( "\n[b]... Compiling %s Flatbuffer Schemas[/b]\n" % schemas.size() )
	var compile_results : Dictionary = {}
	for schema : String in schemas:
		var category = schema.get_base_dir().get_file().to_pascal_case()
		var file = schema.get_file()
		var key = "/".join( [category, file] )
		var result = FlatBuffersPlugin.flatc_generate( schema )
		compile_results[key] = result
		if result['retcode']:
			print_rich("[b]# Error processing %s[/b]" % key )
			print_result_error( result )

	print_results( "Compile Results", compile_results )

	print_rich( "\n[b]... Running %s Tests[/b]\n" % tests.size() )
	var test_results : Dictionary = {}
	for test : String in tests:
		var thread := Thread.new()
		var category = test.get_base_dir().get_file().to_pascal_case()
		var file = test.get_file()
		var key = "/".join( [category, file] )
		thread.start( run_test.bind( test ) )
		var result = thread.wait_to_finish()
		test_results[key] = result
		if result['retcode']:
			print_rich("[b]# Error running test %s[/b]" % key )
			print_result_error( result )

	print_results( "Test Results", test_results )


func run_test( file_path : String ):
	var result : Dictionary = {}
	var script : GDScript = load( file_path )
	if not script.can_instantiate():
		result['retcode'] = FAILED
		result['output'] = ["Cannot instantiate '%s'" % file_path ]
		return result
	var instance = script.new()
	instance.silent = true
	instance._run()
	result['retcode'] = instance.retcode
	result['output'] = instance.output
	return result


func print_results( heading : String, results : Dictionary ):
	var rich_text : String = "\n[b]== %s ==[/b]\n" % heading
	rich_text += "[table=3]"
	for key in results:
		var result = results[key]
		rich_text += "[cell]%s[/cell]" % key
		rich_text += "[cell]:[/cell]"
		rich_text += "[cell]%s[/cell]" % ("[color=red]Failure[/color]" if result['retcode'] else "[color=green]Success[/color]")
	rich_text += "[/table]"
	print_rich( rich_text )


func print_result_error( result : Dictionary ):
	var output = result.get('output')
	result.erase('output')
	printerr( "result: ", JSON.stringify( result, '\t', false ) )
	if output:
		for o in output: print( o.indent('\t') )
	print("")
