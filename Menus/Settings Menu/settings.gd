extends CanvasLayer

@onready var general_sound_slider = $Control/PanelContainer/MarginContainer/VBoxContainer/SettingBox/Sounds/MarginContainer/VBoxContainer/GeneralSoundBox/HSlider
@onready var music_sound_slider = $Control/PanelContainer/MarginContainer/VBoxContainer/SettingBox/Sounds/MarginContainer/VBoxContainer/MusicSound/HSlider

@onready var resolution_opt_button = $Control/PanelContainer/MarginContainer/VBoxContainer/SettingBox/Display/MarginContainer/VBoxContainer/Resolutions
@onready var display_opt_button = $Control/PanelContainer/MarginContainer/VBoxContainer/SettingBox/Display/MarginContainer/VBoxContainer/DisplayModes

@onready var exit_button = $Control/PanelContainer/MarginContainer/VBoxContainer/ExitButton
@onready var save_button = $Control/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/SaveSettings
@onready var apply_button = $Control/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ApplySettings

signal pressed_exit

func _ready():
	self.hide()
	InfoMenu.pressed_settings.connect(_on_settings_pressed)
	
	exit_button.pressed.connect(_on_exit_pressed)
	save_button.pressed.connect(_on_save_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	
	_setup_option_buttons()
	

func _input(event):
	if event.is_action_pressed("ui_cancel") and self.visible:
		_on_exit_pressed()
		
		get_viewport().set_input_as_handled()

func _on_settings_pressed():
	_update_ui_from_settings()
	self.show()

func _setup_option_buttons():
	resolution_opt_button.clear()
	resolution_opt_button.add_item("1280x720")
	resolution_opt_button.add_item("1920x1080")
	resolution_opt_button.add_item("2560x1440")
	
	display_opt_button.clear()
	display_opt_button.add_item("Windowed")
	display_opt_button.add_item("FullScreen")

func _update_ui_from_settings():
	var current = SettingsManager.current_settings
	
	general_sound_slider.value = current["general_sound"]
	music_sound_slider.value = current["music_sound"]
	
	resolution_opt_button.selected = current["resolution_index"]
	display_opt_button.selected = current["display_mode_index"]

func _on_save_pressed():
	var new_settings = {
		"general_sound": general_sound_slider.value,
		"music_sound": music_sound_slider.value,
		"resolution_index": resolution_opt_button.selected,
		"display_mode_index": display_opt_button.selected
	}
	
	SettingsManager.save_settings(new_settings)
	self.hide()

func _on_exit_pressed():
	pressed_exit.emit()
	self.hide()

func _on_apply_pressed():
	var temp_settings = {
		"general_sound": general_sound_slider.value,
		"music_sound": music_sound_slider.value,
		"resolution_index": resolution_opt_button.selected,
		"display_mode_index": display_opt_button.selected
	}
	SettingsManager.apply_settings_temp(temp_settings)
