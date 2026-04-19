extends CanvasLayer

@onready var new_game_button = $MenuPanel/MarginContainer/VBoxContainer/NewGame
@onready var exit_button = $MenuPanel/MarginContainer/VBoxContainer/ExitButton
@onready var load_button = $MenuPanel/MarginContainer/VBoxContainer/LoadButton
@onready var setting_button = $MenuPanel/MarginContainer/VBoxContainer/SettingButton
@onready var save_button = $MenuPanel/MarginContainer/VBoxContainer/SaveButton

signal pressed_exit

signal pressed_settings

func _ready():
	new_game_button.pressed.connect(_on_new_game_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	load_button.pressed.connect(_on_load_pressed)
	save_button.pressed.connect(_on_save_pressed)
	setting_button.pressed.connect(func (): pressed_settings.emit())

func _on_load_pressed():
	if Global.is_saving_game or Global.is_loading_game:
		return
	Global.is_loading_game = true
	get_tree().change_scene_to_file("res://Map Generate Source/Map.tscn")
	get_tree().paused = false

func _on_exit_pressed():
	get_tree().change_scene_to_file("res://Menus/Main Menu/main_menu.tscn")
	self.visible = false
	get_tree().paused = false
	pressed_exit.emit()

func _on_new_game_pressed():
	get_tree().change_scene_to_file("res://Menus/Save Settings Menu/save_settings.tscn")
	get_tree().paused = false
	self.visible = false

func _on_save_pressed():
	SaveManager.save_game_json()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and Global.is_in_game:
		toggle_pause_menu()

func toggle_pause_menu():
	if self.visible:
		self.hide()
		get_tree().paused = false
	else:
		self.show()
		get_tree().paused = true
