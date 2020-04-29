extends Spatial
class_name MotionSensor

const CONE_WIDTH = cos(deg2rad(25.0))
const CONE_OFFSET = cos(deg2rad(90.0))
onready var max_vision_distance := $OmniLight.omni_range as float
const MIN_VISION_DISTANCE := 3.0


onready var rayCaster := $RayCast


export(bool) var always_on := false
var is_turned_on := true setget set_enabled


func _ready():
	add_to_group(Groups.MOTION_SENSORS)
	
	# Start off
	if not always_on:
		set_enabled(true)
		$OmniLight.hide()
	else:
		$MotionSensorArea.monitoring = false


func set_enabled(isOn: bool):
	#print('Sensor Enabled: ' + str(isOn))
	is_turned_on = isOn
	# Only add us to LIGHTS if we are actually enabled
	# This prevents unnecessary processing each tick
	if is_turned_on:
		add_to_group(Groups.LIGHTS)
	elif get_groups().has(Groups.LIGHTS):
		remove_from_group(Groups.LIGHTS)


func _on_MotionSensorArea_body_entered(body):
	if is_turned_on and not $OmniLight.visible:
		if get_tree().is_network_server():
			trigger_light()
			rpc('trigger_light')


remote func trigger_light():
	$OmniLight.show()
	$LightTriggerAudio.play()
	$AutoOffTimer.start()


func process_hider(hider: Hider):
	# Only process if this sensor is on, and the light is currently on
	if not self.is_turned_on or not $OmniLight.visible:
		return
	
	# Cast a ray between the seeker and this hider
	var curHiderShape = hider.get_current_shape().head
	var look_vec := to_local(curHiderShape.global_transform.origin)
	var distance = look_vec.length()
	
	# Quick reject, ray casting is slightly expensive, don't do it if we don't have to
	if distance <= max_vision_distance:
		rayCaster.cast_to = look_vec
		rayCaster.force_raycast_update()
		
		if(rayCaster.is_colliding()):
			
			var bodySeen = rayCaster.get_collider()
			# If the ray hits a wall or something else first, then this Hider is fully occluded
			if(bodySeen == hider.playerBody):
				# At a given distance, fade the hider out
				var distance_visibility: float
				
				# Hider is too far away, make invisible regardless of FOV visibility
				if distance > max_vision_distance:
					distance_visibility = 0.0
				# Hider is at the edge of distance visibility, calculate how close to the edge they are
				else:
					distance_visibility = 1.0 - (distance / max_vision_distance)
				
				# FOV visibility can be faded out if at edge of distance visibility
				var percent_visible = distance_visibility
				
				percent_visible = clamp(percent_visible, 0.0, 1.0)
				hider.update_visibility(percent_visible)


func _on_AutoOffTimer_timeout():
	$OmniLight.hide()
