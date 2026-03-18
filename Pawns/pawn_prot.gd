extends CharacterBody2D

@export var char_body_texture: Texture2D 

@onready var char_body: Sprite2D = $Sprite2D
var char_name = ""

var current_job: Job = null
var move_target: Vector2
var next_state_after_move: String = ""

var character_inventory: PawnInventory

var memory: Dictionary = {
	"reserved_amount": 0,
	"item_pickup_pos": Vector2i.ZERO,
	"target_material": ""
}

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
