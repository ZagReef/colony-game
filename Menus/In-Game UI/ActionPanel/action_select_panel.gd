extends Panel

@export var ui_icons_texture: Texture2D
@export var tile_texture: Texture2D

var icons: Dictionary = {
	"cut_tree": Vector2i(11, 6),
	"mine": Vector2i(8, 5),
	"cancel_job": Vector2i(17, 0),
	"allow_items": Vector2i(1, 8),
	"dig_ground": Vector2i(9, 5),
	"deconstruct": Vector2i(7, 6),
	"remove_floor": Vector2i(12, 10),
	"build_roof": Vector2i(14, 1),
	"remove_roof": Vector2i(0, 8),
	"stockpile": Vector2i(2, 4),
	"stone_wall": Vector2i(1, 11),
	"stone_floor": Vector2i(1, 13),
	"wooden_floor": Vector2i(1, 14)
}

var icons_without_tooltips = ["stone_wall", "stone_floor", "wooden_floor"]

var icon_tooltips: Dictionary = {
	"cut_tree": "Cut Down Trees",
	"mine": "Mining",
	"cancel_job": "Cancel Jobs",
	"allow_items": "Allow Item Pickup",
	"dig_ground": "Dig Ground Resources",
	"deconstruct": "Deconstruction",
	"remove_floor": "Remove Floors",
	"build_roof": "Build Roof",
	"remove_roof": "Deconstruct Roof",
	"stockpile": "Create Stockpile Zone",
}

@onready var order_array: Dictionary = {
	"mine": $TabContainer/Orders/GridContainer/Mine,
	"cut_tree": $TabContainer/Orders/GridContainer/CutTree,
	"cancel_job": $TabContainer/Orders/GridContainer/CancelJob,
	"allow_items": $TabContainer/Orders/GridContainer/AllowItem,
	"dig_ground": $TabContainer/Orders/GridContainer/Dig,
	"deconstruct": $TabContainer/Orders/GridContainer/Deconstruct,
	"remove_floor": $TabContainer/Orders/GridContainer/RemoveFloor,
	"build_roof": $TabContainer/Orders/GridContainer/BuildRoof,
	"remove_roof": $TabContainer/Orders/GridContainer/RemoveRoof
}
@onready var build_array: Dictionary = {
	"stone_wall": $TabContainer/Building/GridContainer/StoneWall,
	"single_bed": $TabContainer/Building/GridContainer/SingleBed,
	"double_bed": $TabContainer/Building/GridContainer/DoubleBed,
	"single_armchair": $TabContainer/Building/GridContainer/SingleArmchair,
	"chair": $TabContainer/Building/GridContainer/Chair,
	"sofa": $TabContainer/Building/GridContainer/Sofa,
	"table": $TabContainer/Building/GridContainer/Table,
	"wooden_floor": $TabContainer/Building/GridContainer/WoodenFloor,
	"stone_floor": $TabContainer/Building/GridContainer/StoneFloor
}
@onready var zone_array: Dictionary = {
	"stockpile": $TabContainer/Zones/GridContainer/Stockpile
}

@onready var tab_container = $TabContainer

func _ready():	
	for order_key in order_array.keys():
		order_array[order_key].pressed.connect(_on_job_button_pressed.bind(order_key))
		setup_button(order_array[order_key], order_key)
	
	for build_key in build_array.keys():
		build_array[build_key].pressed.connect(_on_build_button_pressed.bind(build_key))
	
	for zone_key in zone_array.keys():
		zone_array[zone_key].pressed.connect(_on_zone_button_pressed.bind(zone_key))
		setup_button(zone_array[zone_key], zone_key)
	
	Global.map_created.connect(_on_build_buttons_setted)

func _on_job_button_pressed(button: String):
	var tool_mode: Global.ToolMode
	match button:
		"mine":
			tool_mode = Global.ToolMode.MINE
		"cut_tree":
			tool_mode = Global.ToolMode.CHOP_WOOD
		"cancel_job":
			tool_mode = Global.ToolMode.CANCEL_JOB
		"allow_items":
			tool_mode = Global.ToolMode.ALLOW_ITEM
		"dig_ground":
			tool_mode = Global.ToolMode.DIG
		"deconstruct":
			tool_mode = Global.ToolMode.DECONSTRUCT
		"remove_floor":
			tool_mode = Global.ToolMode.REMOVE_FLOOR
		"build_roof":
			tool_mode = Global.ToolMode.BUILD_ROOF
		"remove_roof":
			tool_mode = Global.ToolMode.REMOVE_ROOF
	Global.tool_mode_changed.emit(tool_mode)

func _on_build_button_pressed(button: String):
	var tool_mode: Global.ToolMode
	tool_mode = Global.ToolMode.BUILD_WALL
	Global.tool_mode_changed.emit(tool_mode, button)

func _on_zone_button_pressed(button: String):
	var tool_mode: Global.ToolMode
	match button:
		"stockpile":
			tool_mode = Global.ToolMode.CREATE_ZONE
	Global.tool_mode_changed.emit(tool_mode)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("tab1"):
		tab_container.current_tab = 0
	elif event.is_action_pressed("tab2"):
		tab_container.current_tab = 1
	elif event.is_action_pressed("tab3"):
		tab_container.current_tab = 2
	elif event.is_action_pressed("tab4"):
		tab_container.current_tab = 3

func _on_build_buttons_setted():
	for build_key in build_array.keys():
		var but: Button = build_array[build_key]
		var recipe = Global.current_map.structure_recipes[build_key]
		
		if recipe.ghost_texture != null:
			but.icon = recipe.ghost_texture
			but.expand_icon = true
			but.custom_minimum_size = Vector2( 32, 32)
			but.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			but.text = ""
		else:
			setup_button(but, build_key)
		
		
		
		var display_name = build_key.capitalize()
		var tooltip_str = display_name + "\n"
		
		build_array[build_key].tooltip_text = ""
		var materials = recipe.materials
		for material in materials:
			var amount = materials[material]
			tooltip_str += material + ": " + str(amount) + " "
		
		but.tooltip_text = tooltip_str
		

func setup_button(but: Button, tool_name: String):
	
	var atlas_tex = AtlasTexture.new()
	if tool_name not in icons_without_tooltips:
		atlas_tex.atlas = ui_icons_texture
	else:
		atlas_tex.atlas = tile_texture
	
	var icon_pos = icons[tool_name]
	atlas_tex.region = Rect2(icon_pos * 32, Vector2(32, 32) )
	
	but.icon = atlas_tex
	but.text = ""
	if tool_name not in icons_without_tooltips:
		but.tooltip_text = icon_tooltips[tool_name]
