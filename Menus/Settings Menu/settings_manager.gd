extends Node

const SAVE_PATH = "user://settings.json"

var current_settings: Dictionary = {
	"general_sound": 1.0,
	"music_sound": 1.0,
	"resolution_index": 1,
	"display_mode_index": 0
	}

var temp_settings: Dictionary = {}

var resolutions: Array[Vector2i]= [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

func _ready():
	Settings.pressed_exit.connect(apply_settings)
	Settings.pressed_exit.connect(func(): temp_settings.clear())
	load_settings()

func save_settings(new_settings: Dictionary):
	current_settings = new_settings
	apply_settings()
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(current_settings, "\t"))
		file.close()

func load_settings():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		
		var parsed_data = JSON.parse_string(json_string)
		if parsed_data is Dictionary:
			for key in parsed_data.keys():
				current_settings[key] = parsed_data[key]
	
	apply_settings()


func apply_settings():
	var master_bus = AudioServer.get_bus_index("Master")
	var music_bus = AudioServer.get_bus_index("Music")
	
	print(current_settings)
	
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(current_settings["general_sound"]))
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(current_settings["music_sound"]))
	
	var selected_res = resolutions[int(current_settings["resolution_index"])]
	DisplayServer.window_set_size(selected_res)
	
	var screen_center = DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2
	var window_pos = screen_center - DisplayServer.window_get_size() / 2
	DisplayServer.window_set_position(window_pos)
	
	match int(current_settings["display_mode_index"]):
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func apply_settings_temp(new_settings):
	temp_settings = new_settings
	
	var master_bus = AudioServer.get_bus_index("Master")
	var music_bus = AudioServer.get_bus_index("Music")
	
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(temp_settings["general_sound"]))
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(temp_settings["music_sound"]))
	
	var selected_res = resolutions[int(temp_settings["resolution_index"])]
	DisplayServer.window_set_size(selected_res)
	
	var screen_center = DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2
	var window_pos = screen_center - DisplayServer.window_get_size() / 2
	DisplayServer.window_set_position(window_pos)
	
	match int(temp_settings["display_mode_index"]):
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
