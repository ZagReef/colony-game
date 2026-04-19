extends Node

const SAVE_PATH = "user://settings.json"

var current_settings: Dictionary = {
	"general_sound": 1.0,
	"music_sound": 1.0,
	"resolution_index": 1,
	"display_mode_index": 0,
	"hud_scale": 1.0
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
	
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(current_settings["general_sound"]))
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(current_settings["music_sound"]))
	
	var selected_res = resolutions[int(current_settings["resolution_index"])]
	if current_settings["display_mode_index"] == 0:
		DisplayServer.window_set_size(selected_res)
		
		var screen_center = DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2
		var window_pos = screen_center - selected_res / 2
		DisplayServer.window_set_position(window_pos)
	
	get_window().content_scale_size = selected_res
	
	match int(current_settings["display_mode_index"]):
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	var new_scale = Vector2(current_settings["hud_scale"], current_settings["hud_scale"])
	
	var hud_nodes = get_tree().get_nodes_in_group("hud_elements")
	
	for node in hud_nodes:
		if node is Control:
			auto_set_pivot_from_anchor(node)
			node.scale = new_scale
	
	if is_instance_valid(PawnsUI.action_panel):
		var base_height = 50.0
		
		PawnsUI.action_panel.custom_minimum_size.y = base_height * current_settings["hud_scale"]
		

func apply_settings_temp(new_settings):
	temp_settings = new_settings
	
	var master_bus = AudioServer.get_bus_index("Master")
	var music_bus = AudioServer.get_bus_index("Music")
	
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(temp_settings["general_sound"]))
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(temp_settings["music_sound"]))
	
	var selected_res = resolutions[int(temp_settings["resolution_index"])]
	if current_settings["display_mode_index"] == 0:
		DisplayServer.window_set_size(selected_res)
		
		var screen_center = DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2
		var window_pos = screen_center - selected_res / 2
		DisplayServer.window_set_position(window_pos)
	
	get_window().content_scale_size = selected_res
	
	match int(temp_settings["display_mode_index"]):
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			
	var new_scale = Vector2(temp_settings["hud_scale"], temp_settings["hud_scale"])
	
	var hud_nodes = get_tree().get_nodes_in_group("hud_elements")
	
	for node in hud_nodes:
		if node is Control:
			auto_set_pivot_from_anchor(node)
			node.scale = new_scale
	
	if is_instance_valid(PawnsUI.action_panel):
		var base_height = 50.0
		
		PawnsUI.action_panel.custom_minimum_size.y = base_height * temp_settings["hud_scale"]
		

func auto_set_pivot_from_anchor(node: Control):
	if not node: return
	
	var anchor_center_x = (node.anchor_left + node.anchor_right) / 2
	var anchor_center_y = (node.anchor_top + node.anchor_bottom) / 2
	
	node.pivot_offset = Vector2(anchor_center_x * node.size.x, anchor_center_y * node.size.y)
