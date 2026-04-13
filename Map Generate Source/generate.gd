extends Node2D

const MAX_ROOF_SUPPORT_DIST = 5

var current_tool_mode = Global.ToolMode.NONE
var is_dragging: bool = false
var is_canceled: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO
var last_clicked_cell: Vector2i = Vector2i(-1, -1)
var selection_index: int = 0

var ghost_blueprint: BluePrint
var ghost_sprite: Sprite2D

var selected_structure_id = "none"

signal check_tile_info(tile_ground: String, tile_top: String, tile_roof: String, tile_max_health: int, tile_current_health: int)
signal check_stockpile_info(size: Vector2i, materials: Dictionary)
signal check_item_info(item: Dictionary)

@onready var selection_box = $ColorRect

@export var item_drop: PackedScene
@export var structure_recipes: Dictionary = {}

@onready var terrain_layer: TileMapLayer = $Layers/TerrainLayer
@onready var object_layer: TileMapLayer = $Layers/Ysorted/ObjectLayer
@onready var plant_layer: TileMapLayer = $Layers/Ysorted/PlantLayer
@onready var icon_layer: TileMapLayer = $Layers/IconLayer
@onready var item_layer: TileMapLayer = $Layers/Ysorted/ItemLayer
@onready var zone_layer: TileMapLayer = $Layers/ZoneLayer
@onready var roof_layer: TileMapLayer = $Layers/RoofLayer
@onready var selection_layer: TileMapLayer = $Layers/SelectionLayer
@onready var work_selection_layer: TileMapLayer = $Layers/WorkSelectionLayer

var tileMap_cell_size
@export var width = 100
@export var height = 100

var grass_id = 0
var tree_id = 1
var stone_tile_id = 2
var new_tileset_id = 3

var ore_types: Array[String] = ["stone", "iron", "gold", "copper"]
var dirt_res: Array[String] = ["clay"]
var ground_types: Array[String] = ["grass", "dirt"]
var structures: Array[String] = ["stone_wall"]
var floors: Array[String] = ["wooden_floor", "stone_floor"]
var deconstructables: Array = []
var all_resources: Array[String] = ["stone", "iron", "gold", "copper", "clay", "tree"]

var speed_multipliers: Dictionary = {
	"dirt": 1,
	"grass": 0.8,
	"wooden_floor": 1.1,
	"stone_floor": 1.2
}

var tile_resources: Dictionary = {
	"stone": load("res://Map Generate Source/TileData/stone.tres"),
	"iron": load("res://Map Generate Source/TileData/iron.tres"),
	"gold": load("res://Map Generate Source/TileData/gold.tres"),
	"copper": load("res://Map Generate Source/TileData/copper.tres"),
	"clay": load("res://Map Generate Source/TileData/clay.tres"),
	"tree": load("res://Map Generate Source/TileData/tree.tres"),
}

var rng = RandomNumberGenerator.new()

var wood_atlas = Vector2i(5,0)

var tiles: Dictionary = {
	"stone": Vector2i(0, 9),
	"tree": Vector2i(0, 0),
	"stone_wall": Vector2i(1, 11),
	"clay": Vector2i(3, 10),
	"dirt": Vector2i(0, 3),
	"stone_floor": Vector2i(1, 13),
	"wooden_floor": Vector2i(1, 14)
}


var icon_tileset_id = 2
var icons: Dictionary = {
	"wood_cut": Vector2i(11, 6),
	"mine": Vector2i(8, 5),
	"build": Vector2i(10, 5),
	"deliver": Vector2i(4, 2),
	"dig": Vector2i(9, 5),
	"deconstruct": Vector2i(7, 6),
	"selection": Vector2i(5, 4),
	"mine_selection": Vector2i(4, 3),
	"work_selection": Vector2i(0, 10),
	"stockpile_selection": Vector2i(6, 3),
	"item_selection": Vector2i(17,2)
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
	tileMap_cell_size = terrain_layer.tile_set.tile_size.x
	width = Global.map_width
	height = Global.map_height
	SaveManager.clear_current_world()
	deconstructables = structure_recipes.keys()
	selection_box.hide()
	Global.current_map = self
	current_tool_mode = Global.ToolMode.NONE
	BuildManager.structure_built.connect(_on_structure_built)
	BuildManager.build_aborted.connect(_on_clear_bp)
	generate_map()
	Global.map_created.emit()
	Global.tool_mode_changed.connect(set_tool_mode)
	Global.is_in_game = true

#Diğer oluşum fonksiyonlarını gerekli sırayla çalıştırır.
func generate_map() -> void:
	terrain_layer.clear()
	object_layer.clear()
	plant_layer.clear()
	icon_layer.clear()
	if InfoMenu.visible:
		PawnsUI.visible = false
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
		var stones = 0
		for y in height:
			for x in width:
				if map_data[y][x]["top"] == "stone":
					stones += 1
		#print(stones)
		var ore_ratio = stones * 0.0004
		#print(ore_ratio)
		generate_veins("iron", int(8 * ore_ratio), 20)
		generate_veins("gold", int(5 * ore_ratio), 10)
		generate_veins("copper", int(15 * ore_ratio), 20)
		generate_floor_res("clay", int(6 * ore_ratio), 10)
		spawn_trees()
		
		print_map()
		set_astar_grid()
		
		PawnManager.spawn_pawns()
	else:
		SaveManager.load_metadata()
		width = Global.map_width
		height = Global.map_height
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
			
			var current_ground = "dirt" if is_wall else "grass"
			var current_top = "stone" if is_wall else "none"
			var current_roof = "mountain" if is_wall else "none"
			var speed_multiplier = speed_multipliers[current_ground]
			
			var cell_info = {
				"ground": current_ground,
				"top": current_top,
				"roof": current_roof,
				"health": tile_resources["stone"].max_health if is_wall else 0,
				"marked_for_mining": false,
				"speed_multiplier": speed_multiplier
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
				is_wall = (map_data[y][x]["top"] == "stone")
				
			var current_ground = "dirt" if is_wall else "grass"
			var current_top = "stone" if is_wall else "none"
			var current_roof = "mountain" if is_wall else "none"
			var speed_multiplier = speed_multipliers[current_ground]
			if is_border(x, y):
				is_wall = true
			
			var cell_info = {
				"ground": current_ground,
				"top": current_top,
				"roof": current_roof,
				"health": tile_resources["stone"].max_health if is_wall else 0,
				"marked_for_mining": false,
				"speed_multiplier": speed_multiplier
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
			elif map_data[ny][nx]["top"] != "none":
				count += 1
			
	return count 

#Dizide kaydedilmiş haritayı TileMapLayer'a yazdırır.
func print_map():
	for y in height:
		for x in width:
			var cell = map_data[y][x]
			var pos = Vector2i(x, y)
			if cell["ground"] == "dirt":
				terrain_layer.set_cell(pos, new_tileset_id, tiles["dirt"])
			elif cell["ground"] in floors:
				terrain_layer.set_cell(pos, new_tileset_id, tiles[cell["ground"]])
			else:
				terrain_layer.set_cell(pos, new_tileset_id, get_weigthed_grass())
			if cell["top"] == "stone":
				object_layer.set_cell(pos, new_tileset_id, tiles["stone"])
				terrain_layer.set_cell(pos, new_tileset_id, tiles["dirt"])
			elif cell["top"] in ore_types and cell["top"] != "stone":
				var ore_name = cell["top"]
				object_layer.set_cell(pos, new_tileset_id, get_weighted_ore(ore_name))
			elif cell["top"] == "tree":
				plant_layer.set_cell(pos, tree_id, tiles["tree"])
			elif cell["top"] in structures:
				object_layer.set_cell(pos, new_tileset_id, tiles[cell["top"]])
			elif cell["top"] == "clay":
				var res_name = cell["top"]
				object_layer.set_cell(pos, new_tileset_id, get_weighted_resource(res_name))
			if cell["roof"] != "none" and (cell["top"] == "none" or cell["top"] in structure_recipes.keys()):
				roof_layer.set_cell(pos, 2, Vector2i(0,0))

func mark_for_mining(map_pos: Vector2i):
	var cell = map_data[map_pos.y][map_pos.x]
	if cell["top"] == "stone" or cell["top"] == "tree" or cell["top"] == "iron":
		cell["marked_for_mining"] = true
		
		#print("kazılmak için işaretlendi: ", map_pos)

func _process(_delta: float) -> void:
	var coords = terrain_layer.local_to_map(get_global_mouse_position())
	PawnsUI.coords_panel.set_coords(coords.x, coords.y)

func _unhandled_input(event: InputEvent) -> void:
	if Global.is_saving_game or Global.is_loading_game:
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
	if event.is_action_pressed("rotate_build"):
		if current_tool_mode == Global.ToolMode.BUILD_WALL and ghost_blueprint != null:
			ghost_blueprint.facing = (ghost_blueprint.facing + 1) % 4
			update_build_preview()
	
	if event is InputEventMouseButton:
		if current_tool_mode == Global.ToolMode.NONE:
			if event.button_index == MOUSE_BUTTON_LEFT and not is_dragging and not event.is_released():
				var space_data = get_world_2d().direct_space_state
				var query = PhysicsPointQueryParameters2D.new()
				query.position = get_global_mouse_position()
				query.collision_mask = 2
				var hit_res = space_data.intersect_point(query)
				if hit_res.size() > 0:
					selection_layer.clear()
					return
				
				PawnManager.emit_signal("pawn_focus_cancelled")
				work_selection_layer.clear()
				
				
				var coords = terrain_layer.local_to_map(terrain_layer.to_local(get_global_mouse_position()))
				if not is_within_bounds(coords.x, coords.y):
					return
				if coords == last_clicked_cell:
					selection_index += 1
				else:
					last_clicked_cell = coords
					selection_index = 0
				selection_layer.clear()
				
				var selectibles: Array[String] = ["tile"]
				
				if ZoneManager.cell_in_any_zone(coords):
					selectibles.append("stockpile")
				if ItemManager.get_item_at(coords):
					selectibles.append("item")
				
				var curre_selection = selectibles[selection_index % selectibles.size()]
				
				match curre_selection:
					"tile":
						var cell = map_data[coords.y][coords.x]
						var max_health = 0
						var current_health = 0
						
						if cell.has("shared_data") and cell["shared_data"] != null:
							#print("shared_data bulundu")
							max_health = cell["shared_data"]["max_health"]
							current_health = cell["shared_data"]["health"]
						else:
							if cell["top"] != "none" and cell["top"] in tile_resources.keys():
								max_health = tile_resources[cell["top"]].max_health
							elif cell["top"] in structure_recipes.keys():
								max_health = structure_recipes["stone_wall"].health
							if cell.has("health"):
								current_health = cell["health"]
						var job = JobManager.check_job(coords)
						var bp = null
						if BuildManager.check_blueprint(coords):
							bp = BuildManager.active_blueprints[coords]
						check_tile_info.emit(cell["ground"], cell["top"], cell["roof"], cell["speed_multiplier"],
						max_health, current_health, job, JobManager.job_in_list(job), bp)
						selection_layer.set_cell(coords, 1, icons["selection"])
					"stockpile":
						var cells = ZoneManager.get_stockpile_cells(coords)
						for coord in cells:
							selection_layer.set_cell(coord, 1, icons["stockpile_selection"])
						check_stockpile_info.emit(cells.size(), ZoneManager.get_stockpile_items(cells))
					"item":
						var item = ItemManager.get_item_at(coords)
						check_item_info.emit(item)
						selection_layer.set_cell(coords, 1, icons["item_selection"])
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				PawnManager.pawn_focus_cancelled.emit()
				PawnsUI.info_panel.hide()
				selection_layer.clear()
			if is_dragging:
				is_dragging = false
				selection_box.hide()
			return
			
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_dragging:
				is_dragging = false
				selection_box.hide()
				work_selection_layer.clear()
				
			else:
				Global.tool_mode_changed.emit(Global.ToolMode.NONE)
			
			get_viewport().set_input_as_handled()
			return
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if current_tool_mode == Global.ToolMode.BUILD_WALL and ghost_blueprint != null:
					var footprint = ghost_blueprint.get_occupied_tiles()
					if is_placement_valid(footprint):
						BuildManager.create_blueprint_from_ghost(ghost_blueprint)
					return
				is_dragging = true
				drag_start_pos = get_global_mouse_position()
				selection_box.global_position = drag_start_pos
				selection_box.size = Vector2.ZERO
				selection_box.show()
			else:
				if is_dragging:
					is_dragging = false
					selection_box.hide()
					var selected_tiles = get_full_tiles()
					process_selection_area(selected_tiles)
	
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
			update_work_selection()
		else:
			if current_tool_mode == Global.ToolMode.BUILD_WALL:
				update_build_preview()
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

func process_selection_area(selected_tiles: Array[Vector2i]):
	var stockpile: Array[Vector2i] = []
	
	if current_tool_mode == Global.ToolMode.CREATE_ZONE:
		stockpile = []
	
	for current_map_pos in selected_tiles:
		var cell = map_data[current_map_pos.y][current_map_pos.x]
		var cell_type = cell["top"]
		
		var cell_world_pos = terrain_layer.map_to_local(current_map_pos)
		
		match current_tool_mode:
			Global.ToolMode.MINE:
				if cell_type in ore_types:
					assign_job_to_cell(current_map_pos, cell_world_pos, Job.Type.MINING)
			Global.ToolMode.CHOP_WOOD:
				if cell_type == "tree":
					assign_job_to_cell(current_map_pos, cell_world_pos, Job.Type.WOOD_CUTTING)
			Global.ToolMode.CREATE_ZONE:
				if cell_type == "none" and not ZoneManager.cell_in_any_zone(current_map_pos):
					stockpile.append(current_map_pos)
					zone_layer.set_cell(current_map_pos, grass_id, wood_atlas)
			Global.ToolMode.CANCEL_JOB:
				var job = JobManager.check_job(current_map_pos)
				
				if job:
					JobManager.abort_job(job)
				if BuildManager.active_blueprints.has(current_map_pos):
					BuildManager.abort_blueprint(current_map_pos)
			Global.ToolMode.BUILD_WALL:
				if ghost_blueprint!= null and ghost_blueprint.get_occupied_tiles().size() == 1:
					if (cell_type == "none" or cell_type in all_resources) and not BuildManager.check_blueprint(current_map_pos):
						BuildManager.create_blueprint(current_map_pos, ghost_blueprint.recipe)
				if ghost_blueprint == null:
					var is_floor = selected_structure_id in floors
					if is_floor:
						if not cell["ground"] in floors and not BuildManager.check_blueprint(current_map_pos) or cell["top"] in structure_recipes.keys():
							BuildManager.create_blueprint(current_map_pos, structure_recipes[selected_structure_id])
					else:
						if (cell_type == "none" or cell_type in all_resources) and not BuildManager.check_blueprint(current_map_pos) and selected_structure_id != "none":
							BuildManager.create_blueprint(current_map_pos, structure_recipes[selected_structure_id])
			Global.ToolMode.ALLOW_ITEM:
				if cell_type == "none" and ItemManager.get_item_at(current_map_pos) != null:
					assign_job_to_cell(current_map_pos, cell_world_pos, Job.Type.HAUL_ITEMS)
			Global.ToolMode.DIG:
				if cell_type in dirt_res:
					assign_job_to_cell(current_map_pos, cell_world_pos, Job.Type.DIGGING)
			Global.ToolMode.DECONSTRUCT:
				var target_coords = current_map_pos
				if cell_type in deconstructables:
					if cell.has("shared_data") and cell["shared_data"] != null:
						target_coords = cell["shared_data"]["anchor"]
					if JobManager.check_job(target_coords):
						continue
					assign_job_to_cell(target_coords, terrain_layer.map_to_local(target_coords), Job.Type.DECONSTRUCT)
			Global.ToolMode.REMOVE_FLOOR:
				var target_coords = current_map_pos
				if cell["ground"] in floors:
					assign_job_to_cell(target_coords, terrain_layer.map_to_local(target_coords), Job.Type.REMOVE_FLOOR)
			Global.ToolMode.BUILD_ROOF:
				var target_coords = current_map_pos
				if cell["roof"] == "none" and cell["top"] != "tree":
					assign_job_to_cell(target_coords, terrain_layer.map_to_local(target_coords), Job.Type.BUILD_ROOF)
			Global.ToolMode.REMOVE_ROOF:
				var target_coords = current_map_pos
				if not cell["roof"] in ["none", "mountain"]:
					assign_job_to_cell(target_coords, terrain_layer.map_to_local(target_coords), Job.Type.REMOVE_ROOF)
	if stockpile.size() > 0:
		ZoneManager.create_stockpile(stockpile)
	work_selection_layer.clear()
	
	
	"""for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var current_map_pos = Vector2i(x, y)
			
			if not is_within_bounds(current_map_pos.x, current_map_pos.y):
				continue
			
			var cell = map_data[current_map_pos.y][current_map_pos.x]
			var cell_type = cell["top"]
			if current_tool_mode == Global.ToolMode.MINE:
				if cell_type in ore_types:
					var cell_world_pos = terrain_layer.map_to_local(current_map_pos)
					assign_job_to_cell(current_map_pos, cell_world_pos, Job.Type.MINING)
			elif current_tool_mode == Global.ToolMode.CHOP_WOOD:
				if cell_type == "tree":
					var cell_world_pos = terrain_layer.map_to_local(current_map_pos)
					assign_job_to_cell(current_map_pos, cell_world_pos, Job.Type.WOOD_CUTTING)
			elif current_tool_mode == Global.ToolMode.CREATE_ZONE:
				if cell_type == "none" and not ZoneManager.cell_in_any_zone(current_map_pos):
					stockpile.append(current_map_pos)
					zone_layer.set_cell(current_map_pos, grass_id, wood_atlas)
			elif current_tool_mode == Global.ToolMode.CANCEL_JOB:
				if cell_type != "none":
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
				if cell_type == "none":
					BuildManager.create_blueprint(current_map_pos, structure_recipes["stone_wall"])
			elif current_tool_mode == Global.ToolMode.ALLOW_ITEM:
				if cell_type == "none" and ItemManager.get_item_at(current_map_pos) != null:
					var cell_world_pos = terrain_layer.map_to_local(current_map_pos)
					assign_job_to_cell(current_map_pos, cell_world_pos, Job.Type.HAUL_ITEMS)
			elif current_tool_mode == Global.ToolMode.DIG:
				if cell_type in dirt_res:
					var cell_world_pos = terrain_layer.map_to_local(current_map_pos)
					assign_job_to_cell(current_map_pos, cell_world_pos, Job.Type.DIGGING)
	
	if stockpile and stockpile.size() > 0:
		ZoneManager.create_stockpile(stockpile)"""

func assign_job_to_cell(map_pos: Vector2i, mouse_pos: Vector2, job_type: int):
	var cell = map_data[map_pos.y][map_pos.x]
	var priority = 1
	
	if job_type == Job.Type.HAUL_ITEMS or job_type == Job.Type.DELIVER_MATERIAL:
		priority = 0
	
	if not cell["marked_for_mining"]:
		cell["marked_for_mining"] = true
		JobManager.post_job(job_type,map_pos, mouse_pos, priority)
		#print("yeni iş atandı: ", map_pos, " ", job_type)

func is_within_bounds(x, y) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height

func get_walk_pos():
	var val_pos = []
	for y in range(height):
		for x in range(width):
			if map_data[y][x]["top"] == "none":
				val_pos.append(Vector2i(x, y))
	return val_pos

func spawn_trees():
	var walk_pos = get_walk_pos()
	if walk_pos.is_empty():
		print("yürünebilir alan yok!")
		return
	count_tree = int(walk_pos.size() * 0.25)
	#print(walk_pos.size())
	for i in range(count_tree):
		var pos = walk_pos.pick_random()
		#print(pos)
		map_data[pos.y][pos.x]["top"] = "tree"
		map_data[pos.y][pos.x]["health"] = tile_resources["tree"].max_health

func damage_tile(coords: Vector2i, amount: int, target_layer: String = "top"):
	#print(coords)
	var x = coords.x
	var y = coords.y
	if not is_within_bounds(x, y):
		return false
	#print(target_layer)
	
	var cell = map_data[y][x]
	if target_layer == "top":
		if cell["top"] != "none":
			if cell.has("shared_data") and cell["shared_data"] != null:
				var s_data = cell["shared_data"]
				s_data["health"] -= amount
				
				if s_data["health"] <= 0:
					var prev_type = cell["top"]
					var anchor = s_data["anchor"]
				
					for tile in s_data["footprint"]:
						var t_cell = map_data[tile.y][tile.x]
						t_cell["top"] = "none"
						t_cell["shared_data"] = null
						t_cell["marked_for_mining"] = false
						astar_grid.set_point_solid(tile, false)
						update_roofs_after_mining(tile)
					var node_name = "Structure_" + str(s_data["anchor"].x) + "_" + str(s_data["anchor"].y)
					var node_to_delete = object_layer.get_node_or_null(node_name)
				#print(node_to_delete)
					if node_to_delete:
						node_to_delete.queue_free()
					else:
						object_layer.erase_cell(anchor)
					spawn_loot(anchor, prev_type)
					JobManager.wake_up_jobs()
					if BuildManager.check_blueprint(coords):
						var bp: BluePrint = BuildManager.active_blueprints[coords]
						icon_layer.set_cell(coords, icon_tileset_id, icons["build"])
						bp.is_blocked = false
						JobManager.unsuspended_blueprint_job(bp)
					return true
				return false
			
		cell["health"] -= amount
		#print("Duvar canı: ", cell.health)
		
		if cell["health"] <= 0:
			var prev_type = cell["top"]
			cell["top"] = "none"
			cell["marked_for_mining"] = false
			spawn_loot(coords, prev_type)
			if prev_type in ore_types or prev_type in dirt_res or prev_type in structures:
				object_layer.erase_cell(coords)
			if prev_type in ore_types:
				roof_layer.set_cell(coords, 2, Vector2i(0 ,0))
				cell["roof"] = "mountain"
			elif prev_type == "tree":
				plant_layer.erase_cell(coords)
			
			icon_layer.erase_cell(coords)
			astar_grid.set_point_solid(coords, false)
			JobManager.wake_up_jobs()
			if BuildManager.check_blueprint(coords):
				var bp: BluePrint = BuildManager.active_blueprints[coords]
				icon_layer.set_cell(coords, icon_tileset_id, icons["build"])
				bp.is_blocked = false
				JobManager.unsuspended_blueprint_job(bp)
			if prev_type in ore_types or prev_type in structures:
				update_roofs_after_mining(coords)
			return true
	elif target_layer == "ground":
		if cell["ground"] in floors:
			var prev_type = cell["ground"]
			cell["ground"] = "dirt"
			cell["marked_for_mining"] = false
			spawn_loot(coords, prev_type)
			terrain_layer.set_cell(coords, new_tileset_id, tiles["dirt"])
			return true
	elif target_layer == "roof":
		if not cell["roof"] in ["none", "mountain"]:
			print("vurdu")
			var prev_type = cell["roof"]
			cell["roof"] = "none"
			cell["marked_for_mining"] = false
			roof_layer.erase_cell(coords)
			update_roofs_after_mining(coords)
			return true
	return false

func set_astar_grid():
	astar_grid.region = Rect2i(0, 0, width, height)
	astar_grid.cell_size = Vector2i(tileMap_cell_size, tileMap_cell_size)
	astar_grid.offset = astar_grid.cell_size / 2
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar_grid.update()
	
	for y in height:
		for x in width:
			var coords = Vector2i(x, y)
			var speed = map_data[y][x]["speed_multiplier"]
			astar_grid.set_point_weight_scale(coords, 1.0 / speed)
			
	
	for tile in object_layer.get_used_cells():
		astar_grid.set_point_solid(tile, true)
	for tile in plant_layer.get_used_cells_by_id(1, tiles["tree"]):
		astar_grid.set_point_solid(tile, false)
	for tile in object_layer.get_used_cells_by_id(3, tiles["clay"]):
		astar_grid.set_point_solid(tile, false)

func spawn_loot(grid_coords: Vector2i, type: String):
	if item_drop == null:
		return
	
	var drop_amount = 0
	var drop_name = ""
	
	if tile_resources.has(type):
		drop_amount = randi_range(tile_resources[type].drop_min, tile_resources[type].drop_max)
		drop_name = tile_resources[type].drop_material
	
	if structure_recipes.has(type):
		var recipe: StructureRecipe = structure_recipes[type]
		for mat in recipe.materials.keys():
			drop_amount = recipe.materials[mat] * (randf_range(0.1, 0.5))
			drop_name = mat
	
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
		
		while map_data[current_y][current_x]["top"] != "stone" and attempts < 100:
			current_x = rng.randi_range(1, width - 2)
			current_y = rng.randi_range(1, height - 2)
			attempts += 1
		
		if map_data[current_y][current_x]["top"] == "stone":
			for s in range(vein_size):
				map_data[current_y][current_x]["top"] = ore_name
				map_data[current_y][current_x]["health"] = health
				
				var dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
				var dir = dirs.pick_random()
				
				var next_x = current_x + dir.x
				var next_y = current_y + dir.y
				
				if not is_border(next_x, next_y):
					var next_type = map_data[next_y][next_x]["top"]
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
		
		while map_data[current_y][current_x]["top"] != "none" and attempts < 100:
			current_x = rng.randi_range(1, width - 2)
			current_y = rng.randi_range(1, height - 2)
			attempts += 1
		
		if map_data[current_y][current_x]["top"] == "none":
			for s in range(group_size):
				map_data[current_y][current_x]["top"] = item_name
				map_data[current_y][current_x]["health"] = health
				
				var dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
				var dir  = dirs.pick_random()
				
				var next_x = current_x + dir.x
				var next_y = current_y + dir.y
				
				var next_type = map_data[next_y][next_x]["top"]
				
				if next_type == "none" or next_type == item_name:
					current_x = next_x
					current_y = next_y

func _on_structure_built(anchor_coords: Vector2i, structure_id: String, footprint: Array[Vector2i], facing: int):
	var shared_structure_data = {
		"health": structure_recipes[structure_id].health,
		"max_health": structure_recipes[structure_id].health,
		"anchor": anchor_coords,
		"facing": facing,
		"footprint": footprint
	}
	
	if structure_id not in floors:
		for coords in footprint:
			map_data[coords.y][coords.x]["top"] = structure_id
			map_data[coords.y][coords.x]["shared_data"] = shared_structure_data
			icon_layer.erase_cell(coords)
		match structure_id:
			"stone_wall":
				object_layer.set_cell(anchor_coords, new_tileset_id, tiles[structure_id])
				astar_grid.set_point_solid(anchor_coords, true)
	else:
		map_data[anchor_coords.y][anchor_coords.x]["ground"] = structure_id
		#map_data[anchor_coords.y][anchor_coords.x]["shared_data"] = shared_structure_data
		icon_layer.erase_cell(anchor_coords)
		match structure_id:
			"stone_floor":
				terrain_layer.set_cell(anchor_coords, new_tileset_id, tiles[structure_id])
				map_data[anchor_coords.y][anchor_coords.x]["speed_multiplier"] = speed_multipliers[structure_id]
			"wooden_floor":
				terrain_layer.set_cell(anchor_coords, new_tileset_id, tiles[structure_id])
				map_data[anchor_coords.y][anchor_coords.x]["speed_multiplier"] = speed_multipliers[structure_id]
		var coords = anchor_coords
		var speed = map_data[coords.y][coords.x]["speed_multiplier"]
		astar_grid.set_point_weight_scale(coords, 1.0 / speed)

func get_save_data() -> Dictionary:
	var map_save_array = []
	var structure_save_array = []
	var processed_anchors = {}
	
	for y in range(map_data.size()):
		var row = map_data[y]
		for x in range(row.size()):
			var cell_data = row[x]
			if cell_data != null:
				var clean_cell = cell_data.duplicate()
				clean_cell.erase("shared_data")
				map_save_array.append({
					"x": x,
					"y": y,
					"cell_info": clean_cell
				})
				
				var s_data = cell_data.get("shared_data")
				
				if typeof(s_data) == TYPE_DICTIONARY and s_data.has("anchor"):
					var anchor_key = str(s_data["anchor"].x) + "_" + str(s_data["anchor"].y)
					
					if not processed_anchors.has(anchor_key):
						processed_anchors[anchor_key] = true
						
						var safe_footprint = []
						if s_data.has("footprint"):
							for pos in s_data["footprint"]:
								safe_footprint.append({"x": pos.x, "y": pos.y})
						
						var safe_s_data = {
							"health": s_data["health"],
							"max_health": s_data["max_health"],
							"anchor_x": s_data["anchor"].x,
							"anchor_y": s_data["anchor"].y,
							"facing": s_data["facing"],
							"footprint": safe_footprint
						}
						structure_save_array.append(safe_s_data)
	return {"meta_data": {
			"map_width": Global.map_width,
			"map_height": Global.map_height,
			"seed": Global.custom_seed
			},
			"map_cells": map_save_array,
			"structures": structure_save_array
			}

func load_save_data(map_data_array: Dictionary):
	map_data.clear()
	for child in object_layer.get_children():
		child.queue_free()
	
	var map_cells = map_data_array["map_cells"]
	var saved_structures = map_data_array["structures"]
	
	for saved_cell in map_cells:
		var x = int(saved_cell["x"])
		var y = int(saved_cell["y"])
		var cell_info = saved_cell["cell_info"]
		
		while map_data.size() <= y:
			map_data.append([])
		
		while map_data[y].size() <= x:
			map_data[y].append(null)
		
		map_data[y][x] = cell_info
	for saved_struct in saved_structures:
		var real_anchor = Vector2i(int(saved_struct["anchor_x"]), int(saved_struct["anchor_y"]))
		var real_footprint: Array[Vector2i]
		for pos_dict in saved_struct["footprint"]:
			real_footprint.append(Vector2i(int(pos_dict["x"]), int (pos_dict["y"])))
		
		var s_data = {
			"health": saved_struct["health"],
			"max_health": saved_struct["max_health"],
			"anchor": real_anchor,
			"facing": int(saved_struct["facing"]),
			"footprint": real_footprint
		}
		
		var top_id = map_data[real_anchor.y][real_anchor.x]["top"]
		
		for tile in real_footprint:
			map_data[tile.y][tile.x]["shared_data"] = s_data
		
		if structure_recipes.has(top_id) and structure_recipes[top_id].scene != null:
			var new_struct = structure_recipes[top_id].scene.instantiate()
			new_struct.name = "Structure_" + str(real_anchor.x) + "_" + str(real_anchor.y)
			
			if "facing" in new_struct:
				new_struct.facing = s_data["facing"]
			
			var act_size = structure_recipes[top_id].size
			if s_data["facing"] == 1 or s_data["facing"] == 3:
				act_size = Vector2i(act_size.y, act_size.x)
			
			var anchor_world_pos = terrain_layer.map_to_local(real_anchor)
			var center_offset = Vector2(act_size.x - 1, act_size.y - 1) * (tileMap_cell_size / 2.0)
			
			new_struct.global_position = anchor_world_pos + center_offset
			object_layer.add_child(new_struct)

func load_seed():
	pass

func set_tool_mode(tool_mode: Global.ToolMode, structure: String = "none"):
	current_tool_mode = tool_mode
	selected_structure_id = structure
	if structure in structures or structure in floors:
		ghost_blueprint = null
		return
	
	if ghost_sprite != null:
		ghost_sprite.hide()
	
	if tool_mode == Global.ToolMode.BUILD_WALL and structure != "none":
		var sel_recipe: StructureRecipe = structure_recipes[structure]
		ghost_blueprint = BluePrint.new(Vector2i.ZERO, sel_recipe)
		
		if ghost_sprite == null:
			ghost_sprite = Sprite2D.new()
			ghost_sprite.z_index = 100
			add_child(ghost_sprite)
		if sel_recipe.ghost_texture != null:
			ghost_sprite.texture = sel_recipe.ghost_texture
			if sel_recipe.scene != null:
				var temp_scene = sel_recipe.scene.instantiate()
				var origin_sprite = temp_scene.get_node("Sprite2D")
				
				if origin_sprite:
					ghost_sprite.scale = temp_scene.scale
					ghost_sprite.offset = origin_sprite.offset
					ghost_sprite.centered = origin_sprite.centered
				else:
					ghost_sprite.scale = temp_scene.scale
				temp_scene.queue_free()
			ghost_sprite.show()
	else:
		ghost_blueprint = null

func _on_clear_bp(coords: Vector2i):
	icon_layer.erase_cell(coords)
	if BuildManager.active_blueprints.has(coords):
		var bp: BluePrint = BuildManager.active_blueprints[coords]
		if bp.recipe.structure_id in floors:
			return
		astar_grid.set_point_solid(coords, false)

func has_roof_support(coords: Vector2i) -> bool:
	var queue = [coords]
	var visited = {coords: true}
	
	while queue.size() > 0:
		var current_pos = queue.pop_front()	
		
		if coords.distance_to(Vector2(current_pos)) > MAX_ROOF_SUPPORT_DIST:
			continue
		
		var cell = map_data[current_pos.y][current_pos.x]
		var top_obj = cell["top"]
		
		if top_obj in structures or top_obj in ore_types:
			return true
		
		if cell["roof"] != "none" or current_pos == coords:
			var neighbors = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0),
			Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1),Vector2i(1, 1)]
			
			for offset in neighbors:
				var neighbor_pos = current_pos + offset
				
				if is_within_bounds(neighbor_pos.x, neighbor_pos.y):
					if not visited.has(neighbor_pos):
						visited[neighbor_pos] = true
						queue.append(neighbor_pos)
	return false

func update_roofs_after_mining(coords: Vector2i):
	for y in range(-MAX_ROOF_SUPPORT_DIST, MAX_ROOF_SUPPORT_DIST + 1):
		for x in range(-MAX_ROOF_SUPPORT_DIST, MAX_ROOF_SUPPORT_DIST + 1):
			var neighbor = coords + Vector2i(x, y)
			
			if is_within_bounds(neighbor.x, neighbor.y):
				if map_data[neighbor.y][neighbor.x]["roof"] != "none":
					if not has_roof_support(neighbor):
						collapse_roof(neighbor)
						var job = JobManager.check_job(neighbor)
						if job != null:
							if job.job_type == Job.Type.REMOVE_ROOF:
								JobManager.abort_job(job)

func collapse_roof(coords: Vector2i):
	map_data[coords.y][coords.x]["roof"] = "none"
	roof_layer.erase_cell(coords)
	print("çatı yıkıldı")

func update_work_selection():
	work_selection_layer.clear()
	
	var valid_tiles = get_full_tiles()
	
	for coords in valid_tiles:
		var cell = map_data[coords.y][coords.x]
		
		match current_tool_mode:
			Global.ToolMode.MINE:
				if cell["top"] in ore_types and not cell["marked_for_mining"]:
					work_selection_layer.set_cell(coords, 1, icons["work_selection"])
			Global.ToolMode.CHOP_WOOD:
				if cell["top"] == "tree" and not cell["marked_for_mining"]:
					work_selection_layer.set_cell(coords, 1, icons["work_selection"])
			Global.ToolMode.DIG:
				if cell["top"] in dirt_res and not cell["marked_for_mining"]:
					work_selection_layer.set_cell(coords, 1, icons["work_selection"])
			Global.ToolMode.BUILD_WALL:
				if not BuildManager.check_blueprint(coords):
					var is_floor = selected_structure_id in floors
					if is_floor:
						if not cell["ground"] in floors and (cell["top"] == "none" or cell["top"] in structure_recipes.keys()):
							work_selection_layer.set_cell(coords, 1, icons["work_selection"])
					else:
						if cell["top"] == "none" or cell["top"] in all_resources:
							work_selection_layer.set_cell(coords, 1, icons["work_selection"])
			Global.ToolMode.ALLOW_ITEM:
				if cell["top"] == "none" and ItemManager.get_item_at(Vector2i(coords.x, coords.y)) != null:
					work_selection_layer.set_cell(coords, 1, icons["work_selection"])
			Global.ToolMode.CREATE_ZONE:
				if cell["top"] == "none" and not ZoneManager.cell_in_any_zone(coords):
					work_selection_layer.set_cell(coords, 1, icons["work_selection"])
			Global.ToolMode.DECONSTRUCT:
				if cell["top"] in structure_recipes.keys():
					work_selection_layer.set_cell(coords, 1, icons["work_selection"])
			Global.ToolMode.REMOVE_FLOOR:
				if cell["ground"] in floors:
					work_selection_layer.set_cell(coords, 1, icons["work_selection"])
			Global.ToolMode.BUILD_ROOF:
				if cell["roof"] == "none" and cell["top"] != "tree":
					work_selection_layer.set_cell(coords, 1, icons["work_selection"])
			Global.ToolMode.REMOVE_ROOF:
				if not cell["roof"] in ["none", "mountain"]:
					work_selection_layer.set_cell(coords, 1, icons["work_selection"])

func get_full_tiles() -> Array[Vector2i]:
	var enclosed_tiles: Array[Vector2i] = []
	
	var selection_rect = Rect2(selection_box.global_position, selection_box.size)
	
	var tl_map = terrain_layer.local_to_map(terrain_layer.to_local(selection_rect.position))
	var br_map = terrain_layer.local_to_map(terrain_layer.to_local(selection_rect.end))
	
	var cell_size = Vector2(terrain_layer.tile_set.tile_size)
	
	var shrink_factor = 0.2
	var inner_box_size = cell_size * shrink_factor
	
	var max_sel_limit = 400
	
	var is_wall_mode = (current_tool_mode == Global.ToolMode.BUILD_WALL and ghost_blueprint == null and selected_structure_id != "none" and selected_structure_id not in floors)
	
	var min_x = min(tl_map.x, br_map.x)
	var max_x = max(tl_map.x, br_map.x)
	var min_y = min(tl_map.y, br_map.y)
	var max_y = max(tl_map.y, br_map.y)
	
	for y in range(min(tl_map.y, br_map.y) - 1, max(tl_map.y, br_map.y) + 2):
		for x in range(min(tl_map.x, br_map.x) - 1, max(tl_map.x, br_map.x) + 2):
			var coords = Vector2i(x, y)
			if enclosed_tiles.size() > max_sel_limit:
				break
			
			if is_within_bounds(coords.x, coords.y):
				var tile_center = terrain_layer.to_global(terrain_layer.map_to_local(coords))
				var tile_rect = Rect2(tile_center - inner_box_size / 2, inner_box_size) 
				
				if selection_rect.intersects(tile_rect):
					if is_wall_mode:
						if coords.x == min_x or coords.x == max_x or coords.y == min_y or coords.y == max_y:
							enclosed_tiles.append(coords)
					else:
						enclosed_tiles.append(coords)
		if enclosed_tiles.size() > max_sel_limit:
			break
	
	return enclosed_tiles

func is_placement_valid(occupied_tiles: Array[Vector2i]) -> bool:
	for coords in occupied_tiles:
		if not is_within_bounds(coords.x, coords.y):
			return false
		
		var cell = map_data[coords.y][coords.x]
		
		if cell["top"] != "none":
			return false
		
		if BuildManager.active_blueprints.has(coords):
			return false
		
	
	return true

func update_build_preview():
	work_selection_layer.clear()
	
	if current_tool_mode == Global.ToolMode.BUILD_WALL and ghost_blueprint != null:
		var mouse_map_pos = terrain_layer.local_to_map(get_global_mouse_position())
		
		ghost_blueprint.coords = mouse_map_pos
		
		var foot_print = ghost_blueprint.get_occupied_tiles()
		
		var can_build = is_placement_valid(foot_print)
		
		if ghost_sprite != null and ghost_sprite.visible:
			var act_size = ghost_blueprint.recipe.size
			if ghost_blueprint.facing == 1 or ghost_blueprint.facing == 3:
				act_size = Vector2i(act_size.y, act_size.x)
			var anchor_world_pos = terrain_layer.map_to_local(mouse_map_pos)
			
			var center_offset = Vector2(act_size.x - 1, act_size.y - 1) * (tileMap_cell_size/2)
			var true_center = anchor_world_pos + center_offset
			
			ghost_sprite.global_position = true_center
			ghost_sprite.rotation_degrees = ghost_blueprint.facing * (-90)
		
		if can_build:
			ghost_sprite.modulate = Color(0.5, 0.7, 1.0, 0.5)
		else:
			ghost_sprite.modulate = Color(1.0, 0.0, 0.0, 0.5)
		
		for coords in foot_print:
			if is_within_bounds(coords.x, coords.y):
				if can_build:
					work_selection_layer.set_cell(coords, 1, icons["work_selection"])

func build_tile_roof(coords: Vector2i):
	var cell = map_data[coords.y][coords.x]
	if cell["roof"] == "none":
		cell["roof"] = "handmade_roof"
		roof_layer.set_cell(coords, 2, Vector2i( 0, 0))
		icon_layer.erase_cell(coords)
		JobManager.unsuspend_all_jobs()
		return true
	return false


func _exit_tree() -> void:
	Global.is_in_game = false
