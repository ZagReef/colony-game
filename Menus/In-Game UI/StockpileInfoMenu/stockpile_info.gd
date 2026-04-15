extends Panel

@onready var size_label = $MarginContainer/VBoxContainer/HBoxContainer/Label1
@onready var id_label = $MarginContainer/VBoxContainer/HBoxContainer/Label2
@onready var items_list = $"MarginContainer/VBoxContainer/TabContainer/Item List/RichTextLabel"

@onready var filter_list = $"MarginContainer/VBoxContainer/TabContainer/Allowed Items/ScrollContainer/VBoxContainer"

var current_stockpile: StockpileZone = null

func _ready():
	self.hide()
	Global.map_created.connect(_set_signals)

func show_stockpile_info(size: int, item_list: Dictionary, stockpile_id: int):
	self.get_parent().check_panel(self)
	self.show()
	size_label.text = "Stockpile Size: " + str(size)
	var text = ""
	for item in item_list.keys():
		text += item + ": " + str(item_list[item]) + "\n"
	items_list.text = text
	id_label.text = "Stockpile " + str(stockpile_id)
	open_panel(ZoneManager.stockpiles[stockpile_id])

func _set_signals():
	Global.current_map.check_stockpile_info.connect(show_stockpile_info)

func open_panel(stockpile: StockpileZone):
	current_stockpile = stockpile
	
	_build_filter_ui()

func _build_filter_ui():
	for child in filter_list.get_children():
		child.queue_free()
	
	var cats: Dictionary = {}
	
	for item_id in ItemManager.ITEM_DB.keys():
		var cat = ItemManager.ITEM_DB[item_id].category
		
		if not cats.has(cat):
			cats[cat] = []
		
		cats[cat].append(item_id)
	
	for cat in cats.keys():
		var header = Label.new()
		header.text = cat
		header.self_modulate = Color(0.337, 0.64, 0.92, 1.0)
		filter_list.add_child(header)
		
		for item_id in cats[cat]:
			var cb: CheckBox= CheckBox.new()
			var item_data: ItemData = ItemManager.ITEM_DB[item_id]
			
			
			cb.text = item_data.ui_name
			if item_data.texture:
				cb.icon = item_data.texture
				cb.expand_icon = true
				cb.add_theme_constant_override("icon_max_width", 16)
				cb.add_theme_constant_override("icon_max_height", 16)
				cb.add_theme_font_size_override("font_size", 8)
			cb.button_pressed = current_stockpile.allowed_items[item_id]
			
			cb.toggled.connect(func(is_pressed: bool):
				current_stockpile.set_item_allowed(item_id, is_pressed)
				)
			
			filter_list.add_child(cb)
