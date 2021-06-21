extends TextureRect

class_name Tile

# Declare member variables here. Examples:

var holding := false
var hover := false
var mouse_offset : Vector2
var target_rotation := 0.0
var target_position : Vector2
var is_moving := false
var pickup_position : Vector2
var pickup_tile_index : int

var in_board := false

export var edge_ver  := []
export var edge_type := []

onready var board := get_parent().get_parent()

const HIGHLIGHT_COL = Color(.8, .8, 0.8, 1.0)

# Called when the node enters the scene tree for the first time.
func _ready():
	rect_pivot_offset = rect_size / 2.0
	pass

func isInAction() -> bool:
	return is_moving || rect_rotation != target_rotation

func setPosition(pos : Vector2):
	target_position = pos
	is_moving = true
	
func setRotation(rot : float):
	target_rotation = rot

func checkEdge(other_tile : Tile, is_right_edge : bool) -> bool:
	
	if(other_tile == null):
		return false
	
	var edge1 : int
	var edge2 : int
	
	if (is_right_edge):
		#compare right edge of this tile to left edge of other tile
		edge1 = getEdgeRotated(1)
		edge2 = other_tile.getEdgeRotated(3)
	else:
		#compare bottom edge of this tile to top edge of other tile
		edge1 = getEdgeRotated(2)
		edge2 = other_tile.getEdgeRotated(0)
		
	if( edge_type[edge1] == other_tile.edge_type[edge2] &&
			edge_ver[edge1] != other_tile.edge_ver[edge2] ):
		return true
	return false

func getEdgeRotated(edge_index : int) -> int:
	var num_quarter_turns := int(round(target_rotation / 90.0))
	return ( ( (edge_index - num_quarter_turns) % 4 ) + 4 ) % 4

func pointEdge( edge_index : int, edge_to_face : int):
	var quarter_turns := edge_to_face - edge_index
	setRotation((((quarter_turns % 4) + 4) % 4) * 90.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if( rect_rotation < target_rotation ):
		rect_rotation += delta * Globals.TILE_ROT_SPEED
		rect_rotation = min( target_rotation, rect_rotation )
		board.update()
	if( rect_rotation > target_rotation ):
		rect_rotation -= delta * Globals.TILE_ROT_SPEED
		rect_rotation = max( target_rotation, rect_rotation )
		board.update()
	
	if( rect_rotation == target_rotation ):
		target_rotation = int(target_rotation) % 360
		rect_rotation = target_rotation
		
	if( is_moving ):
		if(target_position.distance_squared_to(rect_position) < (delta * Globals.TILE_MOVE_SPEED * delta * Globals.TILE_MOVE_SPEED)):
			rect_position = target_position
			is_moving = false
		else:
			var d = (target_position - rect_position).normalized()
			rect_position += d * delta * Globals.TILE_MOVE_SPEED
	
	if( Globals.SOLVING ):
		return
	
	if( holding ):
		rect_position = get_viewport().get_mouse_position() - mouse_offset
		self.modulate = Color.white
	elif( hover ):
		self.modulate = HIGHLIGHT_COL
	else:
		self.modulate = Color.white
		
	if( hover && Input.is_action_just_pressed("tile_rotate_left") ):
		target_rotation -= 90.0
	if( hover && Input.is_action_just_pressed("tile_rotate_right") ):
		target_rotation += 90.0

func _on_Texture_gui_input(event):
	if( Globals.SOLVING ):
		return
	if( event.is_action_pressed("mouse_left") ):
		rect_scale = Vector2(1.1, 1.1)
		holding = true
		mouse_offset = event.position
		pickup_position = rect_position
		pickup_tile_index = board.pickupTile(get_viewport().get_mouse_position(), self)
		get_parent().layer = 3
	elif( event.is_action_released("mouse_left") ):
		rect_scale = Vector2(1, 1)
		holding = false
		board.placeTile(get_viewport().get_mouse_position(), self, pickup_position, pickup_tile_index)
		get_parent().layer = 1

func _on_Texture_mouse_entered():
	hover = true
	if( Globals.SOLVING ):
		return
	get_parent().layer = 1

func _on_Texture_mouse_exited():
	hover = false
	if( Globals.SOLVING ):
		return
	get_parent().layer = 0

