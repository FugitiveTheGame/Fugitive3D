class_name AiHiderController
extends CharacterBody3D

# The server-side body of a bot fugitive. It moves under its own physics
# toward whatever the brain asks for and publishes the same network_update
# stream a human client sends, so every client sees it as a remote hider.

const DEFAULT_ARRIVE_DISTANCE := 0.7

@onready var player := $Player as FugitivePlayer

# The difficulty this bot was given in the lobby, shared with the brain
var profile := AiDifficulty.profile(AiDifficulty.DEFAULT)

var has_target := false
var move_target := Vector3()
var arrive_distance := DEFAULT_ARRIVE_DISTANCE
var want_sprint := false
var want_crouch := false


func _ready():
	player.set_not_local_player()
	player.speed_scale = profile.speed_scale


func get_player() -> FugitivePlayer:
	return player


func apply_difficulty(new_profile: AiDifficulty):
	profile = new_profile
	if is_node_ready():
		player.speed_scale = profile.speed_scale


func set_target(target: Vector3, arrive := DEFAULT_ARRIVE_DISTANCE):
	has_target = true
	move_target = target
	arrive_distance = arrive


func clear_target():
	has_target = false


func reached_target() -> bool:
	return not has_target or _horizontal_offset_to(move_target).length() <= arrive_distance


func can_move() -> bool:
	return player.is_playing() and not player.frozen and player.car == null


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

	player.velocity.y -= Player.GRAVITY * delta

	var horizontal := Vector3()
	if moving and has_target:
		var offset := _horizontal_offset_to(move_target)
		if offset.length() > arrive_distance:
			var direction := offset.normalized()
			horizontal = direction * player.max_speed()
			look_at(global_transform.origin + direction, Vector3.UP)

	player.velocity.x = horizontal.x
	player.velocity.z = horizontal.z

	player.step_body(self)
	player.publish_movement(self)
