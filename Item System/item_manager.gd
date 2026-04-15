extends Node

var ITEM_DB: Dictionary = {}
var grid_items: Dictionary = {}

const ITEM_FOLDER_PATH: String = "res://Item System/ItemData/Items/"

signal item_dropped_on_ground(coords: Vector2i, item_type: String)
signal item_removed(coords: Vector2i, item_type: String)

func _ready():
	load_all_items()

func load_all_items():
	var dir = DirAccess.open(ITEM_FOLDER_PATH)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var file_path = ITEM_FOLDER_PATH + file_name
				var item_data: ItemData = load(file_path)
				
				if item_data and item_data.item_id != "":
					ITEM_DB[item_data.item_id] = item_data
					print("eşya eklendi: ", item_data.item_id)
				
				file_name = dir.get_next()
	else:
		print("Eşya klasörü bulunamadı")

func add_item_to_grid(coords: Vector2i, item_type: String, amount: int, item_layer: Node2D, item_scene: PackedScene, map_to_local_func: Callable):
	if amount == 0:
		return
	
	if not ITEM_DB.has(item_type):
		print("böyle bir eşya yok: ", item_type)
		return
	
	var max_cap = ITEM_DB[item_type].max_stack
	
	if not grid_items.has(coords):
		var new_item = item_scene.instantiate()
		new_item.item_id = item_type
		new_item.item_amount = amount
		new_item.global_position = map_to_local_func.call(coords)
		
		item_layer.add_child(new_item)
		new_item.disp_amount(amount)
		
		grid_items[coords] = {
				"type": item_type,
				"amount": amount,
				"node": new_item
			}
		grid_items[coords]["node"].is_forbidden(false)
		item_dropped_on_ground.emit(coords, item_type)
	elif grid_items[coords]["type"] == item_type:
		var grid_item_amount = grid_items[coords]["amount"]
		if grid_item_amount + amount > max_cap:
			var leftover = grid_item_amount + amount - max_cap
			grid_items[coords]["amount"] = max_cap
			grid_items[coords]["node"].disp_amount(max_cap)
			
			var dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
			
			var spilled = false
			
			for dir in dirs:
				var neighbor_coords = coords + dir
				if not grid_items.has(neighbor_coords) or grid_items[neighbor_coords]["type"] == item_type and grid_items[neighbor_coords]["amount"] < max_cap:
					add_item_to_grid(neighbor_coords, item_type, leftover, item_layer, item_scene, map_to_local_func)
					spilled = true
					break
			if not spilled: print("eşyalar yok oldu")
		else: 
				grid_items[coords]["amount"] += amount
				grid_items[coords]["node"].disp_amount(grid_items[coords]["amount"])
	else:
		var dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		
		var spilled = false
		
		for dir in dirs:
			var neighbor_coords = coords + dir
			if not grid_items.has(neighbor_coords) or grid_items[neighbor_coords]["type"] == item_type and grid_items[neighbor_coords]["amount"] < max_cap:
				add_item_to_grid(neighbor_coords, item_type, amount, item_layer, item_scene, map_to_local_func)
				spilled = true
				break
		
		if not spilled:
			print("çakışma engellendi: ", item_type)

func get_item_at(map_pos):
	if grid_items.has(map_pos):
		return grid_items[map_pos]
	return null

func consume_item(coords: Vector2i, item_amount: int):
	if grid_items.has(coords):
		var item = grid_items[coords]
		item["amount"] -= item_amount
		
		item_removed.emit(coords, item["type"])
		
		if item["amount"] <= 0:
			item["node"].queue_free()
			grid_items.erase(coords)
		else:
			item["node"].disp_amount(item["amount"])

func get_closest_item(character_map_pos: Vector2i, item_type: String):
	var target_coords = null
	var min_dist = INF
	for coords in grid_items.keys():
		var item = grid_items[coords]
		#print(item)
		if item["type"] == item_type:
			var curr_dist = character_map_pos.distance_squared_to(coords)
			#print(curr_dist)
			if curr_dist < min_dist:
				min_dist = curr_dist
				target_coords = coords
	return target_coords

func get_save_data() -> Array:
	var item_save_array = []
	
	for coords in grid_items.keys():
		var item_data = grid_items[coords]
		
		var clean_data = {
			"x": coords.x,
			"y": coords.y,
			"type": item_data["type"],
			"amount": item_data["amount"]
		}
		
		item_save_array.append(clean_data)
	return item_save_array

func load_save_data(item_data_list: Array):
	for item_data in item_data_list:
		var map_pos = Vector2i(item_data["x"], item_data["y"])
		var item_type = item_data["type"]
		var amount  = item_data["amount"]
		
		add_item_to_grid(map_pos, item_type, amount,
		Global.current_map.item_layer, Global.current_map.item_drop, Global.current_map.terrain_layer.map_to_local)

func cancel_haul_item(coords: Vector2i):
	if grid_items.has(coords):
		grid_items[coords]["node"].is_forbidden(true)
		#print("taşıma işi iptal edildi")
		JobManager.abort_haul_job_coords(coords)

func reset_manager():
	grid_items.clear()
