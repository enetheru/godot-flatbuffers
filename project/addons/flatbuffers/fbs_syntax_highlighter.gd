class_name FlatBuffersHighlighter extends EditorSyntaxHighlighter


# Override methods for EditorSyntaxHighlighter
func _get_name ( ) -> String:
	print("fbsh _get_name")
	return "FlatBuffersHighlighter"

func _get_supported_languages ( ) -> PackedStringArray:
	print("fbsh _get_supported_languages()")
	return ["fbs"]

# Override methods for Syntax Highlighter
func _clear_highlighting_cache ( ):
	print("fbsh cache cleared")
	pass

func _get_line_syntax_highlighting ( line : int ) -> Dictionary:
	print("fbsh get line syntax")
	return {}

func _update_cache ( ):
	print("fbsh update cache")
	pass
