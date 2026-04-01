extends Node

var stockpiles: Array[StockpileZone] = []

signal new_stockpile_created(space_amount: int)
signal stockpile_item_consumed(space_amount: int, item_type: String)

func _ready() -> void:
	Global.pressed_escape.connect(reset_manager)

func cell_in_any_zone(map_pos: Vector2i):
	if not Global.current_map.is_within_bounds(map_pos.x, map_pos.y) or stockpiles.size() <= 0:
		return false
	for stockpile in stockpiles:
		if map_pos in stockpile.cells:
			return true
	return false

func get_available_stockpile_cell(item_type: String = "None"):
	for stockpile in stockpiles:
		for cell_pos in stockpile.cells:
			var item_in_cell = ItemManager.get_item_at(cell_pos)
			
			if item_in_cell == null:
				return cell_pos
			elif item_in_cell["type"] == item_type:
				if item_in_cell["amount"] < 75: # 75'i oyunun max stack limiti yapabilirsin
					return cell_pos

func create_stockpile(cells: Array[Vector2i]):
	var stockpile = StockpileZone.new()
	stockpile.cells = cells
	
	stockpiles.append(stockpile)
	
	new_stockpile_created.emit()

func get_save_data():
	var zones_save_array = []
	
	for stockpile in stockpiles:
		var clean_data = {
			cells = []
		}
		
		for cell in stockpile.cells:
			clean_data["cells"].append({"x": cell.x, "y": cell.y})
		
		zones_save_array.append(clean_data)
	return zones_save_array

func load_save_data(stockpile_zones_list: Array):
	stockpiles.clear()
	
	for zone_data in stockpile_zones_list:
		
		var restored_stockpile = StockpileZone.new()
		
		var restored_cells: Array[Vector2i] = []
		
		for cell_data in zone_data["cells"]:
			restored_cells.append(Vector2i(cell_data["x"], cell_data["y"]))
			Global.current_map.zone_layer.set_cell(Vector2i(cell_data["x"], cell_data["y"]), Global.current_map.grass_id, Global.current_map.wood_atlas)
		
		restored_stockpile.cells = restored_cells
		
		stockpiles.append(restored_stockpile)

func reset_manager():
	stockpiles.clear()
