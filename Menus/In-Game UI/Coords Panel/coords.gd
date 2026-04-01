extends Panel

@onready var text_label = $MarginContainer/Label

func set_coords(x: int, y: int):
	text_label.text = "X: " + str(x) + " Y: " + str(y)
