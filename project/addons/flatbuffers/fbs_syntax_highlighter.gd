@tool
class_name FlatBuffersHighlighter extends EditorSyntaxHighlighter

var print_debug : bool = false

# schema grammer : https://flatbuffers.dev/flatbuffers_grammar.html
#schema = include* ( namespace_decl
#					| type_decl
#					| enum_decl
#					| root_decl
#					| file_extension_decl
#					| file_identifier_decl
#					| attribute_decl
#					| rpc_decl
#					| object )*
#include = include string_constant ;
#namespace_decl = namespace ident ( . ident )* ;
#attribute_decl = attribute ident | "</tt>ident<tt>" ;
#type_decl = ( table | struct ) ident metadata { field_decl+ }
#enum_decl = ( enum ident : type | union ident ) metadata { commasep( enumval_decl ) }
#root_decl = root_type ident ;
#field_decl = ident : type [ = scalar ] metadata ;
#rpc_decl = rpc_service ident { rpc_method+ }
#rpc_method = ident ( ident ) : ident metadata ;
#type = bool | byte | ubyte | short | ushort | int | uint | float | long | ulong | double | int8 | uint8 | int16 | uint16 | int32 | uint32| int64 | uint64 | float32 | float64 | string | [ type ] | ident
#enumval_decl = ident [ = integer_constant ]
#metadata = [ ( commasep( ident [ : single_value ] ) ) ]
#scalar = boolean_constant | integer_constant | float_constant
#object = { commasep( ident : value ) }
#single_value = scalar | string_constant
#value = single_value | object | [ commasep( value ) ]
#commasep(x) = [ x ( , x )* ]
#file_extension_decl = file_extension string_constant ;
#file_identifier_decl = file_identifier string_constant ;
#string_constant = \".*?\\"
#ident = [a-zA-Z_][a-zA-Z0-9_]*
#[:digit:] = [0-9]
#[:xdigit:] = [0-9a-fA-F]
#dec_integer_constant = [-+]?[:digit:]+
#hex_integer_constant = [-+]?0[xX][:xdigit:]+
#integer_constant = dec_integer_constant | hex_integer_constant
#dec_float_constant = [-+]?(([.][:digit:]+)|([:digit:]+[.][:digit:]*)|([:digit:]+))([eE][-+]?[:digit:]+)?
#hex_float_constant = [-+]?0[xX](([.][:xdigit:]+)|([:xdigit:]+[.][:xdigit:]*)|([:xdigit:]+))([pP][-+]?[:digit:]+)
#special_float_constant = [-+]?(nan|inf|infinity)
#float_constant = dec_float_constant | hex_float_constant | special_float_constant
#boolean_constant = true | false

enum TokenType {
	UNKNOWN,
	COMMENT,
	KEYWORD,
	TYPE,
	STRING,
	PUNCT,
	IDENT,
	SCALAR,
	META,
	EOF
}

var fbs_text : String
var line_index : Array[int] = [0]
var cursor_p : int = 0
var cursor_lp : int = 0
var line_n : int = 0

func reset():
	user_types.clear()
	user_enum_values.clear()
	line_index = [0]
	cursor_p = 0
	cursor_lp = 0
	line_n = 1

func peek_char( offset : int = 0) -> String:
	return fbs_text[cursor_p + offset] if cursor_p + offset < fbs_text.length() else '\n'

func get_char() -> String:
	adv()
	return fbs_text[cursor_p - 1]

func adv( dist : int = 1):
	for i in dist:
		cursor_p += 1
		cursor_lp += 1
		if fbs_text[cursor_p -1] != '\n': continue
		line_index.append(cursor_p)
		cursor_lp = 0
		line_n = line_index.size()

func next_line():
	while peek_char() != '\n':
		adv()
	adv()

func get_token() -> Dictionary:
	var token = {}
	token['type'] = TokenType.EOF
	while cursor_p < fbs_text.length() -1:
		token['line'] = line_n
		token['col'] = cursor_lp
		token['t'] = peek_char()
		if peek_char() in whitespace: adv(); continue
		if peek_char() == '/' and peek_char(1) == '/': token = get_comment(); continue
		if peek_char() in punc:
			token['type'] = TokenType.PUNCT
			token['t'] = get_char()
			break
		if peek_char() == '"': token = get_string(); break
		token = get_word(); break
	if print_debug: print( "%s:%s | %s | '%s'" % [token.line, token.col, TokenType.keys()[token.type], token.t] )

	return token

func get_string() -> Dictionary:
	var start := cursor_p
	var token : Dictionary = {
		'line':line_n,
		'col': cursor_lp,
		'type':TokenType.STRING
	}
	adv()
	while true:
		if peek_char() == '"' and peek_char(-1) !='\\':
			adv()
			break
		if peek_char() == '\n':
			syntax_error(token, "reached end of line before \"" )
			break
		adv()
	token.t = fbs_text.substr( start, cursor_p - start )
	append( token, string_color )
	return token

func get_comment() -> Dictionary:
	var token : Dictionary = {
		'line':line_n,
		'col': cursor_lp,
		'type':TokenType.COMMENT,
	}
	var start := cursor_p
	while peek_char() != '\n': adv()
	token.t = fbs_text.substr( start, cursor_p - start )
	append( token, comment_color )
	return token

func get_word() -> Dictionary:
	var token : Dictionary = {
		'line':line_n,
		'col': cursor_lp,
		'type':TokenType.UNKNOWN,
	}
	var start := cursor_p
	while not peek_char() in word_separation:
		adv()
	# return the substring
	token.t = fbs_text.substr( start, cursor_p - start )
	if is_type( token.t ):
		token.type = TokenType.TYPE
		append( token, base_type_color )
	elif is_keyword(token.t):
		token.type = TokenType.KEYWORD
		append( token, keyword_color )
	elif is_scalar( token.t ):
		token.type = TokenType.SCALAR
		append( token, number_color )
	elif is_ident(token.t):
		token.type = TokenType.IDENT
		append( token, text_color )
	return token

func is_type( word : String )-> bool:
	#type = bool | byte | ubyte | short | ushort | int | uint | float | long | ulong | double | int8 | uint8 | int16 | uint16 | int32 | uint32| int64 | uint64 | float32 | float64 | string
	# | [ type ] | ident
	if word in types: return true
	if word in user_types: return true
	if variant_included and word in variant_types: return true
	return false

func is_keyword( word : String ) -> bool:
	if word in keywords: return true
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


func syntax_error( token : Dictionary, reason = "" ):
	append( token, Color.RED )
	if print_debug: print( token )
	printerr( "Syntax error at line: %s, column: %s is '%s'%s" %
		[token.line, token.col, token.t, "" if reason.is_empty() else " | %s" % reason] )

var word_separation : Array = [' ', '\t', '\n', '{','}', ':', ';', ',', '(', ')', '[', ']']
var whitespace : Array = [' ', '\t', '\n']
var punc : Array = [',', '.', ':', ';', '[', ']', '{', '}', '(', ')', '=']
var types : Array = [
	"bool",
	"byte",
	"ubyte",
	"short" ,
	"ushort",
	"int",
	"uint",
	"float",
	"long",
	"ulong",
	"double",
	"int8",
	"uint8",
	"int16",
	"uint16",
	"int32",
	"uint32",
	"int64",
	"uint64",
	"float32",
	"float64",
	"string"
	]

var variant_included : bool = false
var variant_types : Array = [
	"Vector3",
	"Color"
]

var keywords : Array = [
	'include',
	'namespace',
	'table',
	'struct',
	'enum',
	'union',
	'root_type',
	'file_extension',
	'file_identifier',
	'attribute',
	'rpc_service',
	]

var user_types : Array = []
var user_enum_values : Array = []

var editor_settings : EditorSettings
var symbol_color : Color= Color.GREEN
var number_color : Color= Color.GREEN
var base_type_color : Color= Color.GREEN
var text_color : Color= Color.GREEN
var string_color : Color= Color.GREEN
var function_color : Color= Color.GREEN
var keyword_color : Color= Color.GREEN
var comment_color : Color = Color.GREEN

var text_edit : TextEdit
var dict : Dictionary

func append( token : Dictionary, color: Color ):
	var line = token.line - 1
	if not dict.has(line):
		dict[line] = {}
	dict[line][token.col] = {'color':color}
	#print( "add: %s" % {line:{lp:{'color':color}}})

func color_default():
	var line = line_n - 1
	if not dict.has(line): dict[line] = {}
	dict[line][cursor_lp] = { 'color':text_color }
	#print( "add: %s" % {line:{lp:{'color':color}}})

func _init():
	if print_debug: print("fbsh._init()")
	resource_name = "FlatBuffersSchemaHighlighter"
	editor_settings = EditorInterface.get_editor_settings()
	symbol_color = editor_settings.get_setting("text_editor/theme/highlighting/symbol_color")
	number_color = editor_settings.get_setting("text_editor/theme/highlighting/number_color")
	base_type_color = editor_settings.get_setting("text_editor/theme/highlighting/base_type_color")
	text_color = editor_settings.get_setting("text_editor/theme/highlighting/text_color")
	if not text_color: comment_color = Color.GREEN
	string_color = editor_settings.get_setting("text_editor/theme/highlighting/string_color")
	function_color = editor_settings.get_setting("text_editor/theme/highlighting/function_color")
	keyword_color = editor_settings.get_setting("text_editor/theme/highlighting/keyword_color")
	if not keyword_color: comment_color = Color.DIM_GRAY
	comment_color = editor_settings.get_setting("text_editor/theme/highlighting/comment_color")
	if not comment_color: comment_color = Color.DIM_GRAY

# Override methods for EditorSyntaxHighlighter
func _get_name ( ) -> String:
	if print_debug: print("fbsh._get_name()")
	return "FlatBuffersSchema"


func _get_supported_languages ( ) -> PackedStringArray:
	if print_debug: print("fbsh._get_supported_languages()")
	return ["FlatBuffersSchema"]


# Override methods for Syntax Highlighter
func _clear_highlighting_cache ( ):
	dict = {}


func _get_line_syntax_highlighting ( line : int ) -> Dictionary:
	if dict.has(line):
		#print( "%s:%s" % [line, dict[line]] )
		return dict[line]
	else:
		return {}


func _update_cache ( ):
	if print_debug: print("fbsh._update_cache()")
	fbs_text = get_text_edit().text
	reset()
	print_debug = EditorInterface.get_editor_settings().get( FlatBuffersPlugin.EDITOR_SETTINGS_BASE + &"fbs_debug_print" )
	parse_schema()
	for key in dict.keys():
		if print_debug: print( "%s:%s" % [key,dict[key]] )

func parse_schema():
	var token : Dictionary = { 'type': 0, 't':"" }
	var include_allowed = true

	while true:
		token = get_token()
		if token.type == TokenType.EOF: break

		# skip comments
		if token.type == TokenType.COMMENT: continue
		
		if token.type != TokenType.KEYWORD:
			syntax_error( token )
			next_line()
			continue

		#include = include string_constant ;
		if token.t == 'include':
			append( token, keyword_color )
			if not include_allowed: syntax_error( token, "includes not allowed mid file" )
			parse_include()
		else: include_allowed = false

		match token.t:
			#namespace_decl = namespace ident ( . ident )* ;
			'namespace':
				color_default()
				next_line()
			#type_decl = ( table | struct ) ident metadata { field_decl+ }
			'struct': parse_type_decl()
			'table': parse_type_decl()
			#enum_decl = ( enum ident : type | union ident ) metadata { commasep( enumval_decl ) }
			'enum': parse_enum_decl()
			'union': parse_union_decl()
			#root_decl = root_type ident;
			'root_type':
				token = get_token()
				if not token.t in user_types: syntax_error(token, "wanted table identifier")
				color_default()
				token = get_token()
				if token.t != ';': syntax_error(token, "wanted ';'")
			#file_extension_decl = file_extension string_constant ;
			'file_extension':
				color_default()
				next_line()
			#file_identifier_decl = file_identifier string_constant ;
			'file_identifier':
				color_default()
				next_line()
			#attribute_decl = attribute ident | "</tt>ident<tt>" ;
			'attribute':
				color_default()
				next_line()
			#rpc_decl = rpc_service ident { rpc_method+ }
			'rpc_service':
				color_default()
				next_line()
			#object = { commasep( ident : value ) }
			# FIXME, what is this???


func parse_include():
	var token = get_token()
	if token.type != TokenType.STRING: syntax_error(token, "wanted filename as string")
	var quoted : String = token.t
	parse_included_file( quoted.substr(1, quoted.length() -2 ) )
	color_default()
	token = get_token()
	if token.t != ';': syntax_error( token, "wanted semicolon" )

func parse_union_decl():
	#enum_decl = ( enum ident : type | union ident ) metadata { commasep( enumval_decl ) }
	var token = get_token()
	if token.type != TokenType.IDENT: syntax_error(token, "wanted ident")
	user_types.append( token.t )
	color_default()

	token = get_token()

	# Optional Metadata
	if token.t == '(':
		parse_metadata()
		color_default()
		token = get_token()

	if token.t != '{': syntax_error(token, "wanted '{'")

	token = get_token()
	#enumval_decl = ident [ = integer_constant ]
	while token.t != '}':
		if not is_type(token.t): syntax_error(token, "wanted type")
		color_default()
		token = get_token()

func parse_enum_decl():
	#enum_decl = ( enum ident : type | union ident ) metadata { commasep( enumval_decl ) }
	var token = get_token()
	if token.type != TokenType.IDENT: syntax_error(token, "wanted ident")
	user_types.append( token.t )
	color_default()

	token = get_token()

	if token.t != ':': syntax_error(token, "wanted ':'")
	token = get_token()
	if not token.t in types: syntax_error(token, "wanted type")
	color_default()
	token = get_token()

	# Optional Metadata
	if token.t == '(':
		parse_metadata()
		color_default()
		token = get_token()

	if token.t != '{': syntax_error(token, "wanted '{'")

	token = get_token()
	#enumval_decl = ident [ = integer_constant ]
	while token.t != '}':
		if token.type != TokenType.IDENT: syntax_error(token, "wanted ident")
		user_enum_values.append( token.t )
		color_default()
		token = get_token()
		if token.t == '=':
			token = get_token()
			if not is_integer( token.t ): syntax_error(token, "wanted integer")
			color_default()
			token = get_token()
		if token.t == '}': break
		if token.t != ',': syntax_error(token, "wanted ','")
		token = get_token()

func parse_type_decl():
	#type_decl = ( table | struct ) ident metadata { field_decl+ }\

	# ident
	var token = get_token()
	append( token, symbol_color )
	if token.type != TokenType.IDENT : syntax_error( token, "wanted ident" )
	user_types.append( token.t )
	color_default()

	token = get_token()
	#metadata = [ ( commasep( ident [ : single_value ] ) ) ]
	if token.t == '(':
		parse_metadata()
		token = get_token()

	# Open Curly
	if token.t != '{': syntax_error(token, "wanted '{'")

	# Field Declaration
	while token.t != '}':
		token = get_field()

	# Close Curly
	if token.t != '}':
		syntax_error(token, "wanted close brace")

func get_field() -> Dictionary:
	# Field Declaration
	#field_decl = ident : type [ = scalar ] metadata ;
	var token = get_token()
	if token.t == '}': return token
	if token.type != TokenType.IDENT: syntax_error( token, "wanted ident")

	token = get_token()
	if token.t != ':': syntax_error(token, "wanted ':'")
	append( token, text_color )

	token = get_token()
	if token.type == TokenType.TYPE: pass
	elif token.t == '[':
		token = get_token()
		if not is_type( token.t ): syntax_error(token, "wanted type")
		color_default()
		token = get_token()
		if token.t != ']': syntax_error(token, "wanted ']'")
	else: syntax_error(token, "wanted type")
	color_default()

	# Optional scalar value
	token = get_token()
	if token.t == '=':
		token = get_token()
		if is_scalar( token.t ): pass
		elif token.t in user_enum_values: pass
		else: syntax_error( token, "wanted scalar" )
		color_default()
		token = get_token()

	# optional metadata
	if token.t == '(':
		parse_metadata()
		token = get_token()

	# ending semicolon
	if token.t != ';': syntax_error(token, "wanted ';'")
	return token

func parse_metadata():
	#metadata = [ ( commasep( ident [ : single_value ] ) ) ]
	#commasep(x) = [ x ( , x )* ]
	#ident = [a-zA-Z_][a-zA-Z0-9_]*
	#single_value = scalar | string_constant
	var token = get_token()
	while not token.t == ')':
		#ident
		if token.type != TokenType.IDENT: syntax_error(token, "wanted identity")
		token = get_token()

		# optional value
		if token.t == ':':
			token = get_token() # Single Value
			match token.type:
				TokenType.STRING: pass
				TokenType.SCALAR: pass
				_: syntax_error(token, "wanted 'string' or 'scalar'")
			color_default()
			token = get_token()

		# end or continue
		if token.t == ')': return
		if token.t != ',': syntax_error( token, "expected ','")
		token = get_token()

func parse_included_file( filename : String ):
	if filename == 'variant.fbs':
		variant_included = true
		return

	# FIXME, there is currently no known way to know which file I am parsing.
	# So that means its impossible to know which files to load and parse
