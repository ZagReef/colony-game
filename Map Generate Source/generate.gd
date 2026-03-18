extends Node2D

var current_tool_mode = Global.ToolMode.NONE
var is_dragging: bool = false
var is_canceled: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO
@onready var selection_box = $ColorRect

@export var item_drop: PackedScene

@export var structure_recipes: Dictionary = {}

@onready var terrain_layer = $Layers/TerrainLayer
@onready var object_layer = $Layers/Ysorted/ObjectLayer
@onready var plant_layer = $Layers/Ysorted/PlantLayer
@onready var icon_layer = $Layers/IconLayer
@onready var item_layer = $Layers/Ysorted/ItemLayer
@onready var zone_layer = $Layers/ZoneLayer

var tileMap_cell_size = 32
@export var width = 100
@export var height = 100

var grass_id = 0
var tree_id = 1
var stone_tile_id = 2
var new_tileset_id = 3

var ore_types: Array[String] = ["stone", "iron", "gold", "copper"]
var dirt_res: Array[String] = ["clay"]

var tile_resources: Dictionary = {
	"stone": load("res://Map Generate Source/TileData/stone.tres"),
	"iron": load("res://Map Generate Source/TileData/iron.tres"),
	"gold": load("res://Map Generate Source/TileData/gold.tres"),
	"copper": load("res://Map Generate Source/TileData/copper.tres"),
	"clay": load("res://Map Generate Source/TileData/clay.tres"),
	"tree": load("res://Map Generate Source/TileData/tree.tres")
}

var rng = RandomNumberGenerator.new()

var wood_atlas = Vector2i(5,0)

var tiles: Dictionary = {
	"stone": Vector2i(0, 9),
	"tree": Vector2i(0, 0),
	"stone_wall": Vector2i(2, 12),
	"clay": Vector2i(3, 10)
}


var icon_tileset_id = 2
var icons: Dictionary = {
	"wood_cut": Vector2i(11, 6),
	"mine": Vector2i(8, 5),
	"build": Vector2i(10, 5),
	"deliver": Vector2i(4, 2),
	"dig": Vector2i(9, 5)
}

var map_data = []
@export var fill_prob = 0.4
@export var threshold = 5 #8-7 ile oldukça benzer,7-aşırı dağınık ama uzun duvarlar,6-dağınık,5-mağara, 4-neredeyse boşluksuz
var it = 10
@export var default_seed : String = ""

@export var npc : PackedScene
@export var count_tree : int = 1000
@export var count_npc: int = 4

var astar_grid = AStarGrid2D.new()

func _ready() -> void:
	selection_box.hide()
	Global.current_map = self
	BuildManager.structure_built.connect(_on_structure_built)
	BuildManager.build_aborted.connect(_on_clear_bp)
	generate_map()
	Global.tool_mode_changed.connect(set_tool_mode)

#Diğer oluşum fonksiyonlarını gerekli sırayla çalıştırır.
func generate_map() -> void:
	terrain_layer.clear()
	object_layer.clear()
	plant_layer.clear()
	icon_layer.clear()
	if not Global.is_loading_game:
		if Global.custom_seed == "":
			Global.custom_seed = str(randi())
		default_seed = Global.custom_seed
		count_npc = Global.start_pawn_count
		threshold = Global.custom_threshold
		rng.seed = hash(default_seed)
		initialize_map()
		for i in it:
			smooth_map()
		generate_veins("iron", 8, 20)
		generate_veins("gold", 5, 10)
		generate_veins("copper", 15, 20)
		generate_floor_res("clay", 6, 10)
		spawn_trees()
		
		print_map()
		set_astar_grid()
		
		PawnManager.spawn_pawns()
	else:
		SaveManager.load_game()
		Global.is_loading_game = false

#Kenar kontrolü yapar.
func is_border(x,y):
	return x == 0 or x == width - 1 or y == 0 or y == height - 1

#Haritayı başlangıçta kabataslak oluşturur. (Belirlenen değişkenlerin uyguladığı kurallara göre)
func initialize_map():
	map_data.clear()
	for y in height:
		var row = []
		for x in width:
			var is_wall = (rng.randf() < fill_prob or is_border(x,y))
			
			var cell_info = {
				"type": "stone" if is_wall else "floor",
				"health": tile_resources["stone"].max_health if is_wall else 0,
				"marked_for_mining": false
			}
			row.append(cell_info)
		map_data.append(row)

#Cellular automata uygular.
func smooth_map():
	var new_map = []
	for y in height:
		var new_row = []
		for x in width:
			var wall_count = count_wall(x, y)
			var is_wall = false
			
			if wall_count >= threshold:
				is_wall = true
			elif wall_count <= 2:
				is_wall = false
			else:
				is_wall = (map_data[y][x]["type"] == "stone")
			
			if is_border(x, y):
				is_wall = true
			
			var cell_info = {
				"type": "stone" if is_wall else "floor",
				"health": tile_resources["stone"].max_health if is_wall else 0,
				"marked_for_mining": false
			}
			
			new_row.append(cell_info)
			
		new_map.append(new_row)
	map_data = new_map

#Bir hücrenin komşularındaki duvarları sayar.
func count_wall(x, y):
	var count = 0
	for dy in range(-1,2):
		for dx in range(-1,2):
			if dx == 0 and dy == 0:
				continue
			var nx = dx + x
			var ny = dy + y
			
			if nx < 0 or nx >= width or ny < 0 or ny >= height:
				count += 1
			elif map_data[ny][nx]["type"] != "floor":
				count += 1
			
	return count 

#Dizide kaydedilmiş haritayı TileMapLayer'a yazdırır.
func print_map():
	for y in height:
		for x in width:
			var cell = map_data[y][x]
			var pos = Vector2i(x, y)
			terrain_layer.set_cell(pos, new_tileset_id, get_weigthed_grass())
			if cell["type"] == "stone":
				object_layer.set_cell(pos, new_tileset_id, tiles["stone"])
			elif cell["type"] == "iron" or cell["type"] == "gold" or cell["type"] == "copper":
				var ore_name = cell["type"]
				object_layer.set_cell(pos, new_tileset_id, get_weighted_ore(ore_name))
			elif cell["type"] == "tree":
				plant_layer.set_cell(pos, tree_id, tiles["tree"])
			elif cell["type"] == "wall":
				object_layer.set_cell(pos, new_tileset_id, tiles["stone_wall"])
			elif cell["type"] == "clay":
				var res_name = cell["type"]
				object_layer.set_cell(pos, new_tileset_id, get_weighted_resource(res_name))

func mark_for_mining(map_pos: Vector2i):
	var cell = map_data[map_pos.y][map_pos.x]
	if cell["type"] == "stone" or cell["type"] == "tree" or cell["type"] == "iron":
		cell["marked_for_mining"] = true
		
		#print("kazılmak için işaretlendi: ", map_pos)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		InfoMenu.visible = !InfoMenu.visible
		Global.pressed_escape.emit()
		return
	if event.is_action_pressed("save_game"):
		SaveManager.save_game_json()
		return
	if event.is_action_pressed("tool_none"):
		current_tool_mode = Global.ToolMode.NONE
	if event.is_action_pressed("tool_mine"):
		current_tool_mode = Global.ToolMode.MINE
	if event.is_action_pressed("tool_chop"):
		current_tool_mode = Global.ToolMode.CHOP_WOOD
	if event.is_action_pressed("tool_cancel"):
		current_tool_mode = Global.ToolMode.CANCEL_JOB
	if event.is_action_pressed("tool_create_stockpile"):
		current_tool_mode = Global.ToolMode.CREATE_ZONE
	if event.is_action_pressed("tool_build"):
		current_tool_mode = Global.ToolMode.BUILD_WALL
	
	if event is InputEventMouseButton:
		if current_tool_mode == Global.ToolMode.NONE:
			if is_dragging:
				is_dragging = false
				selection_box.hide()
			return
			
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_dragging:
				is_dragging = false
				selection_box.hide()
			
			else:
				Global.tool_mode_changed.emit(Global.ToolMode.NONE)
			
			get_viewport().set_input_as_handled()
			return
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_start_pos = get_global_mouse_position()
				selection_box.global_position = drag_start_pos
				selection_box.size = Vector2.ZERO
				selection_box.show()
			else:
				if is_dragging:
					is_dragging = false
					selection_box.hide()
					process_selection_area(drag_start_pos, get_global_mouse_position())
	elif event is InputEventMouseMotion:
		if is_dragging:
			var current_mouse_pos = get_global_mouse_position()
			selection_box.global_position = Vector2i(
				min(drag_start_pos.x, current_mouse_pos.x),
				min(drag_start_pos.y, current_mouse_pos.y)
			)
		
			selection_box.size = Vector2(
				abs(drag_start_pos.x - current_mouse_pos.x),
				abs(drag_start_pos.y - current_mouse_pos.y)
			)
		"""
		var mouse_pos = get_global_mouse_position()
		var map_pos = object_layer.local_to_map(terrain_layer.to_local(mouse_pos))
		
		if not is_within_bounds(map_pos.x, map_pos.y):
			return
		
		var cell = map_data[map_pos.y][map_pos.x]
		var cell_type = cell["type"]
		
		if current_tool_mode == ToolMode.MINE:
			if cell_type == "stone" or cell_type == "iron":
				assign_job_to_cell(map_pos, mouse_pos, Job.Type.MINING)
			else:
				print("Burada kazılacak bir maden yok!")
		
		if current_tool_mode == ToolMode.CHOP_WOOD:
			if cell_type == "wood":
				assign_job_to_cell(map_pos, mouse_pos, Job.Type.WOOD_CUTTING)"""

func process_selection_area(start_pos: Vector2, end_pos: Vector2):
	var start_map = object_layer.local_to_map(terrain_layer.to_local(start_pos))
	var end_map = object_layer.local_to_map(terrain_layer.to_local(end_pos))
	#print(start_map, " ", end_map)
	
	var stockpile: Array[Vector2i]
	
	var min_x = min(start_map.x, end_map.x)
	var max_x = max(start_map.x, end_map.x)
	var min_y = min(start_map.y, end_map.y)
	var max_y = max(start_map.y, end_map.y)
	
	if current_tool_mode == Global.ToolMode.CREATE_ZONE:
		stockpile = []
	
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var current_map_pos = Vector2i(x, y)
			
			if not is_within_bounds(current_map_pos.x, current_map_pos.y):
				continue
			
			var cell = map_data[current_map_pos.y][current_map_pos.x]
			var cell_type = cell["type"]
			if current_tool_mode == Global.ToolMode.MINE:
				if cell_type in ore_types:
					var cell_world_pos = terrain_layer.map_to_local(current_map_pos)
					assign_job_to_cell(current_map_pos, cell_world_pos, Job.Type.MINING)
			elif current_tool_mode == Global.ToolMode.CHOP_WOOD:
				if cell_type == "tree":
					var cell_world_pos = terrain_layer.map_to_local(current_map_pos)
					assign_job_to_cell(current_map_pos, cell_world_pos, Job.Type.WOOD_CUTTING)
			elif current_tool_mode == Global.ToolMode.CREATE_ZONE:
				if cell_type == "floor" and not ZoneManager.cell_in_any_zone(current_map_pos):
					stockpile.append(current_map_pos)
					zone_layer.set_cell(current_map_pos, grass_id, wood_atlas)
			elif current_tool_mode == Global.ToolMode.CANCEL_JOB:
				if cell_type != "floor":
					var job = JobManager.check_job(current_map_pos)
					
					if job:
						#print("iş iptal edildi")
						JobManager.abort_job(job)
					
				else:
					var job = JobManager.check_job(current_map_pos)
					var bp = BuildManager.active_blueprints.has(current_map_pos)
					if job and job.job_type == Job.Type.HAUL_ITEMS:
						JobManager.abort_job(job)
					if bp:
						BuildManager.abort_blueprint(current_map_pos)
					if job:
						JobManager.abort_job(job)
			elif current_tool_mode == Global.ToolMode.BUILD_WALL:
				if cell_type == "floor":
					BuildManager.create_blueprint(current_map_pos, structure_recipes["stone_wall"])
			elif current_tool_mode == Global.ToolMode.ALLOW_ITEM:
				if cell_type == "floor" and ItemManager.get_item_at(current_map_pos) != null:
					var cell_world_pos = terrain_layer.map_to_local(current_map_pos)
					assign_job_to_cell(current_map_pos, cell_world_pos, Job.Type.HAUL_ITEMS)
			elif current_tool_mode == Global.ToolMode.DIG:
				if cell_type in dirt_res:
					var cell_world_pos = terrain_layer.map_to_local(current_map_pos)
					assign_job_to_cell(current_map_pos, cell_world_pos, Job.Type.DIGGING)
	
	if stockpile and stockpile.size() > 0:
		ZoneManager.create_stockpile(stockpile)

func assign_job_to_cell(map_pos: Vector2i, mouse_pos: Vector2, job_type: int):
	var cell = map_data[map_pos.y][map_pos.x]
	
	if not cell["marked_for_mining"]:
		cell["marked_for_mining"] = true
		JobManager.post_job(job_type,map_pos, mouse_pos, 1)
		#print("yeni iş atandı: ", map_pos, " ", job_type)

func is_within_bounds(x, y) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height

func handle_cell_click(pos: Vector2i):
	if map_data[pos.y][pos.x]["type"] == "stone":
		print("duvar var la")
		
	else:
		print("zemin var la: ", pos)

func get_walk_pos():
	var val_pos = []
	for y in range(height):
		for x in range(width):
			if map_data[y][x]["type"] == "floor":
				val_pos.append(Vector2i(x, y))
	return val_pos

func spawn_trees():
	var walk_pos = get_walk_pos()
	if walk_pos.is_empty():
		print("yürünebilir alan yok!")
		return
	#print(walk_pos.size())
	for i in range(count_tree):
		var pos = walk_pos.pick_random()
		#print(pos)
		map_data[pos.y][pos.x]["type"] = "tree"
		map_data[pos.y][pos.x]["health"] = 50

func damage_tile(coords: Vector2i, amount: int):
	#print(coords)
	var x = coords.x
	var y = coords.y
	if not is_within_bounds(x, y):
		return false
	
	var cell = map_data[y][x]
	
	if cell["type"] != "floor":
		cell["health"] -= amount
		#print("Duvar canı: ", cell.health)
		
		if cell["health"] <= 0:
			var prev_type = cell["type"]
			cell["type"] = "floor"
			cell["marked_for_mining"] = false
			spawn_loot(coords, prev_type)
			if prev_type in ore_types or prev_type in dirt_res:
				object_layer.erase_cell(coords)
			elif prev_type == "tree":
				plant_layer.erase_cell(coords)
			
			icon_layer.erase_cell(coords)
			astar_grid.set_point_solid(coords, false)
			JobManager.wake_up_jobs()
			return true
	
	return false

func set_astar_grid():
	astar_grid.region = Rect2i(0, 0, width, height)
	astar_grid.cell_size = Vector2i(tileMap_cell_size, tileMap_cell_size)
	astar_grid.offset = astar_grid.cell_size / 2
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.update()
	
	for tile in object_layer.get_used_cells():
		astar_grid.set_point_solid(tile, true)
	for tile in plant_layer.get_used_cells_by_id(1, tiles["tree"]):
		astar_grid.set_point_solid(tile, false)
	for tile in object_layer.get_used_cells_by_id(1, tiles["clay"]):
		astar_grid.set_point_solid(tile, false)

func spawn_loot(grid_coords: Vector2i, type: String):
	if item_drop == null:
		return
	
	var drop_amount = 0
	var drop_name = ""
	
	drop_amount = randi_range(tile_resources[type].drop_min, tile_resources[type].drop_max)
	drop_name = tile_resources[type].drop_material
	
	if drop_amount <= 0:
		return
	
	ItemManager.add_item_to_grid(
		grid_coords,
		drop_name,
		drop_amount,
		item_layer,
		item_drop,
		terrain_layer.map_to_local
	)
	
	JobManager.post_job(Job.Type.HAUL_ITEMS, grid_coords, terrain_layer.map_to_local(grid_coords), 0)

func get_weigthed_grass():
	var main_grass = Vector2i(0, 5)
	var grass2 = Vector2i(1, 5)
	var grass3 = Vector2i(2,5)
	
	var rand = randf()
	
	if rand < 0.80:
		return main_grass
	elif rand < 0.90:
		return grass2
	else:
		return grass3

func get_weighted_ore(ore_name: String):
	var ore1: Vector2i
	var ore2: Vector2i
	match ore_name:
		"iron":
			ore1 = Vector2i(1,9)
			ore2 = Vector2i(2, 9)
		"gold":
			ore1 = Vector2i(3, 9)
			ore2 = Vector2i(4, 9)
		"copper":
			ore1 = Vector2i(5, 9)
			ore2 = Vector2i(6, 9)
	
	var rand = randf()
	
	if rand < 0.50:
		return ore1
	else:
		return ore2

func get_weighted_resource(item_name: String):
	var res1: Vector2i
	var res2: Vector2i
	match item_name:
		"clay":
			res1 = Vector2i(3,10)
			res2 = Vector2i(4, 10)
	
	var rand = randf()
	
	if rand < 0.50:
		return res1
	else:
		return res2


func generate_veins(ore_name: String, vein_count: int, vein_size: int):
	var health: int = 0
	health = tile_resources[ore_name].max_health
	for v in range(vein_count):
		var current_x = rng.randi_range(1, width - 2)
		var current_y = rng.randi_range(1, height - 2)
		
		var attempts = 0
		
		while map_data[current_y][current_x]["type"] != "stone" and attempts < 100:
			current_x = rng.randi_range(1, width - 2)
			current_y = rng.randi_range(1, height - 2)
			attempts += 1
		
		if map_data[current_y][current_x]["type"] == "stone":
			for s in range(vein_size):
				map_data[current_y][current_x]["type"] = ore_name
				map_data[current_y][current_x]["health"] = health
				
				var dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
				var dir = dirs.pick_random()
				
				var next_x = current_x + dir.x
				var next_y = current_y + dir.y
				
				if not is_border(next_x, next_y):
					var next_type = map_data[next_y][next_x]["type"]
					if next_type == "stone" or next_type == ore_name:
						current_x = next_x
						current_y = next_y

func generate_floor_res(item_name: String, group_count: int, group_size: int):
	var health: int = 0
	health = tile_resources[item_name].max_health
	
	for v in range(group_count):
		var current_x = rng.randi_range(1, width - 2)
		var current_y = rng.randi_range(1, height - 2)
		
		var attempts = 0
		
		while map_data[current_y][current_x]["type"] != "floor" and attempts < 100:
			current_x = rng.randi_range(1, width - 2)
			current_y = rng.randi_range(1, height - 2)
			attempts += 1
		
		if map_data[current_y][current_x]["type"] == "floor":
			for s in range(group_size):
				map_data[current_y][current_x]["type"] = item_name
				map_data[current_y][current_x]["health"] = health
				
				var dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
				var dir  = dirs.pick_random()
				
				var next_x = current_x + dir.x
				var next_y = current_y + dir.y
				
				var next_type = map_data[next_y][next_x]["type"]
				
				if next_type == "floor" or next_type == item_name:
					current_x = next_x
					current_y = next_y

func _on_structure_built(coords: Vector2i, structure_id: String):
	match structure_id:
		"stone_wall":
			map_data[coords.y][coords.x]["type"] = "wall"
			map_data[coords.y][coords.x]["health"] = 300

func get_save_data() -> Array:
	var map_save_array = []
	
	for y in range(map_data.size()):
		var row = map_data[y]
		for x in range(row.size()):
			var cell_data = row[x]
			if cell_data != null:
				
				var clean_data = {
					"x": x,
					"y": y,
					"cell_info": cell_data
				}
				
				map_save_array.append(clean_data)
	
	return map_save_array

func load_save_data(map_data_array: Array):
	map_data.clear()
	
	for saved_cell in map_data_array:
		var x = int(saved_cell["x"])
		var y = int(saved_cell["y"])
		var cell_info = saved_cell["cell_info"]
		
		while map_data.size() <= y:
			map_data.append([])
		
		while map_data[y].size() <= x:
			map_data[y].append(null)
		
		map_data[y][x] = cell_info

func set_tool_mode(tool_mode: Global.ToolMode):
	current_tool_mode = tool_mode

func _on_clear_bp(coords: Vector2i):
	icon_layer.erase_cell(coords)
	astar_grid.set_point_solid(coords, false)
