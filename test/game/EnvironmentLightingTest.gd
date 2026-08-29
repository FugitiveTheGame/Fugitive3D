extends GdUnitTestSuite

# The maps configure a dim blue ambient so unlit surfaces read as night rather
# than as pure black. Godot 4 only applies ambient_light_color when the sky is
# not supplying all of the ambient, so with sky_contribution left at its Godot 4
# default of 1.0 the colour below is loaded, ignored, and the ground goes black.
const ENVIRONMENT := "res://common/game/maps/default_environment.tres"


func test_configured_ambient_colour_actually_reaches_the_scene() -> void:
	var env: Environment = load(ENVIRONMENT)
	assert_object(env).override_failure_message(
		"Could not load %s" % ENVIRONMENT).is_not_null()

	var colour_is_used: bool = (
		env.ambient_light_source == Environment.AMBIENT_SOURCE_COLOR
		or env.ambient_light_sky_contribution < 1.0)

	assert_bool(colour_is_used).override_failure_message(
		"ambient_light_color %s is configured but contributes nothing: source=%d, sky_contribution=%s"
		% [str(env.ambient_light_color), env.ambient_light_source,
			str(env.ambient_light_sky_contribution)]).is_true()


func test_ambient_is_not_switched_off_outright() -> void:
	var env: Environment = load(ENVIRONMENT)
	assert_int(env.ambient_light_source).is_not_equal(Environment.AMBIENT_SOURCE_DISABLED)
	assert_float(env.ambient_light_energy).is_greater(0.0)
