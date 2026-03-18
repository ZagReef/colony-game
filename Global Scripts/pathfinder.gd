extends Node

func find_walkable_tile(target_map_pos: Vector2i, character_world_pos: Vector2i) -> Vector2i:
	var best_pos = Vector2i(-1, -1)
	var min_dist = INF
	var map_gen = Global.current_map
	var astar_grid = map_gen.astar_grid
	
	var neighbors = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	for offset in neighbors:
		var neighbor_pos = offset + target_map_pos
		
		if not map_gen.is_within_bounds(neighbor_pos.x, neighbor_pos.y):
			continue
		
		if astar_grid.is_point_solid(neighbor_pos):
			continue
		
		var path = astar_grid.get_point_path(character_world_pos, neighbor_pos)
		if not path:
			continue
		
		var dist = path.size()
		
		if dist < min_dist:
			min_dist = dist
			best_pos = neighbor_pos
			
	return best_pos


func get_astar_path(path_start: Vector2, path_end: Vector2) -> PackedVector2Array:
	var map_gen = Global.current_map
	var tileMap = map_gen.object_layer
	var astar_grid = map_gen.astar_grid
	
	var map_start = tileMap.local_to_map(tileMap.to_local(path_start))
	var map_end = tileMap.local_to_map(tileMap.to_local(path_end))
	
	#print("Yol İsteği: ", map_start, " -> ", map_end) # DEBUG 4
	if !map_gen.is_within_bounds(map_end.x, map_end.y):
		return PackedVector2Array()
	if astar_grid.is_point_solid(map_end):
		var valid_neighbor = find_walkable_tile(map_end, map_start)
			
		if valid_neighbor != Vector2i(-1, -1) and Global.current_map.is_within_bounds(valid_neighbor.x, valid_neighbor.y):
			return astar_grid.get_point_path(map_start, valid_neighbor)
			
	if map_gen.is_within_bounds(map_end.x, map_end.y):
		#print("HATA: Duvarın etrafı tamamen kapalı!")
		return astar_grid.get_point_path(map_start, map_end)
	
	return PackedVector2Array()
