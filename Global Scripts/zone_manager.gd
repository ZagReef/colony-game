extends Node

var stockpiles: Dictionary = {}
var stockpiles_id: int  = 0

signal new_stockpile_created(space_amount: int)
signal stockpile_item_consumed(space_amount: int, item_type: String)
signal stockpile_setting_changed(stockpile: StockpileZone)

func _ready() -> void:
	Global.pressed_escape.connect(reset_manager)

func cell_in_any_zone(map_pos: Vector2i):
	if not Global.current_map.is_within_bounds(map_pos.x, map_pos.y):
		return false
	for stockpile in stockpiles.keys():
		if map_pos in stockpiles[stockpile].cells:
			return true
	return false

func get_available_stockpile_cell(item_type: String = "None"):
	for stockpile_id in stockpiles.keys():
		if item_type != "None" and not stockpiles[stockpile_id].accepts_item(item_type):
			continue
		
		for cell_pos in stockpiles[stockpile_id].cells:
			var item_in_cell = ItemManager.get_item_at(cell_pos)
			
			if item_in_cell == null:
				return cell_pos
			elif item_in_cell["type"] == item_type:
				if item_in_cell["amount"] < ItemManager.ITEM_DB[item_type].max_stack :
					return cell_pos
	return null

func create_stockpile(cells: Array[Vector2i]):
	var stockpile = StockpileZone.new(stockpiles_id, cells)
	stockpile.size = cells.size()
	
	stockpiles[stockpiles_id] = stockpile
	stockpiles_id += 1
	
	new_stockpile_created.emit()

func get_save_data():
	var zones_save_array = []
	
	for stockpile_id in stockpiles:
		var stockpile = stockpiles[stockpile_id]
		
		var clean_data = {
			"cells": [],
			"allowed_items": stockpile.allowed_items
		}
		
		for cell in stockpiles[stockpile_id].cells:
			clean_data["cells"].append({"x": cell.x, "y": cell.y})
		
		zones_save_array.append(clean_data)
	return zones_save_array

func load_save_data(stockpile_zones_list: Array):
	stockpiles.clear()
	
	for zone_data in stockpile_zones_list:
		var restored_cells: Array[Vector2i] = []
		
		for cell_data in zone_data["cells"]:
			restored_cells.append(Vector2i(cell_data["x"], cell_data["y"]))
			Global.current_map.zone_layer.set_cell(Vector2i(cell_data["x"], cell_data["y"]), Global.current_map.grass_id, Global.current_map.wood_atlas)
		
		var restored_stockpile = StockpileZone.new(stockpiles_id, restored_cells)
		restored_stockpile.size = restored_cells.size()
		
		if zone_data.has("allowed_items"):
			var saved_filters = zone_data["allowed_items"]
			
			for item_key in saved_filters:
				if restored_stockpile.allowed_items.has(item_key):
					restored_stockpile.allowed_items[item_key] = saved_filters[item_key]
		
		stockpiles[stockpiles_id] = restored_stockpile
		stockpiles_id += 1

func reset_manager():
	stockpiles.clear()

func get_stockpile_cells(cell: Vector2i):
	for stockpile_id in stockpiles.keys():
		if cell in stockpiles[stockpile_id].cells:
			return stockpiles[stockpile_id].cells

func get_stockpile_items(cells: Array[Vector2i]):
	var item_list = {}
	for cell in cells:
		var item = ItemManager.get_item_at(cell)
		
		if item != null:
			var item_name = ItemManager.ITEM_DB[item["type"]].ui_name
			var amount = item["amount"]
			
			if item_list.has(item_name):
				item_list[item_name] += amount
			else:
				item_list[item_name] = amount
	
	return item_list

func get_stockpile_id(cell: Vector2i):
	for stockpile in stockpiles.values():
		if cell in stockpile.cells:
			return stockpile.stockpile_id

func is_item_in_valid_stockpile(coords: Vector2i, item_type: String):
	for stockpile: StockpileZone in stockpiles.values():
		if coords in stockpile.cells:
			return stockpile.accepts_item(item_type)
	return false
