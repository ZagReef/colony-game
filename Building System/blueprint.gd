extends RefCounted

class_name BluePrint

enum Direction {UP, RIGHT, DOWN, LEFT}

var coords: Vector2i
var recipe: StructureRecipe
var is_blocked: bool = false
var facing:Direction = Direction.UP

var progress: Dictionary = {}

var visual_node: Node2D

func _init(c: Vector2i, r: StructureRecipe, dir: Direction = Direction.UP):
	coords = c
	recipe = r
	facing = dir
	
	for item_type in recipe.materials.keys():
		progress[item_type] = {
			"current": 0 , 
			"incoming": 0
		}

func get_occupied_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var act_size = recipe.size
	
	if facing == Direction.RIGHT or facing == Direction.LEFT:
		act_size = Vector2i(recipe.size.y, recipe.size.x)
	
	for x in range(act_size.x):
		for y in range(act_size.y):
			tiles.append(coords + Vector2i(x, y))
	
	return tiles


func get_remaining_needs(item_type: String):
	if not progress.has(item_type):
		return 0
	if is_blocked:
		return 0
	
	var needed = recipe.materials[item_type]
	var current = progress[item_type]["current"]
	var incoming = progress[item_type]["incoming"]
	
	return needed - (current + incoming)

func is_ready_to_build() -> bool:
	for item_type in recipe.materials.keys():
		var needed = recipe.materials[item_type]
		var current = progress[item_type]["current"]
		if current < needed:
			return false
	
	return true

func get_material_needs() -> Array[String]:
	"""if is_blocked:
		return []"""
	var needs: Array[String] = []
	for material in recipe.materials.keys():
		#print(material)
		if progress[material]["incoming"] + progress[material]["current"] < recipe.materials[material]:
			#print(material)
			needs.append(material)
	#print(needs)
	return needs
