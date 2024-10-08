@tool
class_name FlatBuffersHighlighter extends EditorSyntaxHighlighter

var editor_settings : EditorSettings
var verbose : int = 0

#region Highlighter
# ██   ██ ██  ██████  ██   ██ ██      ██  ██████  ██   ██ ████████ ███████ ██████
# ██   ██ ██ ██       ██   ██ ██      ██ ██       ██   ██    ██    ██      ██   ██
# ███████ ██ ██   ███ ███████ ██      ██ ██   ███ ███████    ██    █████   ██████
# ██   ██ ██ ██    ██ ██   ██ ██      ██ ██    ██ ██   ██    ██    ██      ██   ██
# ██   ██ ██  ██████  ██   ██ ███████ ██  ██████  ██   ██    ██    ███████ ██   ██

enum TokenType { UNKNOWN, COMMENT, KEYWORD, TYPE, STRING, PUNCT, IDENT, SCALAR,
				META, EOL, EOF }

var colours : Dictionary = {
	TokenType.UNKNOWN : Color.GREEN,
	TokenType.COMMENT : Color.DIM_GRAY,
	TokenType.KEYWORD : Color.SALMON,
	TokenType.TYPE : Color.GREEN,
	TokenType.STRING : Color.GREEN,
	TokenType.PUNCT : Color.GREEN,
	TokenType.IDENT : Color.GREEN,
	TokenType.SCALAR : Color.GREEN,
	TokenType.META : Color.GREEN,
	TokenType.EOF : Color.GREEN,
}
var error_color : Color = Color.FIREBRICK

var resource : Resource
var file_location : String
var reader : Reader				# the main reader
var qreader : Reader			# for scanning alternate files
var dict : Dictionary
var line_dict : Dictionary
var error_flag : bool = false 	# This is to indicate not to save the stack to the next line

var user_types : Dictionary = {}
var user_enum_vals : Dictionary = {}

var new_index_chunk : Array[bool]
var stack_index : Array[bool]		= [false]	# array index = index in stack list
var stack_list : Dictionary			= {}	# saved stacks

func _init():
	new_index_chunk.resize(10)
	new_index_chunk.fill(false)
	editor_settings = EditorInterface.get_editor_settings()
	error_color = Color.RED

	reader = Reader.new()
	qreader = Reader.new()

	reader.new_token.connect(func( token ):
		if verbose > 1:
			var colour : Color = colours[token.type]
			if verbose > 1: print_rich("next: [color=%s]%s[/color]" % [colour.to_html(), stoken( token )] )
		loop_detection = 0
		highlight( token )
	)
	reader.newline.connect( func(l,p):
		if error_flag: return
		save_stack(l, 0)
	)
	#FIXME reader.endfile.connect( save_stack )

	colours[TokenType.UNKNOWN] = editor_settings.get_setting("text_editor/theme/highlighting/text_color")
	colours[TokenType.COMMENT] = editor_settings.get_setting("text_editor/theme/highlighting/comment_color")
	colours[TokenType.KEYWORD] = editor_settings.get_setting("text_editor/theme/highlighting/keyword_color")
	colours[TokenType.TYPE] = editor_settings.get_setting("text_editor/theme/highlighting/base_type_color")
	colours[TokenType.STRING] = editor_settings.get_setting("text_editor/theme/highlighting/string_color")
	colours[TokenType.PUNCT] = editor_settings.get_setting("text_editor/theme/highlighting/text_color")
	colours[TokenType.IDENT] = editor_settings.get_setting("text_editor/theme/highlighting/symbol_color")
	colours[TokenType.SCALAR] = editor_settings.get_setting("text_editor/theme/highlighting/number_color")
	colours[TokenType.META] = editor_settings.get_setting("text_editor/theme/highlighting/text_color")

	verbose = editor_settings.get_setting( FlatBuffersPlugin.debug_verbosity )
	#TODO move the regex compilation to the plugin
	#Regex Compilation
	# STRING_CONSTANT = \".*?\\"
	regex_string_constant = RegEx.new()
	regex_string_constant.compile("^\\\".*?\\\\\"$")

	# IDENT = [a-zA-Z_][a-zA-Z0-9_]*
	regex_ident = RegEx.new()
	regex_ident.compile("^[a-zA-Z_][a-zA-Z0-9_]*$")

	# DIGIT [:digit:] = [0-9]
	regex_digit = RegEx.new()
	regex_digit.compile("^[0-9]$")

	# XDIGIT [:xdigit:] = [0-9a-fA-F]
	regex_xdigit = RegEx.new()
	regex_xdigit.compile("^[0-9a-fA-F]$")

	# DEC_INTEGER_CONSTANT = [-+]?[:digit:]+
	regex_dec_integer_constant = RegEx.new()
	regex_dec_integer_constant.compile("^[-+]?[0-9]+$")

	# HEX_INTEGER_CONSTANT = [-+]?0[xX][:xdigit:]+
	regex_hex_integer_constant = RegEx.new()
	regex_hex_integer_constant.compile("^[-+]?0[xX][0-9a-fA-F]+$")

	# DEC_FLOAT_CONSTANT = [-+]?(([.][:digit:]+)|([:digit:]+[.][:digit:]*)|([:digit:]+))([eE][-+]?[:digit:]+)?
	regex_dec_float_constant = RegEx.new()
	regex_dec_float_constant.compile("^[-+]?(([.][0-9]+)|([0-9]+[.][0-9]*)|([0-9]+))([eE][-+]?[0-9]+)?$")

	# HEX_FLOAT_CONSTANT = [-+]?0[xX](([.][:xdigit:]+)|([:xdigit:]+[.][:xdigit:]*)|([:xdigit:]+))([pP][-+]?[:digit:]+)
	regex_hex_float_constant = RegEx.new()
	regex_hex_float_constant.compile("^[-+]?0[xX](([.][[+-]?[0-9a-fA-F]+]+)|([[+-]?[0-9a-fA-F]+]+[.][[+-]?[0-9a-fA-F]+]*)|([[+-]?[0-9a-fA-F]+]+))([pP][+-]?[0-9]+)$")

	# SPECIAL_FLOAT_CONSTANT = [-+]?(nan|inf|infinity)
	regex_special_float_constant = RegEx.new()
	regex_special_float_constant.compile("^[-+]?(nan|inf|infinity)$")
	if verbose > 1: print_rich("[b]FlatBuffersHighlighter._init() - Completed[/b]")

# Override methods for EditorSyntaxHighlighter
func _get_name ( ) -> String:
	return "FlatBuffersSchema"


func _get_supported_languages ( ) -> PackedStringArray:
	return ["FlatBuffersSchema", "fbs"]


# Override methods for Syntax Highlighter
func _clear_highlighting_cache ( ):
	resource = get_edited_resource()
	file_location = resource.resource_path.get_base_dir() + "/"
	if verbose > 2: print_rich("[b]_clear_highlighting_cache( )[/b]")
	included_files.clear()
	user_enum_vals.clear()
	user_types.clear()
	dict.clear()
	error_flag = false
	stack_list.clear()
	stack_index.resize( get_text_edit().text.length() + 10)
	stack_index.fill(false)
	if verbose > 2: print( "highlight dict: ", JSON.stringify(dict, '\t') )

# This function runs on any change, with the line number that is edited.
# we can use it to update the highlighting.
func _get_line_syntax_highlighting ( line_num : int ) -> Dictionary:
	# Very early out for an empty line
	var line = get_text_edit().get_line( line_num )
	dict.erase(line_num)
	line_dict = {}
	stack_index[line_num] = false
	if line.is_empty():
		return {}

	if verbose > 1:
		print_rich( "\n[b]Line %s[/b]" % [line_num+1] )
		print( "stack_index[%s]: %s" % [line_num+1, stack_index[line_num]] )

	# reset the reader
	reader.reset( line, line_num )
	# skip whitespace, comments and empty lines
	reader.skip_whitespace()
	if verbose > 2: print( "peek_char() = '%s'" % reader.peek_char().c_escape() )
	if reader.peek_char() == '/' and reader.peek_char(1) == '/':
		highlight(reader.next_token())
		dict[line_num] = line_dict
		return line_dict
	if reader.peek_char() == '\n': return {}


	# get the previous stack save, skip lines with empty stacks.
	# FIXME This part takes forever.
	while stack_index.size() < line_num: stack_index.append_array(new_index_chunk)
	prev_stack = []

	var stack_line : int = line_num
	while not prev_stack and stack_line > 0:
		stack_line -= 1
		if not stack_index[stack_line]: continue
		if not stack_list.has( stack_line ): continue
		prev_stack = stack_list.get( stack_line )

	#-- dictionary code
	#prev_stack = []
	#var stack_line : int = line_num
	#while not prev_stack and stack_line:
		#stack_line -= 1
		#if not dict.has( stack_line ): continue
		#line_dict = dict.get( stack_line, {} )
		#if not line_dict.has('stack'): continue
		#prev_stack = line_dict.get( 'stack' )
#
	stack = copy_stack( prev_stack ) if prev_stack else []

	if verbose > 1:
		print_rich( "Using stack from line %s | %s" % [stack_line+1, sstack()] )

	parse()

	dict[line_num] = line_dict
	return line_dict


func _update_cache ( ):
	# Get settings
	verbose = editor_settings.get_setting( FlatBuffersPlugin.debug_verbosity )
	if verbose > 2: print_rich("[b]_update_cache( )[/b]")
	quick_scan_text( get_text_edit().text )
	error_color = Color.RED

func highlight( token : Dictionary ):
	if token.type in [TokenType.EOF, TokenType.UNKNOWN]: return
	line_dict[token.col] = { 'color':colours[token.type] }

func syntax_warning( token : Dictionary, reason = "" ):
	line_dict[token.col] = { 'color':colours[TokenType.COMMENT] }
	if verbose > 0:
		var padding = "".lpad(stack.size(), '\t') if verbose > 1 else ""
		var colour = Color.ORANGE.to_html()
		var frame_type = FrameType.keys()[stack.back().type] if stack.size() else '#'
		print_rich( padding + "[color=%s]%s:Warning in: %s - %s[/color]" % [colour, frame_type, stoken( token ), reason] )
		if verbose > 1: print_rich( "[color=%s]%s[/color]\n" % [colour,sstack()] )

func syntax_error( token : Dictionary, reason = "" ):
	error_flag = true
	if line_dict.has(token.col): line_dict.erase(token.col)
	line_dict[token.col] = { 'color':error_color }
	if verbose > 0:
		var padding = "".lpad(stack.size(), '\t') if verbose > 1 else ""
		var colour = error_color.to_html()
		var frame_type = FrameType.keys()[stack.back().type] if stack.size() else '#'
		print_rich( padding + "[color=%s]%s:Error in: %s - %s[/color]" % [colour, frame_type, stoken( token ), reason] )
		if verbose > 1: print_rich( "[color=%s]%s[/color]\n" % [colour,sstack()] )

#endregion

#region Grammar
#  ██████  ██████   █████  ███    ███ ███    ███  █████  ██████
# ██       ██   ██ ██   ██ ████  ████ ████  ████ ██   ██ ██   ██
# ██   ███ ██████  ███████ ██ ████ ██ ██ ████ ██ ███████ ██████
# ██    ██ ██   ██ ██   ██ ██  ██  ██ ██  ██  ██ ██   ██ ██   ██
#  ██████  ██   ██ ██   ██ ██      ██ ██      ██ ██   ██ ██   ██

enum FrameType {
	NONE, # so that SCHEMA isnt at zero which is conflated with bool
	# schema grammer : https://flatbuffers.dev/flatbuffers_grammar.html
	SCHEMA, # = include ( namespace_decl
	#					| type_decl
	#					| enum_decl
	#					| root_decl
	#					| file_extension_decl
	#					| file_identifier_decl
	#					| attribute_decl
	#					| rpc_decl
	#					| object )*
	INCLUDE,# = include string_constant ;
	NAMESPACE_DECL, # = namespace ident ( . ident )* ;
	ATTRIBUTE_DECL, # = attribute ident | "</tt>ident<tt>" ;
	TYPE_DECL, # = ( table | struct ) ident metadata { field_decl+ }
	ENUM_DECL, # = ( enum ident : type | union ident ) metadata { commasep( enumval_decl ) }
	ROOT_DECL, # = root_type ident ;
	FIELD_DECL, # = ident : type [ = scalar ] metadata ;
	RPC_DECL, # = rpc_service ident { rpc_method+ }
	RPC_METHOD, # = ident ( ident ) : ident metadata ;
	TYPE, # = bool | byte | ubyte | short | ushort | int | uint | float | long | ulong | double | int8 | uint8 | int16 | uint16 | int32 | uint32| int64 | uint64 | float32 | float64 | string | [ type ] | ident
	ENUMVAL_DECL, # = ident [ = integer_constant ]
	METADATA, # = [ ( commasep( ident [ : single_value ] ) ) ]
	SCALAR, # = boolean_constant | integer_constant | float_constant
	OBJECT, # = { commasep( ident : value ) }
	SINGLE_VALUE, # = scalar | string_constant
	VALUE, # = single_value | object | [ commasep( value ) ]
	COMMASEP, #(x) = [ x ( , x )* ]
	FILE_EXTENSION_DECL, # = file_extension string_constant ;
	FILE_IDENTIFIER_DECL, # = file_identifier string_constant ;
	STRING_CONSTANT, # = \".*?\\"
	IDENT, # = [a-zA-Z_][a-zA-Z0-9_]*
	#DIGIT, # [:digit:] = [0-9]
	#XDIGIT, # [:xdigit:] = [0-9a-fA-F]
	#DEC_INTEGER_CONSTANT, # = [-+]?[:digit:]+
	#HEX_INTEGER_CONSTANT, # = [-+]?0[xX][:xdigit:]+
	INTEGER_CONSTANT, # = dec_integer_constant | hex_integer_constant
	#DEC_FLOAT_CONSTANT, # = [-+]?(([.][:digit:]+)|([:digit:]+[.][:digit:]*)|([:digit:]+))([eE][-+]?[:digit:]+)?
	#HEX_FLOAT_CONSTANT, # = [-+]?0[xX](([.][:xdigit:]+)|([:xdigit:]+[.][:xdigit:]*)|([:xdigit:]+))([pP][-+]?[:digit:]+)
	#SPECIAL_FLOAT_CONSTANT, # = [-+]?(nan|inf|infinity)
	#FLOAT_CONSTANT, # = dec_float_constant | hex_float_constant | special_float_constant
	#BOOLEAN_CONSTANT, # = true | false
}

var keywords : Array = [ 'include', 'namespace', 'table', 'struct', 'enum',
	'union', 'root_type', 'file_extension', 'file_identifier', 'attribute',
	'rpc_service']

var scalar_types: Array = [ "bool", "byte", "ubyte", "short", "ushort", "int",
	"uint", "float", "long", "ulong", "double", "int8", "uint8", "int16",
	"uint16", "int32", "uint32", "int64", "uint64", "float32", "float64" ]

var struct_types: Array = [
	"Vector2",
	"Vector2i",
	"Rect2",
	"Rect2i",
	"Vector3",
	"Vector3i",
	"Transform2D",
	"Vector4",
	"Vector4i",
	"Plane",
	"Quaternion",
	"AABB",
	"Basis",
	"Transform3D",
	"Projection",
	"Color", ]

var table_types: Array = []

var array_types: Array = [
	"string",
	"String",
	"StringName",
	"NodePath", ]
#endregion

#region Regex
# ██████  ███████  ██████  ███████ ██   ██
# ██   ██ ██      ██       ██       ██ ██
# ██████  █████   ██   ███ █████     ███
# ██   ██ ██      ██    ██ ██       ██ ██
# ██   ██ ███████  ██████  ███████ ██   ██
var regex_string_constant : RegEx # = \".*?\\"
var regex_ident : RegEx # = [a-zA-Z_][a-zA-Z0-9_]*
var regex_digit : RegEx # [:digit:] = [0-9]
var regex_xdigit : RegEx # [:xdigit:] = [0-9a-fA-F]
var regex_dec_integer_constant : RegEx # = [-+]?[:digit:]+
var regex_hex_integer_constant : RegEx # = [-+]?0[xX][:xdigit:]+
var regex_dec_float_constant : RegEx # = [-+]?(([.][:digit:]+)|([:digit:]+[.][:digit:]*)|([:digit:]+))([eE][-+]?[:digit:]+)?
var regex_hex_float_constant : RegEx # = [-+]?0[xX](([.][:xdigit:]+)|([:xdigit:]+[.][:xdigit:]*)|([:xdigit:]+))([pP][-+]?[:digit:]+)
var regex_special_float_constant : RegEx # = [-+]?(nan|inf|infinity)
var regex_boolean_constant : RegEx # = true | false
#endregion

#region Reader
# ██████  ███████  █████  ██████  ███████ ██████
# ██   ██ ██      ██   ██ ██   ██ ██      ██   ██
# ██████  █████   ███████ ██   ██ █████   ██████
# ██   ██ ██      ██   ██ ██   ██ ██      ██   ██
# ██   ██ ███████ ██   ██ ██████  ███████ ██   ██

class Reader:
	static var parent = load('res://addons/gdflatbuffers/FlatBuffersHighlighter.gd').new()

	signal new_token( token : Dictionary )
	signal newline( ln, p )
	signal endfile( ln, p )

	var word_separation : Array = [' ', '\t', '\n', '{','}', ':', ';', ',',
	'(', ')', '[', ']' ]
	var whitespace : Array = [' ', '\t', '\n']
	var punc : Array = [',', '.', ':', ';', '[', ']', '{', '}', '(', ')', '=']

	var text : String					# The text to parse
	var line_index : Array[int] = [0]	# cursor position for each line start
	var cursor_p : int = 0				# Cursor position in file
	var cursor_lp : int = 0				# Cursor position in line
	var line_n : int = 0				# Current line number
	var line_start : int				# When updating chunks of a larger source file, what line does this chunk start on.

	var token : Dictionary

	func _to_string() -> String:
		return JSON.stringify({
			'text': text,
			'line_index':line_index,
			'cursor_p': cursor_p,
			'cursor_lp': cursor_lp,
			'line_n': line_n,
			'line_start': line_start,
			'token': token,
		},'\t', false)

	func length() -> int:
		return text.length()

	func reset( text_ : String, line_i : int = 0 ):
		text = text_
		line_index = [0]
		cursor_p = 0
		cursor_lp = 0
		line_start = line_i
		line_n = line_i
		token = peek_token()

	func at_end() -> bool:
		if cursor_p >= text.length(): return true
		return false

	func peek_char( offset : int = 0 ) -> String:
		return text[cursor_p + offset] if cursor_p + offset < text.length() else '\n'

	func get_char() -> String:
		adv(); return text[cursor_p - 1]

	func adv( dist : int = 1 ):
		if cursor_p >= text.length(): return # dont advance further than length
		for i in dist:
			cursor_p += 1
			cursor_lp += 1
			if not cursor_p < text.length():
				endfile.emit( line_n + 1, cursor_p )
				return;
			if peek_char( ) != '\n': continue
			line_index.append( cursor_p )
			cursor_lp = 0
			line_n = line_index.size() -1
			newline.emit( line_n, cursor_p )
			break

	func next_line():
		adv( text.length() ) # adv automatically stops on a line break.
		next_token()

	func get_string() -> Dictionary:
		var start := cursor_p
		var token : Dictionary = {
			'line':line_n,
			'col':cursor_lp,
			'type':TokenType.STRING
		}
		adv()
		while true:
			if peek_char() == '"' and peek_char(-1) !='\\':
				adv()
				break
			if peek_char() == '\n':
				token['error'] = "reached end of line before \""
				break
			adv()
		token['t'] = text.substr( start, cursor_p - start )
		return token

	func get_comment() -> Dictionary:
		var token : Dictionary = {
			'line':line_n,
			'col': cursor_lp,
			'type':TokenType.COMMENT,
		}
		var start := cursor_p
		while peek_char() != '\n': adv()
		token['t'] = text.substr( start, start + 2 )

		return token

	func get_word() -> Dictionary:
		var token : Dictionary = {
			'line':line_n,
			'col': cursor_lp,
			'type':TokenType.UNKNOWN,
		}
		var start := cursor_p
		while not peek_char() in word_separation: adv()
		# return the substring
		token['t'] = text.substr( start, cursor_p - start )
		if is_type( token.get('t') ): token['type'] = TokenType.TYPE
		elif is_keyword(token.get('t')): token['type'] = TokenType.KEYWORD
		elif is_scalar( token.get('t') ): token['type'] = TokenType.SCALAR
		elif is_ident(token.get('t')): token['type'] = TokenType.IDENT
		return token

	func is_type( word : String )-> bool:
		# TYPE = bool | byte | ubyte | short | ushort | int | uint | float |
		# long | ulong | double | int8 | uint8 | int16 | uint16 | int32 |
		# uint32| int64 | uint64 | float32 | float64 | string | [ type ] |
		# ident
		if word in parent.scalar_types: return true
		if word in parent.struct_types: return true
		if word in parent.table_types: return true
		if word in parent.array_types: return true
		return false

	func is_keyword( word : String ) -> bool:
		if word in parent.keywords: return true
		return false

	func is_ident( word : String ) -> bool:
		#ident = [a-zA-Z_][a-zA-Z0-9_]*
		var ident_start : String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
		var ident_end : String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
		# verify first character
		if not ident_start.contains(word[0]) : return false
		# verify the remaining
		for i in range( 1, word.length() ):
			if not ident_end.contains(word[i]): return false
		return true

	func is_scalar( word : String ) -> bool:
		#scalar = boolean_constant | integer_constant | float_constant
		if is_boolean( word ): return true
		if is_integer( word ): return true
		if is_float( word ): return true
		return false

	func is_boolean( word : String ) -> bool:
		if word in ['true', 'false']: return true
		return false

	func is_integer( word : String ) -> bool:
		#integer_constant = dec_integer_constant | hex_integer_constant
		var regex = RegEx.new()
		#dec_integer_constant = [-+]?[:digit:]+
		regex.compile("^[-+]?[0-9]+$")
		var result = regex.search( word )
		if result: return true
		#hex_integer_constant = [-+]?0[xX][:xdigit:]+
		regex = RegEx.new()
		regex.compile("^[-+]?0[xX][0-9a-fA-F]+$")
		result = regex.search( word )
		if result: return true
		return false

	func is_float( word : String ) -> bool:
		#float_constant = dec_float_constant | hex_float_constant | special_float_constant
		var regex = RegEx.new()
		#dec_float_constant = [-+]?(([.][:digit:]+)|([:digit:]+[.][:digit:]*)|([:digit:]+))([eE][-+]?[:digit:]+)?
		regex.compile("^[-+]?(([.][0-9]+)|([0-9]+[.][0-9]*)|([0-9]+))([eE][-+]?[0-9]+)?$")
		var result = regex.search( word )
		if result: return true
		#hex_float_constant = [-+]?0[xX](([.][:xdigit:]+)|([:xdigit:]+[.][:xdigit:]*)|([:xdigit:]+))([pP][-+]?[:digit:]+)
		regex.compile("^[-+]?0[xX](([.][[+-]?[0-9a-fA-F]+]+)|([[+-]?[0-9a-fA-F]+]+[.][[+-]?[0-9a-fA-F]+]*)|([[+-]?[0-9a-fA-F]+]+))([pP][+-]?[0-9]+)$")
		result = regex.search( word )
		if result: return true
		#special_float_constant = [-+]?(nan|inf|infinity)
		regex.compile("^[-+]?(nan|inf|infinity)$")
		result = regex.search( word )
		if result: return true
		return false


	func next_token() -> Dictionary:
		token = { 'line':line_n, 'col': cursor_lp, 'type':TokenType.UNKNOWN, 't':peek_char() }
		if at_end(): token.type = TokenType.EOF
		while not at_end():
			token['line'] = line_n
			token['col'] =  cursor_lp
			token['t'] = peek_char()
			if peek_char() == '\n': token['type'] = TokenType.EOL
			if peek_char() in whitespace: adv(); continue
			if peek_char() == '/' and peek_char(1) == '/':
				token = get_comment();
				break
			if peek_char() in punc:
				token['type'] = TokenType.PUNCT
				token['t'] = get_char()
				break
			if peek_char() == '"':
				token = get_string(); break
			token = get_word(); break
		new_token.emit( token )
		return token

	func get_token() -> Dictionary:
		skip_whitespace()
		while true:
			if token.type == TokenType.COMMENT: next_token(); continue
			break
		return token

	func skip_whitespace():
		while not at_end():
			if peek_char() in [' ','\t']: adv(); continue
			break;

	func peek_token() -> Dictionary:
		skip_whitespace()
		var p_token = { 'line':line_n, 'col': cursor_lp, 'type':TokenType.UNKNOWN, 't':peek_char() }
		if at_end(): p_token.type = TokenType.EOF
		if peek_char() == '\n': p_token.type = TokenType.EOL
		return p_token


	func get_integer_constant() -> Dictionary:
		# Verify Starting position.
		var p_token = peek_token()
		if p_token.type != TokenType.UNKNOWN:
			return p_token

		#DIGIT, # [:digit:] = [0-9]
		#XDIGIT, # [:xdigit:] = [0-9a-fA-F]
		#DEC_INTEGER_CONSTANT, # = [-+]?[:digit:]+
		#HEX_INTEGER_CONSTANT, # = [-+]?0[xX][:xdigit:]+
		#INTEGER_CONSTANT, # = dec_integer_constant | hex_integer_constant
		var first_char : String = "-+0123456789abcdefABCDEF"
		var valid_chars = "xX0123456789abcdefABCDEF"
		if peek_char() not in first_char: return p_token
		token = p_token
		token.type = TokenType.SCALAR
		# seek to the end and return our valid integer constant
		var start : int = cursor_p
		while not at_end():
			adv()
			if peek_char() in valid_chars: continue
			break

		token.t = text.substr( start, cursor_p - start )
		new_token.emit( token )
		return token
#endregion

#region Parser
# ██████   █████  ██████  ███████ ███████ ██████
# ██   ██ ██   ██ ██   ██ ██      ██      ██   ██
# ██████  ███████ ██████  ███████ █████   ██████
# ██      ██   ██ ██   ██      ██ ██      ██   ██
# ██      ██   ██ ██   ██ ███████ ███████ ██   ██

var parse_funcs : Dictionary = {
	FrameType.NONE : syntax_error,
	FrameType.SCHEMA : parse_schema,
	FrameType.INCLUDE : parse_include,
	FrameType.NAMESPACE_DECL : parse_namespace_decl,
	FrameType.ATTRIBUTE_DECL : parse_attribute_decl,
	FrameType.TYPE_DECL : parse_type_decl,
	FrameType.ENUM_DECL : parse_enum_decl,
	FrameType.ROOT_DECL : parse_root_decl,
	FrameType.FIELD_DECL : parse_field_decl,
	FrameType.RPC_DECL : parse_rpc_decl,
	FrameType.RPC_METHOD : parse_rpc_method,
	FrameType.TYPE : parse_type,
	FrameType.ENUMVAL_DECL : parse_enumval_decl,
	FrameType.METADATA : parse_metadata,
	FrameType.SCALAR : parse_scalar,
	FrameType.OBJECT : parse_object,
	FrameType.SINGLE_VALUE : parse_single_value,
	FrameType.VALUE : parse_value,
	FrameType.COMMASEP : parse_commasep,
	FrameType.FILE_EXTENSION_DECL : parse_file_extension_decl,
	FrameType.FILE_IDENTIFIER_DECL : parse_file_identifier_decl,
	FrameType.STRING_CONSTANT : parse_string_constant,
	FrameType.IDENT : parse_ident,
	#FrameType.DIGIT : parse_digit,
	#FrameType.XDIGIT : parse_xdigit,
	#FrameType.DEC_INTEGER_CONSTANT : parse_dec_integer_constant,
	#FrameType.HEX_INTEGER_CONSTANT : parse_hex_integer_constant,
	FrameType.INTEGER_CONSTANT : parse_integer_constant,
	#FrameType.DEC_FLOAT_CONSTANT : parse_dec_float_constant,
	#FrameType.HEX_FLOAT_CONSTANT : parse_hex_float_constant,
	#FrameType.SPECIAL_FLOAT_CONSTANT : parse_special_float_constant,
	#FrameType.FLOAT_CONSTANT : parse_float_constant,
	#FrameType.BOOLEAN_CONSTANT : parse_boolean_constant,
}

var kw_frame_map : Dictionary = {
	'include' : FrameType.INCLUDE,
	'namespace' : FrameType.NAMESPACE_DECL,
	'table' : FrameType.TYPE_DECL,
	'struct' : FrameType.TYPE_DECL,
	'enum' : FrameType.ENUM_DECL,
	'union' : FrameType.ENUM_DECL,
	'root_type' : FrameType.ROOT_DECL,
	'file_extension' : FrameType.FILE_EXTENSION_DECL,
	'file_identifier' : FrameType.FILE_IDENTIFIER_DECL,
	'attribute' : FrameType.ATTRIBUTE_DECL,
	'rpc_service' : FrameType.RPC_DECL,
}

class StackFrame:
	func _init( t : FrameType, d : Dictionary = {}) -> void: type = t; data = d.duplicate(true)
	var type : FrameType
	var data : Dictionary

var prev_stack : Array = []
var stack : Array = []

func copy_stack( _stack ) -> Array:
	var new_stack : Array
	new_stack.resize(_stack.size())
	for i in _stack.size():
		var frame : StackFrame = _stack[i]
		new_stack[i] = StackFrame.new( frame.type, frame.data )
	return new_stack

func push_stack( type : FrameType, args = null ):
	stack.append( StackFrame.new( type, {'args': args } if args else {} ) )

func start_frame( token : Dictionary ) -> StackFrame:
	var frame : StackFrame = stack.back()
	if verbose > 1:
		var padding = "".lpad(stack.size()-1, '\t')
		var head = "⮱Start" if frame.data.is_empty() else " Con.."
		var frame_name = FrameType.keys()[frame.type] if stack.size() else "empty"
		print( padding + head + " %s | {Token:%s} | Data:%s" % [frame_name, stoken( token ), frame.data] )
	return frame

func end_frame( retval = null ) -> bool:
	var type_name : String = FrameType.keys()[stack.back().type] if stack.size() else "empty"
	if verbose > 1:
		var padding = "".lpad(stack.size()-1, '\t')
		var result = "" if retval else "ret:%s" % retval
		print( padding + "⮶End %s | %s" % [type_name, result] )
	stack.pop_back()
	if stack.size() && retval: stack.back().data['return'] = retval
	return true

func save_stack( line_num : int, cursor_pos : int = 0 ):
	if stack.size() == prev_stack.size(): return # FIXME
	if verbose > 2: print( "Stack saved to line %s | " % [line_num+1], sstack( stack ) )

	#var this_dict = dict.get( line_num, {} )
	#this_dict['stack'] = copy_stack( stack )
	#dict[line_num] = this_dict
	#if verbose > 1: print_rich( "[b]Line %s |Saved: %s[/b]" % [line_num+1, sstack( dict.get(line_num, {'stack':[]})['stack'] )] )


	if stack_index.size() < line_num: stack_index.append_array( new_index_chunk )
	stack_list[line_num] = copy_stack( stack )
	stack_index[line_num] = true


func stoken( token : Dictionary ) -> String:
	var t : String = token.t
	var type : String = TokenType.keys()[token.type]
	var coord := Vector2i(token.line+1, token.col+1) # +1 is because the editor counts from 1
	return "%s | %s | '%s'" % [coord, type, t.c_escape() ]

func sstack( _stack : Array = stack ):
	var stack_string : String = "#"
	for frame in _stack:
		var data = "" if frame.data.is_empty() else frame.data
		stack_string += "/%s%s" % [ FrameType.keys()[frame.type], data ]
	return stack_string

func check_token_t( token : Dictionary, t : String, msg : String = "" ) -> bool:
	if token.get('t') == t:
		reader.next_token()
		return true
	if not msg.is_empty(): syntax_error( token, "wanted '%s'" % t )
	return false

var loop_detection : int = 0
func parse():
	if not stack.size(): push_stack(FrameType.SCHEMA)
	loop_detection = 0
	reader.next_token()
	while stack.size() > 0 or not reader.at_end():
		loop_detection += 1
		if loop_detection > 10: break
		var frame = stack.back()
		var token = reader.get_token()
		if token.type == TokenType.EOF: if verbose > 1: print("EOF"); break
		start_frame( token )
		parse_funcs[ frame.type ].call( token )



	save_stack(reader.line_n, 0 )

# ███████  ██████ ██   ██ ███████ ███    ███  █████
# ██      ██      ██   ██ ██      ████  ████ ██   ██
# ███████ ██      ███████ █████   ██ ████ ██ ███████
#      ██ ██      ██   ██ ██      ██  ██  ██ ██   ██
# ███████  ██████ ██   ██ ███████ ██      ██ ██   ██

func parse_schema( token : Dictionary ):
	#schema # = include* ( namespace_decl | type_decl | enum_decl | root_decl
	#					 | file_extension_decl | file_identifier_decl
	#					 | attribute_decl | rpc_decl | object )*
	var frame : StackFrame = stack.back()

	if token.type == TokenType.EOF: return# end_frame()

	if token.type != TokenType.KEYWORD:
		syntax_error( token, "Wanted TokenType.KEYWORD" )
		reader.next_line()
		return

	if token.t == 'include':
		if frame.data.has('no_includes'):
			syntax_error( token, "Trying to use include mid file" )
			reader.next_line()
			return
		push_stack( FrameType.INCLUDE )
		return

	frame.data['no_includes'] = true
	push_stack(kw_frame_map.get( token.t ))

# ██ ███    ██  ██████ ██      ██    ██ ██████  ███████
# ██ ████   ██ ██      ██      ██    ██ ██   ██ ██
# ██ ██ ██  ██ ██      ██      ██    ██ ██   ██ █████
# ██ ██  ██ ██ ██      ██      ██    ██ ██   ██ ██
# ██ ██   ████  ██████ ███████  ██████  ██████  ███████

func parse_include( token : Dictionary ):
	# INCLUDE = include string_constant ;
	var frame = stack.back()

	if frame.data.get('next') == null:
		if token.get('t') != 'include':
			syntax_error( token, "wanted include" )
			return end_frame()
		push_stack( FrameType.STRING_CONSTANT )
		frame.data['next'] = 'parse'
		reader.next_token();
		return
	if frame.data.get('next') == 'parse':
		var string_constant = frame.data.get('return')
		frame.data.erase('return')
		if not string_constant:
			return end_frame()
		var filestring : String= string_constant.t
		if not quick_scan_file( filestring.substr(1, filestring.length() -2 ) ):
			syntax_error( string_constant, "Unable to scan filename")
		frame.data['next'] = ';'
		return
	if frame.data.get('next') == ';':
		check_token_t(token, ';', "wanted semicolon" )
		return end_frame()

	# what else?
	syntax_error( token, "we shouldnt be here." )
	return end_frame()

# ███    ██  █████  ███    ███ ███████ ███████ ██████   █████   ██████ ███████
# ████   ██ ██   ██ ████  ████ ██      ██      ██   ██ ██   ██ ██      ██
# ██ ██  ██ ███████ ██ ████ ██ █████   ███████ ██████  ███████ ██      █████
# ██  ██ ██ ██   ██ ██  ██  ██ ██           ██ ██      ██   ██ ██      ██
# ██   ████ ██   ██ ██      ██ ███████ ███████ ██      ██   ██  ██████ ███████

func parse_namespace_decl( token : Dictionary ):
	#NAMESPACE_DECL = namespace ident ( . ident )* ;
	var frame = stack.back()

	if frame.data.get('next') == null:
		if token.t != 'namespace':
			syntax_error(token, "wanted 'namespace'")
			return end_frame()
		reader.next_token()
		frame.data['next'] = 'ident'
		return
	if frame.data.get('next') == 'ident':
		reader.next_token() # FIXME the reader only gets the whole thing right now.
		frame.data['next'] = ';'
		return
	if frame.data.get('next') == ';':
		if check_token_t(token, ';'): return end_frame()
		#if check_token_t(token, '.'): return push_stack( FrameType.IDENT )

	syntax_error(token, "reached end of parse_namespace_decl(...)")
	return end_frame()

#  █████  ████████ ████████ ██████  ██ ██████  ██    ██ ████████ ███████
# ██   ██    ██       ██    ██   ██ ██ ██   ██ ██    ██    ██    ██
# ███████    ██       ██    ██████  ██ ██████  ██    ██    ██    █████
# ██   ██    ██       ██    ██   ██ ██ ██   ██ ██    ██    ██    ██
# ██   ██    ██       ██    ██   ██ ██ ██████   ██████     ██    ███████

func parse_attribute_decl( token : Dictionary ):
	# ATTRIBUTE_DECL = attribute ident | "</tt>ident<tt>" ;
	var frame = stack.back()

	if frame.data.get('next') == null:
		if token.t != 'attribute':
			syntax_error(token, "wanted 'attribute'")
			return end_frame()
		reader.next_token()
		token = reader.get_token()
		if token.type == TokenType.IDENT: push_stack( FrameType.IDENT )
		elif token.type == TokenType.STRING: push_stack( FrameType.STRING_CONSTANT )
		frame.data['next'] = ';'
		return
	if frame.data.get('next') == ';':
		check_token_t(token, ';', "wanted semicolon")
		return end_frame()

	syntax_error(token, "reached end of parse_attribute_decl( ... )")
	return end_frame()

# ████████ ██    ██ ██████  ███████         ██████  ███████  ██████ ██
#    ██     ██  ██  ██   ██ ██              ██   ██ ██      ██      ██
#    ██      ████   ██████  █████           ██   ██ █████   ██      ██
#    ██       ██    ██      ██              ██   ██ ██      ██      ██
#    ██       ██    ██      ███████ ███████ ██████  ███████  ██████ ███████

func parse_type_decl( token : Dictionary ):
	#type_decl = ( table | struct ) ident [metadata] { field_decl+ }\
	var frame : StackFrame = stack.back()

	if frame.data.get('next') == null:
		if token.t not in ['table','struct']:
			syntax_error(token, "wanted ( table | struct )")
			return end_frame()
		reader.next_token()
		push_stack( FrameType.IDENT )
		frame.data['next'] = 'add_ident'
		return
	if frame.data.get('next') == 'add_ident':
		var type_name = frame.data.get('return')
		if type_name:
			user_types[(frame.data.get('return'))] = OK
			frame.data.erase('return')
		frame.data['next'] = 'meta'
		return
	if frame.data.get('next') == 'meta':
		push_stack( FrameType.METADATA )
		frame.data['next'] = '{'
		return
	if frame.data.get('next') == '{':
		if check_token_t(token, '{', "wanted '{'"):
			frame.data['next'] = 'fields'
			return
		return end_frame()
	if frame.data.get('next') == 'fields':
		if token.type == TokenType.EOF: return
		if check_token_t(token, '}'): return end_frame()
		return push_stack( FrameType.FIELD_DECL )

	syntax_error(token, "reached end of parse_type_decl(...)")
	return end_frame()

# ███████ ███    ██ ██    ██ ███    ███         ██████  ███████  ██████ ██
# ██      ████   ██ ██    ██ ████  ████         ██   ██ ██      ██      ██
# █████   ██ ██  ██ ██    ██ ██ ████ ██         ██   ██ █████   ██      ██
# ██      ██  ██ ██ ██    ██ ██  ██  ██         ██   ██ ██      ██      ██
# ███████ ██   ████  ██████  ██      ██ ███████ ██████  ███████  ██████ ███████

func parse_enum_decl( token : Dictionary ):
	#enum_decl = ( enum ident : type | union ident ) metadata { commasep( enumval_decl ) }
	var frame : StackFrame = stack.back()

	if frame.data.get('next') == null:
		if token.t not in ['enum','union']:
			syntax_error(token, "wanted ( enum | union )")
			return end_frame()
		frame.data['keyword'] = token.t
		reader.next_token()
		frame.data['next'] = 'ident'
		return
	if frame.data.get('next') == 'ident':
		if not regex_ident.search(token.t):
			syntax_error(token, "wanted ident")
			return end_frame()
		reader.next_token()
		user_types[ token.t ] = OK
		if frame.data['keyword'] == 'enum': frame.data['next'] = 'enum'
		else: frame.data['next'] = 'meta'
		return
	if frame.data.get('next') == 'enum':
		if check_token_t(token, ':', "wanted ':'"):
			frame.data['next'] = 'meta'
			return push_stack( FrameType.TYPE )
		return end_frame()
	if frame.data.get('next') == 'meta':
		frame.data.erase('return') # erase return 'type'
		push_stack( FrameType.METADATA )
		frame.data['next'] = '{'
		return
	if frame.data.get('next') == '{':
		if check_token_t(token, '{', "wanted '{'" ):
			frame.data['next'] = '}'
			push_stack( FrameType.ENUMVAL_DECL )
			return
		return end_frame()
	if frame.data.get('next') == '}':
		if frame.data['keyword'] == 'enum':
			var ident = frame.data.get('return')
			if ident:
				user_enum_vals[ident.t] = OK
		if frame.data['keyword'] == 'union':
			var ident = frame.data.get('return')
			if ident:
				ident.type = TokenType.TYPE
				highlight(token)
		if check_token_t(token, '}'): return end_frame()
		if check_token_t(token, ','):
			push_stack( FrameType.ENUMVAL_DECL )
			return

	syntax_error(token, "reached end of parse_enum_val( ... )" )
	return end_frame()


# ██████   ██████   ██████  ████████      ██████  ███████  ██████ ██
# ██   ██ ██    ██ ██    ██    ██         ██   ██ ██      ██      ██
# ██████  ██    ██ ██    ██    ██         ██   ██ █████   ██      ██
# ██   ██ ██    ██ ██    ██    ██         ██   ██ ██      ██      ██
# ██   ██  ██████   ██████     ██ ███████ ██████  ███████  ██████ ███████

func parse_root_decl( token : Dictionary ):
	# ROOT_DECL = root_type ident ;
	var frame = stack.back()

	if frame.data.get('next') == null:

		if token.get('t') != 'root_type':
			syntax_error( token, "wanted root_type" )
			return end_frame()
		push_stack( FrameType.TYPE )
		frame.data['next'] = ';'
		reader.next_token();
		return
	if frame.data.get('next') == ';':
		check_token_t(token, ';', "wanted semicolon" )
		return end_frame()

	# what else?
	syntax_error( token, "we shouldnt be here." )
	return end_frame()

# ███████ ██ ███████ ██      ██████          ██████  ███████  ██████ ██
# ██      ██ ██      ██      ██   ██         ██   ██ ██      ██      ██
# █████   ██ █████   ██      ██   ██         ██   ██ █████   ██      ██
# ██      ██ ██      ██      ██   ██         ██   ██ ██      ██      ██
# ██      ██ ███████ ███████ ██████  ███████ ██████  ███████  ██████ ███████

func parse_field_decl( token : Dictionary ):
	# field_decl = ident : type [ = scalar ] metadata;
	var frame : StackFrame = stack.back()

	if frame.data.get('next') == null:
		push_stack(FrameType.IDENT)
		frame.data['next'] = ':'
		return
	if frame.data.get('next') == ':':
		if token.t != ':':
			syntax_error(token, "wanted ':'")
			reader.next_line()
			return end_frame()
		reader.next_token()
		push_stack( FrameType.TYPE )
		frame.data['next'] = '='
		return
	if frame.data.get('next') == '=':
		if check_token_t(token, '='):
			return push_stack( FrameType.SCALAR )
		push_stack( FrameType.METADATA )
		frame.data['next'] = ';'
		return
	if frame.data.get('next') == ';':
		check_token_t(token, ';', "wanted semicolon")
		return end_frame()

	syntax_error(token, "reached end of parse_type_decl(...)")
	return end_frame()


func parse_rpc_decl( token : Dictionary ):
	var this_frame = stack.back()
	syntax_warning( token, "Unimplemented")
	reader.next_line()
	return end_frame()

func parse_rpc_method( token : Dictionary ):
	var this_frame = stack.back()
	syntax_warning( token, "Unimplemented")
	reader.next_line()
	return end_frame()

func parse_type( token : Dictionary ):
	var this_frame = stack.back()
	# TYPE = bool | byte | ubyte | short | ushort | int | uint | float |
	# long | ulong | double | int8 | uint8 | int16 | uint16 | int32 |
	# uint32| int64 | uint64 | float32 | float64 | string
	# | [ type ]
	# | ident

	# NOTE TYPE can also be [type:integer] to denote a fixed type array
	# however in this case the type must be a scalar or struct
	var types: Array = [ "bool", "byte", "ubyte", "short", "ushort", "int",
	"uint", "float", "long", "ulong", "double", "int8", "uint8", "int16",
	"uint16", "int32", "uint32", "int64", "uint64", "float32", "float64",
	"string" ]

	var is_type : bool = true
	var is_array : bool = false
	var is_fixed : bool = false

	var start = token
	var type
	var fixed_size
	var end
	if start.t == '[':
		is_array = true
		type = reader.next_token()
	else: type = start

	# Check type as it stands currently, it can be any type.
	while true:
		if type.t in types: break
		if type.t in user_types: break
		is_type = false;
		break

	if is_array:
		end = reader.next_token()
		if end.t == ':':
			is_fixed = true
			# Look for the size
			fixed_size = reader.get_integer_constant()
			if fixed_size.type != TokenType.SCALAR:
				syntax_error(fixed_size, "did not find integer constant")
			# we have a fixed array, and much check the type against scalar and struct.
			if type.t in struct_types || type.t in scalar_types: pass
			else: syntax_error(type,"cannot have a fixed sized array with anything but scalar | struct")
			end = reader.next_token()

		if end.t != ']':
			syntax_error(start, "missing matching brace ']'")
			syntax_error(end, "missing matching brace '['")

	if is_type:
		type.type = TokenType.TYPE
		highlight( type )
		reader.next_token()
		return end_frame(type.t)

	syntax_error( type, "Unknown Type" )
	return end_frame()

# ███████ ███    ██ ██    ██ ███    ███ ██    ██  █████  ██
# ██      ████   ██ ██    ██ ████  ████ ██    ██ ██   ██ ██
# █████   ██ ██  ██ ██    ██ ██ ████ ██ ██    ██ ███████ ██
# ██      ██  ██ ██ ██    ██ ██  ██  ██  ██  ██  ██   ██ ██
# ███████ ██   ████  ██████  ██      ██   ████   ██   ██ ███████

func parse_enumval_decl( token : Dictionary ):
	# ENUMVAL_DECL = ident [ = integer_constant ]
	if token.type == TokenType.EOF: return
	var frame = stack.back()

	if frame.data.get('next') == null:
		if token.t == '}': return end_frame() # trailing comma
		if not regex_ident.search(token.t):
			syntax_error(token, "wanted ident") #
			return end_frame()
		reader.next_token()
		frame.data['ident'] = token
		frame.data['next'] = '='
		return
	if frame.data.get('next') == '=':
		end_frame(frame.data['ident'])
		if check_token_t(token, '='):
			return push_stack( FrameType.INTEGER_CONSTANT )
		return

	syntax_error(token, "reached end of parse_enumval_decl(...)")
	return end_frame()

# ███    ███ ███████ ████████  █████  ██████   █████  ████████  █████
# ████  ████ ██         ██    ██   ██ ██   ██ ██   ██    ██    ██   ██
# ██ ████ ██ █████      ██    ███████ ██   ██ ███████    ██    ███████
# ██  ██  ██ ██         ██    ██   ██ ██   ██ ██   ██    ██    ██   ██
# ██      ██ ███████    ██    ██   ██ ██████  ██   ██    ██    ██   ██

func parse_metadata( token : Dictionary ):
	#metadata = [ ( commasep( ident [ : single_value ] ) ) ]
	var frame : StackFrame = stack.back()

	if frame.data.get('next') == null:
		if check_token_t( token, '(' ):
			frame.data['next'] = 'ok'
			return
		return end_frame()
	if frame.data.get('next') == 'ok':
		if check_token_t(token, ')'): return end_frame()
		return push_stack( FrameType.COMMASEP, FrameType.IDENT )
		# FIXME this doesnt handle the '[ : single_value ]' part

	syntax_error(token, "reached end of parse_metadata(...)")
	return end_frame()


func parse_scalar( token : Dictionary ):
	# SCALAR = boolean_constant | integer_constant | float_constant
	var this_frame = stack.back()
	if token.type == TokenType.SCALAR:
		reader.next_token()
		return end_frame()
	if token.t in user_enum_vals:
		token.type = TokenType.SCALAR
		highlight( token )
		reader.next_token()
		return end_frame()
	syntax_error( token, "Wanted TokenType.SCALAR" )
	reader.next_line()
	end_frame()
	return false

func parse_object( token : Dictionary ):
	var this_frame = stack.back()
	syntax_warning( token, "unimplemented" )
	reader.next_line()
	return end_frame()

func parse_single_value( token : Dictionary ):
	var this_frame = stack.back()
	syntax_warning( token, "unimplemented" )
	reader.next_line()
	end_frame()
	return false

func parse_value( token : Dictionary ):
	var this_frame = stack.back()
	syntax_warning( token, "unimplemented" )
	reader.next_line()
	return end_frame()

#  ██████  ██████  ███    ███ ███    ███  █████  ███████ ███████ ██████
# ██      ██    ██ ████  ████ ████  ████ ██   ██ ██      ██      ██   ██
# ██      ██    ██ ██ ████ ██ ██ ████ ██ ███████ ███████ █████   ██████
# ██      ██    ██ ██  ██  ██ ██  ██  ██ ██   ██      ██ ██      ██
#  ██████  ██████  ██      ██ ██      ██ ██   ██ ███████ ███████ ██

func parse_commasep( token : Dictionary ):
	# COMMASEP(x) = [ x ( , x )* ]
	var frame = stack.back()
	var arg_type = frame.data.get('args')
	if arg_type == null:
		syntax_error(token, "commasep needs an argument")
		return end_frame()

	if token.type == TokenType.EOF: return
	if not (token.type == TokenType.IDENT || token.t == ','):
		return end_frame()

	if frame.data.get('next') == null:
		push_stack( arg_type )
		frame.data['next'] = ','
		return
	if frame.data.get('next') == ',':
		frame.data.erase('return')
		if token.t != ',': return end_frame()
		reader.next_token()
		frame.data['next'] = null
		return

	syntax_error(token, "Reached the end of parse_commasep(...)")
	return end_frame()

func parse_file_extension_decl( token : Dictionary ):
	var this_frame = stack.back()
	syntax_warning( token, "Unimplemented")
	reader.next_line()
	return end_frame()

func parse_file_identifier_decl( token : Dictionary ):
	var this_frame = stack.back()
	syntax_warning( token, "Unimplemented")
	reader.next_line()
	return end_frame()

func parse_string_constant( token : Dictionary ):
	var frame = stack.back()
	if token.get('type') == TokenType.STRING:
		reader.next_token()
		return end_frame( token )
	syntax_error(token, "wanted filename as string")
	end_frame()

func parse_ident( token : Dictionary ):
	#ident = [a-zA-Z_][a-zA-Z0-9_]*
	#FIXME use regex?
	var ident_start : String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"
	var ident_end : String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"

	var word : String = token.get('t', ' ')
	var is_ident : bool = true
	while is_ident:
		# verify first character
		if not ident_start.contains(word[0]) : is_ident = false; break
		# verify the remaining
		for i in range( 1, word.length() ):
			if not ident_end.contains(word[i]): is_ident = false; break
		break

	if is_ident:
		token.type == TokenType.IDENT
		reader.next_token()
		return end_frame( token )

	syntax_error( token, "ident = [a-zA-Z_][a-zA-Z0-9_]*" )
	end_frame()


func parse_integer_constant( token : Dictionary ):
	# INTEGER_CONSTANT = dec_integer_constant | hex_integer_constant
	var frame : StackFrame = stack.back()

	var ok : bool = true
	while true:
		if regex_dec_integer_constant.search( token.t ): break
		if regex_hex_integer_constant.search( token.t ): break
		ok = false; break
	if ok:
		reader.next_token()
		return end_frame()
	syntax_error( token, "Wanted ( dec_integer_constant | hex_integer_constant )" )
	return end_frame()

#endregion Parser


#  ██████  ██    ██ ██  ██████ ██   ██         ███████  ██████  █████  ███    ██
# ██    ██ ██    ██ ██ ██      ██  ██          ██      ██      ██   ██ ████   ██
# ██    ██ ██    ██ ██ ██      █████           ███████ ██      ███████ ██ ██  ██
# ██ ▄▄ ██ ██    ██ ██ ██      ██  ██               ██ ██      ██   ██ ██  ██ ██
#  ██████   ██████  ██  ██████ ██   ██ ███████ ███████  ██████ ██   ██ ██   ████

var included_files : Array = []

func quick_scan_file( filename : String ) -> bool:
	if filename.begins_with("res://"):
		if verbose > 0: printerr("paths starting with res:// or user:// are not yet supported: ", filename)
		return false

	if filename == "godot.fbs":
		filename = 'res://addons/gdflatbuffers/godot.fbs'
	else:
		filename = file_location + filename

	if not FileAccess.file_exists( filename ):
		if verbose > 0: printerr("Enable to locate file for inclusion: ", filename)
		return false

	if filename in included_files: return true # Dont create a loop
	included_files.append( filename )
	if verbose > 1: print( "Including file: ", filename )
	if verbose > 1: print( "Included files: ", included_files )
	var file = FileAccess.open( filename, FileAccess.READ )
	var content = file.get_as_text()
	quick_scan_text( content )
	return true

func quick_scan_text( text : String ):
	if verbose > 1: print_rich( "[b]quick_scan_text( ... )[/b]")
	# I need a function which scans the source fast to pick up names before the main scan happens.
	qreader.reset( text )

	while not qreader.at_end():
		var token = qreader.get_token()

		if token.type != TokenType.KEYWORD:
			qreader.next_line()
			continue

		if token.t == 'include':
			var filename : String = qreader.next_token().t
			if regex_string_constant.search(filename):
				quick_scan_file( filename.substr( 1, filename.length() - 2 ) )
			qreader.next_line()
			continue

		if token.t in ['struct', 'table', 'enum', 'union']:
			var ident = qreader.next_token()
			if regex_ident.search(ident.t):
				user_types[ident.t] = OK

			if token.t == 'enum':
				pass # TODO get the enum names
		qreader.next_line()

	if verbose > 1: print( "user_types: ", user_types.keys())
	if verbose > 1: print( "user_enum_vals: ", user_enum_vals.keys())
