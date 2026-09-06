extends GdUnitTestSuite

# The headlight raycast sits at car-local y 0.898 while a hider's head is at
# 1.55, so aiming one ray at the head leaves it 0.65m above the beam axis at
# every range. That inverted the near field: a hider a metre in front of the
# headlights read 0.09 while one five metres out read 0.80.
const CAR_SCENE := "res://common/game/mode/fugitive/cop_car/CopCar.tscn"
const HIDER_SCENE := "res://common/game/mode/fugitive/hider/RemoteHider.tscn"

var car: CharacterBody3D
var hider: CharacterBody3D
var ray: RayCast3D


# One pair for the whole suite, so character body depenetration cannot shove a
# freshly spawned car and hider apart underneath the ray
func before() -> void:
	car = auto_free((load(CAR_SCENE) as PackedScene).instantiate())
	hider = auto_free((load(HIDER_SCENE) as PackedScene).instantiate())
	add_child(car)
	add_child(hider)
	car.global_transform = Transform3D(Basis.IDENTITY, Vector3.ZERO)
	ray = car.get_node("RayCast3D")
	await await_millis(50)


func visibility_at(metres_ahead: float) -> float:
	hider.global_transform = Transform3D(
		Basis.IDENTITY, Vector3(0, 0, ray.global_transform.origin.z - metres_ahead))
	await await_millis(50)

	var hider_player = hider.get_node("Player")
	hider_player.current_visibility = 0.0
	car.process_hider(hider_player)
	return hider_player.current_visibility


func test_a_hider_in_front_of_the_headlights_is_lit() -> void:
	for metres in [0.5, 1.0, 2.0, 3.0]:
		var lit: float = await visibility_at(metres)
		assert_float(lit).override_failure_message(
			"Hider %.2fm in front of the headlights only read %f" % [metres, lit]
		).is_greater(0.6)


# Not a monotonic falloff. Brightness peaks around 1.75m and eases off either
# side, because BODY_SAMPLES puts the nearest sample 0.123m under the beam axis
# and that offset costs more angle the closer the hider stands. The dip is about
# 0.015 between the peak and 1m. Closer than the hider's 0.3m capsule radius the
# ray caster is inside them and Godot reports no hit at all, which is why this
# only claims near beats far.
func test_a_hider_at_the_headlights_reads_brighter_than_a_distant_one() -> void:
	var close: float = await visibility_at(1.0)
	var distant: float = await visibility_at(12.0)
	assert_float(close).override_failure_message(
		"A hider 12m off read %f, brighter than one 1m away at %f" % [distant, close]
	).is_greater(distant)
