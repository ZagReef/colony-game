extends Node2D

const gridSize = 50
var grid = []
var grid_copy = grid
var grid_copy1
var finished = false
var entrance = []
var exit = []

func _ready() -> void:
	initialize_grid()
	add_rand_walls(30)
	print_grid()
	for i in 500:
		summon_wall()
		if wall_count():
			print_grid()
			print(i, ". iterasyonda tamamlandı")
			break
		else: if(i%100 == 0 and i != 500):
			print_grid()
		add_edge()
		grid_copy1 = deep_copy(grid)

func initialize_grid():
	for y in range(gridSize):
		grid.append([])
		for x in range(gridSize):
			grid[y].append(".")

	
func print_grid():
	for x in range(gridSize):
		var str_r = ""
		for y in range(gridSize):
			str_r += str(grid[y][x] + " ")
		print(str_r)
	print()

func detect_neighbors_8way(x, y) -> int:
	var wall_count = 0
	var directions = [
		Vector2(-1,1), Vector2(0,1), Vector2(1,1),
		Vector2(-1,0),               Vector2(1,0),
		Vector2(-1,-1), Vector2(0,-1), Vector2(1,-1)
		]
	for dir in directions:
		var nx = x + dir.x
		var ny = y + dir.y
		
		if nx >= 0 and ny >= 0 and nx < grid.size() and ny < grid[0].size():
			if grid[ny][nx] == "X": 
				wall_count += 1
	return wall_count

func set_wall(x, y):
	grid_copy[y][x] = "X"
	
func set_space(x, y):
	grid_copy[y][x] = "."

func summon_wall():
	grid_copy = deep_copy(grid)
	for y in range(gridSize):
		for x in range(gridSize):
			if detect_neighbors_8way(x, y) >= 2 and detect_neighbors_8way(x, y) < 4:
				set_wall(x, y)
			else: if detect_neighbors_8way(x, y) > 4:
				set_space(x, y)
	grid = grid_copy
	
func deep_copy(original_grid):
	var new_grid = []
	for y in range(original_grid.size()):
		new_grid.append([])
		for x in range(original_grid[y].size()):
			new_grid[y].append(original_grid[y][x])
	return new_grid
	
func add_rand_walls(count : int) -> void:
	randomize()
	
	var placed_walls = 0
	while placed_walls < count:
		var x = randi() % gridSize - 1
		var y = randi() % gridSize - 1
		
		if grid[y][x] == ".":
			set_wall(x, y)
			placed_walls += 1

func check_edge() -> int:
	var count : int = 0
	for i in range(gridSize):
		if grid[0][i] == ".":
			count += 1
		if grid[gridSize - 1][i] == ".":
			count += 1
	for i in range(1, gridSize - 1):
		if grid[i][0] == ".":
			count += 1
		if grid[i][gridSize - 1] == ".":
			count += 1
	return count

func add_edge():
	randomize()
	
	var odd_even = randi() % 2
	var odd_even1 = randi() % 2
	
	if odd_even == 1:
		if odd_even1 == 1:
			for i in range(gridSize - 1):
				if grid[0][i] == ".":
					set_wall(i, 0)
		else:
			for i in range(gridSize - 1):
				if grid[gridSize-1][i] == ".":
					set_wall(i, gridSize-1)
	else:
		if odd_even1 == 1:
			for i in range(gridSize - 1):
				if grid[i][0] == ".":
					set_wall(0, i)
		else:
			for i in range(gridSize - 1):
				if grid[i][gridSize-1] == ".":
					set_wall(gridSize-1, i)
					
func wall_count() -> bool:
	var count = 0
	for x in range(gridSize - 1):
		for y in range(gridSize - 1):
			if grid[y][x] == "X":
				count += 1
	if count >= gridSize*gridSize/2:
		return true
	else: return false
