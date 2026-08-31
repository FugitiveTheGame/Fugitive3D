extends "res://common/game/mode/fugitive/FugitivePlayer.gd"
class_name Seeker

const GROUP := "seeker"
const CONE_WIDTH = cos(deg_to_rad(35.0))
const MAX_DETECT_DISTANCE := 3.0
const MAX_VISION_DISTANCE := 50.0
const MIN_VISION_DISTANCE := 3.0
const CLOSE_PROXIMITY_DISTANCE := 1.5

# Points tested from a hider's feet up to their head
const BODY_SAMPLES := 5

const MOVEMENT_VISIBILITY_PENALTY := 0.10
const SPRINT_VISIBILITY_PENALTY := 0.75

@export var flash_light_path: NodePath
@onready var flash_light := get_node(flash_light_path) as Node3D
@onready var seeker_ray_caster := flash_light.get_ray_caster() as RayCast3D


func _ready():
	super._ready()
	add_to_group(GROUP)
	
	# Only the server listens for detections
	if multiplayer.is_server():
		# SeekerShape has a special DetectionArea node
		# Listen to it for detection logic
		playerShape.get_node("DetectionArea").connect("body_entered", Callable(self, "body_entered_detection_radius"))


# Detect if a particular hider has been seen by the seeker
# Change the visibility of the Hider depending on if the
# seeker can see them.
func process_hider(hider):
	# Distance between Hider and Seeker
	var distance = playerController.global_transform.origin.distance_to(hider.playerController.global_transform.origin)
	
	# TODO: CLOSE_PROXIMITY_DISTANCE is a hack, see issue #14
	if distance < CLOSE_PROXIMITY_DISTANCE:
		hider.update_visibility(1.0)
	# Quick reject, if too far away, or flashlight is off, just give up
	elif distance <=  MAX_VISION_DISTANCE and flash_light.is_on:
		############################################
		# Begin visibility calculations
		############################################
		
		# At a given distance, fade the hider out
		var distance_visibility: float
		
		# Hider is too far away, make invisible regardless of FOV visibility
		if distance > MAX_VISION_DISTANCE:
			distance_visibility = 0.0
		# Hider is at the edge of distance visibility, calculate how close to the edge they are
		elif distance > MIN_VISION_DISTANCE:
			var shiftedDistance = distance - MIN_VISION_DISTANCE
			distance_visibility = 1.0 - (shiftedDistance / (MAX_VISION_DISTANCE-MIN_VISION_DISTANCE))
		# Hider is well with-in visible distance, we won't modify the FOV visibility at all
		else:
			distance_visibility = 1.0
		
		# The flashlight rides at the seeker's waist while a hider's head is most
		# of a metre higher, so measuring a single point at the head swings outside
		# the cone whenever the seeker looks down at someone close, even with the
		# body squarely in the beam. Take the best view along the whole hider;
		# update_visibility() keeps the highest value it is given.
		var feet: Vector3 = hider.playerController.global_transform.origin
		var head: Vector3 = hider.get_current_shape().head.global_transform.origin
		
		for sample in BODY_SAMPLES:
			var point: Vector3 = feet.lerp(head, float(sample) / float(BODY_SAMPLES - 1))
			var fov_visibility: float = beam_strength_at(hider, point)
			
			# FOV visibility can be faded out if at edge of distance visibility
			var percent_visible: float = fov_visibility * distance_visibility
			percent_visible = clamp(percent_visible, 0.0, 1.0)
			
			# The hider's set visibility method will handle the visible effects of this
			hider.update_visibility(percent_visible)


# How brightly the flashlight beam falls on one point of a hider, or 0.0 when
# anything stands between the seeker and that point
func beam_strength_at(hider, point: Vector3) -> float:
	# Cast a ray between the seeker's flashlight and this point
	var look_vec := flash_light.to_local(point)
	
	seeker_ray_caster.target_position = look_vec
	seeker_ray_caster.force_raycast_update()
	
	# Only if ray is colliding. If it's not, and we try to do logic,
	# wierd stuff happens
	if not seeker_ray_caster.is_colliding():
		return 0.0
	
	# If the ray hits a wall or something else first, then this point is occluded
	if seeker_ray_caster.get_collider() != hider.playerBody:
		return 0.0
	
	# Calculate the angle of this ray from the cetner of the Flashlight's FOV
	var look_angle := Vector3(0.0, 0.0, -1.0).dot(look_vec.normalized())
	
	# If hider is in the center of Seeker's FOV, they are fully visible
	# otherwise, they will gradually fade out the further out to the edges
	# of the FOV they are. Outside the FOV cone, they are invisible.
	var rangeShifted = clamp(look_angle - CONE_WIDTH, 0.0, CONE_WIDTH)
	return rangeShifted / (1.0 - CONE_WIDTH)


# Hider detection
func body_entered_detection_radius(body: Node):
	if gameStarted and not gameEnded:
		if body.has_method("get_player"):
			var player = body.get_player()
			if player != null and player.playerType == FugitiveTeamResolver.PlayerType.Hider:
				# 1) Neither Hider nor Seeker may be in a car
				# 2) Hider must not be in a win zone
				# 3) Hider must not be frozen
				if self.car == null and player.car == null and not player.is_in_winzone() and not player.frozen:
					freeze_hider(player)


func freeze_hider(hider):
	print("Freeze hider!")
	
	# Only the server is actually making this decision
	if multiplayer.is_server():
		hider.freeze()
		
		FugitivePlayerDataUtility.increment_stat_for_player_id(id, FugitivePlayerDataUtility.STAT_SEEKER_FREEZES)
		FugitivePlayerDataUtility.increment_stat_for_player_id(hider.id, FugitivePlayerDataUtility.STAT_HIDER_FROZEN)
		
		ClientNetwork.update_players()


func on_state_playing():
	print("Seeker: on_state_playing()")
	if multiplayer.is_server():
		unfreeze()


func can_lock_car(car) -> bool:
	return car != null and not car.locked and not car.has_occupants()
