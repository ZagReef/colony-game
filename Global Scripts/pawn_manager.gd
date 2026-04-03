extends Node

var current_pawns: Array[PawnPrototype]
var curr_map: Node2D

const NPC: PackedScene = preload("res://Pawns/pawn_prot.tscn")

signal pawn_spawned(pawn: CharacterBody2D)
signal pawn_focus_requested(target_pawn: CharacterBody2D)
signal pawn_focus_cancelled(target_pawn: CharacterBody2D)

var char_textures: Array[Texture] = [
	load("res://Textures/Character Textures/rimworld_demongirl.png"),
	load("res://Textures/Character Textures/rimworld_buffedguy.png"),
	load("res://Textures/Character Textures/rimworld_characters.png"),
	load("res://Textures/Character Textures/jamal.png")
]

var count_npc: int = 4

func _ready() -> void:
	#Global.pressed_escape.connect(clear_pawns)
	pawn_focus_requested.connect(set_char_selection)
	Global.pawn_selected.connect(set_char_selection)
	pawn_focus_cancelled.connect(deselect_all_chars)


func spawn_pawns():
	curr_map = Global.current_map
	var walk_pos = Global.current_map.get_walk_pos()
	var y_sort = curr_map.get_node("Layers/Ysorted")
	count_npc = Global.start_pawn_count
	if walk_pos.is_empty():
		print("yürünebilir alan yok!")
		return
	for i in range(count_npc):
		var pos = walk_pos.pick_random()
		pos = curr_map.terrain_layer.map_to_local(pos)
		var new_npc = NPC.instantiate()
		new_npc.char_body_texture = char_textures.pick_random()
		new_npc.global_position = pos
		new_npc.z_index = 1
		y_sort.add_child(new_npc)
		current_pawns.append(new_npc)
		pawn_spawned.emit(new_npc)

func get_character_save_data() -> Array:
	var chars_save_array = []
	
	var all_pawns = current_pawns
	
	for pawn in all_pawns:
		var clean_data = {
			"pos_x": pawn.global_position.x,
			"pos_y": pawn.global_position.y,
			
			"carried_item": pawn.character_inventory.carried_item,
			"item_amount": pawn.character_inventory.item_amount,
			"texture": pawn.get_node("Sprite2D").texture.resource_path
		}
		
		chars_save_array.append(clean_data)
	return chars_save_array

func load_save_data(char_data_list: Array):
	for char_data in char_data_list:
		var new_pawn = NPC.instantiate()
		
		new_pawn.global_position = Vector2(char_data["pos_x"], char_data["pos_y"])
		
		get_tree().current_scene.get_node("Layers/Ysorted").add_child(new_pawn)
		
		new_pawn.char_body_texture = load(char_data["texture"])
		if new_pawn.char_body_texture == load("res://Textures/Character Textures/jamal.png"):
			new_pawn.char_name = "Jamal"
			new_pawn.label.text = "Jamal"
		new_pawn.get_node("Sprite2D").texture = new_pawn.char_body_texture
		
		new_pawn.character_inventory.carried_item = char_data["carried_item"]
		new_pawn.character_inventory.item_amount = char_data["item_amount"]
		
		current_pawns.append(new_pawn)
		pawn_spawned.emit(new_pawn)

func clear_pawns():
	current_pawns.clear()

func set_char_selection(pawn):
	for curr_pawn in current_pawns:
		if curr_pawn == pawn:
			if !curr_pawn.is_selected:
				curr_pawn.is_selected = true
				curr_pawn.char_body.self_modulate = Color(0.412, 0.412, 0.412, 1.0)
			elif curr_pawn.is_selected:
				curr_pawn.is_selected = false
				curr_pawn.char_body.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			if curr_pawn.is_selected:
				curr_pawn.is_selected = false
				curr_pawn.char_body.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

func deselect_all_chars():
	for pawn in current_pawns:
		if pawn in current_pawns:
			pawn.is_selected = false
			pawn.char_body.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
