extends GdUnitTestSuite

# Godot 3 spelled these initial_velocity / linear_accel / damping with a
# separate _random ratio. Godot 4 uses _min/_max pairs, so the Godot 3 names
# are ignored on load and every motion parameter silently falls back to zero,
# leaving the fireflies frozen in place instead of drifting through the air.
const FIREFLIES := "res://common/game/mode/fugitive/ambience/FireflyParticles.tscn"


func _particles() -> CPUParticles3D:
	var p: CPUParticles3D = load(FIREFLIES).instantiate()
	auto_free(p)
	return p


func test_fireflies_drift_rather_than_hanging_motionless() -> void:
	assert_float(_particles().initial_velocity_max).is_greater(0.0)


func test_fireflies_keep_drifting_after_they_spawn() -> void:
	var p := _particles()
	var wanders: bool = p.linear_accel_max > 0.0 or p.radial_accel_max > 0.0 or p.tangential_accel_max > 0.0
	assert_bool(wanders).override_failure_message(
		"No acceleration, so fireflies travel in dead straight lines").is_true()


func test_fireflies_spread_over_an_area_instead_of_clumping() -> void:
	# Godot 4 inserted SPHERE_SURFACE at index 2, pushing BOX from 2 to 3, so a
	# Godot 3 box emitter silently becomes a one metre sphere and every firefly
	# bunches up around the node.
	var p := _particles()
	assert_int(p.emission_shape).override_failure_message(
		"Emitting from %d, so the box extents %s are ignored" % [p.emission_shape, str(p.emission_box_extents)]
	).is_equal(CPUParticles3D.EMISSION_SHAPE_BOX)
	assert_float(p.emission_box_extents.x).is_greater(5.0)


func test_fireflies_hang_in_the_world_while_the_emitter_follows_the_player() -> void:
	# The effect reparents itself onto the player, so world space is what keeps
	# individual fireflies pinned in place instead of dragging along behind.
	assert_bool(_particles().local_coords).is_false()
