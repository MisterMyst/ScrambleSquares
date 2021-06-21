extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var TILE_MOVE_SPEED := 6000.0
var TILE_ROT_SPEED := 2000.0

var SOLVING := false

var SOLVE_START_TIME := 0

var ROTATE_CENTER : bool
var START_CENTER : bool
var VERBOSE_WAITING : bool

var ALGORITHM : int

var BOARD

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
