extends CharacterBody2D

class_name PawnPrototype

@export var char_body_texture: Texture2D 

@onready var char_body: Sprite2D = $Sprite2D
var char_name = ""

var current_job: Job = null
var move_target: Vector2
var next_state_after_move: String = ""

var character_inventory: PawnInventory

class PawnMemory:
	var reserved_amount: int = 0
	var item_pickup_pos: Vector2i = Vector2i.ZERO
	var target_material: String = ""

var memory: PawnMemory = PawnMemory.new()

@onready var state_machine = $StateMachine

@onready var label = $Label

var is_selected: bool = false

func _ready():
	char_name = "PawnPrototype"
	char_body.texture = char_body_texture
	character_inventory = PawnInventory.new()
	character_inventory.max_capacity = 25
	label.text = char_name

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if !is_selected:
			Global.pawn_selected.emit(self)
		else:
			PawnManager.pawn_focus_cancelled.emit()
		
		get_viewport().set_input_as_handled()

func _physics_process(_delta: float) -> void:
	pass
	#label.text = $StateMachine.current_state.name
