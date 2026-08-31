extends GdUnitTestSuite

# The seeker's flashlight reveals hiders by casting a ray at the hider's head
# and fading them in by how close that ray sits to the centre of the beam.
# Godot 4 capsules stand on Y and measure their full length, where Godot 3
# capsules stood on Z and measured only the middle section, so the ported
# player shapes ended up lying down and too short for the ray to ever reach
# the head.
const HIDER_SCENE := "res://common/game/mode/fugitive/hider/RemoteHider.tscn"
const SEEKER_SCENE := "res://common/game/mode/fugitive/seeker/RemoteSeeker.tscn"

var hider: CharacterBody3D
var seeker: CharacterBody3D


# One pair for the whole suite: a second pair spawned on top of the first
# would be shoved apart by character body depenetration
func before() -> void:
	hider = auto_free((load(HIDER_SCENE) as PackedScene).instantiate())
	seeker = auto_free((load(SEEKER_SCENE) as PackedScene).instantiate())
	add_child(seeker)
	add_child(hider)
	await await_millis(50)


func head_of(player: CharacterBody3D) -> Node3D:
	return player.get_node("Player").get_current_shape().head


func capsule_span(player: CharacterBody3D) -> Array:
	var shape_node := player.get_node("CollisionShape3D") as CollisionShape3D
	var capsule := shape_node.shape as CapsuleShape3D
	var axis := shape_node.global_transform.basis.y.normalized()
	var reach := axis * (capsule.height * 0.5 + capsule.radius)
	return [shape_node.global_transform.origin - reach, shape_node.global_transform.origin + reach]


# Move both players and let the physics server catch up before casting
func place(distance: float, flashlight_yaw_degrees: float, flashlight_pitch_degrees: float = 0.0) -> void:
	seeker.global_transform = Transform3D(Basis.IDENTITY, Vector3.ZERO)
	hider.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 0, -distance))
	var flashlight := seeker.get_node("Flashlight") as Node3D
	flashlight.rotation = Vector3(deg_to_rad(flashlight_pitch_degrees), deg_to_rad(flashlight_yaw_degrees), 0)
	await await_millis(50)


func visibility_of_hider() -> float:
	var hider_player := hider.get_node("Player")
	hider_player.current_visibility = 0.0
	seeker.get_node("Player").process_hider(hider_player)
	return hider_player.current_visibility


func test_player_capsules_stand_upright() -> void:
	for player in [hider, seeker]:
		var shape_node := player.get_node("CollisionShape3D") as CollisionShape3D
		assert_vector(shape_node.global_transform.basis.y.normalized()) \
			.override_failure_message("%s capsule is not standing on end" % player.name) \
			.is_equal_approx(Vector3.UP, Vector3.ONE * 0.001)


func test_capsules_reach_the_head_the_flashlight_aims_at() -> void:
	for player in [hider, seeker]:
		var span := capsule_span(player)
		var head_y: float = head_of(player).global_transform.origin.y
		assert_float(head_y) \
			.override_failure_message("%s head at %f sits outside its capsule %s" % [player.name, head_y, str(span)]) \
			.is_between(span[0].y, span[1].y)


func test_flashlight_ray_reaches_a_hider_it_points_at() -> void:
	for distance in [5.0, 10.0, 20.0, 40.0]:
		await place(distance, 0.0)
		assert_float(visibility_of_hider()) \
			.override_failure_message("Hider %fm dead ahead was not lit at all" % distance) \
			.is_greater(0.0)


func test_visibility_fades_from_the_centre_of_the_beam_to_its_edge() -> void:
	await place(10.0, 0.0)
	var centred := visibility_of_hider()

	await place(10.0, 20.0)
	var off_centre := visibility_of_hider()

	await place(10.0, 45.0)
	var outside_cone := visibility_of_hider()

	assert_float(centred).is_greater(off_centre)
	assert_float(off_centre).is_greater(0.0)
	assert_float(outside_cone).is_equal(0.0)


func test_visibility_fades_with_distance() -> void:
	await place(10.0, 0.0)
	var near := visibility_of_hider()

	await place(40.0, 0.0)
	var far := visibility_of_hider()

	assert_float(near).is_greater(far)
	assert_float(far).is_greater(0.0)

# The flashlight rides at the seeker's waist and a hider's head is most of a
# metre higher, so aiming at the head alone drops anyone the seeker looks down at
func test_a_hider_close_ahead_stays_lit_when_the_seeker_looks_down() -> void:
	for pitch in [0.0, -20.0, -30.0]:
		await place(3.0, 0.0, pitch)
		assert_float(visibility_of_hider()) \
			.override_failure_message("Hider 3m dead ahead faded out at %f degrees of look-down" % pitch) \
			.is_greater(0.5)


# Looking down must still lose a hider eventually, or the beam reveals everyone
func test_visibility_fades_as_the_beam_tips_off_a_distant_hider() -> void:
	await place(8.0, 0.0, 0.0)
	var level := visibility_of_hider()

	await place(8.0, 0.0, -40.0)
	var steeply_down := visibility_of_hider()

	assert_float(level).is_greater(steeply_down)
	assert_float(steeply_down).is_less(0.25)
