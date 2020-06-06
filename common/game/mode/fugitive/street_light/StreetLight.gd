extends Spatial
class_name StreetLight

export (int) var illumination_range := 7.0

onready var rayCaster := $OmniLight/RayCast


func process_hider(hider: Hider):
	# Cast a ray between the seeker and this hider
	var hiderGlobalPos := hider.playerBody.global_transform.origin
	var lookVec = to_local(hiderGlobalPos)
	var distance = lookVec.length()
	
	# Quick reject, ray casting is slightly expensive, don't do it if we don't have to
	if distance <= illumination_range:
		
		rayCaster.cast_to = rayCaster.to_local(hiderGlobalPos)
		rayCaster.force_raycast_update()
	
		if(rayCaster.is_colliding()):
			var bodySeen = rayCaster.get_collider()
			
			# If the ray hits a wall or something else first, then this Hider is fully occluded
			if(bodySeen == hider.playerBody):
				var percent_visible = 1.0 - (distance / illumination_range)
				percent_visible = clamp(percent_visible, 0.0, 1.0)
				hider.update_visibility(percent_visible)
