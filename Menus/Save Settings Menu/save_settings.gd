extends Control

@onready var create_button = $CanvasLayer/Panel/VBoxContainer/CreateButton
@onready var seed_line = $CanvasLayer/Panel/VBoxContainer/SeedContainer/LineEdit
@onready var pawn_spin = $CanvasLayer/Panel/VBoxContainer/PawnContainer/SpinBox
@onready var autoamata_spin = $CanvasLayer/Panel/VBoxContainer/AutomataContainer/SpinBox
@onready var width_line = $CanvasLayer/Panel/VBoxContainer/SeedContainer2/Width
@onready var height_line = $CanvasLayer/Panel/VBoxContainer/SeedContainer2/Height


var custom_seed: String = ""
var pawn_count: int = 1
var threshold: int = 4

var min_size: int = 50
var max_size: int = 300



func _ready() -> void:
	create_button.pressed.connect(_on_create_button_pressed)
	
	width_line.text_changed.connect(_on_text_changed.bind(width_line))
	height_line.text_changed.connect(_on_text_changed.bind(height_line))
	
	width_line.text_submitted.connect(_on_text_submitted.bind(width_line))
	height_line.text_submitted.connect(_on_text_submitted.bind(height_line))
	
	width_line.focus_exited.connect(_on_focus_exited.bind(width_line))
	height_line.focus_exited.connect(_on_focus_exited.bind(height_line))

func _on_create_button_pressed():
	validate_and_clamp(width_line)
	validate_and_clamp(height_line)
	
	Global.map_width = int(width_line.text)
	Global.map_height = int(height_line.text)
	
	Global.start_pawn_count = int(pawn_spin.value)
	custom_seed = seed_line.text
	Global.custom_seed = custom_seed
	Global.custom_threshold = int(autoamata_spin.value)
	Global.is_loading_game = false
	get_tree().change_scene_to_file("res://Map Generate Source/Map.tscn")

func _on_text_changed(new_text: String, but: LineEdit):
	var old_caret_pos = but.caret_column 
	
	var clean_text = ""
	
	for char in new_text:
		if char in "0123456789" :
			clean_text += char
	
	but.text = clean_text
	
	but.caret_column = old_caret_pos

func _on_text_submitted(_new_text: String, but: LineEdit):
	validate_and_clamp(but)
	but.release_focus()

func _on_focus_exited(but: LineEdit):
	validate_and_clamp(but)

func validate_and_clamp(but: LineEdit):
	var text_val = but.text
	
	if text_val == "":
		but.text = text_val
	var current_val = int(text_val)
	
	var clamped_val = clamp(current_val, min_size, max_size)
	
	but.text = str(clamped_val)
