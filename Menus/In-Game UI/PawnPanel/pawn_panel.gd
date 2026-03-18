extends Panel

@onready var pawn_container = $VBoxContainer/PawnContainer
@onready var container_parent = pawn_container.get_parent()
@onready var canvas_layer = self.get_parent()

func _ready():
	PawnManager.pawn_spawned.connect(add_pawn)
	Global.pressed_escape.connect(func (): canvas_layer.visible = !canvas_layer.visible)
	InfoMenu.pressed_exit.connect(clear_pawns)

func add_pawn(pawn: CharacterBody2D):
	canvas_layer.visible = true
	var new_container = pawn_container.duplicate()
	new_container.get_node("PawnTexture").texture = pawn.char_body_texture
	new_container.get_node("PawnName").text = pawn.char_name
	new_container.visible = true
	container_parent.add_child(new_container)

func clear_pawns():
	for container in container_parent.get_children():
		if container.visible:
			container.queue_free()
	
	canvas_layer.visible = false
