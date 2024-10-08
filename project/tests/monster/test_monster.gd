@tool
extends TestBase

const schema = preload('./Monster_generated.gd')

#region == Testing Setup ==
# testing variables

var test_object
#endregion

func _run() -> void:
	# Setup Persistent data
	# ...

	# Generate the flatbuffer using the three methods of creations
	example_reading( example_creating() )
	#reconstruct( manual() )
	#reconstruct( create() )
	#reconstruct( create2() )
	if not silent:
		print_rich( "\n[b]== Monster ==[/b]\n" )
		for o in output: print( o )


#  ██████ ██████  ███████  █████  ████████ ██ ███    ██  ██████
# ██      ██   ██ ██      ██   ██    ██    ██ ████   ██ ██
# ██      ██████  █████   ███████    ██    ██ ██ ██  ██ ██   ███
# ██      ██   ██ ██      ██   ██    ██    ██ ██  ██ ██ ██    ██
#  ██████ ██   ██ ███████ ██   ██    ██    ██ ██   ████  ██████
func example_creating() -> PackedByteArray:
# Creating and Writing Orc FlatBuffers
#
# The first step is to import/include the library, generated files, etc.
# #include "monster_generated.h" // This was generated by `flatc`.
#
# using namespace MyGame::Sample; // Specified in the schema.
#
# Now we are ready to start building some buffers. In order to start, we need
# to create an instance of the FlatBufferBuilder, which will contain the buffer
# as it grows. You can pass an initial size of the buffer (here 1024 bytes),
# which will grow automatically if needed:
# // Create a `FlatBufferBuilder`, which will be used to create our
# // monsters' FlatBuffers.
# flatbuffers::FlatBufferBuilder builder(1024);
	var builder := FlatBufferBuilder.create(1024)
#
# After creating the builder, we can start serializing our data. Before we make
# our orc Monster, let's create some Weapons: a Sword and an Axe.
# auto weapon_one_name = builder.CreateString("Sword");
	var weapon_one_name = builder.create_String( "Sword" )
# short weapon_one_damage = 3;
	var weapon_one_damage = 3
#
# auto weapon_two_name = builder.CreateString("Axe");
	var weapon_two_name = builder.create_String( "Axe" )
# short weapon_two_damage = 5;
	var weapon_two_damage = 5
#
# // Use the `CreateWeapon` shortcut to create Weapons with all the fields set.
# auto sword = CreateWeapon(builder, weapon_one_name, weapon_one_damage);
	var sword = schema.CreateWeapon( builder, weapon_one_name, weapon_one_damage )
# auto axe = CreateWeapon(builder, weapon_two_name, weapon_two_damage);
	var axe = schema.CreateWeapon( builder, weapon_two_name, weapon_two_damage )
#
# Now let's create our monster, the orc. For this orc, lets make him red with
# rage, positioned at (1.0, 2.0, 3.0), and give him a large pool of hit points
# with 300. We can give him a vector of weapons to choose from (our Sword and
# Axe from earlier). In this case, we will equip him with the Axe, since it is
# the most powerful of the two. Lastly, let's fill his inventory with some
# potential treasures that can be taken once he is defeated.
#
# Before we serialize a monster, we need to first serialize any objects that
# are contained therein, i.e. we serialize the data tree using depth-first,
# pre-order traversal. This is generally easy to do on any tree structures.
# // Serialize a name for our monster, called "Orc".
# auto name = builder.CreateString("Orc");
	var name = builder.create_String("Orc")
#
# // Create a `vector` representing the inventory of the Orc. Each number
# // could correspond to an item that can be claimed after he is slain.
# unsigned char treasure[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
	var treasure : PackedByteArray = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
# auto inventory = builder.CreateVector(treasure, 10);
	var inventory = builder.create_vector_uint8( treasure )
#
# We serialized two built-in data types (string and vector) and captured their
# return values. These values are offsets into the serialized data, indicating
# where they are stored, such that we can refer to them below when adding
# fields to our monster.
#
# Note: To create a vector of nested objects (e.g. tables, strings, or other
# vectors), collect their offsets into a temporary data structure, and then
# create an additional vector containing their offsets.
#
# If instead of creating a vector from an existing array you serialize elements
# individually one by one, take care to note that this happens in reverse
# order, as buffers are built back to front.
#
# For example, take a look at the two Weapons that we created earlier (Sword
# and Axe). These are both FlatBuffer tables, whose offsets we now store in
# memory. Therefore we can create a FlatBuffer vector to contain these offsets.
# // Place the weapons into a `std::vector`, then convert that into a FlatBuffer `vector`.
# std::vector<flatbuffers::Offset<Weapon>> weapons_vector;
	var weapons_vector : Array
# weapons_vector.push_back(sword);
	weapons_vector.push_back(sword)
# weapons_vector.push_back(axe);
	weapons_vector.push_back(axe)

# auto weapons = builder.CreateVector(weapons_vector);
	var weapons = builder.create_vector_offset( weapons_vector )
#
#
# Note there are additional convenience overloads of CreateVector, allowing you
# to work with data that's not in a std::vector or allowing you to generate
# elements by calling a lambda. For the common case of std::vector<std::string>
# there's also CreateVectorOfStrings.
#
# Note that vectors of structs are serialized differently from tables, since
# structs are stored in-line in the vector. For example, to create a vector for
# the path field above:
# Vec3 points[] = { Vec3(1.0f, 2.0f, 3.0f), Vec3(4.0f, 5.0f, 6.0f) };
	var _points : Array # FIXME, I havent figured this part out yet

# auto path = builder.CreateVectorOfStructs(points, 2);
	var path = 0# FIXME  = builder.create_vector_ ??
#
# We have now serialized the non-scalar components of the orc, so we can
# serialize the monster itself:
# // Create the position struct
# auto position = Vec3(1.0f, 2.0f, 3.0f);
	var position = schema.Vec3.new()
	position.x = 1.0
	position.y = 2.0
	position.z = 3.0
#
# // Set his hit points to 300 and his mana to 150.
# int hp = 300;
	var hp = 300
# int mana = 150;
	var mana = 150
#
# // Finally, create the monster using the `CreateMonster` helper function
# // to set all fields.
# auto orc = CreateMonster(builder, &position, mana, hp, name, inventory,
#                         Color_Red, weapons, Equipment_Weapon, axe.Union(),
#                         path);
	var orc = schema.CreateMonster( builder, position, mana, hp, name, inventory,
							schema.Color_.RED, weapons, schema.Equipment.WEAPON, axe,
							path )
#
# Note how we create Vec3 struct in-line in the table. Unlike tables, structs
# are simple combinations of scalars that are always stored inline, just like
# scalars themselves.
#
# Important: Unlike structs, you should not nest tables or other objects, which
# is why we created all the strings/vectors/tables that this monster refers to
# before start. If you try to create any of them between start and end, you
# will get an assert/exception/panic depending on your language.
#
# Note: Since we are passing 150 as the mana field, which happens to be the
# default value, the field will not actually be written to the buffer, since
# the default value will be returned on query anyway. This is a nice space
# savings, especially if default values are common in your data. It also means
# that you do not need to be worried about adding a lot of fields that are only
# used in a small number of instances, as it will not bloat the buffer if
# unused.
#
# If you do not wish to set every field in a table, it may be more convenient
# to manually set each field of your monster, instead of calling
# CreateMonster(). The following snippet is functionally equivalent to the
# above code, but provides a bit more flexibility.
# // You can use this code instead of `CreateMonster()`, to create our orc
# // manually.
# MonsterBuilder monster_builder(builder);
	#NOTE var monster_builder = schema.MonsterBuilder.new( builder )
# monster_builder.add_pos(&position);
	#NOTE monster_builder.add_pos( position )
# monster_builder.add_hp(hp);
	#NOTE monster_builder.add_hp(hp)
# monster_builder.add_name(name);
	#NOTE monster_builder.add_name(name)
# monster_builder.add_inventory(inventory);
	#NOTE monster_builder.add_inventory(inventory)
# monster_builder.add_color(Color_Red);
	#NOTE monster_builder.add_color(schema.Color_.RED)
# monster_builder.add_weapons(weapons);
	#NOTE monster_builder.add_weapons(weapons)
# monster_builder.add_equipped_type(Equipment_Weapon);
	#NOTE monster_builder.add_equipped_type(schema.Equipment.WEAPON)
# monster_builder.add_equipped(axe.Union());
	#NOTE monster_builder.add_equipped(axe)
# auto orc = monster_builder.Finish();
	#NOTE var orc = monster_builder.finish()

#
# Before finishing the serialization, let's take a quick look at FlatBuffer
# union Equipped. There are two parts to each FlatBuffer union. The first is a
# hidden field _type that is generated to hold the type of table referred to by
# the union. This allows you to know which type to cast to at runtime. Second
# is the union's data.
#
# In our example, the last two things we added to our Monster were the Equipped
# Type and the Equipped union itself.
#
# Here is a repetition of these lines, to help highlight them more clearly:
# monster_builder.add_equipped_type(Equipment_Weapon); // Union type
	# NOTE monster_builder.add_equipped_type( schema.Equipment.WEAPON ) # Union type
# monster_builder.add_equipped(axe.Union()); // Union data
	# NOTE monster_builder.add_equipped( axe ) # Union data
#
# After you have created your buffer, you will have the offset to the root of
# the data in the orc variable, so you can finish the buffer by calling the
# appropriate finish method.
# // Call `Finish()` to instruct the builder that this monster is complete.
# // Note: Regardless of how you created the `orc`, you still need to call
# // `Finish()` on the `FlatBufferBuilder`.
# builder.Finish(orc); // You could also call `FinishMonsterBuffer(builder, orc);`.
	builder.finish( orc ) # You could also call `schema.FinishMonsterBuffer(builder, orc);`.
	# FIXME missing function schema.FinishMonsterBuffer( builder, orc )
#
# The buffer is now ready to be stored somewhere, sent over the network, be
# compressed, or whatever you'd like to do with it. You can access the buffer
# like so:
# // This must be called after `Finish()`.
# uint8_t *buf = builder.GetBufferPointer();
	var buf = builder.to_packed_byte_array()
# int size = builder.GetSize(); // Returns the size of the buffer that
#                               // `GetBufferPointer()` points to.
	var _size = builder.get_size()
#
# Now you can write the bytes to a file or send them over the network. Make
# sure your file mode (or transfer protocol) is set to BINARY, not text. If you
# transfer a FlatBuffer in text mode, the buffer will be corrupted, which will
# lead to hard to find problems when you read the buffer.

	return buf

func example_reading( buffer : PackedByteArray ):

# ██████  ███████  █████  ██████  ██ ███    ██  ██████
# ██   ██ ██      ██   ██ ██   ██ ██ ████   ██ ██
# ██████  █████   ███████ ██   ██ ██ ██ ██  ██ ██   ███
# ██   ██ ██      ██   ██ ██   ██ ██ ██  ██ ██ ██    ██
# ██   ██ ███████ ██   ██ ██████  ██ ██   ████  ██████

# Reading Orc FlatBuffers
#
# Now that we have successfully created an Orc FlatBuffer, the monster data can
# be saved, sent over a network, etc. Let's now adventure into the inverse, and
# access a FlatBuffer.
#
# This section requires the same import/include, namespace, etc. requirements as before:
# #include "monster_generated.h" // This was generated by `flatc`.
#
# using namespace MyGame::Sample; // Specified in the schema.
#
# Then, assuming you have a buffer of bytes received from disk, network, etc.,
# you can start accessing the buffer like so:
#
# Again, make sure you read the bytes in BINARY mode, otherwise the code below
# won't work.
# uint8_t *buffer_pointer = /* the data you just read */;
#
# // Get a pointer to the root object inside the buffer.
# auto monster = GetMonster(buffer_pointer);
	var monster = schema.GetMonster( buffer )
	output.append( "monster: " + JSON.stringify( monster.debug(), '\t', false ) )
#
# // `monster` is of type `Monster *`.
# // Note: root object pointers are NOT the same as `buffer_pointer`.
# // `GetMonster` is a convenience function that calls `GetRoot<Monster>`,
# // the latter is also available for non-root types.
#
# If you look in the generated files from the schema compiler, you will see it
# generated accessors for all non-deprecated fields. For example:
# auto hp = monster->hp();
	var hp = monster.hp()
# auto mana = monster->mana();
	var mana = monster.mana()
# auto name = monster->name()->c_str();
	var name = monster.name()
#
# These should hold 300, 150, and "Orc" respectively.
	TEST_EQ( hp, 300, "monster.hp()" )
	TEST_EQ( mana, 150, "monster.mana()" )
	TEST_EQ( name, "Orc", "monster.name()" )
#
# Note: The default value 150 wasn't stored in mana, but we are still able to
# retrieve it.
#
# To access sub-objects, in the case of our pos, which is a Vec3:
# auto pos = monster->pos();
	var pos : schema.Vec3 = monster.pos()
# auto x = pos->x();
	var x = pos.x
# auto y = pos->y();
	var y = pos.y
# auto z = pos->z();
	var z = pos.z
#
# x, y, and z will contain 1.0, 2.0, and 3.0, respectively.
	TEST_EQ( x, 1.0, "monster.pos.x()" )
	TEST_EQ( y, 2.0, "monster.pos.y()" )
	TEST_EQ( z, 3.0, "monster.pos.z()" )
#
# Note: Had we not set pos during serialization, it would be a null-value.
#
# Similarly, we can access elements of the inventory vector by indexing it. You
# can also iterate over the length of the array/vector representing the
# FlatBuffers vector.
# auto inv = monster->inventory(); // A pointer to a `flatbuffers::Vector<>`.
	var inv = monster.inventory()
# auto inv_len = inv->size();
	var _inv_len = inv.size()
	# NOTE: monster.inventory_size()
# auto third_item = inv->Get(2);
	var _third_item = inv[2]
	# NOTE: monster.inventory_at(2)
#
# For vectors of tables, you can access the elements like any other vector,
# except you need to handle the result as a FlatBuffer table:
# auto weapons = monster->weapons(); // A pointer to a `flatbuffers::Vector<>`.
	var weapons = monster.weapons()
# auto weapon_len = weapons->size();
	var _weapon_len = weapons.size()
# auto second_weapon_name = weapons->Get(1)->name()->str();
	var _second_weapon_name = weapons[1].name()
# auto second_weapon_damage = weapons->Get(1)->damage()
	var _second_weapon_damage = weapons[1].damage()
#
# Last, we can access our Equipped FlatBuffer union. Just like when we created
# the union, we need to get both parts of the union: the type and the data.
#
# We can access the type to dynamically cast the data as needed (since the
# union only stores a FlatBuffer table).
# auto union_type = monster.equipped_type();
	var union_type : schema.Equipment = monster.equipped_type()
#
# if (union_type == Equipment_Weapon) {
#   auto weapon = static_cast<const Weapon*>(monster->equipped()); // Requires `static_cast`
#                                                                  // to type `const Weapon*`.
#
#   auto weapon_name = weapon->name()->str(); // "Axe"
#   auto weapon_damage = weapon->damage();    // 5
# }
	match union_type:
		schema.Equipment.WEAPON:
			var weapon : schema.Weapon = monster.equipped()
			var weapon_name = weapon.name()
			var weapon_damage = weapon.damage()
			TEST_EQ( weapon_name, "Axe", "weapon_name" )
			TEST_EQ( weapon_damage, 5, "weapon_damage" )
	#NOTE, output of monster.equipped is a Variant, so it can be checked.
	#var equipment = monster.equipped()
	#if equipment is schema.Weapon:
		#var weapon_name = equipment.name()
		#var weapon_damage = equipment.damage()



func reconstruct( buffer : PackedByteArray ):
	var root_table : FlatBuffer = schema.GetRoot( buffer )
	output.append( "root_table: " + JSON.stringify( root_table.debug(), '\t', false ) )

	# Perform testing on the reconstructed flatbuffer.
	#TEST_EQ( <value>, <value>, "Test description if failed")
