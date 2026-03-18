extends State

class_name HaulState

var inventory: PawnInventory
var job: Job
var character: CharacterBody2D

var next_item_exists: bool = false

func enter(_msg: Dictionary = {}):
	character = state_machine.get_parent()
	
	inventory = character.character_inventory
	job = character.current_job
	
	do_haul()
	


func do_haul():
	if inventory.is_inventory_empty() or next_item_exists:
		var ground_item = ItemManager.get_item_at(job.target_map_pos)
		
		next_item_exists = false
		
		if ground_item == null:
			if inventory.item_amount > 0:
				pass
			
			else:
				JobManager.abort_job(job)
				character.next_state_after_move = ""
				character.current_job = null
				state_machine.change_state("IdleState")
				return
		
		else:
			var leftover = inventory.collect_items(ground_item["type"], ground_item["amount"])
			
			if leftover > 0:
				ground_item["amount"] = leftover
				ground_item["node"].disp_amount(leftover)
			elif ground_item.has("node"):
				ground_item["node"].queue_free()
				ItemManager.grid_items.erase(job.target_map_pos)
				JobManager.abort_haul_job_coords(job.target_map_pos)
		
		if inventory.item_amount < inventory.max_capacity:
			var curr_cell = Global.current_map.terrain_layer.local_to_map(character.global_position)
			var next_item_coords = ItemManager.get_closest_item(curr_cell, inventory.carried_item)
			var job_exists: Job
			if next_item_coords != null:
				job_exists = JobManager.check_job(next_item_coords)
			
			if next_item_coords != null and job_exists != null:
				job.target_map_pos = next_item_coords
				character.move_target = Global.current_map.terrain_layer.map_to_local(next_item_coords)
				next_item_exists = true
				state_machine.change_state("MoveState")
				return
			else: next_item_exists = false
		
		var drop_pos = ZoneManager.get_available_stockpile_cell(inventory.carried_item)
		
		if drop_pos != null:
			job.target_map_pos = drop_pos
			character.move_target = Global.current_map.terrain_layer.map_to_local(drop_pos)
			state_machine.change_state("MoveState")
		else:
			var my_pos = Global.current_map.terrain_layer.local_to_map(character.global_position)
			ItemManager.add_item_to_grid(
				my_pos, 
				inventory.carried_item, 
				inventory.item_amount, 
				Global.current_map.item_layer, 
				Global.current_map.item_drop, 
				Global.current_map.terrain_layer.map_to_local
			)
			inventory.clear_inventory()
			JobManager.suspend_job(job)
			character.current_job = null
			character.next_state_after_move = ""
			state_machine.change_state("IdleState") 
	else:
		var target_cell = job.target_map_pos
		var cell_item = ItemManager.get_item_at(target_cell)
		var stack_limit = 75
		
		if cell_item != null and cell_item["type"] != inventory.carried_item:
			find_new_stockpile_cell(character, job)
			return
		
		var space_left = stack_limit
		if cell_item != null:
			space_left = stack_limit - cell_item["amount"]
		
		if space_left <= 0:
			find_new_stockpile_cell(character, job)
			return
		
		var drop_amount = min(inventory.item_amount, space_left)
		var leftover = inventory.item_amount - drop_amount
		
		ItemManager.add_item_to_grid(target_cell, inventory.carried_item, drop_amount,
		Global.current_map.item_layer, Global.current_map.item_drop, Global.current_map.terrain_layer.map_to_local
		)
		
		inventory.item_amount = leftover
		
		var remaining_cell_cap = space_left - drop_amount
		
		if remaining_cell_cap > 0:
			JobManager.wake_up_jobs_for_type(inventory.carried_item, remaining_cell_cap)
		
		if inventory.item_amount <= 0:
			inventory.clear_inventory()
			JobManager.complete_job(job)
			character.next_state_after_move = ""
			character.current_job = null
			state_machine.change_state("IdleState")
		else:
			find_new_stockpile_cell(character, job)

func find_new_stockpile_cell(_character: CharacterBody2D, _job: Job):
	var new_drop_pos = ZoneManager.get_available_stockpile_cell(inventory.carried_item)
	
	if new_drop_pos != null:
		job.target_map_pos = new_drop_pos
		character.move_target = Global.current_map.terrain_layer.map_to_local(new_drop_pos)
		state_machine.change_state("MoveState")
	else:
		var curr_grid_pos = Global.current_map.terrain_layer.local_to_map(character.global_position)
		ItemManager.add_item_to_grid(curr_grid_pos, inventory.carried_item, inventory.item_amount,
		Global.current_map.item_layer,
		Global.current_map.item_drop,
		Global.current_map.terrain_layer.map_to_local
		)
		
		inventory.clear_inventory()
		JobManager.suspend_job(job)
		character.next_state_after_move = ""
		character.current_job = null
		state_machine.change_state("IdleState")
