extends State

class_name IdleState

var character: PawnPrototype
@export var wander_range = 200
@export var idle_speed = 300
@export var wait_time_min = 1.0
@export var wait_time_max = 4.0
@export var target_to_move: Vector2i

var start_pos: Vector2
var is_waiting: bool = false

func enter(_msg: Dictionary = {}):
	#print("İdle çalıştırıldı")
	
	character = state_machine.get_parent() as PawnPrototype
	
	var inventory = character.character_inventory
	
	var map = Global.current_map
	
	start_pos = character.global_position
	character.velocity = Vector2.ZERO
	
	if not inventory.is_inventory_empty():
		var local_pos = map.terrain_layer.to_local(character.global_position)
		ItemManager.add_item_to_grid(map.terrain_layer.local_to_map(local_pos), inventory["carried_item"], inventory["item_amount"], 
		map.item_layer, map.item_drop, map.terrain_layer.map_to_local)
		#print("eşyalar silindi ", inventory["carried_item"],"  " ,inventory["item_amount"])
		inventory.clear_inventory()
	
	call_deferred("start_waiting")

func exit():
	#print("Chase'den çıkıldı"
	character.velocity = Vector2.ZERO

func make_path() -> void:
	#print("makepath çalıştı")
	
	is_waiting = false
	
	var rand_offset = Vector2i(
		randi_range(-wander_range, wander_range), randi_range(-wander_range, wander_range)
	)
	
	target_to_move += rand_offset
	

func _on_timer_finished():
	if state_machine.current_state == self and character.current_job == null:
		#character.next_state_after_move = "IdleState"
		character.move_target = character.global_position + Vector2(randi_range(-100, 100), randi_range(-100, 100))
		state_machine.change_state("MoveState")
	else:
		state_machine.change_state("IdleState")

func start_waiting():
	if check_for_work():
		#print("osuruk")
		return
	
	
	#print("start_waiting check_for_work geçildi")
	is_waiting = true
	var wait_time = randf_range(wait_time_min, wait_time_max)
	
	#print(wait_time, " kadar bekliyor")
	get_tree().create_timer(wait_time/Global.sim_speed).timeout.connect(_on_timer_finished)

func check_for_work():
	#print("iş kontrol edildi")
	var found_job = JobManager.request_job(character)
	if found_job:
		var job_type = found_job.job_type
		#print("iş bulundu")
		character.current_job = found_job
		
		character.move_target = found_job.target_world_pos
		
		if job_type == Job.Type.HAUL_ITEMS:
			character.next_state_after_move = "HaulState"
		elif job_type in [Job.Type.WOOD_CUTTING, Job.Type.MINING, Job.Type.DIGGING]:
			character.next_state_after_move = "MineState"
		elif job_type == Job.Type.DELIVER_MATERIAL:
			character.move_target = character.global_position
			character.next_state_after_move = "DeliverMaterialState"
		elif job_type == Job.Type.BUILD_STRUCTURE:
			character.next_state_after_move = "BuildState"
		
		state_machine.change_state("MoveState")
		return true
	return false
