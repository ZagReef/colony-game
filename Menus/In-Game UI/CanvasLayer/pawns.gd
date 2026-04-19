extends CanvasLayer

@onready var info_panel = $TilePawnInfo
@onready var coords_panel = $CoordsPanel
@onready var stockpile_panel = $StockpileInfo
@onready var action_panel = $ActionSelectionPanel

@onready var exclusive_panels = [info_panel, stockpile_panel]

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

func check_panel(active_panel: Panel):
	for panel in exclusive_panels:
		if panel == active_panel:
			panel.show()
		else:
			panel.hide()
	
