@tool
class_name FlatBuffersHighlighter extends EditorSyntaxHighlighter

var print_debug : bool = false

#  ██████  ██████   █████  ███    ███ ███    ███ ███████ ██████
# ██       ██   ██ ██   ██ ████  ████ ████  ████ ██      ██   ██
# ██   ███ ██████  ███████ ██ ████ ██ ██ ████ ██ █████   ██████
# ██    ██ ██   ██ ██   ██ ██  ██  ██ ██  ██  ██ ██      ██   ██
#  ██████  ██   ██ ██   ██ ██      ██ ██      ██ ███████ ██   ██

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

# ██████  ███████  █████  ██████  ███████ ██████
# ██   ██ ██      ██   ██ ██   ██ ██      ██   ██
# ██████  █████   ███████ ██   ██ █████   ██████
# ██   ██ ██      ██   ██ ██   ██ ██      ██   ██
# ██   ██ ███████ ██   ██ ██████  ███████ ██   ██

class Reader:
	var hl = load('res://addons/gdflatbuffers/fbs_syntax_highlighter.gd')
	var text : String					# The text to parse
	var line_index : Array[int] = [0]	# cursor position for each line start
	var cursor_p : int = 0				# Cursor position in file
	var cursor_lp : int = 0				# Cursor position in line
	var line_n : int = 0				# Current line number

	func _init( text_ : String ) -> void:
		text = text_

	func length() -> int:
		return text.length()

	func reset():
		cursor_p = 0
		line_n = 0
		line_index = [0]
		cursor_lp = 0

	func at_end() -> bool:
		if cursor_p >= text.length() -1: return true
		return false

	func peek_char( offset : int = 0 ) -> String:
		return text[cursor_p + offset] if cursor_p + offset < text.length() else '\n'

	func get_char() -> String:
		adv(); return text[cursor_p - 1]

	func adv( dist : int = 1):
		for i in dist:
			cursor_p += 1
			cursor_lp += 1
			if text[cursor_p -1] != '\n': continue
			line_index.append(cursor_p)
			cursor_lp = 0
			line_n = line_index.size() -1

	func next_line():
		while peek_char() != '\n':
			adv()
		adv()

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
		token['t'] = text.substr( start, cursor_p - start )
		return token

# ████████  ██████  ██   ██ ███████ ███    ██ ██ ███████ ███████ ██████
#    ██    ██    ██ ██  ██  ██      ████   ██ ██    ███  ██      ██   ██
#    ██    ██    ██ █████   █████   ██ ██  ██ ██   ███   █████   ██████
#    ██    ██    ██ ██  ██  ██      ██  ██ ██ ██  ███    ██      ██   ██
#    ██     ██████  ██   ██ ███████ ██   ████ ██ ███████ ███████ ██   ██

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

var builtin_included : bool = false
var builtin_types : Array = [
	"Vector3",
	"Vector3i",
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

func reset():
	user_types.clear()
	user_enum_values.clear()


func get_token( r : Reader ) -> Dictionary:
	var token = { 'line':r.line_n, 'col':r. cursor_lp, 'type':TokenType.UNKNOWN, 't':r.peek_char() }
	if r.cursor_p >= r.length(): token.type = TokenType.EOF

	while r.cursor_p < r.length() -1:
		token['line'] = r.line_n
		token['col'] = r. cursor_lp
		token['t'] = r.peek_char()
		if r.peek_char() in whitespace: r.adv(); continue
		if r.peek_char() == '/' and r.peek_char(1) == '/':
			token = r.get_comment();
			break
		if r.peek_char() in punc:
			token['type'] = TokenType.PUNCT
			token['t'] = r.get_char()
			break
		if r.peek_char() == '"': token = r.get_string(); break
		token = get_word( r ); break
	if print_debug:
		if token['type'] == TokenType.EOF: print( "EOF" )
	print( "%s:%s | %s | '%s'" % [token.line, token.col, TokenType.keys()[token.get('type')], token.get('t')] )
	return token

func get_word( r : Reader ) -> Dictionary:
	var token : Dictionary = {
		'line':r.line_n,
		'col': r.cursor_lp,
		'type':TokenType.UNKNOWN,
	}
	var start := r.cursor_p
	while not r.peek_char() in word_separation: r.adv()
	# return the substring
	token['t'] = r.text.substr( start, r.cursor_p - start )
	if is_type( token.get('t') ): token['type'] = TokenType.TYPE
	elif is_keyword(token.get('t')): token['type'] = TokenType.KEYWORD
	elif is_scalar( token.get('t') ): token['type'] = TokenType.SCALAR
	elif is_ident(token.get('t')): token['type'] = TokenType.IDENT
	append( token )
	return token

func is_type( word : String )-> bool:
	#type = bool | byte | ubyte | short | ushort | int | uint | float | long | ulong | double | int8 | uint8 | int16 | uint16 | int32 | uint32| int64 | uint64 | float32 | float64 | string
	# | [ type ] | ident
	if word in types: return true
	if word in user_types: return true
	if builtin_included and word in builtin_types: return true
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

# ██   ██ ██  ██████  ██   ██ ██      ██  ██████  ██   ██ ████████ ███████ ██████
# ██   ██ ██ ██       ██   ██ ██      ██ ██       ██   ██    ██    ██      ██   ██
# ███████ ██ ██   ███ ███████ ██      ██ ██   ███ ███████    ██    █████   ██████
# ██   ██ ██ ██    ██ ██   ██ ██      ██ ██    ██ ██   ██    ██    ██      ██   ██
# ██   ██ ██  ██████  ██   ██ ███████ ██  ██████  ██   ██    ██    ███████ ██   ██

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
var editor_settings : EditorSettings
var error_color : Color = Color.FIREBRICK

var reader : Reader
var dict : Dictionary
var want : TokenType = TokenType.KEYWORD

func _init():
	if print_debug: print("fbsh._init()")
	editor_settings = EditorInterface.get_editor_settings()
	error_color = Color.FIREBRICK
	want = TokenType.KEYWORD

	colours[TokenType.UNKNOWN] = editor_settings.get_setting("text_editor/theme/highlighting/text_color")
	colours[TokenType.COMMENT] = editor_settings.get_setting("text_editor/theme/highlighting/comment_color")
	colours[TokenType.KEYWORD] = editor_settings.get_setting("text_editor/theme/highlighting/keyword_color")
	colours[TokenType.TYPE] = editor_settings.get_setting("text_editor/theme/highlighting/base_type_color")
	colours[TokenType.STRING] = editor_settings.get_setting("text_editor/theme/highlighting/string_color")
	colours[TokenType.PUNCT] = editor_settings.get_setting("text_editor/theme/highlighting/text_color")
	colours[TokenType.IDENT] = editor_settings.get_setting("text_editor/theme/highlighting/symbol_color")
	colours[TokenType.SCALAR] = editor_settings.get_setting("text_editor/theme/highlighting/number_color")
	colours[TokenType.META] = editor_settings.get_setting("text_editor/theme/highlighting/text_color")

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

# This function runs on any change, with the line number that is edited.
# we can use it to update the highlighting.
func _get_line_syntax_highlighting ( line_num : int ) -> Dictionary:
	#var line = get_text_edit().get_line( line_num )
	#if line.is_empty(): return {}
	#parse_line( line_num )
	return dict[line_num] if dict.has(line_num) else {}


func _update_cache ( ):
	if print_debug: print("fbsh._update_cache()")
	var text = get_text_edit().text
	if text.is_empty(): return
	reader = Reader.new( text )
	print_debug = EditorInterface.get_editor_settings().get( FlatBuffersPlugin.EDITOR_SETTINGS_BASE + &"fbs_debug_print" )
	parse_schema()
	if not print_debug: return
	for key in dict.keys():
		print( "%s:%s" % [key,dict[key]] )

func color_default():
	var line = reader.line_n
	if not dict.has(line): dict[line] = {}
	dict[line][reader.cursor_lp] = { 'color':colours[TokenType.UNKNOWN] }
	#print( "add: %s" % {line:{lp:{'color':color}}})

func append( token : Dictionary, color : Color = error_color ):
	color = colours[token.type]
	dict.get_or_add(token.line, { 'want':want } )[token.col] = {'color':color}

func syntax_error( token : Dictionary, reason = "" ):
	append( token, error_color )
	if print_debug:
		push_error( "Syntax Error: ", JSON.stringify( token, '\t', false ) )

# ██████   █████  ██████  ███████ ███████ ██████
# ██   ██ ██   ██ ██   ██ ██      ██      ██   ██
# ██████  ███████ ██████  ███████ █████   ██████
# ██      ██   ██ ██   ██      ██ ██      ██   ██
# ██      ██   ██ ██   ██ ███████ ███████ ██   ██

func parse_line( line_num ):
	var line = get_text_edit().get_line( line_num )
	if line.is_empty(): return

	reader = Reader.new( line )

	var context = dict.get( line_num, { 'want': TokenType.KEYWORD } )

	var token = get_token( reader )
	while not reader.at_end():
		token = get_token( reader )
		token['line'] = line_num
		print( TokenType.keys()[token.type], token )


func parse_schema():
	var token : Dictionary = { 'type': 0, 't':"" }
	var include_allowed = true

	while not reader.at_end():
		token = get_token( reader )
		print( TokenType.keys()[token.type], token )
		# skip comments
		if token['type'] == TokenType.COMMENT: continue

		# First thing we want is a keyword.
		if token.get('type') != TokenType.KEYWORD:
			syntax_error( token, "Wanted TokenType.KEYWORD" )
			reader.next_line()
			continue

		#include = include string_constant ;
		if token['t'] == 'include':
			if not include_allowed:
				syntax_error( token, "includes not allowed mid file" )
				append( token )
			append( token, error_color )
			parse_include()
		else: include_allowed = false

		match token.get('t'):
			#TODO namespace_decl = namespace ident ( . ident )* ;
			'namespace':
				color_default()
				reader.next_line()
			#type_decl = ( table | struct ) ident metadata { field_decl+ }
			'struct': parse_type_decl()
			'table': parse_type_decl()
			#enum_decl = ( enum ident : type | union ident ) metadata { commasep( enumval_decl ) }
			'enum': parse_enum_decl()
			'union': parse_union_decl()
			#root_decl = root_type ident;
			'root_type':
				token = get_token(reader)
				if not token.get('t') in user_types: syntax_error(token, "wanted table identifier")
				color_default()
				token = get_token(reader)
				if token.get('t') != ';': syntax_error(token, "hl:414 - wanted ';'")
			#TODO file_extension_decl = file_extension string_constant ;
			'file_extension':
				color_default()
				reader.next_line()
			#TODO file_identifier_decl = file_identifier string_constant ;
			'file_identifier':
				color_default()
				reader.next_line()
			#TODO attribute_decl = attribute ident | "</tt>ident<tt>" ;
			'attribute':
				color_default()
				reader.next_line()
			#TODO rpc_decl = rpc_service ident { rpc_method+ }
			'rpc_service':
				color_default()
				reader.next_line()
			#TODO object = { commasep( ident : value ) }

	print("")
	for key in dict.keys():
		print( "%s:%s" % [key,dict[key]] )


func parse_include():
	var token = get_token(reader)
	if token.get('type') != TokenType.STRING: syntax_error(token, "wanted filename as string")
	else: append( token )
	var quoted : String = token.get('t')
	parse_included_file( quoted.substr(1, quoted.length() -2 ) )
	color_default()
	token = get_token(reader)
	if token.get('t') != ';': syntax_error( token, "wanted semicolon" )

func parse_union_decl():
	#enum_decl = ( enum ident : type | union ident ) metadata { commasep( enumval_decl ) }
	var token = get_token(reader)
	if token.get('type') != TokenType.IDENT: syntax_error(token, "wanted ident")
	user_types.append( token.get('t') )
	color_default()

	token = get_token(reader)

	# Optional Metadata
	if token['t'] == '(':
		parse_metadata()
		color_default()
		token =  get_token(reader)

	if token.get('t') != '{': syntax_error(token, "wanted '{'")

	token =  get_token(reader)
	#enumval_decl = ident [ = integer_constant ]
	while token.get('t') != '}':
		if not is_type(token.get('t')): syntax_error(token, "wanted type(highligher:464)")
		color_default()
		token =  get_token(reader)

func parse_enum_decl():
	#enum_decl = ( enum ident : type | union ident ) metadata { commasep( enumval_decl ) }
	var token =  get_token(reader)
	if token.get('type') != TokenType.IDENT: syntax_error(token, "wanted ident")
	user_types.append( token.get('t') )
	color_default()

	token =  get_token(reader)

	if token.get('t') != ':': syntax_error(token, "wanted ':'")
	token =  get_token(reader)
	if not token.get('t') in types: syntax_error(token, "wanted type(highligher:479)")
	color_default()
	token =  get_token(reader)

	# Optional Metadata
	if token['t'] == '(':
		parse_metadata()
		color_default()
		token =  get_token(reader)

	if token.get('t') != '{': syntax_error(token, "wanted '{'")

	token =  get_token(reader)
	#enumval_decl = ident [ = integer_constant ]
	while token.get('t') != '}':
		if token.get('type') != TokenType.IDENT: syntax_error(token, "wanted ident")
		user_enum_values.append( token.get('t') )
		color_default()
		token =  get_token(reader)
		if token['t'] == '=':
			token =  get_token(reader)
			if not is_integer( token.get('t') ): syntax_error(token, "wanted integer")
			color_default()
			token =  get_token(reader)
		if token['t'] == '}': break
		if token.get('t') != ',': syntax_error(token, "wanted ','")
		token =  get_token(reader)

func parse_type_decl():
	#type_decl = ( table | struct ) ident metadata { field_decl+ }\

	# ident
	var token =  get_token(reader)
	append( token )
	if token.get('type') != TokenType.IDENT : syntax_error( token, "wanted ident" )
	user_types.append( token.get('t') )
	color_default()

	token =  get_token(reader)
	#metadata = [ ( commasep( ident [ : single_value ] ) ) ]
	if token['t'] == '(':
		parse_metadata()
		token =  get_token(reader)

	# Open Curly
	if token.get('t') != '{': syntax_error(token, "wanted '{'")

	# Field Declaration
	while token.get('t') != '}' and not reader.at_end():
		token = parse_field()

	# Close Curly
	if token.get('t') != '}':
		syntax_error(token, "wanted close brace")

func parse_field() -> Dictionary:
	# Field Declaration
	# field_decl = ident : type [ = scalar ] metadata ;
	var token =  get_token(reader)
	if token['t'] == '}': return token
	if token.get('type') != TokenType.IDENT: syntax_error( token, "wanted ident")

	token =  get_token(reader)
	if token.get('t') != ':': syntax_error(token, "wanted ':'")
	append( token )

	token =  get_token(reader)
	if token['type'] == TokenType.TYPE: pass
	elif token['t'] == '[':
		token =  get_token(reader)
		if not is_type( token.get('t') ): syntax_error(token, "wanted type(highligher:549) %s " )
		color_default()
		token =  get_token(reader)
		if token.get('t') != ']': syntax_error(token, "wanted ']'")
	else: syntax_error(token, "wanted type(highligher:552)" )

	color_default()

	# Optional scalar value
	token =  get_token(reader)
	if token['t'] == '=':
		token =  get_token(reader)
		if is_scalar( token.get('t') ): pass
		elif token.get('t') in user_enum_values: pass
		else: syntax_error( token, "wanted scalar" )
		color_default()
		token =  get_token(reader)

	# optional metadata
	if token['t'] == '(':
		parse_metadata()
		token =  get_token(reader)

	# ending semicolon
	if token.get('t') != ';': syntax_error(token, "wanted ';'")
	return token

func parse_metadata():
	#metadata = [ ( commasep( ident [ : single_value ] ) ) ]
	#commasep(x) = [ x ( , x )* ]
	#ident = [a-zA-Z_][a-zA-Z0-9_]*
	#single_value = scalar | string_constant
	var token =  get_token(reader)
	while not token['t'] == ')':
		#ident
		if token.get('type') != TokenType.IDENT: syntax_error(token, "wanted identity")
		token =  get_token(reader)

		# optional value
		if token['t'] == ':':
			token =  get_token(reader) # Single Value
			match token.get('type'):
				TokenType.STRING: pass
				TokenType.SCALAR: pass
				_: syntax_error(token, "wanted 'string' or 'scalar'")
			color_default()
			token =  get_token(reader)

		# end or continue
		if token['t'] == ')': return
		if token.get('t') != ',': syntax_error( token, "expected ','")
		token =  get_token(reader)

func parse_included_file( filename : String ):
	if filename == 'godot.fbs':
		builtin_included = true
		return

	# NOTE, there is currently no known way to know which file I am parsing.
	# So that means its impossible to know which files to load and parse
	# if this were a game script compiled with debug, then I could use
	# get_stack(), however it is not available in a thread, and that appears to
	# be where the syntax highliter lives.
