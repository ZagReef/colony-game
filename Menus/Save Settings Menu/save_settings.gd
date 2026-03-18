extends Control

@onready var create_button = $CanvasLayer/Panel/VBoxContainer/CreateButton
@onready var seed_line = $CanvasLayer/Panel/VBoxContainer/SeedContainer/LineEdit
@onready var pawn_spin = $CanvasLayer/Panel/VBoxContainer/PawnContainer/SpinBox
@onready var autoamata_spin = $CanvasLayer/Panel/VBoxContainer/AutomataContainer/SpinBox

var custom_seed: String = ""
var pawn_count: int = 1
var threshold: int = 4



func _ready() -> void:
	create_button.pressed.connect(_on_create_button_pressed)

func _on_create_button_pressed():
	Global.start_pawn_count = int(pawn_spin.value)
	custom_seed = seed_line.text
	Global.custom_seed = custom_seed
	Global.custom_threshold = int(autoamata_spin.value)
	Global.is_loading_game = false
	get_tree().change_scene_to_file("res://Map Generate Source/Map.tscn")
