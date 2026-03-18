extends Panel

@onready var order_array: Dictionary = {
	"mine": $TabContainer/Orders/GridContainer/Mine,
	"cut_tree": $TabContainer/Orders/GridContainer/CutTree,
	"cancel_job": $TabContainer/Orders/GridContainer/CancelJob,
	"allow_items": $TabContainer/Orders/GridContainer/AllowItem,
	"dig_ground": $TabContainer/Orders/GridContainer/Dig
}
@onready var build_array: Dictionary = {
	"stone_wall": $TabContainer/Building/GridContainer/StoneWall
}
@onready var zone_array: Dictionary = {
	"stockpile": $TabContainer/Zones/GridContainer/Stockpile
}

@onready var tab_container = $TabContainer

func _ready():
	for order_key in order_array.keys():
		order_array[order_key].pressed.connect(_on_job_button_pressed.bind(order_key))
	
	build_array["stone_wall"].pressed.connect(_on_build_button_pressed.bind("stone_wall"))
	
	zone_array["stockpile"].pressed.connect(_on_zone_button_pressed.bind("stockpile"))

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
	Global.tool_mode_changed.emit(tool_mode)

func _on_build_button_pressed(button: String):
	var tool_mode: Global.ToolMode
	match button:
		"stone_wall":
			tool_mode = Global.ToolMode.BUILD_WALL
	Global.tool_mode_changed.emit(tool_mode)

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
