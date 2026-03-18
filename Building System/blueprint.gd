extends RefCounted

class_name BluePrint

var coords: Vector2i
var recipe: StructureRecipe

var progress: Dictionary = {}

var visual_node: Node2D

func _init(c: Vector2i, r: StructureRecipe):
	coords = c
	recipe = r
	
	for item_type in recipe.materials.keys():
		progress[item_type] = {
			"current": 0 , 
			"incoming": 0
		}

func get_remaining_needs(item_type: String):
	if not progress.has(item_type):
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
	var needs: Array[String] = []
	for material in recipe.materials.keys():
		#print(material)
		if progress[material]["incoming"] + progress[material]["current"] < recipe.materials[material]:
			#print(material)
			needs.append(material)
	#print(needs)
	return needs
