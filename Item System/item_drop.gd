extends Area2D

class_name ItemDrop

@export var item_id: String = "stone"
@export var item_amount: int
@onready var amount_label = $Label
@onready var sprite = $Sprite2D
@onready var forbidden_sprite = $Forbidden

var forbidden: bool

func ready():
	pass
	"""var tween = create_tween()
	var rand_offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	tween.tween_property(self, "position", position + rand_offset, 0.2)"""

func disp_amount(amount: int):
	item_amount = amount
	if amount <= 0:
		ItemManager.consume_item(Global.current_map.terrain_layer.local_to_map(self.global_position), 1)
		return
	if ItemManager.ITEM_DB.has(item_id):
		sprite.texture = ItemManager.ITEM_DB[item_id].texture
	if amount_label:
		$Label.text = str(amount)

func is_forbidden(_forbidden: bool):
	forbidden_sprite.visible = _forbidden
	self.forbidden = _forbidden
