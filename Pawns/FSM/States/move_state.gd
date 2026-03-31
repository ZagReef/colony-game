extends State

class_name MoveState

var current_path: PackedVector2Array
var current_path_index: int = 0

@export var default_move_speed: int = 150
var current_move_speed = default_move_speed

var character: PawnPrototype

func enter(_msg: Dictionary = {}):
	#print("Move state aktif")
	character = state_machine.get_parent()
	var target = character.move_target
	var path_finder = Pathfinder
	
	current_path = path_finder.get_astar_path(character.global_position, target)
	current_path_index = 0
	
	if character.next_state_after_move == "MineState":
		#print(current_path)
		pass
	
	if not current_path.is_empty():
		draw_debug_path(current_path) # <--- YOLU ÇİZ
	
	if current_path.is_empty():
		"""if character.current_job:
			print("HATA: ", character.name, " yol bulamadı! Hedef: ", character.current_job.target_map_pos)"""
		
		var current_cell = Global.current_map.terrain_layer.local_to_map(character.global_position)
		var target_cell = Global.current_map.terrain_layer.local_to_map(target)
		
		if current_cell == target_cell:
			if character.next_state_after_move != "":
				state_machine.change_state(character.next_state_after_move)
			else:
				state_machine.change_state("IdleState")
			return
		
		var char_job = character.current_job
		if char_job:
			if char_job.job_type == Job.Type.DELIVER_MATERIAL:
				var bp_coords = char_job.target_map_pos
				if BuildManager.active_blueprints.has(bp_coords):
					var bp: BluePrint =  BuildManager.active_blueprints[bp_coords]
					var mat = character.memory.target_material
					var amount = character.memory.reserved_amount
					if bp.progress.has(mat):
						bp.progress[mat]["incoming"] -= amount
						if bp.progress[mat]["incoming"] < 0:
							bp.progress[mat]["incoming"] = 0
					
			char_job.worker_black_list.append(character)
			char_job.is_taken = false
			character.current_job.worker = null
			character.current_job = null
		
		if character.character_inventory and not character.character_inventory.is_inventory_empty():
			var curr_grid = Global.current_map.terrain_layer.local_to_map(character.global_position)
			ItemManager.add_item_to_grid(
				curr_grid, 
				character.character_inventory.carried_item, 
				character.character_inventory.item_amount, 
				Global.current_map.item_layer, 
				Global.current_map.item_drop, 
				Global.current_map.terrain_layer.map_to_local
			)
			character.character_inventory.clear_inventory()
			
		character.next_state_after_move = ""
		state_machine.change_state("IdleState") 
		return

func physics_update(_delta: float):
	if current_path.is_empty() or current_path_index >= current_path.size():
		character.velocity = Vector2.ZERO
		#print(current_path.size())
		
		if character.next_state_after_move != "":
			state_machine.change_state(character.next_state_after_move)
		else:
			state_machine.change_state("IdleState")
		return
	
	var target_point = current_path[current_path_index]
	
	if character.global_position.distance_to(target_point) < 5.0:
		current_path_index += 1
		
		if current_path_index < current_path.size():
			var next_point = current_path[current_path_index]
			var target_coords =  Global.current_map.terrain_layer.local_to_map(Global.current_map.terrain_layer.to_local(next_point))
			if Global.current_map.is_within_bounds(target_coords.x, target_coords.y):
				var target_cell = Global.current_map.map_data[target_coords.y][target_coords.x] 
				current_move_speed = target_cell["speed_multiplier"] * default_move_speed
	else:
		character.velocity = character.global_position.direction_to(target_point) * current_move_speed * Global.sim_speed
		character.move_and_slide()

func exit():
	pass
	#print("move state'den çıkıldı ", character.next_state_after_move)


func draw_debug_path(path_array: PackedVector2Array):
	var line = Line2D.new()
	line.width = 3
	line.default_color = Color.DIM_GRAY
	line.points = path_array
	   # Çizgiyi sahneye ekle (Geçici olarak)
	get_tree().root.add_child(line)
		# 5 saniye sonra silinsin
	get_tree().create_timer(5.0 / Global.sim_speed).timeout.connect(line.queue_free)
