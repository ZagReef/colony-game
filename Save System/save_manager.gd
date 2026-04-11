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
	if Global.is_saving_game or Global.is_loading_game:
		return
	Global.is_saving_game = true
	
	SaveBlocker.label.text = "Saving Game"
	SaveBlocker.show()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	get_tree().paused = true
	
	var is_save_corrupted = false
	
	
	var save_data = {
		"items": ItemManager.get_save_data(),
		"structure": BuildManager.get_save_data(),
		"map_data": Global.current_map.get_save_data(),
		"jobs": JobManager.get_save_data(),
		"characters": PawnManager.get_character_save_data(),
		"stockpiles": ZoneManager.get_save_data(),
		"seed": Global.custom_seed
	}
	
	var critical_keys = ["map_data", "characters"]
	
	for key in critical_keys:
		if typeof(save_data[key]) == TYPE_ARRAY or typeof(save_data[key]) == TYPE_DICTIONARY:
			if save_data[key].size() <= 0:
				print("kritik hata: ", key, " kaydedilemedi")
				is_save_corrupted = true
		elif save_data[key] == null:
			print("kritik hata: ", key, "verisi null")
			is_save_corrupted = true
			
	if not is_save_corrupted:
		
		var file = FileAccess.open_compressed(SAVE_PATH_JSON, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
		if file:
			var json_str = JSON.stringify(save_data, "\t")
			
			file.store_string(json_str)
			file.flush()
			
			file.close()
			
			print("oyun kaydedildi: ", ProjectSettings.globalize_path(SAVE_PATH_JSON))
		else: print("hata oluştu, kayıt dosyası yok")
	else:
		print("bozuk save verisi yüzünden dosyaya yazılmadı")
	
	SaveBlocker.hide()
	get_tree().paused = false
	Global.is_saving_game = false
	InfoMenu.load_button.disabled = false

func load_game():
	if not FileAccess.file_exists(SAVE_PATH_JSON):
		print("kayıt doyası bulunamadı")
		return
	
	if Global.is_saving_game:
		print("İşlem yapılıyor, bekleyin")
		return
	
	
	Global.is_loading_game = true
	SaveBlocker.label.text = "Loading Game"
	SaveBlocker.show()
	get_tree().paused = true
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var file = FileAccess.open_compressed(SAVE_PATH_JSON, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	var json_str = file.get_as_text()
	file.close()
	
	var save_data = JSON.parse_string(json_str)
	if save_data == null:
		print("save bilgileri bulunamadı")
		Global.is_loading_game = false
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
		#PawnManager.current_pawns.clear()
		PawnManager.load_save_data(save_data["characters"])
	if save_data.has("stockpiles"):
		ZoneManager.load_save_data(save_data["stockpiles"])
	if save_data.has("jobs"):
		JobManager.load_save_data(save_data["jobs"])
	SaveBlocker.hide()
	get_tree().paused = false
	Global.is_loading_game = false

func clear_current_world():
	var old_pawns = get_tree().get_nodes_in_group("Pawn Group")
	var old_pawnsui = PawnsUI.get_node("PawnPanel/ScrollContainer/VBoxContainer").get_children()
	for pawn_ui in old_pawnsui:
		if pawn_ui.visible:
			pawn_ui.queue_free()
	for pawn in old_pawns:
		pawn.remove_from_group("Pawn Group")
		pawn.queue_free()
	
	PawnManager.current_pawns.clear()
	ItemManager.grid_items.clear()
	JobManager.available_jobs.clear()
	JobManager.suspended_jobs.clear()
	BuildManager.active_blueprints.clear()
	ZoneManager.stockpiles.clear()

func load_metadata():
	if not FileAccess.file_exists("user://colony_save.json"):
		print("dosyaya erişilemedi çıkılıyor")
		return
		
	var file = FileAccess.open_compressed("user://colony_save.JSON", FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	var json_string = file.get_as_text()
	file.close()
	var parse_result = JSON.parse_string(json_string)
	
	if parse_result != null:
		print(parse_result.keys())
		if parse_result.has("map_data"):
			if parse_result["map_data"].has("meta_data"):
				var meta = parse_result["map_data"]["meta_data"]
				print(meta)
				Global.map_width = int(meta.get("map_width", 100)) # Değer yoksa varsayılan 100
				Global.map_height = int(meta.get("map_height", 100))
				Global.custom_seed = meta.get("seed", "")
