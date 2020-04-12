extends "res://common/game/mode/FugitivePlayer.gd"
class_name Seeker
const GROUP := "seeker"
const CONE_WIDTH = cos(deg2rad(35.0))
const MAX_DETECT_DISTANCE := 2.0
const MAX_VISION_DISTANCE := 50.0
const MIN_VISION_DISTANCE := 3.0
const CLOSE_PROXIMITY_DISTANCE := 1.5

const MOVEMENT_VISIBILITY_PENALTY := 0.10
const SPRINT_VISIBILITY_PENALTY := 0.75

export(NodePath) var flash_light_path: NodePath
onready var flash_light := get_node(flash_light_path) as Spatial
onready var seeker_ray_caster := flash_light.get_ray_caster() as RayCast

onready var win_zones := get_tree().get_nodes_in_group(Groups.WIN_ZONE)


func _ready():
	playerType = GameData.PlayerType.Seeker
	add_to_group(GROUP)


# Detect if a particular hider has been seen by the seeker
# Change the visibility of the Hider depending on if the
# seeker can see them.
func process_hider(hider):
	# Distance between Hider and Seeker
	var distance = playerController.transform.origin.distance_to(hider.playerController.transform.origin)
	
	# TODO: CLOSE_PROXIMITY_DISTANCE is a hack, see issue #14
	if distance < CLOSE_PROXIMITY_DISTANCE:
		hider.update_visibility(1.0)
	# Quick reject, if too far away, just give up
	elif distance <=  MAX_VISION_DISTANCE:
		# Cast a ray between the seeker's flashlight and this hider
		var curHiderShape = hider.get_current_shape()
		var look_vec := flash_light.to_local(curHiderShape.global_transform.origin)
		
		seeker_ray_caster.cast_to = look_vec
		seeker_ray_caster.force_raycast_update()
		
		# Only if ray is colliding. If it's not, and we try to do logic,
		# wierd stuff happens
		if(seeker_ray_caster.is_colliding()):
			
			var bodySeen = seeker_ray_caster.get_collider()
			
			# If the ray hits a wall or something else first, then this Hider is fully occluded
			if(bodySeen == hider.playerBody):
				# Calculate the angle of this ray from the cetner of the Flashlight's FOV
				var look_angle := Vector3(0.0, 0.0, -1.0).dot(look_vec.normalized())
				
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
					var x = distance - MIN_VISION_DISTANCE
					distance_visibility = 1.0 - (x / (MAX_VISION_DISTANCE-MIN_VISION_DISTANCE))
				# Hider is well with-in visible distance, we won't modify the FOV visibility at all
				else:
					distance_visibility = 1.0
				
				# If hider is in the center of Seeker's FOV, they are fully visible
				# otherwise, they will gradually fade out the further out to the edges
				# of the FOV they are. Outside the FOV cone, they are invisible.
				var rangeShifted = clamp(look_angle - CONE_WIDTH, 0.0, CONE_WIDTH)
				var rangeMapped = rangeShifted / (1.0 - CONE_WIDTH)
				var fov_visibility = rangeMapped
				
				# To be detected, the Hider must be inside the Seeker's flashlight FOV cone.
				#
				# Some extra game logic for distance, should have to be some what close to "detect"
				# the Hider for gameplay purposes
				if(fov_visibility > 0.0 and distance <= MAX_DETECT_DISTANCE):
					# Don't allow capture while in a car, or while in a win zone
					#if self.car == null and (not is_in_winzone(hider)):
					if not is_in_winzone(hider) and not hider.frozen:
						freeze_hider(hider)
				
				# FOV visibility can be faded out if at edge of distance visibility
				var percent_visible: float = fov_visibility * distance_visibility
				percent_visible = clamp(percent_visible, 0.0, 1.0)
				
				# The hider's set visibility method will handle the visible effects of this
				hider.update_visibility(percent_visible)


func is_in_winzone(hider) -> bool:
	for zone in win_zones:
		if zone.overlaps_body(hider):
			return true
	return false


func freeze_hider(hider):
	print("Freeze hider!")
	
	# Only the server is actually making this decision
	if get_tree().is_network_server():
		hider.freeze()


func on_state_playing():
	print("Seeker: on_state_playing()")
	if get_tree().is_network_server():
		unfreeze()
