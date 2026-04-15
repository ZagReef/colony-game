extends Resource

class_name ItemData

@export var item_id: String = ""
@export_enum("Materials", "Ores") var category: String = "Materials"
@export var ui_name: String = ""
@export var max_stack: int = 75
@export var texture: Texture2D
