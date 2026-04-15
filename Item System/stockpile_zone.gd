extends Node

class_name StockpileZone

var stockpile_id: int
var cells: Array[Vector2i] = []
var priority: int
var size: int

var allowed_items: Dictionary = {}

signal stockpile_setting_changed(stockpile: StockpileZone)

func _init(new_id: int, initial_cells: Array[Vector2i]):
	self.stockpile_id = new_id
	self.cells = initial_cells
	
	for item_id in ItemManager.ITEM_DB.keys():
		allowed_items[item_id] = true

func set_item_allowed(item_id: String, is_allowed: bool):
	if allowed_items.has(item_id):
		allowed_items[item_id] = is_allowed
	ZoneManager.emit_signal("stockpile_setting_changed", self)

func set_category_allowed(category: String, is_allowed: bool):
	for item_id in allowed_items.keys():
		if ItemManager.ITEM_DB[item_id].category == category:
			allowed_items[item_id] = is_allowed
	ZoneManager.emit_signal("stockpile_setting_changed", self)

func set_all_allowed(is_allowed: bool):
	for item_id in allowed_items.keys():
		allowed_items[item_id] = is_allowed
	ZoneManager.emit_signal("stockpile_setting_changed", self) 

func accepts_item(item_id: String):
	return allowed_items.get(item_id, false)
