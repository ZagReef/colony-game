extends Node

signal pressed_escape
signal tool_mode_changed(tool_mode: Global.ToolMode)

var current_map = null

var is_loading_game:bool = false

enum ToolMode {NONE, MINE, DIG, CHOP_WOOD, CANCEL_JOB, CREATE_ZONE, BUILD_WALL, ALLOW_ITEM}

var start_pawn_count: int = 1
var custom_seed: String = ""
var custom_threshold: int = 4
