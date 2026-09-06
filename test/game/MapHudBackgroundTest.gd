extends GdUnitTestSuite

# Image.create() and ImageTexture.create_from_image() are static in Godot 4.
# Called on an instance they build a new object and throw it away, leaving the
# original Image empty, so the map view asked for a texture from an empty image
# and logged "Invalid image: image is empty" instead of drawing a background.
const MAP_HUD := "res://client/game/mode/fugitive/hud/mapview/MapHudBase.tscn"


class FakeMap:
	extends Node
	var roads: Array = []
	var mapBoundingBox := AABB(Vector3.ZERO, Vector3(100.0, 10.0, 100.0))

	func get_win_zones() -> Array:
		return []


var _previous_map
var _fake: FakeMap


func before_test() -> void:
	_previous_map = GameData.currentMap
	_fake = FakeMap.new()
	GameData.currentMap = _fake


func after_test() -> void:
	GameData.currentMap = _previous_map
	if is_instance_valid(_fake):
		_fake.free()


func test_map_background_gets_a_real_texture() -> void:
	var hud: Control = load(MAP_HUD).instantiate()
	add_child(hud)
	auto_free(hud)

	hud.update_map_background()
	var texture: Texture2D = hud.mapBackground.texture

	# Out of the tree before the queued redraw runs, so the fake map is not
	# asked to draw roads it does not have.
	remove_child(hud)

	assert_object(texture).override_failure_message(
		"the map background produced no texture at all").is_not_null()
	assert_int(texture.get_width()).is_greater(0)
	assert_int(texture.get_height()).is_greater(0)
