extends Panel

@onready var order_array: Dictionary = {
	"mine": $TabContainer/Orders/GridContainer/Mine,
	"cut_tree": $TabContainer/Orders/GridContainer/CutTree,
	"cancel_job": $TabContainer/Orders/GridContainer/CancelJob,
	"allow_items": $TabContainer/Orders/GridContainer/AllowItem,
	"dig_ground": $TabContainer/Orders/GridContainer/Dig,
	"deconstruct": $TabContainer/Orders/GridContainer/Deconstruct,
	"remove_floor": $TabContainer/Orders/GridContainer/RemoveFloor,
	"build_roof": $TabContainer/Orders/GridContainer/BuildRoof
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
	
	for build_key in build_array.keys():
		build_array[build_key].pressed.connect(_on_build_button_pressed.bind(build_key))
	
	zone_array["stockpile"].pressed.connect(_on_zone_button_pressed.bind("stockpile"))
	
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
		build_array[build_key].tooltip_text = ""
		var materials = Global.current_map.structure_recipes[build_key].materials
		for material in materials:
			var amount = materials[material]
			build_array[build_key].tooltip_text += material + ": " + str(amount) + " "
