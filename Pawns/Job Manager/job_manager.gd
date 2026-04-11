extends Node

var available_jobs: Array[Job] = []
var suspended_jobs: Array[Job] = []

func _ready():
	ItemManager.item_dropped_on_ground.connect(on_item_dropped)
	ZoneManager.new_stockpile_created.connect(on_stockpile_cell_opened)
	ZoneManager.stockpile_item_consumed.connect(_on_item_consumed)
	BuildManager.blueprint_created.connect(_on_bp_created)

func post_job(type: Job.Type, map_pos: Vector2i, world_pos: Vector2, priority: int = 0):
	var new_job = Job.new()
	new_job.target_map_pos = map_pos
	new_job.job_type = type
	
	
	for job in available_jobs:
		if new_job.target_map_pos == job.target_map_pos and new_job.job_type == job.job_type:
			return
	for job in suspended_jobs:
		if new_job.target_map_pos == job.target_map_pos and new_job.job_type == job.job_type:
			return
	new_job.job_type = type
	new_job.target_world_pos = world_pos
	new_job.priority = priority
	if type == Job.Type.HAUL_ITEMS and  !ItemManager.grid_items.has(map_pos):
		return
	
	if Global.is_loading_game and type == Job.Type.HAUL_ITEMS and ItemManager.grid_items.has(new_job.target_map_pos) and ZoneManager.get_available_stockpile_cell(ItemManager.grid_items[new_job.target_map_pos]["type"]) != null:
		suspended_jobs.append(new_job)
	else:
		available_jobs.append(new_job)
		available_jobs.sort_custom(func(a, b): return a.priority > b.priority)
	var tile_dict = Global.current_map.icons
	var tileset_id = Global.current_map.icon_tileset_id
	match new_job.job_type:
		Job.Type.WOOD_CUTTING:
			Global.current_map.icon_layer.set_cell(map_pos, tileset_id, tile_dict["wood_cut"])
		Job.Type.MINING:
			Global.current_map.icon_layer.set_cell(map_pos, tileset_id, tile_dict["mine"])
		Job.Type.BUILD_STRUCTURE:
			Global.current_map.icon_layer.set_cell(map_pos, tileset_id, tile_dict["build"])
		Job.Type.DELIVER_MATERIAL:
			Global.current_map.icon_layer.set_cell(map_pos, tileset_id, tile_dict["deliver"])
		Job.Type.HAUL_ITEMS:
			if ItemManager.grid_items.has(map_pos):
				ItemManager.grid_items[map_pos]["node"].is_forbidden(false)
			else:
				print("zortingen oldu: ",map_pos)
		Job.Type.DIGGING:
			Global.current_map.icon_layer.set_cell(map_pos, tileset_id, tile_dict["dig"])
		Job.Type.DECONSTRUCT:
			Global.current_map.icon_layer.set_cell(map_pos, tileset_id, tile_dict["deconstruct"])
		Job.Type.REMOVE_FLOOR:
			Global.current_map.icon_layer.set_cell(map_pos, tileset_id, tile_dict["deconstruct"])
		Job.Type.BUILD_ROOF:
			Global.current_map.icon_layer.set_cell(map_pos, tileset_id, tile_dict["build"])
	return new_job

func request_job(npc: PawnPrototype):
	var min_dist: float = INF
	var target_job = null
	for job in available_jobs:
		if job.job_type == Job.Type.BUILD_ROOF:
			if not Global.current_map.has_roof_support(job.target_map_pos):
				suspend_job(job)
				continue
		# KRİTİK DEĞİŞİKLİK: İş alınmamışsa VE mühürlü değilse ver!
		if not job.is_taken and not (npc in job.worker_black_list):
			if job.job_type == Job.Type.HAUL_ITEMS:
				var ground_item = ItemManager.get_item_at(job.target_map_pos)
				
				if ground_item == null:
					continue
				
				var is_stockpile_available = ZoneManager.get_available_stockpile_cell(ItemManager.grid_items[job.target_map_pos]["type"])
				if is_stockpile_available == null:
					continue
			var dist = npc.global_position.distance_to(job.target_world_pos)
			if dist < min_dist:
				min_dist = dist
				target_job = job
	if target_job != null:
		return target_job
	return null

func request_job_type(npc: CharacterBody2D, job_type: Job.Type):
	for job in available_jobs:
		if job.job_type == job_type and not job.is_taken and not (npc in job.worker_black_list):
			npc.current_job = job
			job.is_taken = true
			job.worker = npc
			return job
	return null

func assign_job_to_pawn(job: Job, pawn:PawnPrototype):
	if pawn.current_job != null:
		var old_job = pawn.current_job
		old_job.is_taken  =false
		old_job.worker = null
		"""abondon_job(pawn.current_job, pawn)"""
	
	job.is_taken = true
	job.worker = pawn
	pawn.current_job = job

func abondon_job(job: Job, pawn: PawnPrototype):
	if job.job_type == Job.Type.DELIVER_MATERIAL:
		var bp = BuildManager.active_blueprints.get(job.target_map_pos)
		if bp != null:
			var cancel_amount = 0
			var mat = ""
			
			if not pawn.character_inventory.is_inventory_empty():
				cancel_amount = pawn.character_inventory.item_amount
				mat = pawn.character_inventory.carried_item
			elif pawn.memory.reserved_amount > 0:
				cancel_amount = pawn.memory.reserved_amount
				mat = pawn.memory.target_material
			
			if cancel_amount > 0 and bp.progress.has(mat):
				bp.progress[mat]["incoming"] -= cancel_amount
				if bp.progress[mat]["incoming"] < 0:
					bp.progress[mat]["incoming"] = 0
		pawn.memory.reserved_amount = 0
		pawn.memory.target_material = ""
	
	if pawn.current_job == job:
		pawn.current_job = null
		"""if pawn.state_machine.current_state.name != "IdleState":
			pawn.state_machine.change_state("IdleState")"""
	
	if not available_jobs.has(job):
		available_jobs.append(job)
	job.is_taken = false
	job.worker = null

func complete_job(job: Job):
	Global.current_map.icon_layer.erase_cell(job.target_map_pos)
	job.is_taken = false
	job.worker = null
	available_jobs.erase(job)

func wake_up_jobs():
	#print("işler uyandırılıyor")
	for job in available_jobs:
		if job.worker_black_list.size() > 0:
			job.worker_black_list.clear()

func abort_job(job: Job):
	var curr_map = Global.current_map
	var map_data = curr_map.map_data
	map_data[job.target_map_pos.y][job.target_map_pos.x]["marked_for_mining"] = false
	curr_map.icon_layer.erase_cell(job.target_map_pos)
	for pawn in PawnManager.current_pawns:
		if pawn.current_job == job:
			pawn.current_job = null
			pawn.next_state_after_move = ""
			pawn.state_machine.change_state("IdleState")
	if job.job_type == job.Type.HAUL_ITEMS:
		ItemManager.cancel_haul_item(job.target_map_pos)
	if available_jobs.has(job):
		available_jobs.erase(job)
	elif suspended_jobs.has(job):
		suspended_jobs.erase(job)
	

func check_job(job_map_pos: Vector2i) -> Job:
	for job in available_jobs:
		if job.target_map_pos == job_map_pos:
			return job
	for job in suspended_jobs:
		if (job.job_type == Job.Type.HAUL_ITEMS or job.job_type == Job.Type.DELIVER_MATERIAL) and job.target_map_pos == job_map_pos:
			return job
	return null

func on_item_dropped(coords: Vector2i, item_type: String):
	var is_needed_for_construction = false
	
	for job in available_jobs:
		if job.job_type == Job.Type.DELIVER_MATERIAL:
			var bp: BluePrint = BuildManager.active_blueprints.get(job.target_map_pos)
			if bp != null and bp.get_remaining_needs(item_type):
				is_needed_for_construction = true
	
	if not is_needed_for_construction:
		for i in range(suspended_jobs.size() - 1, -1, -1):
			var job = suspended_jobs[i]
			
			if job.job_type == Job.Type.DELIVER_MATERIAL:
				
				var bp = BuildManager.active_blueprints.get(job.target_map_pos)
				
				if bp == null:
					suspended_jobs.remove_at(i)
					continue
					
				if bp.get_remaining_needs(item_type):
					
					suspended_jobs.remove_at(i)
					available_jobs.append(job)
					
					is_needed_for_construction = true
		
	if not is_needed_for_construction and not ZoneManager.cell_in_any_zone(coords):
		post_job(Job.Type.HAUL_ITEMS, coords, Global.current_map.terrain_layer.map_to_local(coords), 0)
	

func suspend_job(job: Job):
	if available_jobs.has(job):
		available_jobs.erase(job)
	job.is_taken = false
	job.worker = null
	
	if not suspended_jobs.has(job):
		suspended_jobs.append(job)
	
	
	if job.job_type == Job.Type.HAUL_ITEMS:
		var failed_item = ItemManager.get_item_at(job.target_map_pos)
		if failed_item != null:
			var target_type = failed_item["type"]
			
			for i in range(available_jobs.size() - 1, -1, -1):
				var curr_job = available_jobs[i]
				if curr_job.job_type == Job.Type.HAUL_ITEMS:
					var curr_item = ItemManager.get_item_at(curr_job.target_map_pos)
					
					if curr_item != null and curr_item["type"] == target_type:
						available_jobs.remove_at(i)
						
						curr_job.is_taken = false
						curr_job.worker = null
						
						if not suspended_jobs.has(curr_job):
							suspended_jobs.append(curr_job)

func on_stockpile_cell_opened():
	for i in range(suspended_jobs.size() - 1, -1, -1):
		var job = suspended_jobs[i]
		
		if job.job_type != Job.Type.HAUL_ITEMS:
			continue
		
		var ground_item = ItemManager.get_item_at(job.target_map_pos)
		
		if ground_item == null:
			suspended_jobs.remove_at(i)
			continue
		
		suspended_jobs.remove_at(i)
		available_jobs.append(job)

func wake_up_jobs_for_type(item_type: String, capacity_to_fill: int):
	var filled_so_far = 0
	for i in range(suspended_jobs.size() - 1, -1, -1):
		if filled_so_far >= capacity_to_fill:
			break
		
		var job = suspended_jobs[i]
		if job.job_type != Job.Type.HAUL_ITEMS:
			continue
		
		var ground_item = ItemManager.get_item_at(job.target_map_pos)
		
		if ground_item == null or ZoneManager.cell_in_any_zone(job.target_map_pos):
			suspended_jobs.remove_at(i)
			continue
		
		if ground_item["type"] == item_type:
			suspended_jobs.remove_at(i)
			available_jobs.append(job)
			
			filled_so_far += ground_item["amount"]

func _on_bp_created(bp: BluePrint):
	for item_type in bp.recipe.materials.keys():
		var _needed = bp.get_remaining_needs(item_type)
		#print("malzemeler: ", item_type, "gereken miktar: ", needed)
	post_job(Job.Type.DELIVER_MATERIAL, bp.coords, Global.current_map.terrain_layer.map_to_local(bp.coords), 0)

func get_save_data() -> Array:
	var jobs_save_array = []
	
	var all_jobs = []
	
	all_jobs.append_array(available_jobs)
	all_jobs.append_array(suspended_jobs)
	
	for job in all_jobs:
		var clean_data = {
			"job_type": job.job_type,
			"target_x": job.target_map_pos.x,
			"target_y": job.target_map_pos.y,
			
		} 
		
		jobs_save_array.append(clean_data)
	
	return jobs_save_array

func load_save_data(job_data_list: Array):
	available_jobs.clear()
	suspended_jobs.clear()
	
	for job_data in job_data_list:
		var job_map_pos =  Vector2i(job_data["target_x"], job_data["target_y"])
		post_job(job_data["job_type"], job_map_pos, Global.current_map.terrain_layer.map_to_local(job_map_pos))

func abort_haul_job_coords(coords: Vector2i):
	for job in available_jobs:
		if job.job_type == Job.Type.HAUL_ITEMS and job.target_map_pos == coords:
			available_jobs.erase(job)
	for job in suspended_jobs:
		if job.job_type == Job.Type.HAUL_ITEMS and job.target_map_pos == coords:
			suspended_jobs.erase(job)

func reset_manager():
	available_jobs.clear()
	suspended_jobs.clear()

func _on_item_consumed(item_amount: int, item_type: String):
	var space_freed = item_amount
	
	for i in range(suspended_jobs.size() - 1, -1, -1):
		if space_freed <= 0:
			break
		
		var job = suspended_jobs[i]
		
		if job.job_type != Job.Type.HAUL_ITEMS:
			continue
		
		var ground_item = ItemManager.get_item_at(job.target_map_pos)
		
		if ground_item == null:
			suspended_jobs.remove_at(i)
			continue
		
		if ground_item["type"] == item_type:
			var available_cell = ZoneManager.get_available_stockpile_cell(item_type)
			suspended_jobs.remove_at(i)
			available_jobs.append(job)
			
			space_freed -= ground_item["amount"]

func job_in_list(job: Job):
	for _job in available_jobs:
		if _job == job:
			return("Available")
	for _job in suspended_jobs:
		if _job == job:
			return("Suspended")

func unsuspended_blueprint_job(bp: BluePrint):
	for job in suspended_jobs:
		if job.target_map_pos == bp.coords:
			suspended_jobs.erase(job)
			available_jobs.append(job)
			break
