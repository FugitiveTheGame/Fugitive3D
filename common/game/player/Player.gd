extends Spatial
class_name Player


const DEFAULT_SPEED_CROUCH := 2.0
const DEFAULT_SPEED_WALK := 5.0
const DEFAULT_SPEED_SPRINT := 10.0
const DEFAULT_STAMINA_MAX := 100.0
const DEFAULT_STAMINA_SPRINT_RATE := 20.0
const DEFAULT_STAMINA_REGEN_RATE := 5.0

var speed_crouch := DEFAULT_SPEED_CROUCH
var speed_walk := DEFAULT_SPEED_WALK
var speed_sprint := DEFAULT_SPEED_SPRINT
var stamina_max := DEFAULT_STAMINA_MAX
var stamina_sprint_rate := DEFAULT_STAMINA_SPRINT_RATE
var stamina_regen_rate := DEFAULT_STAMINA_REGEN_RATE

onready var walking_sound = $WalkingSound

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


var isSprinting := false setget set_is_sprinting
func set_is_sprinting(value: bool):
	isSprinting = value
	if value:
		walking_sound.pitch_scale = 2.0
	else:
		walking_sound.pitch_scale = 1.0


var stamina := stamina_max

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


puppet func network_update(networkPosition: Vector3, networkRotation: Vector3, networkCrouching: bool, networkMoving: bool, networkSprinting):
	playerController.translation = networkPosition
	playerController.rotation = networkRotation
	self.is_crouching = networkCrouching
	self.isMoving = networkMoving
	self.isSprinting = networkSprinting


func _physics_process(delta):
	if is_network_master():
		process_stamina(delta)


func configure(playerName: String):
	set_player_name(playerName)


func set_not_local_player():
	print("set_not_local_player()")


func set_is_local_player():
	print("set_is_local_player()")
	add_to_group(Groups.LOCAL_PLAYER)
	hide_avatar()


func set_player_name(playerName: String):
	#$NameLabel.text = playerName
	pass


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
	return isSprinting and stamina > 0.0 and not is_crouching


func is_moving():
	return isMoving


func is_moving_fast():
	return is_moving() and is_sprinting()


func process_stamina(delta: float):
	if is_sprinting() and is_moving():
		stamina -= (stamina_sprint_rate * delta)
	elif not is_moving():
		stamina += (stamina_sprint_rate * delta)
	stamina = clamp(stamina, 0.0, stamina_max)
