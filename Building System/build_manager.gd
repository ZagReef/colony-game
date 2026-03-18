extends Node

class_name BlueprintManager

var active_blueprints: Dictionary = {}

signal blueprint_created(blueprint: BluePrint)
signal ready_to_build(blueprint: BluePrint)
signal structure_built(coords: Vector2i, structure_id: String)
signal build_aborted(coords: Vector2i)

func _ready() -> void:
	Global.pressed_escape.connect(reset_manager)

func create_blueprint(coords: Vector2i, recipe: StructureRecipe):
	if active_blueprints.has(coords): return
	
	var new_bp = BluePrint.new(coords, recipe)
	active_blueprints[coords] = new_bp
	#print("gerekli materyal bulundu: ", active_blueprints[coords].get_material_needs())
	
	Global.current_map.astar_grid.set_point_solid(coords, true)
	blueprint_created.emit(new_bp)

func add_materials_to_blueprint(coords: Vector2i, item_type: String, amount: int):
	if active_blueprints.has(coords):
		var bp = active_blueprints[coords]
		
		if bp.progress.has(item_type):
			bp.progress[item_type]["incoming"] -= amount
			bp.progress[item_type]["current"] += amount
			
			if bp.is_ready_to_build():
				ready_to_build.emit(bp)

func finish_building(coords: Vector2i):
	if active_blueprints.has(coords):
		var bp = active_blueprints[coords]
		var structure_id = bp.recipe.structure_id
		
		if bp.visual_node != null:
			bp.visual_node.queue_free()
		var map = Global.current_map
		active_blueprints.erase(coords)
		if structure_id == "stone_wall":
			map.object_layer.set_cell(coords, map.new_tileset_id, Vector2i(2, 12))
		
		structure_built.emit(coords, structure_id)

func get_save_data() -> Array:
	var bp_save_array = []
	
	for coords in active_blueprints.keys():
		var bp  = active_blueprints[coords]
		
		var clean_data = {
			"x": coords.x,
			"y": coords.y,
			"recipe_id": bp.recipe.structure_id,
			"progress": bp.progress
		}
		
		bp_save_array.append(clean_data)
	
	return bp_save_array

func load_save_data(bp_data_list: Array):
	for bp in bp_data_list:
		var coords = Vector2i(bp["x"], bp["y"])
		var recipe_id = bp["recipe_id"]
		var progress = bp["progress"]
		
		var recipe = load("res://Building System/Building Recipes/"+ recipe_id +".tres")
		
		var restored_bp = BluePrint.new(coords, recipe)
		
		restored_bp.progress = progress
		
		active_blueprints[coords] = restored_bp
		
		var build_icon = Global.current_map.icons["build"]
		
		Global.current_map.astar_grid.set_point_solid(coords, true)
		blueprint_created.emit(restored_bp)
		
		Global.current_map.icon_layer.set_cell(coords, 1, build_icon)

func reset_manager():
	active_blueprints.clear()

func abort_blueprint(coords: Vector2i):
	var bp = active_blueprints[coords]
	var materials: Array = bp.recipe.materials.keys()
	
	for material in materials:
		var drop_amount = bp.progress[material]["current"]
		if drop_amount > 0:
			ItemManager.add_item_to_grid(coords, material, drop_amount, Global.current_map.item_layer, 
			Global.current_map.item_drop, Global.current_map.terrain_layer.map_to_local)
	
	active_blueprints.erase(coords)
	build_aborted.emit(coords)
	
