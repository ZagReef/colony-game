extends Node

class_name StateMachine

@export var init_st: State
var current_state: State
var states: Dictionary= {}

func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.state_machine = self
	
	if init_st:
		await get_parent().ready
		change_state(init_st.name.to_lower())

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func change_state(new_state_name: String, msg: Dictionary = {}) -> void:
	if current_state:
		current_state.exit()
	
	current_state = states.get(new_state_name.to_lower())
	
	if current_state:
		current_state.enter(msg)
		#print(current_state.name)
	else:
		print("State Machine içinde istenen state yok")
