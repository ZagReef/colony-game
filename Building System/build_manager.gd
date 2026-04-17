extends Node

class_name BlueprintManager

var active_blueprints: Dictionary = {}

signal blueprint_created(blueprint: BluePrint)
signal ready_to_build(blueprint: BluePrint)
signal structure_built(coords: Vector2i, structure_id: String, footprint: Array[Vector2i], facing: int)
signal build_aborted(coords: Vector2i)

func _ready() -> void:
	pass

func create_blueprint(coords: Vector2i, recipe: StructureRecipe):
	var cell = Global.current_map.map_data[coords.y][coords.x]
	var is_blocked = false
	
	if active_blueprints.has(coords): return
	
	if cell["top"] != "none" and not recipe.structure_id in Global.current_map.floors:
		is_blocked = true
		print("cell_top", cell["top"])
		if cell["top"] == "tree":
			JobManager.post_job(Job.Type.WOOD_CUTTING, coords, Global.current_map.terrain_layer.map_to_local(coords), 1)
		elif cell["top"] in Global.current_map.ore_types:
			JobManager.post_job(Job.Type.MINING, coords, Global.current_map.terrain_layer.map_to_local(coords), 1)
		elif cell["top"] in  Global.current_map.dirt_res:
			JobManager.post_job(Job.Type.DIGGING, coords, Global.current_map.terrain_layer.map_to_local(coords), 1)
	
	var new_bp = BluePrint.new(coords, recipe)
	new_bp.is_blocked = is_blocked
	active_blueprints[coords] = new_bp
	#print("gerekli materyal bulundu: ", active_blueprints[coords].get_material_needs())
	blueprint_created.emit(new_bp)

func create_blueprint_from_ghost(ghost_bp: BluePrint):
	var new_bp = BluePrint.new(ghost_bp.coords, ghost_bp.recipe, ghost_bp.facing)
	if new_bp.recipe.ghost_texture != null:
		var ghost_sprite = Sprite2D.new()
		ghost_sprite.texture = ghost_bp.recipe.ghost_texture
		ghost_sprite.modulate = Color(0.1, 1.0, 1.0, 0.5)
		
		var act_size = new_bp.recipe.size
		if new_bp.facing == 1 or new_bp.facing == 3:
			act_size = Vector2i(act_size.y, act_size.x)
		
		var anchor_world_pos = Global.current_map.terrain_layer.map_to_local(ghost_bp.coords)
		var center_offset = Vector2(act_size.x - 1, act_size.y - 1) * (Global.current_map.tileMap_cell_size / 2)
		ghost_sprite.global_position = anchor_world_pos + center_offset
		ghost_sprite.rotation_degrees = new_bp.facing * (-90)
		var ghost_sprite_scale: Vector2
		
		if new_bp.recipe.scene != null:
			var temp_scene = ghost_bp.recipe.scene.instantiate()
			ghost_sprite_scale = temp_scene.scale
			temp_scene.queue_free()
		
		ghost_sprite.apply_scale(ghost_sprite_scale)
		Global.current_map.object_layer.add_child(ghost_sprite)
		new_bp.visual_node = ghost_sprite
	var footprint = new_bp.get_occupied_tiles()
	
	for coords in footprint:
		active_blueprints[coords] = new_bp
		#Global.current_map.astar_grid.set_point_solid(coords, true)
		Global.current_map.icon_layer.set_cell(coords, 2, Global.current_map.icons["deliver"])
	
	blueprint_created.emit(new_bp)

func add_materials_to_blueprint(coords: Vector2i, item_type: String, amount: int):
	if active_blueprints.has(coords):
		var bp: BluePrint = active_blueprints[coords]
		
		if bp.progress.has(item_type):
			bp.progress[item_type]["incoming"] -= amount
			bp.progress[item_type]["current"] += amount
			
			if bp.is_ready_to_build():
				ready_to_build.emit(bp)
				if bp.recipe.structure_id in Global.current_map.floors:
					return

func finish_building(coords: Vector2i):
	if active_blueprints.has(coords):
		var bp: BluePrint = active_blueprints[coords]
		var structure_id = bp.recipe.structure_id
		var footprint = bp.get_occupied_tiles()
		
		for mat in bp.recipe.materials:
			if bp.progress[mat]["current"] > bp.recipe.materials[mat]:
				var leftover = bp.progress[mat]["current"] - bp.recipe.materials[mat]
				ItemManager.add_item_to_grid(bp.coords, mat, leftover, Global.current_map.item_layer,
				Global.current_map.item_drop, Global.current_map.terrain_layer.map_to_local)
		
		if bp.recipe.scene != null:
			var new_struct = bp.recipe.scene.instantiate()
			new_struct.max_health = bp.recipe.health
			new_struct.name = "Structure_" + str(bp.coords.x) + "_" + str(bp.coords.y)
			var act_size = bp.recipe.size
			if bp.facing == 1 or bp.facing == 3:
				act_size = Vector2i(act_size.y , act_size.x)
			
			var anchor_world_pos = Global.current_map.terrain_layer.map_to_local(bp.coords)
			var center_offset = Vector2(act_size.x - 1, act_size.y -1 ) * (Global.current_map.tileMap_cell_size / 2)
			new_struct.global_position = anchor_world_pos + center_offset
			if "facing" in new_struct:
				new_struct.facing = bp.facing
			
			Global.current_map.object_layer.add_child(new_struct)
			if new_struct.has_method("update_visual_rotation"):
				new_struct.update_visual_rotation()
			
		if bp.visual_node != null:
			bp.visual_node.queue_free()
		for tile in footprint:
			active_blueprints.erase(tile)
			var trapped_item = ItemManager.get_item_at(tile)
			
			if trapped_item != null:
				var dirs = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
				var is_resplaced: bool = false
				for dir in dirs:
					var offset = tile + dir
					if !Global.current_map.astar_grid.is_point_solid(offset):
						var item_type = trapped_item["type"]
						var item_amount = trapped_item["amount"]
						
						ItemManager.consume_item(tile, item_amount)
						
						ItemManager.add_item_to_grid(tile, item_type, item_amount, Global.current_map.item_layer,
						Global.current_map.item_drop, Global.current_map.terrain_layer.map_to_local)
		
		structure_built.emit(coords, structure_id, footprint, bp.facing)

func get_save_data() -> Array:
	var bp_save_array = []
	var saved_anchors = []
	
	for coords in active_blueprints.keys():
		var bp  = active_blueprints[coords]
		
		if saved_anchors.has(bp.coords):
			continue
		saved_anchors.append(bp.coords)
		
		var clean_data = {
			"x": coords.x,
			"y": coords.y,
			"recipe_id": bp.recipe.structure_id,
			"progress": bp.progress,
			"facing": bp.facing
		}
		
		bp_save_array.append(clean_data)
	
	return bp_save_array

func load_save_data(bp_data_list: Array):
	for bp in bp_data_list:
		var coords = Vector2i(bp["x"], bp["y"])
		var recipe_id = bp["recipe_id"]
		var progress = bp["progress"]
		var facing = int(bp.get("facing", 0))
		
		for mat in progress.keys():
			if progress[mat].has("incoming"):
				progress[mat]["incoming"] = 0
		
		var recipe = load("res://Building System/Building Recipes/"+ recipe_id +".tres")
		
		var restored_bp: BluePrint = BluePrint.new(coords, recipe)
		
		restored_bp.progress = progress
		restored_bp.facing = facing
		
		if restored_bp.recipe.ghost_texture != null:
			var ghost_sprite = Sprite2D.new()
			ghost_sprite.texture = restored_bp.recipe.ghost_texture
			ghost_sprite.modulate = Color(0.1, 1.0, 1.0, 0.5)
			
			var act_size = restored_bp.recipe.size
			if restored_bp.facing == 1 or restored_bp.facing == 3:
				act_size = Vector2i(act_size.y, act_size.x)
			
			var anchor_world_pos = Global.current_map.terrain_layer.map_to_local(restored_bp.coords)
			var center_offset = Vector2(act_size.x - 1, act_size.y - 1) * (Global.current_map.tileMap_cell_size / 2)
			ghost_sprite.global_position = anchor_world_pos + center_offset
			ghost_sprite.rotation_degrees = restored_bp.facing * (-90)
			var ghost_sprite_scale: Vector2
			
			if restored_bp.recipe.scene != null:
				var temp_scene = restored_bp.recipe.scene.instantiate()
				ghost_sprite_scale = temp_scene.scale
				temp_scene.queue_free()
			
			ghost_sprite.apply_scale(ghost_sprite_scale)
			Global.current_map.object_layer.add_child(ghost_sprite)
			restored_bp.visual_node = ghost_sprite
		
		var footprint = restored_bp.get_occupied_tiles()
		for tile in footprint:
			active_blueprints[tile] = restored_bp
			Global.current_map.icon_layer.set_cell(tile, 2, Global.current_map.icons["deliver"])
		blueprint_created.emit(restored_bp)
	
func reset_manager():
	active_blueprints.clear()

func abort_blueprint(coords: Vector2i):
	var bp: BluePrint = active_blueprints[coords]
	var materials: Array = bp.recipe.materials.keys()
	var footprint = bp.get_occupied_tiles()
	
	for material in materials:
		var drop_amount = bp.progress[material]["current"]
		if drop_amount > 0:
			ItemManager.add_item_to_grid(coords, material, drop_amount, Global.current_map.item_layer, 
			Global.current_map.item_drop, Global.current_map.terrain_layer.map_to_local)
	
	for tile in footprint:
		active_blueprints.erase(tile)
		Global.current_map.icon_layer.erase_cell(tile)
		Global.current_map.astar_grid.set_point_solid(tile, false)
		build_aborted.emit(tile)

func check_blueprint(coords: Vector2i) -> bool:
	if active_blueprints.has(coords):
		return true
	return false
