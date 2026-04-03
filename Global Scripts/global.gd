extends Node

signal pressed_escape
signal tool_mode_changed(tool_mode: Global.ToolMode)
signal map_created
signal pawn_selected(pawn)
signal selection_cleared

var current_map = null

var is_loading_game: bool = false
var is_saving_game: bool = false
var is_in_game: bool= false

enum ToolMode {NONE, MINE, DIG, CHOP_WOOD, CANCEL_JOB, CREATE_ZONE, BUILD_WALL, ALLOW_ITEM, DECONSTRUCT}

var start_pawn_count: int = 1
var custom_seed: String = ""
var custom_threshold: int = 4
var sim_speed: float = 1.0

var map_width: int = 100
var map_height: int = 100

func _ready() -> void:
	InfoMenu.pressed_exit.connect(reset_all_managers)

func reset_all_managers():
	PawnManager.clear_pawns()
	ItemManager.reset_manager()
	JobManager.reset_manager()
	ZoneManager.reset_manager()
	BuildManager.reset_manager()
