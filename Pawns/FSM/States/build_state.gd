extends State

class_name BuildState

var character: PawnPrototype
var is_building: bool = false
var build_time: float = 0.0
var target_bp: BluePrint

func enter(_msg: Dictionary = {}):
	character = state_machine.get_parent()
	var job: Job = character.current_job
	
	target_bp = BuildManager.active_blueprints.get(job.target_map_pos)
	
	if target_bp == null:
		JobManager.abort_job(job)
		character.current_job = null
		character.next_state_after_move = ""
		state_machine.change_state("IdleState")
		return
	
	var curr_cell = Global.current_map.terrain_layer.local_to_map(character.global_position)
	
	var is_adjacent = false
	var footprint = target_bp.get_occupied_tiles() 
	
	for tile in footprint:
		var dist_x = abs(curr_cell.x - tile.x)
		var dist_y = abs(curr_cell.y - tile.y)
		
		# Çapraz veya yan yana (1 kare mesafe) ise bitişiktir
		if dist_x <= 1 and dist_y <= 1:
			is_adjacent = true
			break
	
	if is_adjacent:
		is_building = true
		build_time = target_bp.recipe.build_time
	else:
		character.move_target = Global.current_map.terrain_layer.map_to_local(target_bp.coords)
		character.next_state_after_move = "BuildState"
		state_machine.change_state("MoveState")

func physics_update(delta: float):
	if is_building:
		build_time -= delta
		if build_time <= 0:
			is_building = false
			finish_building()

func finish_building():
	var job: Job = character.current_job
	
	BuildManager.finish_building(target_bp.coords)
	
	JobManager.complete_job(job)
	character.current_job = null
	
	character.next_state_after_move = ""
	
	state_machine.change_state("IdleState")
