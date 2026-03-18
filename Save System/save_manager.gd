extends Node

const SAVE_PATH_STORE_VAR = "user://colony_save.save"
const SAVE_PATH_JSON = "user://colony_save.json"

const PAWN_SCENE = preload("res://Pawns/pawn_prot.tscn")

func save_game_store_var():
	print("kayıt başlıyor...")
	
	var save_data = {
		"items": ItemManager.get_save_data(),
		"structure": BuildManager.get_save_data()
	}
	
	
	var file = FileAccess.open(SAVE_PATH_STORE_VAR, FileAccess.WRITE)
	
	if file:
		file.store_var(save_data)
		file.close()
		
		print("kayıt başarılı: ", ProjectSettings.globalize_path(SAVE_PATH_STORE_VAR))
	else: print("hata oluştu, kayıt dosyası yok")

func save_game_json():
	#print("kayıt başlıyor")
	
	var save_data = {
		"items": ItemManager.get_save_data(),
		"structure": BuildManager.get_save_data(),
		"map_data": Global.current_map.get_save_data(),
		"jobs": JobManager.get_save_data(),
		"characters": PawnManager.get_character_save_data(),
		"stockpiles": ZoneManager.get_save_data(),
		"seed": Global.custom_seed
	}
	
	var file = FileAccess.open(SAVE_PATH_JSON, FileAccess.WRITE)
	
	if file:
		var json_str = JSON.stringify(save_data, "\t")
		
		file.store_string(json_str)
		
		file.close()
		
		print("oyun kaydedildi: ", ProjectSettings.globalize_path(SAVE_PATH_JSON))
	else: print("hata oluştu, kayıt dosyası yok")

func load_game():
	if not FileAccess.file_exists(SAVE_PATH_JSON):
		print("kayıt doyası bulunamadı")
		return
	
	var file = FileAccess.open(SAVE_PATH_JSON, FileAccess.READ)
	var json_str = file.get_as_text()
	file.close()
	
	var save_data = JSON.parse_string(json_str)
	
	if save_data == null:
		print("save bilgileri bulunamadı")
		return
	
	clear_current_world()
	if save_data.has("map_data"):
		var curr_map = Global.current_map
		curr_map.load_save_data(save_data["map_data"])
		curr_map.print_map()
		curr_map.set_astar_grid()
	if save_data.has("items"):
		ItemManager.load_save_data(save_data["items"])
	if save_data.has("structure"):
		BuildManager.load_save_data(save_data["structure"])
	if save_data.has("characters"):
		PawnManager.current_pawns.clear()
		PawnManager.load_save_data(save_data["characters"])
	if save_data.has("stockpiles"):
		ZoneManager.load_save_data(save_data["stockpiles"])
	if save_data.has("jobs"):
		JobManager.load_save_data(save_data["jobs"])
	Global.is_loading_game = false

func clear_current_world():
	var old_pawns = get_tree().get_nodes_in_group("Pawn Group")
	for pawn in old_pawns:
		pawn.queue_free()
	
	ItemManager.grid_items.clear()
	JobManager.available_jobs.clear()
	JobManager.suspended_jobs.clear()
	BuildManager.active_blueprints.clear()
	
