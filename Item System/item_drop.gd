extends Area2D

class_name ItemDrop

@export var item_id: String = "Stone"
@export var item_amount: int
@onready var amount_label = $Label
@onready var sprite = $Sprite2D
@onready var forbidden_sprite = $Forbidden

var forbidden: bool

var textures: Dictionary = {
	"Wood": load("res://Textures/Item Textures/WoodPile-Photoroom.png"),
	"Stone": load("res://Textures/Item Textures/StonePile-Photoroom.png"),
	"Iron": load("res://Textures/Item Textures/İronPile-Photoroom.png"),
	"Gold": load("res://Textures/Item Textures/gold_pile-Photoroom.png"),
	"Copper": load("res://Textures/Item Textures/copper_pile-Photoroom.png"),
	"Clay": load("res://Textures/Item Textures/clay-Photoroom.png")
}

func ready():
	pass
	"""var tween = create_tween()
	var rand_offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	tween.tween_property(self, "position", position + rand_offset, 0.2)"""

func disp_amount(amount: int):
	item_amount = amount
	sprite.texture = textures[item_id]
	if amount_label:
		$Label.text = str(amount)

func is_forbidden(_forbidden: bool):
	forbidden_sprite.visible = _forbidden
	self.forbidden = _forbidden
