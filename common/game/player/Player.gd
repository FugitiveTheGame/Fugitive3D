extends Spatial
class_name Player


const DEFAULT_SPEED_CROUCH := 2.0
const DEFAULT_SPEED_WALK := 5.0
const DEFAULT_SPEED_SPRINT := 10.0
const DEFAULT_STAMINA_MAX := 100.0
const DEFAULT_STAMINA_SPRINT_RATE := 20.0
const DEFAULT_STAMINA_REGEN_RATE := 5.0
const JUMP_STAMINA_COST := DEFAULT_STAMINA_MAX / 4.0

var speed_crouch := DEFAULT_SPEED_CROUCH
var speed_walk := DEFAULT_SPEED_WALK
var speed_sprint := DEFAULT_SPEED_SPRINT
var stamina_max := DEFAULT_STAMINA_MAX
var stamina_sprint_rate := DEFAULT_STAMINA_SPRINT_RATE
var stamina_regen_rate := DEFAULT_STAMINA_REGEN_RATE

# Use for clientside prediction
var velocity := Vector3()

# The player ID that this player object represents
var id: int

# This is useful so players on opposing teams from the local player
#  can be configured differently
var localPlayerType: int

onready var walking_sound = $WalkingSound
onready var jumping_sound = $JumpingSound
onready var no_stamina_sound = $NoStaminaSound


var minimum_stamina_recovered := true

var isMoving := false setget set_is_moving
func set_is_moving(value: bool):
	isMoving = value
	
	# Don't make any noise while crouching
	if value and not is_crouching:
		if not walking_sound.playing:
			walking_sound.play()
	else:
		if walking_sound.playing:
			walking_sound.stop()


var sprint := false

var stamina := stamina_max setget set_stamina
func set_stamina(value: float):
	stamina = value
	stamina = clamp(stamina, 0, DEFAULT_STAMINA_MAX)


var show_avatar := true
var is_crouching := false setget set_is_crouching
func set_is_crouching(value: bool):
	if value != is_crouching:
		is_crouching = value
		
		if show_avatar:
			playerShape.set_crouching(value)

export(NodePath) var shapePath: NodePath
export(NodePath) var playerControllerPath: NodePath
export(NodePath) var playerBodyPath: NodePath

onready var playerController := get_node(playerControllerPath) as Spatial
onready var playerShape := get_node(shapePath) as Spatial
onready var playerBody := get_node(playerBodyPath) as KinematicBody


puppet func network_update(networkPosition: Vector3, networkRotation: Vector3, networkVelocity: Vector3, networkCrouching: bool, networkMoving: bool, networkSprinting, networkStamina: float):
	playerController.translation = networkPosition
	playerController.rotation = networkRotation
	self.is_crouching = networkCrouching
	self.isMoving = networkMoving
	self.sprint = networkSprinting
	self.velocity = networkVelocity
	self.stamina = networkStamina


func _physics_process(delta):
	if is_network_master():
		process_stamina(delta)
	
	if is_sprinting():
		walking_sound.pitch_scale = 2.0
	else:
		walking_sound.pitch_scale = 1.0


func configure(_playerName: String, _playerId: int, _localPlayerType: int):
	id = _playerId
	localPlayerType = _localPlayerType


func set_not_local_player():
	print("set_not_local_player()")


func set_is_local_player():
	walking_sound.unit_db = -15.0
	print("set_is_local_player()")
	add_to_group(Groups.LOCAL_PLAYER)
	hide_avatar()


func hide_avatar():
	show_avatar = false
	playerShape.get_standing_shape().hide()
	playerShape.get_crouching_shape().hide()


func get_current_shape() -> Spatial:
	if is_crouching:
		return playerShape.get_crouching_shape()
	else:
		return playerShape.get_standing_shape()


func is_sprinting() -> bool:
	return sprint and stamina > 0.0 and not is_crouching


func is_moving():
	return isMoving


func is_moving_fast():
	return is_moving() and is_sprinting()


func process_stamina(delta: float):
	if is_sprinting() and is_moving():
		stamina -= (stamina_sprint_rate * delta)
	elif not is_moving():
		stamina += (stamina_sprint_rate * delta)
	
	if stamina <= 0.0 and minimum_stamina_recovered:
		out_of_stamina()
	if stamina >= 0.25:
		minimum_stamina_recovered = true
	
	stamina = clamp(stamina, 0.0, stamina_max)


func jump():
	rpc("on_jump")


remotesync func on_jump():
	jumping_sound.play()


func out_of_stamina():
	minimum_stamina_recovered = false
	rpc("on_out_of_stamina")


remotesync func on_out_of_stamina():
	no_stamina_sound.play()


func stop_movement_sounds():
	walking_sound.stop()
	jumping_sound.stop()
	no_stamina_sound.stop()
