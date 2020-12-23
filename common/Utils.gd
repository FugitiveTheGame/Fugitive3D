extends Object
class_name Utils

const COMMON_NETWORK_UPDATE_THRESHOLD := 33

static func set_window_to_screen_size():
	OS.set_window_size(OS.get_screen_size())


static func get_map_rotation(globalTransform: Transform) -> float:
	return (globalTransform.basis.get_euler().y + deg2rad(180)) * -1.0


static func renderer_is_gles2() -> bool:
	return ProjectSettings.get_setting("rendering/quality/driver/driver_name") == "GLES2"


static func is_quest2() -> bool:
	if vr.ovrSystem != null:
		return vr.ovrSystem.is_oculus_quest_2_device()
	return false


static func is_quest1() -> bool:
	if vr.ovrSystem != null:
		return vr.ovrSystem.is_oculus_quest_1_device()
	return false


static func aabb_from_shape(colShape: CollisionShape) -> AABB:
	var boxShape := colShape.shape as BoxShape
	var pos := colShape.global_transform.origin
	var extents := boxShape.extents
	
	var newBB := AABB()
	newBB.position = pos - extents
	newBB.size = extents * 2.0
	
	return newBB


static func rand_unit_vec3(ignore_axis := Vector3()) -> Vector3:
	var vec := Vector3(rand_range(-1.0, 1.0) * ignore_axis.x,
						rand_range(-1.0, 1.0) * ignore_axis.y,
						rand_range(-1.0, 1.0) * ignore_axis.z)
	# Don't allow a zero length vec
	if vec.length() == 0.0:
		vec.x += 0.001 * ignore_axis.x
		vec.y += 0.001 * ignore_axis.y
		vec.z += 0.001 * ignore_axis.z
	
	vec = vec.normalized()
	return vec
