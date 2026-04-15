extends State

class_name HaulState

var inventory: PawnInventory
var job: Job
var character: PawnPrototype
var next_item_exists: bool = false

func enter(_msg: Dictionary = {}):
	character = state_machine.get_parent() as PawnPrototype
	
	inventory = character.character_inventory
	job = character.current_job
	
	do_haul()
	


func do_haul():
	if inventory.is_inventory_empty() or next_item_exists:
		var ground_variant: Variant = ItemManager.get_item_at(job.target_map_pos)
		
		var needs_lefover_job: bool = false
		var pickup_pos
		
		next_item_exists = false
		
		if ground_variant == null:
			if inventory.item_amount > 0:
				pass
			
			else:
				JobManager.abort_job(job)
				character.next_state_after_move = ""
				character.current_job = null
				state_machine.change_state("IdleState")
				return
		
		else:
			var ground_item: Dictionary = ground_variant as Dictionary
			var leftover = inventory.collect_items(ground_item["type"], ground_item["amount"])
			
			if leftover > 0:
				ground_item["amount"] = leftover
				ground_item["node"].disp_amount(leftover)
				
				if not ZoneManager.is_item_in_valid_stockpile(job.target_map_pos, ground_item["type"]):
					needs_lefover_job = true
					pickup_pos = job.target_map_pos
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
				character.next_state_after_move = "HaulState"
				next_item_exists = true
				state_machine.change_state("MoveState")
				return
			else: next_item_exists = false
		
		
		var drop_pos = ZoneManager.get_available_stockpile_cell(inventory.carried_item)
		
		if drop_pos != null:
			job.target_map_pos = drop_pos
			character.move_target = Global.current_map.terrain_layer.map_to_local(drop_pos)
			character.next_state_after_move = "HaulState"
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
			job.target_map_pos = my_pos
			JobManager.suspend_job(job)
			character.current_job = null
			character.next_state_after_move = ""
			state_machine.change_state("IdleState")
		if needs_lefover_job:
			JobManager.post_job(Job.Type.HAUL_ITEMS, pickup_pos, Global.current_map.terrain_layer.map_to_local(pickup_pos), 0) 
	else:
		var target_cell = Global.current_map.terrain_layer.local_to_map(character.global_position)
		var cell_variant: Variant = ItemManager.get_item_at(target_cell)
		var stack_limit = ItemManager.ITEM_DB[inventory.carried_item].max_stack
		var space_left = stack_limit
		
		if cell_variant != null:
			var cell_item: Dictionary = cell_variant as Dictionary
			if cell_item["type"] != inventory.carried_item:
				find_new_stockpile_cell(character, job)
				return
			
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
		#job.target_map_pos = new_drop_pos
		character.move_target = Global.current_map.terrain_layer.map_to_local(new_drop_pos)
		character.next_state_after_move = "HaulState"
		state_machine.change_state("MoveState")
	else:
		var curr_grid_pos = Global.current_map.terrain_layer.local_to_map(character.global_position)
		ItemManager.add_item_to_grid(curr_grid_pos, inventory.carried_item, inventory.item_amount,
		Global.current_map.item_layer,
		Global.current_map.item_drop,
		Global.current_map.terrain_layer.map_to_local
		)
		job.target_map_pos = curr_grid_pos
		inventory.clear_inventory()
		JobManager.suspend_job(job)
		character.next_state_after_move = ""
		character.current_job = null
		state_machine.change_state("IdleState")
