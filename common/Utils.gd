extends Object
class_name Utils

const COMMON_NETWORK_UPDATE_THRESHOLD := 33

# The MultiplayerAPI default peer is an always-connected OfflineMultiplayerPeer,
# so has_multiplayer_peer() alone cannot tell "in a network session" apart from idle
static func has_active_network_peer(mp: MultiplayerAPI) -> bool:
	return mp.has_multiplayer_peer() and not (mp.multiplayer_peer is OfflineMultiplayerPeer)


static func set_window_to_screen_size():
	DisplayServer.window_set_size(DisplayServer.screen_get_size())


static func get_map_rotation(globalTransform: Transform3D) -> float:
	return (globalTransform.basis.get_euler().y + deg_to_rad(180)) * -1.0


static func renderer_is_gles2() -> bool:
	return ProjectSettings.get_setting("rendering/quality/driver/driver_name") == "GLES2"


static func is_quest2() -> bool:
	return vr.is_oculus_quest_2_device()


static func is_quest1() -> bool:
	return vr.is_oculus_quest_1_device()


static func aabb_from_shape(colShape: CollisionShape3D) -> AABB:
	var boxShape := colShape.shape as BoxShape3D
	var pos := colShape.global_transform.origin
	var extents := boxShape.size * 0.5
	
	var newBB := AABB()
	newBB.position = pos - extents
	newBB.size = extents * 2.0
	
	return newBB


static func rand_unit_vec3(ignore_axis := Vector3()) -> Vector3:
	var vec := Vector3(randf_range(-1.0, 1.0) * ignore_axis.x,
						randf_range(-1.0, 1.0) * ignore_axis.y,
						randf_range(-1.0, 1.0) * ignore_axis.z)
	# Don't allow a zero length vec
	if vec.length() == 0.0:
		vec.x += 0.001 * ignore_axis.x
		vec.y += 0.001 * ignore_axis.y
		vec.z += 0.001 * ignore_axis.z
	
	vec = vec.normalized()
	return vec

# This disables baked lights so they don't cast expensive dynamic shadows
static func turn_off_baked_lights(node: Node):
	var lights := node.get_tree().get_nodes_in_group("baked_lights")
	for light in lights:
		light.visible = false
