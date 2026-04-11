extends Panel

@onready var pawn_container = $ScrollContainer/VBoxContainer/PawnContainer
@onready var container_parent = pawn_container.get_parent()
@onready var canvas_layer = self.get_parent()
@onready var scroll_container = self.get_node("ScrollContainer")

func _ready():
	PawnManager.pawn_spawned.connect(add_pawn)
	Global.pressed_escape.connect(func (): canvas_layer.visible = !canvas_layer.visible)
	InfoMenu.pressed_exit.connect(clear_pawns)
	scroll_container.mouse_entered.connect(switch_mouse_over)
	scroll_container.mouse_exited.connect(switch_mouse_over)

func add_pawn(pawn: CharacterBody2D):
	if !InfoMenu.visible:
		canvas_layer.visible = true
	var new_container = pawn_container.duplicate()
	new_container.get_node("PawnTexture").texture = pawn.char_body_texture
	new_container.get_node("PawnName").text = pawn.char_name
	new_container.visible = true
	new_container.gui_input.connect(_on_pawn_container_gui_input.bind(pawn))
	container_parent.add_child(new_container)

func clear_pawns():
	for container in container_parent.get_children():
		if container.visible:
			container.queue_free()
	
	canvas_layer.visible = false

func _on_pawn_container_gui_input(event: InputEvent, pawn: CharacterBody2D):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if pawn.is_selected:
			PawnManager.pawn_focus_cancelled.emit()
			#print("seçim yapıldı: ", pawn)
		else:
			PawnManager.pawn_focus_requested.emit(pawn)
			Global.current_map.work_selection_layer.clear()

func switch_mouse_over():
	Global.is_mouse_over_ui = !Global.is_mouse_over_ui
