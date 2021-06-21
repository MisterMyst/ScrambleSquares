extends PanelContainer

export(NodePath) var move_slider_path
export(NodePath) var rotate_slider_path
export(NodePath) var alg_select_path
export(NodePath) var start_center_check_path
export(NodePath) var center_rot_check_path
export(NodePath) var verbose_waiting_check_path
export(NodePath) var start_button_path
export(NodePath) var stop_button_path

onready var move_slider = get_node(move_slider_path)
onready var rotate_slider = get_node(rotate_slider_path)
onready var alg_select = get_node(alg_select_path)
onready var start_center_check = get_node(start_center_check_path)
onready var center_rot_check = get_node(center_rot_check_path)
onready var verbose_waiting_check = get_node(verbose_waiting_check_path)
onready var start_button = get_node(start_button_path)
onready var stop_button = get_node(stop_button_path)

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.ROTATE_CENTER = center_rot_check.pressed
	Globals.START_CENTER = start_center_check.pressed
	if(Globals.BOARD != null):
		Globals.BOARD.resetSolver()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	Globals.TILE_MOVE_SPEED = move_slider.value
	Globals.TILE_ROT_SPEED = rotate_slider.value
	
	Globals.ALGORITHM = alg_select.selected

func _on_SolveButton_button_up():
	#solve button pressed
	center_rot_check.disabled = true
	start_center_check.disabled = true
	verbose_waiting_check.disabled = true
	alg_select.disabled = true
	Globals.ROTATE_CENTER = center_rot_check.pressed
	Globals.START_CENTER = start_center_check.pressed
	Globals.VERBOSE_WAITING = verbose_waiting_check.pressed
	Globals.BOARD.resetSolver()
	Globals.SOLVING = true
	Globals.SOLVE_START_TIME = OS.get_ticks_msec()
	start_button.disabled = true

func _on_StopButton_pressed():
	alg_select.disabled = false
	center_rot_check.disabled = false
	start_center_check.disabled = false
	verbose_waiting_check.disabled = false
	Globals.SOLVING = false
	start_button.disabled = false
