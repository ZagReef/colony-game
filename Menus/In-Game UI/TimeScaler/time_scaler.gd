extends Panel

@onready var slider: HSlider = $MarginContainer/VBoxContainer/HSlider
@onready var label: Label = $MarginContainer/VBoxContainer/Label

func _ready() -> void:
	slider.value_changed.connect(set_engine_scale)


func set_engine_scale(scale_value):
	if scale_value == 0.0:
		label.text = "Time Scale: X" + str(scale_value)
		get_tree().paused = true
	else:
		get_tree().paused = false
		label.text = "Time Scale: " + "X" + str(scale_value)
		Global.sim_speed = scale_value
