extends StaticBody2D
class_name DoubleBed

enum Direction {UP, RIGHT, DOWN, LEFT}
var facing: Direction = Direction.UP

var max_health: int
var current_health: int

@onready var sprite = $Sprite2D

func _ready():
	rotation_degrees = facing * (-90)

func update_visual_rot():
	if sprite == null:
		return
	self.rotation_degrees = facing * (-90)
