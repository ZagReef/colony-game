extends RefCounted

class_name PawnInventory

var carried_item: String = ""
var item_amount: int = 0
var max_capacity: int = 25

var pawn_cloths: Dictionary = {
	"headgear": "",
	"shirt": "",
	"pants": "",
	}

var weapon: String = ""


func collect_items(item_name: String, amount: int):
	if is_inventory_empty():
		carried_item = item_name
	if item_name == carried_item:
		var total = item_amount + amount
		
		if total > max_capacity:
			var leftover = total - max_capacity
			item_amount = max_capacity
			return leftover
		else:
			item_amount = total
			return 0
	
	return amount

func is_inventory_empty():
	return carried_item == "" and item_amount == 0

func clear_inventory():
	carried_item = ""
	item_amount = 0
