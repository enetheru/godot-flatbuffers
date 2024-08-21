@tool
class_name FlatBuffersHighlighter extends EditorSyntaxHighlighter

var verbose : bool = false

# ██████  ███████  █████  ██████  ███████ ██████
# ██   ██ ██      ██   ██ ██   ██ ██      ██   ██
# ██████  █████   ███████ ██   ██ █████   ██████
# ██   ██ ██      ██   ██ ██   ██ ██      ██   ██
# ██   ██ ███████ ██   ██ ██████  ███████ ██   ██

class Reader:
	signal newline( ln, p )
	signal endfile( ln, p )

	var hl = load('res://addons/gdflatbuffers/fbs_syntax_highlighter.gd')
	var text : String					# The text to parse
	var line_index : Array[int] = [0]	# cursor position for each line start
	var cursor_p : int = 0				# Cursor position in file
	var cursor_lp : int = 0				# Cursor position in line
	var line_n : int = 0				# Current line number
	var line_start : int				# When updating chunks of a larger source file, what line does this chunk start on.

	func _init( text_ : String, line_i : int = 0 ) -> void:
		text = text_
		line_start = line_i
		line_n = line_i

	func length() -> int:
		return text.length()

	func reset():
		cursor_p = 0
		line_n = line_start
		line_index = [0]
		cursor_lp = 0

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
			if peek_char( -1 ) != '\n': continue
			line_index.append( cursor_p )
			cursor_lp = 0
			line_n = line_index.size() -1
			newline.emit( line_n, cursor_p )

	func next_line():
		adv( text.length() ) # adv automatically stops on a line break.

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

#  ██████  ██████   █████  ███    ███ ███    ███ ███████ ██████
# ██       ██   ██ ██   ██ ████  ████ ████  ████ ██      ██   ██
# ██   ███ ██████  ███████ ██ ████ ██ ██ ████ ██ █████   ██████
# ██    ██ ██   ██ ██   ██ ██  ██  ██ ██  ██  ██ ██      ██   ██
#  ██████  ██   ██ ██   ██ ██      ██ ██      ██ ███████ ██   ██

enum Context {
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
	DIGIT, # [:digit:] = [0-9]
	XDIGIT, # [:xdigit:] = [0-9a-fA-F]
	DEC_INTEGER_CONSTANT, # = [-+]?[:digit:]+
	HEX_INTEGER_CONSTANT, # = [-+]?0[xX][:xdigit:]+
	INTEGER_CONSTANT, # = dec_integer_constant | hex_integer_constant
	DEC_FLOAT_CONSTANT, # = [-+]?(([.][:digit:]+)|([:digit:]+[.][:digit:]*)|([:digit:]+))([eE][-+]?[:digit:]+)?
	HEX_FLOAT_CONSTANT, # = [-+]?0[xX](([.][:xdigit:]+)|([:xdigit:]+[.][:xdigit:]*)|([:xdigit:]+))([pP][-+]?[:digit:]+)
	SPECIAL_FLOAT_CONSTANT, # = [-+]?(nan|inf|infinity)
	FLOAT_CONSTANT, # = dec_float_constant | hex_float_constant | special_float_constant
	BOOLEAN_CONSTANT, # = true | false
}


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

var word_separation : Array = [' ', '\t', '\n', '{','}', ':', ';', ',', '(', ')', '[', ']', '.']
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

var keywords : Dictionary = {
	'include' : Context.INCLUDE,
	'namespace' : Context.NAMESPACE_DECL,
	'table' : Context.TYPE_DECL,
	'struct' : Context.TYPE_DECL,
	'enum' : Context.ENUM_DECL,
	'union' : Context.ENUM_DECL,
	'root_type' : Context.ROOT_DECL,
	'file_extension' : Context.FILE_EXTENSION_DECL,
	'file_identifier' : Context.FILE_IDENTIFIER_DECL,
	'attribute' : Context.ATTRIBUTE_DECL,
	'rpc_service' : Context.RPC_DECL,
}

var user_types : Array = []
var user_enum_values : Array = []

func reset():
	user_types.clear()
	user_enum_values.clear()


func get_token( r : Reader ) -> Dictionary:
	var token = { 'line':r.line_n, 'col':r. cursor_lp, 'type':TokenType.UNKNOWN, 't':r.peek_char() }
	if r.at_end(): token.type = TokenType.EOF

	while not r.at_end():
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
		if r.peek_char() == '"':
			token = r.get_string(); break
		token = get_word( r ); break
	if verbose:
		if token['type'] == TokenType.EOF: print( "EOF" )
		print( "%s:%s | %s | '%s'" % [token.line, token.col, TokenType.keys()[token.get('type')], token.get('t')] )
	highlight( token )
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
var line_dict : Dictionary

func _init():
	if verbose: print("fbsh._init()")
	editor_settings = EditorInterface.get_editor_settings()
	error_color = Color.RED

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
	if verbose: print("fbsh._get_name()")
	return "FlatBuffersSchema"


func _get_supported_languages ( ) -> PackedStringArray:
	if verbose: print("fbsh._get_supported_languages()")
	return ["FlatBuffersSchema"]


# Override methods for Syntax Highlighter
func _clear_highlighting_cache ( ):
	dict = {}

# This function runs on any change, with the line number that is edited.
# we can use it to update the highlighting.
func _get_line_syntax_highlighting ( line_num : int ) -> Dictionary:
	line_dict = dict.get( line_num, {} )

	# clear the colour flags but keep the stack
	# line_num = 0 is special, as there is no context to go back to.
	stack = line_dict.get('stack', [] ) if line_num else []
	line_dict = { 'stack':stack }
	dict[line_num] = line_dict

	var line = get_text_edit().get_line( line_num )
	if line.is_empty():
		# We need to push our stack forward
		save_stack(line_num +1, 0 )
		return line_dict

	reader = Reader.new( line, line_num )
	#reader.newline.connect( save_stack )
	reader.endfile.connect( save_stack )
	reader.line_n = line_num

	parse()
	if verbose: print( "line:%s | After parse() %s\n" % [line_num, sstring( stack )] )
	# make sure that our changes are in the main dict.
	line_dict['stack'] = stack.duplicate(true)
	dict[line_num] = line_dict
	save_stack(line_num +1, 0 )
	return line_dict


func _update_cache ( ):
	verbose = true
	if verbose: print("fbsh._update_cache()")
	error_color = Color.RED

	# FIXME I dont know what this function is for.
	#print( JSON.stringify( dict, '\t') )

func color_default():
	line_dict[reader.cursor_lp] = { 'color':colours[TokenType.UNKNOWN] }

func highlight( token : Dictionary ):
	line_dict[token.col] = { 'color':colours[token.type] }

func syntax_error( token : Dictionary, reason = "" ):
	var pos = token.col
	if pos > 0: pos -= 1
	line_dict[pos] = { 'color':error_color }
	if verbose:
		print()
		printerr( sstring() )
		printerr( "Syntax Error: %s - %s" % [tstring( token ), reason] )

# ██████   █████  ██████  ███████ ███████ ██████
# ██   ██ ██   ██ ██   ██ ██      ██      ██   ██
# ██████  ███████ ██████  ███████ █████   ██████
# ██      ██   ██ ██   ██      ██ ██      ██   ██
# ██      ██   ██ ██   ██ ███████ ███████ ██   ██

var include_allowed = true

class ParseFrame:
	func _init( c : Context, s : int = 0) -> void: context = c; step_num = s
	var context : Context
	var step_num : int

var stack : Array = []
var current_frame : ParseFrame

func start_frame( new_context : Context ) -> ParseFrame:
	var context_name : String = Context.keys()[stack.back().context] if stack.size() else "empty"
	if verbose: print( "Start %s | %s" % [context_name, sstring()] )
	if not current_frame || current_frame.context != new_context:
		current_frame = ParseFrame.new( new_context )
		stack.push_back( current_frame )
	return current_frame

func end_frame( pop_stack : bool = true):
	var context_name : String = Context.keys()[stack.back().context] if stack.size() else "empty"
	if pop_stack: stack.pop_back()
	if verbose: print( "End   %s | %s" % [ context_name, sstring()] )

func save_stack( line_num : int, cursor_pos : int = 0 ):
	var this_dict = dict.get( line_num, {} )
	this_dict['stack'] = stack.duplicate(true)
	dict[line_num] = this_dict

func tstring( token : Dictionary ) -> String:
	return "Token|%s:%s|%s|'%s'" % [token.line, token.col, TokenType.keys()[token.type], token.t]

func sstring( _stack : Array = stack ):
	var stack_string : String = "Stack"
	if not _stack.size(): stack_string += "->[]"
	for frame in _stack:
		stack_string += "->[%s.%s]" % [ Context.keys()[frame.context], frame.step_num ]
	return stack_string

var parse_funcs : Dictionary = {
	Context.SCHEMA : parse_schema,
	Context.INCLUDE : parse_include,
	Context.NAMESPACE_DECL : parse_namespace_decl,
	Context.ATTRIBUTE_DECL : parse_attribute_decl,
	Context.TYPE_DECL : parse_type_decl,
	Context.ENUM_DECL : parse_enum_decl,
	Context.ROOT_DECL : parse_root_decl,
	Context.FIELD_DECL : parse_field_decl,
	Context.RPC_DECL : parse_rpc_decl,
	Context.RPC_METHOD : parse_rpc_method,
	Context.TYPE : parse_type,
	Context.ENUMVAL_DECL : parse_enumval_decl,
	Context.METADATA : parse_metadata,
	Context.SCALAR : parse_scalar,
	Context.OBJECT : parse_object,
	Context.SINGLE_VALUE : parse_single_value,
	Context.VALUE : parse_value,
	Context.COMMASEP : parse_commasep,
	Context.FILE_EXTENSION_DECL : parse_file_extension_decl,
	Context.FILE_IDENTIFIER_DECL : parse_file_identifier_decl,
	Context.STRING_CONSTANT : parse_string_constant,
	Context.IDENT : parse_ident,
	Context.DIGIT : parse_digit,
	Context.XDIGIT : parse_xdigit,
	Context.DEC_INTEGER_CONSTANT : parse_dec_integer_constant,
	Context.HEX_INTEGER_CONSTANT : parse_hex_integer_constant,
	Context.INTEGER_CONSTANT : parse_integer_constant,
	Context.DEC_FLOAT_CONSTANT : parse_dec_float_constant,
	Context.HEX_FLOAT_CONSTANT : parse_hex_float_constant,
	Context.SPECIAL_FLOAT_CONSTANT : parse_special_float_constant,
	Context.FLOAT_CONSTANT : parse_float_constant,
	Context.BOOLEAN_CONSTANT : parse_boolean_constant,
}

func parse():
	# We might already exist, so process it before continuing
	# FIXME temporary change from while to if so I dont accidentally get an endless loop
	current_frame = null
	if stack.size() > 0:
		current_frame = stack.back()
		parse_funcs[ current_frame.context ].call( {} )

	current_frame = stack.back() if stack.size() else null
	parse_schema()


func parse_schema( token : Dictionary = {} ):
	var this_frame = start_frame( Context.SCHEMA )
	#schema # = include* ( namespace_decl | type_decl | enum_decl | root_decl
	#					 | file_extension_decl | file_identifier_decl
	#					 | attribute_decl | rpc_decl | object )*

	while true:
		token = get_token( reader )
		match token.type:
			TokenType.COMMENT: continue
			TokenType.EOF: break

		var context = keywords.get(token.t )
		if context == null:
			syntax_error( token, "Wanted TokenType.KEYWORD" )
			reader.next_line()
			break

		if context == Context.INCLUDE:
			if this_frame.step_num == 0:
				parse_funcs[context].call( token )
				continue
			else:
				syntax_error( token, "Trying to use include mid file" )
				reader.next_line()
				break

		this_frame.step_num = 1
		parse_funcs[context].call( token )
		if reader.at_end(): break

	# dont pop the stack if the end of the reader was reached.
	end_frame( this_frame.step_num == 0 )


func parse_include( token : Dictionary ):
	start_frame( Context.INCLUDE )

	token = get_token(reader)
	if token.get('type') != TokenType.STRING:
		syntax_error(token, "wanted filename as string")
		reader.next_line()
		return end_frame()

	# FIXME Perform a very fast parse of this file
	var quoted : String = token.get('t')
	parse_included_file( quoted.substr(1, quoted.length() -2 ) )

	color_default()
	token = get_token(reader)
	if token.get('t') == ';': return end_frame()
	reader.next_line()
	syntax_error( token, "wanted semicolon" )
	end_frame()

func parse_namespace_decl( token : Dictionary ):
	start_frame( Context.NAMESPACE_DECL )
	#NAMESPACE_DECL = namespace ident ( . ident )* ;

	token = get_token( reader )
	if token.type != TokenType.IDENT:
		syntax_error( token, "Wanted TokenType.IDENT" )
		reader.next_line()
		return end_frame()

	while true:
		token = get_token( reader )
		if token.get('t') != '.': break
		token = get_token( reader )
		if token.type != TokenType.IDENT:
			syntax_error( token, "Wanted TokenType.IDENT" )
			reader.next_line()
			return end_frame()

	color_default()
	if token.get('t') == ';': return end_frame()
	syntax_error( token, "wanted semicolon" )
	reader.next_line()
	end_frame()

func parse_attribute_decl( token : Dictionary ):
	start_frame( Context.ATTRIBUTE_DECL )
	# ATTRIBUTE_DECL = attribute ident | "</tt>ident<tt>" ;
	token = get_token(reader)
	match token.type:
		TokenType.IDENT:
			token = get_token( reader )
		TokenType.STRING:
			token = get_token( reader )
		_:
			syntax_error( token, "Wanted: ident | \"</tt>ident<tt>\" " )
			reader.next_line()
			return end_frame()

	color_default()
	if token.get('t') == ';': return end_frame()
	syntax_error( token, "wanted semicolon" )
	reader.next_line()
	end_frame()


func parse_type_decl( token : Dictionary ):
	var this_frame = start_frame( Context.TYPE_DECL )
	#type_decl = ( table | struct ) ident [metadata] { field_decl+ }\

	if this_frame.step_num == 0:
		#ident
		token = get_token( reader )
		if token.type != TokenType.IDENT:
			syntax_error( token, "Wanted TokenType.IDENT" )
			reader.next_line()
			return end_frame()
		color_default()

		# [metadata]
		token = get_token( reader )
		if token.t != '{':
			parse_metadata( token )
			token = get_token( reader )

		# Open Curly
		if token.get('t') != '{':
			syntax_error( token, "wanted '{'" )
			reader.next_line()
			return end_frame()

		this_frame.step_num = 1

	# Field Declaration
	while true:
		token = get_token( reader )
		if token.type == TokenType.EOF: return end_frame(false)
		if token.type == TokenType.IDENT: parse_field_decl( token )
		if token.get('t') == '}': return end_frame()


func parse_enum_decl( token : Dictionary ):
	var this_frame = start_frame( Context.ENUM_DECL )
	syntax_error( token, "Unimplemented")
	reader.next_line()
	return end_frame()

	#enum_decl = ( enum ident : type | union ident ) metadata { commasep( enumval_decl ) }
	token =  get_token(reader)
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
		parse_metadata( token )
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
	stack.pop_back()

func parse_root_decl( token : Dictionary ):
	var this_frame = start_frame( Context.ROOT_DECL )
	syntax_error( token, "Unimplemented")
	reader.next_line()
	return end_frame()

func parse_field_decl( token : Dictionary ):
	var this_frame = start_frame( Context.FIELD_DECL )
	# field_decl = ident : type [ = scalar ] metadata ;
	#ident

	# The token given will already be the identity
	if token.type != TokenType.IDENT:
		syntax_error( token, "Wanted TokenType.IDENT" )
		reader.next_line()
		return end_frame()

	token = get_token( reader )
	if token.t != ':':
		syntax_error( token, "missing colon separator" )
		reader.next_line()
		return end_frame()

	token = get_token( reader )
	if token.type != TokenType.TYPE:
		syntax_error( token, "Wanted TokenType.TYPE" )
		reader.next_line()
		return end_frame()

	token = get_token( reader )
	if token.t == ';': return end_frame()
	if token.t == '=':
		token = get_token( reader )
		if token.type == TokenType.SCALAR:
			token = get_token(reader)
		else:
			syntax_error( token, "Wanted TokenType.SCALAR" )
			reader.next_line()
			return end_frame()

	if token.t == ';': return end_frame()
	parse_metadata( token )

	get_token(reader)
	if token.t == ';': return end_frame()
	syntax_error( token, "wanted semicolon" )
	reader.next_line()
	return end_frame()


func parse_rpc_decl( token : Dictionary ):
	var this_frame = start_frame( Context.RPC_DECL )
	syntax_error( token, "Unimplemented")
	reader.next_line()
	return end_frame()

func parse_rpc_method( token : Dictionary ):
	var this_frame = start_frame( Context.RPC_METHOD )
	syntax_error( token, "Unimplemented")
	reader.next_line()
	return end_frame()

func parse_type( token : Dictionary ):
	current_frame = ParseFrame.new( Context.TYPE )
	stack.push_back( current_frame )
	stack.pop_back()

func parse_enumval_decl( token : Dictionary ):
	current_frame = ParseFrame.new( Context.ENUMVAL_DECL )
	stack.push_back( current_frame )
	stack.pop_back()

func parse_metadata( token : Dictionary ):
	var this_frame = start_frame( Context.METADATA )
	syntax_error( token, "Unimplemented")
	reader.next_line()
	return end_frame()
	#metadata = [ ( commasep( ident [ : single_value ] ) ) ]
	#commasep(x) = [ x ( , x )* ]
	#ident = [a-zA-Z_][a-zA-Z0-9_]*
	#single_value = scalar | string_constant
	token =  get_token(reader)
	while not token['t'] == ')' and not reader.at_end():
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
	stack.pop_back()

func parse_scalar( token : Dictionary ):
	current_frame = ParseFrame.new( Context.SCALAR )
	stack.push_back( current_frame )
	stack.pop_back()

func parse_object( token : Dictionary ):
	current_frame = ParseFrame.new( Context.OBJECT )
	stack.push_back( current_frame )
	stack.pop_back()

func parse_single_value( token : Dictionary ):
	current_frame = ParseFrame.new( Context.SINGLE_VALUE )
	stack.push_back( current_frame )
	stack.pop_back()

func parse_value( token : Dictionary ):
	current_frame = ParseFrame.new( Context.VALUE )
	stack.push_back( current_frame )
	stack.pop_back()

func parse_commasep( token : Dictionary ):
	current_frame = ParseFrame.new( Context.COMMASEP )
	stack.push_back( current_frame )
	stack.pop_back()

func parse_file_extension_decl( token : Dictionary ):
	current_frame = ParseFrame.new( Context.FILE_EXTENSION_DECL )
	stack.push_back( current_frame )
	stack.pop_back()

func parse_file_identifier_decl( token : Dictionary ):
	current_frame = ParseFrame.new( Context.FILE_IDENTIFIER_DECL )
	stack.push_back( current_frame )
	stack.pop_back()

func parse_string_constant( token : Dictionary ):
	current_frame = ParseFrame.new( Context.STRING_CONSTANT )
	stack.push_back( current_frame )
	stack.pop_back()

func parse_ident( token : Dictionary ):
	current_frame = ParseFrame.new( Context.IDENT )
	stack.push_back( current_frame )
	stack.pop_back()

func parse_digit( token : Dictionary ):
	current_frame = ParseFrame.new( Context.DIGIT )
	stack.push_back( current_frame )
	stack.pop_back()

func parse_xdigit( token : Dictionary ):
	current_frame = ParseFrame.new( Context.XDIGIT )
	stack.push_back( current_frame )
	stack.pop_back()

func parse_dec_integer_constant( token : Dictionary ):
	current_frame = ParseFrame.new( Context.DEC_INTEGER_CONSTANT )
	stack.push_back( current_frame )
	stack.pop_back()

func parse_hex_integer_constant( token : Dictionary ):
	current_frame = ParseFrame.new( Context.HEX_INTEGER_CONSTANT )
	stack.push_back( current_frame )
	stack.pop_back()

func parse_integer_constant( token : Dictionary ):
	current_frame = ParseFrame.new( Context.INTEGER_CONSTANT )
	stack.push_back( current_frame )
	stack.pop_back()

func parse_dec_float_constant( token : Dictionary ):
	current_frame = ParseFrame.new( Context.DEC_FLOAT_CONSTANT )
	stack.push_back( current_frame )
	stack.pop_back()

func parse_hex_float_constant( token : Dictionary ):
	current_frame = ParseFrame.new( Context.HEX_FLOAT_CONSTANT )
	stack.push_back( current_frame )
	stack.pop_back()

func parse_special_float_constant( token : Dictionary ):
	current_frame = ParseFrame.new( Context.SPECIAL_FLOAT_CONSTANT )
	stack.push_back( current_frame )
	stack.pop_back()

func parse_float_constant( token : Dictionary ):
	current_frame = ParseFrame.new( Context.FLOAT_CONSTANT )
	stack.push_back( current_frame )
	stack.pop_back()

func parse_boolean_constant( token : Dictionary ):
	current_frame = ParseFrame.new( Context.BOOLEAN_CONSTANT )
	stack.push_back( current_frame )
	stack.pop_back()

#  ██████  ██      ██████      ███████ ████████ ██    ██ ███████ ███████
# ██    ██ ██      ██   ██     ██         ██    ██    ██ ██      ██
# ██    ██ ██      ██   ██     ███████    ██    ██    ██ █████   █████
# ██    ██ ██      ██   ██          ██    ██    ██    ██ ██      ██
#  ██████  ███████ ██████      ███████    ██     ██████  ██      ██

func parse_union_decl():
	#enum_decl = ( enum ident : type | union ident ) metadata { commasep( enumval_decl ) }
	var token = get_token(reader)
	if token.get('type') != TokenType.IDENT: syntax_error(token, "wanted ident")
	user_types.append( token.get('t') )
	color_default()

	token = get_token(reader)

	# Optional Metadata
	if token['t'] == '(':
		parse_metadata( token )
		color_default()
		token =  get_token(reader)

	if token.get('t') != '{': syntax_error(token, "wanted '{'")

	token =  get_token(reader)
	#enumval_decl = ident [ = integer_constant ]
	while token.get('t') != '}':
		if not is_type(token.get('t')): syntax_error(token, "wanted type(highligher:464)")
		color_default()
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
