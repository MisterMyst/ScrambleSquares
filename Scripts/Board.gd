extends Control

export var line_width := 2.0

var cell_size : Vector2

var cells := []

onready var available_set = [$"0/Texture", $"1/Texture", $"2/Texture", $"3/Texture", 
		$"4/Texture", $"5/Texture", $"6/Texture", $"7/Texture", $"8/Texture"]

var available_sets := []

var waiting_index : int
var waiting_piece : Tile
var tile_rotations :=  [0,0,0,
								0,0,0,
								0,0,0]

var victory := false

var tile_pool_pos : Vector2

var edge_graph := {}

# Called when the node enters the scene tree for the first time.
func _ready():
#	resetSolver()
	
	set_process(visible)
	resetSolver()
	if(visible):
		Globals.BOARD = self


func buildEdgeGraph():
	edge_graph.clear()
	for tile in available_set:
		for i in range(0, 4):
			var index = tile.edge_type[i] + (int(!tile.edge_ver[i]) * 4)
			if( edge_graph.has(index) ):
				edge_graph[index].append([tile, i])
			else:
				edge_graph[index] = [[tile, i]]

func _process(delta):
	if(Globals.SOLVING):
		if(!victory):
			if(Globals.ALGORITHM == 0):
				bruteForce(delta)
			elif(Globals.ALGORITHM == 1):
				bruteForceBacktracking(delta)
			else:
				graphSolve(delta)
			var msecs = OS.get_ticks_msec() - Globals.SOLVE_START_TIME
			get_parent().get_node("Timer").text = str(msecs / 60000, ":", str((msecs / 1000) % 60).pad_zeros(2), ":", str(msecs % 1000).pad_zeros(3))
	pass

func resetSolver():
	cell_size = $"0/Texture".get_rect().size
	cells.clear()
	cells.resize(9)
	
	tile_pool_pos = cell_size * 1.5 + Vector2(cell_size.x * 2.5, 0)
	
	tile_rotations =  [0,0,0,
							 0,0,0,
							 0,0,0]
	
	if(!Globals.ROTATE_CENTER):
		if(Globals.START_CENTER):
			tile_rotations[0] = 4
		else:
			tile_rotations[4] = 4
	
	available_sets.clear()
	available_sets.resize(9)
	available_sets[transformIndex(0)] = available_set.duplicate()
	for tile in available_set:
		tile.visible = visible
		tile.rect_position = tile_pool_pos
		tile.rect_rotation = 0
		tile.target_rotation = 0
		tile.in_board = false
	
	waiting_index = -1
	waiting_piece = null
		
	buildEdgeGraph()
	victory = false
	get_parent().get_node("VictoryText").visible = false
	update()

func getAdjacentEdge(trans_index_prev : int, trans_index_curr : int) -> int:
	var diff := ((trans_index_curr % 3) - (trans_index_prev % 3))
	
	if( diff == 1 ):
		#new tile is in the same row to the right of previous tile
		return 1
	elif( diff == 0 ):
		if( trans_index_curr > trans_index_prev ):
			#new tile is below previous tile
			return 2
		else:
			#new tile is above previous tile
			return 0
	elif( diff == -1 ):
		#new tile is to the left of previous tile
		return 3
	elif( diff == -2 ):
		#new tile is below a DIFFERENT tile
		return 2
	elif( diff == 2):
		#new tile is above a DIFFERENT tile
		return 0
	
	return -1

func getEdgePossibilities(index : int):
	
	var trans_index_prev := transformIndex(index - 1)
	var trans_index_curr := transformIndex(index)
	var prev_tile = cells[trans_index_prev]
	
	var diff := ((trans_index_curr % 3) - (trans_index_prev % 3))
	
	var edge : int
	
	if( diff == 1 ):
		#new tile is in the same row to the right of previous tile
		edge = prev_tile.getEdgeRotated(1)
	elif( diff == 0 ):
		if( trans_index_curr > trans_index_prev ):
			#new tile is below previous tile
			edge = prev_tile.getEdgeRotated(2)
		else:
			#new tile is above previous tile
			edge = prev_tile.getEdgeRotated(0)
	elif( diff == -1 ):
		#new tile is to the left of previous tile
		edge = prev_tile.getEdgeRotated(3)
	elif( diff == -2 ):
		#new tile is below a DIFFERENT tile
		trans_index_prev = transformIndex(index - 3)
		prev_tile = cells[trans_index_prev]
		edge = prev_tile.getEdgeRotated(2)
	
	var dict_index = prev_tile.edge_type[edge] + (int(prev_tile.edge_ver[edge]) * 4)
	return edge_graph[dict_index]

func graphSolve(delta):
	if(waiting_piece != null && !waiting_piece.isInAction()):
		#finished piece movement
		update()
		var tile_valid := true
		for i in range(0, 9):
			if( cells[i] != null ):
				if( i+1 < 9 && i%3 != 2 && cells[i + 1] != null):
					var result = cells[i].checkEdge(cells[i + 1], true)
					tile_valid = tile_valid && result
				if( i+3 < 9 && cells[i+3] != null):
					var result = cells[i].checkEdge(cells[i + 3], false)
					tile_valid = tile_valid && result
		if( !tile_valid ):
			waiting_piece.setPosition(tile_pool_pos)
			waiting_piece.target_rotation = 360
			var trans_index = transformIndex(waiting_index)
			cells[trans_index].in_board = false
			cells[trans_index] = null
			if( !Globals.VERBOSE_WAITING ):
				waiting_index = -1
				waiting_piece = null
		else:
			waiting_index = -1
			waiting_piece = null
			if( hasWon() ):
				return
	
	if(waiting_piece != null && waiting_piece.isInAction()):
		return
	
	#check cells to see if we need to add a piece
	for i in range(0, 9):
		var trans_index := transformIndex(i)
		if( cells[trans_index] == null ):
			var tile : Tile
			var adjacent_edge := 0
			var edge_to_match := 0
			if( i == 0 ):
				tile = available_sets[trans_index].pop_front()
			else:
				var edge_entry = available_sets[trans_index].pop_front()
				while( edge_entry != null && edge_entry[0].in_board ):
					edge_entry = available_sets[trans_index].pop_front()
				if( edge_entry != null ):
					tile = edge_entry[0]
					edge_to_match = edge_entry[1]
					adjacent_edge = getAdjacentEdge(trans_index, transformIndex(i - 1))
			if( tile != null ):
				cells[trans_index] = tile
				tile.in_board = true
				waiting_piece = tile
				waiting_index = i
				tile.setPosition(getWorldPos(Vector2(trans_index % 3, int(trans_index / 3 + .1))) - cell_size/2)
				tile.pointEdge(edge_to_match, adjacent_edge)
			else:
				if( trans_index == 1 && !Globals.START_CENTER && tile_rotations[0] < 3 ):
					#do first piece rotations
					tile_rotations[0] += 1
					cells[0].setRotation((tile_rotations[0] * 90))
					available_sets[trans_index] = getEdgePossibilities(i).duplicate()
					waiting_piece = cells[0]
					waiting_index = i
				else:
					var prev_trans_index = transformIndex( i - 1 )
					if( Globals.VERBOSE_WAITING ):
						waiting_piece = cells[prev_trans_index]
						waiting_index = i - 1
					cells[prev_trans_index].target_rotation = 0.0
					cells[prev_trans_index].setPosition(tile_pool_pos)
					cells[prev_trans_index].in_board = false
					cells[prev_trans_index] = null
					if(prev_trans_index == 0 && !Globals.START_CENTER):
						tile_rotations[0] = 0
				return
			if( i < 8 ):
				var next_index_trans := transformIndex(i + 1)
				available_sets[next_index_trans] = getEdgePossibilities(i + 1).duplicate()
			return

func bruteForce(delta):
	if(waiting_piece != null && !waiting_piece.isInAction()):
		#finished piece movement
		update()
		if( hasWon() ):
			return
	
	if(waiting_piece != null && waiting_piece.isInAction()):
		return
	
	#check cells to see if we need to add a piece
	for i in range(0, 9):
		var trans_index = transformIndex(i)
		if( cells[trans_index] == null ):
			var tile = available_sets[trans_index].pop_front()
			if( tile != null):
				cells[trans_index] = tile
				tile.in_board = true
				waiting_piece = tile
				waiting_index = i
				tile.setPosition(getWorldPos(Vector2(trans_index % 3, int(trans_index / 3 + .1))) - cell_size/2)
			else:
				if( waiting_index < 0 ):
					waiting_index = i
				break
			if( i < 8 ):
				var next_index_trans := transformIndex(i + 1)
				available_sets[next_index_trans] = available_set.duplicate()
				for j in range(0, 9):
					available_sets[next_index_trans].erase(cells[j])
			return
	
	#rotate a piece
	for i in range(waiting_index, -1, -1):
		var trans_index = transformIndex(i)
		var next_trans_index = transformIndex(i + 1)
		if( cells[trans_index] == null):
			continue
		if( tile_rotations[i] < 4 ):
			if (i == 8 || available_sets[next_trans_index].empty()):
				#if there are no more options for the next cell, rotate this cell
				tile_rotations[i] += 1
				cells[trans_index].setRotation((tile_rotations[i] * 90))
				waiting_piece = cells[trans_index]
				waiting_index = i
				#if we haven't completed a full 360, refresh available tiles on next slot
				if (tile_rotations[i] < 4 && i+1 < 9):
					#for j in range(i + 1, 9):
					if( Globals.ROTATE_CENTER || i + 1 != 0 ):
						tile_rotations[i+1] = 0
					available_sets[next_trans_index] = available_set.duplicate()
					for k in range(0, 9):
						available_sets[next_trans_index].erase(cells[k])
					if( cells[next_trans_index] == null):
						return
					cells[next_trans_index].rect_rotation = 0.0
					cells[next_trans_index].target_rotation = 0.0
				elif( tile_rotations[i] == 4):
					for j in range(i, 9):
						var trans_j = transformIndex(j)
						if( cells[trans_j] != null ):
							tile_rotations[j] = 0
							cells[trans_j].in_board = false
							cells[trans_j] = null
				return #done with this step, don't keep looping backwards for rotation
		elif(i == 0 || (i < 8 && available_sets[next_trans_index].empty())):
			if(Globals.ROTATE_CENTER || i != 0):
				tile_rotations[i] = 0
			if( Globals.VERBOSE_WAITING ):
				waiting_index = i
				waiting_piece = cells[trans_index]
			cells[trans_index].rect_rotation = 0.0
			cells[trans_index].target_rotation = 0.0
			cells[trans_index].setPosition(tile_pool_pos)
			cells[trans_index].in_board = false
			cells[trans_index] = null
			return

func bruteForceBacktracking(delta):
	if(waiting_piece != null && !waiting_piece.isInAction()):
		#finished piece movement
		update()
		var tile_valid = true
		for i in range(0, 9):
			if( cells[i] != null ):
				if( i+1 < 9 && i%3 != 2 && cells[i + 1] != null):
					var result = cells[i].checkEdge(cells[i + 1], true)
					tile_valid = tile_valid && result
				if( i+3 < 9 && cells[i+3] != null):
					var result = cells[i].checkEdge(cells[i + 3], false)
					tile_valid = tile_valid && result
		if( !tile_valid ):
			if( tile_rotations[waiting_index] >= 3 ):
				if( Globals.ROTATE_CENTER || waiting_index != 0 ):
					tile_rotations[waiting_index] = 0
				waiting_piece.setPosition(tile_pool_pos)
#				waiting_piece.rect_rotation = 0.0
				waiting_piece.target_rotation = 360
				var trans_index = transformIndex(waiting_index)
				cells[trans_index].in_board = false
				cells[trans_index] = null
				if( !Globals.VERBOSE_WAITING ):
					waiting_piece = null
					waiting_index = -1
			else:
				tile_rotations[waiting_index] += 1
				waiting_piece.setRotation((tile_rotations[waiting_index] * 90) % 360)
				return
		else:
			waiting_index = -1
			waiting_piece = null
		if( hasWon() ):
			return
	
	if(waiting_piece != null && waiting_piece.isInAction()):
		return
	
	#check cells to see if we need to add a piece
	for i in range(0, 9):
		var trans_index = transformIndex(i)
		if( cells[trans_index] == null ):
			var tile = available_sets[trans_index].pop_front()
			if( tile != null):
				cells[trans_index] = tile
				tile.in_board = true
				waiting_piece = tile
				waiting_index = i
				tile.setPosition(getWorldPos(Vector2(trans_index % 3, int(trans_index / 3 + .1))) - cell_size/2)
			else:
				if( waiting_index < 0 ):
					waiting_index = i
				break
			if( i < 8 ):
				var next_index_trans := transformIndex(i + 1)
				available_sets[next_index_trans] = available_set.duplicate()
				for j in range(0, 9):
					available_sets[next_index_trans].erase(cells[j])
			return
	
	#rotate a piece
	for i in range(waiting_index, -1, -1):
		var trans_index = transformIndex(i)
		var next_trans_index = transformIndex(i + 1)
		if( cells[trans_index] == null):
			continue
		if( tile_rotations[i] < 4 ):
			if (i == 8 || available_sets[next_trans_index].empty()):
				#if there are no more options for the next cell, rotate this cell
				tile_rotations[i] += 1
				cells[trans_index].setRotation((tile_rotations[i] * 90) % 360)
				waiting_piece = cells[trans_index]
				waiting_index = i
				#if we haven't completed a full 360, refresh available tiles on next slot
				if (tile_rotations[i] < 4 && i+1 < 9):
					#for j in range(i + 1, 9):
					if( Globals.ROTATE_CENTER || i + 1 != 0 ):
						tile_rotations[i+1] = 0
					available_sets[next_trans_index] = available_set.duplicate()
					for k in range(0, 9):
						available_sets[next_trans_index].erase(cells[k])
					if( cells[next_trans_index] == null):
						return
					cells[next_trans_index].rect_rotation = 0.0
					cells[next_trans_index].target_rotation = 0.0
				return #done with this step, don't keep looping backwards for rotation
		elif(i == 0 || available_sets[next_trans_index].empty()):
			if(Globals.ROTATE_CENTER || i != 0):
				tile_rotations[i] = 0
			if( Globals.VERBOSE_WAITING ):
				waiting_piece = cells[trans_index]
				waiting_index = i
			cells[trans_index].rect_rotation = 0.0
			cells[trans_index].target_rotation = 0.0
			cells[trans_index].setPosition(tile_pool_pos)
			cells[trans_index].in_board = false
			cells[trans_index] = null
			return

func transformIndex(index : int) -> int:
	if(!Globals.START_CENTER):
		return index
	#convert index to center start version
	if( index < 2):
		return index + 4
	elif( index < 5):
		return 10 - index
	elif(index == 5):
		return 3
	elif(index > 5):
		return index - 6
	return index

func hasWon() -> bool:
	victory = true
	for i in range(0, 9):
		if( cells[i] != null):
			if( i+1 < 9 && i%3 != 2):
				var result = cells[i].checkEdge(cells[i + 1], true)
				victory = victory && result
			if( i+3 < 9):
				var result = cells[i].checkEdge(cells[i + 3], false)
				victory = victory && result
		else:
			#empty cell, we have not won yet
			victory = false
	return victory

func _draw():	
	var spacing := cell_size.x + line_width
	var total_size := 3*cell_size.x + 3*line_width
	for i in range( 0, 4 ):
		var pos = Vector2( spacing * i, 0 )
		draw_line(pos, pos + Vector2(0, total_size), Color.black, line_width)
	for i in range( 0, 4 ):
		var pos = Vector2( 0, spacing * i )
		draw_line(pos, pos + Vector2(total_size, 0), Color.black, line_width)
	
	draw_set_transform(-rect_global_position, 0, Vector2(1, 1))
	var victory := true
	for i in range(0, 9):
		if( cells[i] != null):
			if( i+1 < 9 && i%3 != 2):
				var result = cells[i].checkEdge(cells[i + 1], true)
				victory = victory && result
				if( result ):
					draw_circle(getWorldPos( Vector2(i % 3, int(i / 3 + .1))) + Vector2(cell_size.x/2, 0), 10, Color.green)
				else:
					draw_circle(getWorldPos( Vector2(i % 3, int(i / 3 + .1))) + Vector2(cell_size.x/2, 0), 10, Color.red)
			if( i+3 < 9):
				var result = cells[i].checkEdge(cells[i + 3], false)
				victory = victory && result
				if( result ):
					draw_circle(getWorldPos( Vector2(i % 3, int(i / 3 + .1))) + Vector2(0, cell_size.y / 2), 10, Color.green)
				else:
					draw_circle(getWorldPos( Vector2(i % 3, int(i / 3 + .1))) + Vector2(0, cell_size.y / 2), 10, Color.red)
		else:
			#empty cell, we have not won yet
			victory = false
	if(victory):
		get_parent().get_node("VictoryText").visible = true

func getTilePos(mouse_pos) -> Vector2:
	var offset = mouse_pos - rect_position + Vector2(line_width, line_width)
	var pos = Vector2((offset.x / (cell_size.x + line_width)), (offset.y / (cell_size.y + line_width)))
	return pos.floor()
	
func placeTile(mouse_pos : Vector2, tile, old_position : Vector2, old_slot : int) -> int:
	
	var cell_pos := getTilePos(mouse_pos)
	
	var tile_index = getTileIndex(cell_pos)
	if(tile_index < 0):
		return tile_index
	if( cells[tile_index] != null):
		cells[tile_index].setPosition(old_position)
		if( old_slot >= 0 ):
			cells[old_slot] = cells[tile_index]
		else:
			cells[tile_index].in_board = false
	cells[tile_index] = tile
	tile.in_board = true
	tile.rect_position = getWorldPos(cell_pos) - cell_size/2
	update()
	return tile_index

#returns center position of tile
func getWorldPos(tile_pos : Vector2) -> Vector2:
	return rect_global_position + tile_pos * (cell_size + Vector2(line_width, line_width)) + cell_size/2

func pickupTile(mouse_pos : Vector2, tile) -> int:
	var cell_pos := getTilePos(mouse_pos)
	var tile_index = getTileIndex(cell_pos)
	if(tile_index < 0):
		return -1
	if( cells[tile_index] == tile ):
		cells[tile_index] = null
		tile.in_board = false
		update()
		return tile_index
	return -1

func getTileIndex(tile_pos : Vector2) -> int:
	if (int(tile_pos.x) < 0 || int(tile_pos.x) > 2 || int(tile_pos.y) < 0 || int(tile_pos.y) > 2):
		return -1
	return int(tile_pos.x) + int(tile_pos.y) * 3
	
