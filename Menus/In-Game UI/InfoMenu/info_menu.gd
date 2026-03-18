extends CanvasLayer

@onready var new_game_button = $MenuPanel/MarginContainer/VBoxContainer/NewGame
@onready var exit_button = $MenuPanel/MarginContainer/VBoxContainer/ExitButton
@onready var load_button = $MenuPanel/MarginContainer/VBoxContainer/LoadButton
@onready var setting_button = $MenuPanel/MarginContainer/VBoxContainer/SettingButton

signal pressed_exit

func _ready():
	new_game_button.pressed.connect(_on_new_game_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	load_button.pressed.connect(_on_load_pressed)
	#setting_button.connect(func (): get_tree.change_scene_to_file())

func _on_load_pressed():
	Global.is_loading_game = true
	get_tree().change_scene_to_file("res://Map Generate Source/Map.tscn")

func _on_exit_pressed():
	get_tree().change_scene_to_file("res://Menus/Main Menu/main_menu.tscn")
	self.visible = false
	pressed_exit.emit()

func _on_new_game_pressed():
	get_tree().change_scene_to_file("res://Menus/Save Settings Menu/save_settings.tscn")
	self.visible = false
