extends Resource

class_name Job

enum Type {WOOD_CUTTING, MINING, HAUL_ITEMS, DELIVER_MATERIAL, BUILD_STRUCTURE, DIGGING, DECONSTRUCT, 
REMOVE_FLOOR, BUILD_ROOF, REMOVE_ROOF}

var job_type: Type
var target_world_pos: Vector2
var target_map_pos: Vector2i
var priority: int  = 0
var is_taken: bool = false

var worker: CharacterBody2D = null
var worker_black_list: Array[CharacterBody2D] = []
