@tool
extends EditorScript

var pp : PP = PP.new()

func _run() -> void:
	print("Creating and Writing Orc FlatBuffers")

	# Create a `FlatBufferBuilder`, which will be used to create our
	# monsters' FlatBuffers.
	var builder := FlatBufferBuilder.create(1024)

	var weapon_one_name := builder.create_string("Sword")
	var weapon_one_damage = 3

	var weapon_two_name := builder.create_string("Axe")
	var weapon_two_damage = 5;

	# Use the `CreateWeapon` shortcut to create Weapons with all the fields set.
	var sword = Monster.CreateWeapon( builder, weapon_one_name, weapon_one_damage )
	var axe = Monster.CreateWeapon( builder, weapon_two_name, weapon_two_damage )

	# Serialize a name for our monster, called "Orc".
	var name = builder.create_string("Orc")

	# Create a `vector` representing the inventory of the Orc. Each number
	# could correspond to an item that can be claimed after he is slain.
	var treasure : Array = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
	var inventory = builder.create_vector( treasure, 10 )

	# Place the weapons into a `std::vector`, then convert that into a FlatBuffer `vector`.
	var weapons_vector : Array
	weapons_vector.push_back( sword )
	weapons_vector.push_back( axe )
	var weapons = builder.create_vector( weapons_vector )

	var points : Array[Vec3] = [ Vec3(1.0, 2.0, 3.0), Vec3(4.0, 5.0, 6.0) ]
	var path = builder.CreateVectorOfStructs( points, 2 )


	# Create the position struct
	var position = Vec3(1.0, 2.0, 3.0)

	# Set his hit points to 300 and his mana to 150.
	var hp : int = 300
	var mana : int = 150

	# Finally, create the monster using the `CreateMonster` helper function
	# to set all fields.
	var orc = Monster.CreateMonster(
		builder,
		position,
		mana,
		hp,
		name,
		inventory,
		Monster.Color_.RED,
		weapons,
		Monster.Equipment.WEAPON,
		axe.Union(),
		path)


	# Alternate creation method
	# You can use this code instead of `CreateMonster()`, to create our orc
	# manually.
	#var monster_builder := MonsterBuilder.new( builder )
	#monster_builder.add_pos( position )
	#monster_builder.add_hp( hp )
	#monster_builder.add_name( name )
	#monster_builder.add_inventory( inventory )
	#monster_builder.add_color( Color_Red )
	#monster_builder.add_weapons( weapons )
	#monster_builder.add_equipped_type( Equipment_Weapon )
	#monster_builder.add_equipped( axe.Union() )
	#var orc = monster_builder.finish()

	# Call `Finish()` to instruct the builder that this monster is complete.
	# Note: Regardless of how you created the `orc`, you still need to call
	# `Finish()` on the `FlatBufferBuilder`.
	builder.finish( orc ) # You could also call `FinishMonsterBuffer(builder, orc);`.

