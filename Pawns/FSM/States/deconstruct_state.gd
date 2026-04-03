extends State

class_name DeconstructState

var character: PawnPrototype
var current_job: Job
var mining_timer: float = 0.0

@export var hit_interval = 0.8
@export var damage_per_hit = 20

var is_performing_work: bool = false

func enter(_msg: Dictionary = {}):
	character = state_machine.get_parent() as PawnPrototype
	is_performing_work = false
	
	current_job = character.current_job
	
	if current_job == null:
		state_machine.change_state("IdleState")
		return
	
	#print("İş başladı", current_job.job_type)
	
	character.velocity = Vector2.ZERO
	
func physics_update(delta: float):
	
	if current_job == null:
		state_machine.change_state("IdleState")
		return
	mining_timer += delta * Global.sim_speed
	if mining_timer >= hit_interval:
		mining_timer = 0
		hit_target()

func update(_delta: float):
	pass

func start_work_timer():
	if is_performing_work: return
	is_performing_work = true
	hit_target()


func _on_work_completed():
	if current_job:
		JobManager.complete_job(current_job)
	
	character.next_state_after_move = ""
	character.current_job = null
	state_machine.change_state("IdleState")

func hit_target():
	if state_machine.current_state != self: return
	if current_job == null: return
	
	var coords = current_job.target_map_pos
	var curr_map = Global.current_map
	var target_cell = curr_map.map_data[coords.y][coords.x]
	if target_cell["top"] == "none":
		_on_work_completed()
		return
	
	var is_destroyed = Global.current_map.damage_tile(coords,damage_per_hit)
	#print("taşa vuruldu")
	
	if is_destroyed:
		_on_work_completed()

func exit():
	#print("mine state'den çıkıldı")
	#character.current_job = null
	mining_timer = 0.0
