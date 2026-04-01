extends State

class_name DeliverMaterialState

var character: PawnPrototype
var char_inventory: PawnInventory
var char_memory

func enter(_msg: Dictionary = {}):
	character = state_machine.get_parent()
	char_inventory = character.character_inventory
	char_memory = character.memory
	
	var job: Job = character.current_job
	if job == null:
		character.next_state_after_move = ""
		state_machine.change_state("IdleState")
		return
	var bp: BluePrint
	
	if BuildManager.active_blueprints.has(job.target_map_pos):
		bp = BuildManager.active_blueprints.get(job.target_map_pos)
	
	if bp == null:
		print("blueprint yok")
		JobManager.abort_job(job)
		character.current_job = null
		state_machine.change_state("IdleState")
		return
	
	var current_cell = Global.current_map.terrain_layer.local_to_map(character.global_position)
	if char_inventory.item_amount == 0:
		if current_cell == char_memory.item_pickup_pos:
			var take_amount = char_memory.reserved_amount
			var target_mat = char_memory.target_material
			
			var ground_item = ItemManager.get_item_at(current_cell)
			
			if ground_item == null:
				if bp.progress.has(target_mat):
					bp.progress[target_mat]["incoming"] -= take_amount
					if bp.progress[target_mat]["incoming"] < 0:
						bp.progress[target_mat]["incoming"] = 0
				
				job.worker = null
				job.is_taken = false
				
				character.current_job = null
				character.next_state_after_move = ""
				
				state_machine.change_state("IdleState")
				return
			ZoneManager.stockpile_item_consumed.emit(take_amount, target_mat)
			ItemManager.consume_item(current_cell, take_amount)
			
			char_inventory.carried_item = target_mat
			char_inventory.item_amount = take_amount
			
			character.move_target = Global.current_map.terrain_layer.map_to_local(bp.coords)
			character.next_state_after_move = "DeliverMaterialState"
			state_machine.change_state("MoveState")
			return
			
		
		var needed_materials = bp.get_material_needs()
		var selected_material = ""
		var closest_coords = null
		
		#print(needed_materials)
		
		for material in needed_materials:
			var char_cell = Global.current_map.terrain_layer.local_to_map(character.global_position)
			var coords = ItemManager.get_closest_item(char_cell, material)
			if coords != null:
				closest_coords = coords
				selected_material = material
				break
		
		if closest_coords == null or selected_material == "":
			job.worker = null
			job.is_taken = false
			#print("koordinat bulunmadı")
			JobManager.suspend_job(job)
			character.current_job = null
			character.next_state_after_move = ""
			state_machine.change_state("IdleState")
			return
		
		
		var ground_item = ItemManager.get_item_at(closest_coords)
		
		var needed = bp.get_remaining_needs(selected_material)
		var available = ground_item["amount"]
		var carry_cap = char_inventory.max_capacity
		
		var amount_to_take = min(needed, min(available, carry_cap))
		
		bp.progress[selected_material]["incoming"] += amount_to_take
		
		character.memory.reserved_amount = amount_to_take
		character.memory.item_pickup_pos = closest_coords
		character.memory.target_material = selected_material
		
		character.move_target = Global.current_map.terrain_layer.map_to_local(closest_coords)
		character.next_state_after_move = "DeliverMaterialState"
		state_machine.change_state("MoveState")
		
	else:
		var dirs = [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.ZERO]
		var is_adjacent = false
		var footprint = bp.get_occupied_tiles()
		for tile in footprint:
			var dist_x = abs(current_cell.x - tile.x)
			var dist_y = abs(current_cell.y - tile.y)
			
			if dist_x <= 1 and dist_y <= 1:
				is_adjacent = true
				break
		
		if is_adjacent:
			var drop_amount = char_inventory.item_amount
			var drop_mat = char_inventory.carried_item
			
			BuildManager.add_materials_to_blueprint(bp.coords, drop_mat, drop_amount)
			
			char_inventory.clear_inventory()
			
			if bp.is_ready_to_build():
				JobManager.complete_job(job)
				JobManager.post_job(Job.Type.BUILD_STRUCTURE, bp.coords, Global.current_map.terrain_layer.map_to_local(bp.coords), 0)
			else:
				job.worker = null
				job.is_taken = false
			character.current_job = null
			character.next_state_after_move = ""
			state_machine.change_state("IdleState")
		else:
			var target_pos = bp.coords
			var found_walkable = false
			
			for tile in footprint:
				var neighbors = [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]
				for offset in neighbors:
					var neighbor = tile + offset
					
					if Global.current_map.is_within_bounds(neighbor.x, neighbor.y):
						target_pos = neighbor
						found_walkable = true
						break
				
				if found_walkable:
					break
				
			
			character.move_target = Global.current_map.terrain_layer.map_to_local(target_pos)
			character.next_state_after_move = "DeliverMaterialState"
			state_machine.change_state("MoveState")
