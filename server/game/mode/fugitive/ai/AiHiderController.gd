class_name AiHiderController
extends CharacterBody3D

# The server-side body of a bot fugitive. It moves under its own physics
# toward whatever the brain asks for and publishes the same network_update
# stream a human client sends, so every client sees it as a remote hider.

const GRAVITY := pow(9.8, 2)
const MOVEMENT_LAMBDA := 0.01
const DEFAULT_ARRIVE_DISTANCE := 0.7

@onready var player := $Player as FugitivePlayer

var update_threshold := Threshold.new(Utils.COMMON_NETWORK_UPDATE_THRESHOLD)

var has_target := false
var move_target := Vector3()
var arrive_distance := DEFAULT_ARRIVE_DISTANCE
var want_sprint := false
var want_crouch := false


func _ready():
	player.set_not_local_player()


func get_player() -> FugitivePlayer:
	return player


func set_target(target: Vector3, arrive := DEFAULT_ARRIVE_DISTANCE):
	has_target = true
	move_target = target
	arrive_distance = arrive


func clear_target():
	has_target = false


func reached_target() -> bool:
	return not has_target or _horizontal_offset_to(move_target).length() <= arrive_distance


func can_move() -> bool:
	return player.gameStarted and not player.gameEnded and not player.frozen and player.car == null


func on_car_entered(_car):
	pass


func on_car_exited(_car):
	pass


func car_rotate(angle: float):
	rotate_y(angle)


func _horizontal_offset_to(target: Vector3) -> Vector3:
	var offset := target - global_transform.origin
	offset.y = 0.0
	return offset


func _physics_process(delta):
	var moving := can_move()
	player.sprint = want_sprint and moving
	player.is_crouching = want_crouch

	player.velocity.y -= GRAVITY * delta

	var horizontal := Vector3()
	if moving and has_target:
		var offset := _horizontal_offset_to(move_target)
		if offset.length() > arrive_distance:
			var speed: float
			if player.is_sprinting():
				speed = player.speed_sprint
			elif player.is_crouching:
				speed = player.speed_crouch
			else:
				speed = player.speed_walk
			var direction := offset.normalized()
			horizontal = direction * speed
			look_at(global_transform.origin + direction, Vector3.UP)

	player.velocity.x = horizontal.x
	player.velocity.z = horizontal.z

	set_velocity(player.velocity)
	set_up_direction(Vector3.UP)
	move_and_slide()
	player.velocity = velocity

	player.isMoving = Vector3(velocity.x, 0.0, velocity.z).length() > MOVEMENT_LAMBDA

	if not player.gameEnded and update_threshold.is_exceeded():
		player.rpc("network_update", position, rotation, player.velocity, player.is_crouching, player.isMoving, player.sprint, player.stamina)
