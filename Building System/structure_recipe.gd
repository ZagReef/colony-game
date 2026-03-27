extends Resource

class_name StructureRecipe

@export var structure_id: String
@export var structure_name: String
@export var build_time: float
@export var health: int

@export var size: Vector2i = Vector2i(1 , 1)

@export var materials: Dictionary = {}

@export var icon: Texture2D
@export var ghost_texture: Texture2D
@export var scene: PackedScene
