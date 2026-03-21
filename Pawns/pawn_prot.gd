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
func _ready():
	char_name = "PawnPrototype"
	char_body.texture = char_body_texture
	character_inventory = PawnInventory.new()
	character_inventory.max_capacity = 25
	label.text = char_name

func _physics_process(_delta: float) -> void:
	pass
	#label.text = $StateMachine.current_state.name
