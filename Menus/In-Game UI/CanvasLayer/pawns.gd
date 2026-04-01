extends CanvasLayer

@onready var info_panel = $TilePawnInfo
@onready var coords_panel = $CoordsPanel

func _ready():
	self.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and Global.is_in_game:
		toggle_pawn_menu()

func toggle_pawn_menu():
	if self.visible:
		self.hide()
	else:
		self.show()
