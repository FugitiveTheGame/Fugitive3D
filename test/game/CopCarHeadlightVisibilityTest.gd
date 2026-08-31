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
	for metres in [1.0, 2.0, 3.0]:
		var lit: float = await visibility_at(metres)
		assert_float(lit).override_failure_message(
			"Hider %.0fm in front of the headlights only read %f" % [metres, lit]
		).is_greater(0.6)


func test_a_hider_does_not_get_brighter_as_they_back_away() -> void:
	var close: float = await visibility_at(1.0)
	var distant: float = await visibility_at(12.0)
	assert_float(close).override_failure_message(
		"A hider 12m off read %f, brighter than one 1m away at %f" % [distant, close]
	).is_greater(distant)
