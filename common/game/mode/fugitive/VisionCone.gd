class_name VisionCone

# Points tested from a hider's feet up to their head
const BODY_SAMPLES := 5


# How brightly a cone falls on a point, ignoring anything in the way: full at
# the centre of the cone, fading to nothing at its edge
static func falloff(look_vec: Vector3, cone_width: float) -> float:
	# Calculate the angle of this ray from the cetner of the cone
	var look_angle := Vector3(0.0, 0.0, -1.0).dot(look_vec.normalized())

	var range_shifted := clampf(look_angle - cone_width, 0.0, cone_width)
	return range_shifted / (1.0 - cone_width)


# Whether the caster has a clear line to this point on the hider
static func reaches(hider, ray_caster: RayCast3D, look_vec: Vector3) -> bool:
	ray_caster.target_position = look_vec
	ray_caster.force_raycast_update()

	# Only if ray is colliding. If it's not, and we try to do logic,
	# wierd stuff happens
	if not ray_caster.is_colliding():
		return false

	# If the ray hits a wall or something else first, this point is occluded
	return ray_caster.get_collider() == hider.playerBody


# The brightest the cone falls anywhere on a hider, or 0.0 when every part of
# them is outside it or behind something.
#
# A light mounted at waist height aimed at a single point on the head swings
# outside its own cone whenever the hider is close, which inverts the near
# field: the nearer they stand, the dimmer they read. Rank points up the hider
# by how near the cone centre they fall, then take the brightest one with a
# clear line to it. A ray can only confirm a point or occlude it, so the first
# hit is the best view available and the rest need no cast.
static func brightest_view_of(hider, ray_caster: RayCast3D, cone_width: float) -> float:
	var feet: Vector3 = hider.playerController.global_transform.origin
	var head: Vector3 = hider.get_current_shape().head.global_transform.origin

	var ranked := []
	for sample in BODY_SAMPLES:
		var point: Vector3 = feet.lerp(head, float(sample) / float(BODY_SAMPLES - 1))
		var look_vec: Vector3 = ray_caster.to_local(point)
		ranked.append([falloff(look_vec, cone_width), look_vec])
	ranked.sort_custom(func(a, b): return a[0] > b[0])

	for entry in ranked:
		# Brightest first, so nothing further down the hider can beat this
		if entry[0] <= 0.0:
			return 0.0

		if reaches(hider, ray_caster, entry[1]):
			return entry[0]

	return 0.0
