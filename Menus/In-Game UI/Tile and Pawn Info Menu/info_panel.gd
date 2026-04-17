extends Panel

@onready var info_label = $MarginContainer/VBoxContainer/HBoxContainer/NameInfo
var info_container
@onready var progress_bar = $MarginContainer/VBoxContainer/HBoxContainer2/ProgressBar
@onready var progress_container = $MarginContainer/VBoxContainer/HBoxContainer2
@onready var health_ratio = $MarginContainer/VBoxContainer/HBoxContainer2/ProgressBar/HealthRatio
@onready var margin_container = $MarginContainer

var tracked_pawn: PawnPrototype = null
var tracked_job = null
var tracked_bp: BluePrint = null

func _ready():
	self.visible = false
	Global.map_created.connect(_set_signals)
	Global.pawn_selected.connect(show_pawn_info)
	Global.selection_cleared.connect(clear_panel)
	PawnManager.pawn_focus_requested.connect(show_pawn_info)
	PawnManager.pawn_focus_cancelled.connect(clear_panel)
	set_process(false)

func show_tile_info(item_ground: String, item_top: String, item_roof: String, speed_multiplier: float, is_passable: bool, item_max_health: int, item_current_health: int, assigned_job = null, assigned_job_list = "None", blueprint = null):
	self.get_parent().check_panel(self)
	self.visible = true
	tracked_pawn = null
	tracked_job = assigned_job
	tracked_bp = blueprint
	
	var text = "Ground: " + item_ground + " / " + "Top: " + item_top + "\n" + "Roof: " + item_roof + " / " + "Speed Multplier: " + String.num(speed_multiplier, 2) + " \n " + "Is Passable: " + str(!is_passable).to_upper()
	
	if tracked_job != null:
		var job_string = tracked_job.Type.find_key(tracked_job.job_type)
		text += "\nJob: " + str(job_string) + " / "+ str(assigned_job_list)
	if tracked_bp != null:
		text += "\nBlueprint Progress: " + tracked_bp.recipe.structure_name
		for mat in tracked_bp.progress.keys():
			text += "\n" + ItemManager.ITEM_DB[mat].ui_name + ": " + str(int(tracked_bp.progress[mat]["current"])) + " + " + str(tracked_bp.progress[mat]["incoming"]) + " / " + str(tracked_bp.recipe.materials[mat])
	if item_max_health > 0:
		info_label.text = text
		progress_container.visible = true
		progress_bar.max_value = item_max_health
		progress_bar.value = item_current_health
		health_ratio.text = str(item_current_health) + "/" + str(item_max_health)
	else:
		info_label.text = text
		progress_container.visible = false
	info_label.text = text
	set_process(false)

func show_pawn_info(pawn):
	self.visible = true
	tracked_pawn = pawn
	tracked_job = null
	progress_container.visible = false
	set_process(true)

func show_item_info(item: Dictionary):
	self.get_parent().check_panel(self)
	self.show()
	var text = item["type"] + ": " + str(item["amount"])
	info_label.text = text

func _set_signals():
	Global.current_map.check_tile_info.connect(show_tile_info)
	Global.current_map.check_item_info.connect(show_item_info)

func clear_panel():
	self.visible = false
	tracked_pawn = null
	tracked_job = null
	set_process(false)

func _process(_delta: float) -> void:
	if tracked_pawn != null and tracked_pawn.current_job != null:
		info_label.text = "Name: " + str(tracked_pawn.char_name) + "\nState: " + str(tracked_pawn.state_machine.current_state.name) + "\nJob: "  + str(tracked_pawn.current_job.Type.find_key(tracked_pawn.current_job.job_type))
	elif tracked_pawn != null:
		info_label.text = "Name: " + str(tracked_pawn.char_name) + "\nState: " + str(tracked_pawn.state_machine.current_state.name) + "\nJob: "  + "None"
