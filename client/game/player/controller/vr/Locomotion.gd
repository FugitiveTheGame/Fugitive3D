extends Node

# Coordinates the godot-xr-tools movement providers behind the surface the
# game scripts already use: allowMovement, allowTurn, move_speed, is_moving.
# Movement is head-oriented (the xr-tools PlayerBody applies ground control
# in the camera frame), so the old vr_movement_orientation setting is inert.

@export var leftMovePath: NodePath
@export var rightMovePath: NodePath
@export var leftTurnPath: NodePath
@export var rightTurnPath: NodePath
@export var playerBodyPath: NodePath
@export var vignettePath: NodePath

@onready var leftMove := get_node(leftMovePath) as XRToolsMovementDirect
@onready var rightMove := get_node(rightMovePath) as XRToolsMovementDirect
@onready var leftTurn := get_node(leftTurnPath) as XRToolsMovementTurn
@onready var rightTurn := get_node(rightTurnPath) as XRToolsMovementTurn
@onready var playerBody := get_node(playerBodyPath) as XRToolsPlayerBody
@onready var vignette := get_node(vignettePath)

var move: XRToolsMovementDirect
var turn: XRToolsMovementTurn

var allowMovement := true:
	set(value):
		allowMovement = value
		_apply_enabled()

var allowTurn := true:
	set(value):
		allowTurn = value
		_apply_enabled()

var move_speed := 3.0:
	set(value):
		move_speed = value
		if move != null:
			move.max_speed = value

var is_moving: bool:
	get:
		return allowMovement and playerBody != null \
				and playerBody.ground_control_velocity.length() > 0.1


func _ready():
	match UserData.data.vr_movement_hand:
		1:
			move = rightMove
			turn = leftTurn
		_:
			move = leftMove
			turn = rightTurn

	move.strafe = true
	move.max_speed = move_speed
	_apply_enabled()

	vignette.visible = UserData.data.vr_movement_vignetting


func _apply_enabled():
	if move == null:
		return
	move.enabled = allowMovement
	turn.enabled = allowTurn
	leftMove.enabled = allowMovement and move == leftMove
	rightMove.enabled = allowMovement and move == rightMove
	leftTurn.enabled = allowTurn and turn == leftTurn
	rightTurn.enabled = allowTurn and turn == rightTurn
