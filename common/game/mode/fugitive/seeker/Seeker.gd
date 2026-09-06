extends "res://common/game/mode/fugitive/FugitivePlayer.gd"
class_name Seeker

const GROUP := "seeker"
const CONE_WIDTH = cos(deg_to_rad(35.0))
const MAX_DETECT_DISTANCE := 3.0
const MAX_VISION_DISTANCE := 50.0
const MIN_VISION_DISTANCE := 3.0
const CLOSE_PROXIMITY_DISTANCE := 1.5

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
		
		var fov_visibility := VisionCone.brightest_view_of(hider, seeker_ray_caster, CONE_WIDTH)
		
		# FOV visibility can be faded out if at edge of distance visibility
		var percent_visible: float = fov_visibility * distance_visibility
		percent_visible = clamp(percent_visible, 0.0, 1.0)
		
		# The hider's set visibility method will handle the visible effects of this
		hider.update_visibility(percent_visible)


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
