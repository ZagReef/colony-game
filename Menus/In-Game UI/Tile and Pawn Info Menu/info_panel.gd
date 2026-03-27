extends Panel

@onready var tile_info_label = $MarginContainer/VBoxContainer/HBoxContainer/NameInfo
@onready var progress_bar = $MarginContainer/VBoxContainer/HBoxContainer2/ProgressBar
@onready var health_ratio = $MarginContainer/VBoxContainer/HBoxContainer2/ProgressBar/HealthRatio

func _ready():
	Global.map_created.connect(_set_signals)

func set_label(item_ground: String, item_top: String, item_roof: String, speed_multiplier: float, item_max_health: int, item_current_health: int):
	self.visible = true
	if item_max_health == 0:
		var container = progress_bar.get_parent()
		container.visible = false
	else:
		var container = progress_bar.get_parent()
		container.visible = true
		progress_bar.max_value = item_max_health
		progress_bar.value = item_current_health
		health_ratio.text = str(item_current_health) + "/" + str(item_max_health) 
	tile_info_label.text = "Ground: " + item_ground + "\n" + "Top: " + item_top + "\n" + "Roof: " + item_roof + "\n" + "Speed Multplier: " + String.num(speed_multiplier, 2)


func _set_signals():
	Global.current_map.check_tile_info.connect(set_label)
