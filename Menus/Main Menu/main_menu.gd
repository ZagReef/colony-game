extends Control

@onready var play_but = $CanvasLayer/VBoxContainer/NewGame
@onready var load_but = $CanvasLayer/VBoxContainer/LoadGame
@onready var setting_but = $CanvasLayer/VBoxContainer/Settings
@onready var quit_but = $CanvasLayer/VBoxContainer/Quit


func _ready():
	play_but.pressed.connect(_on_play_pressed)
	setting_but.pressed.connect(func(): InfoMenu.pressed_settings.emit())
	quit_but.pressed.connect(_on_quit_pressed)
	load_but.pressed.connect(_on_load_game_pressed)


func _on_play_pressed():
	Global.is_loading_game = false
	get_tree().change_scene_to_file("res://Menus/Save Settings Menu/save_settings.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _on_load_game_pressed():
	Global.is_loading_game = true
	get_tree().change_scene_to_file("res://Map Generate Source/Map.tscn")
