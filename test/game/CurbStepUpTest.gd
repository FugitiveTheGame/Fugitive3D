extends GdUnitTestSuite

# Godot 3's CapsuleShape was Z-aligned and its `height` measured only the
# cylinder section; Godot 4's CapsuleShape3D is Y-aligned and `height` is the
# total. The port inherited a capsule lying on its side, which put the camera
# under the road and presented a flat wall to every curb.
#
# With the capsule upright the curb is still a 0.1m step, and a sphere of
# radius r meeting a step of height h reports a contact normal
# acos((r - h) / r) off vertical -- 48.2 degrees here, just past Godot's
# default 45 degree floor_max_angle. Both player bodies raise that threshold.
const GROUND_LIBRARY := "res://common/game/tilesets/suburban_neighborhood/suburban_neighborhood_ground.meshlib.res"
const FLAT_CONTROLLER := "res://client/game/player/controller/flat/FlatPlayerController.tscn"
const VR_CONTROLLER := "res://client/game/player/controller/vr/VrPlayerController.tscn"

const ROAD_TILE := "road_straight"
const SIDEWALK_TILE := "yard_sidewalk_straight_edge"
const CURB_HEIGHT := 0.1
const PLAYER_RADIUS := 0.3

const GRAVITY := 96.04
const WALK_SPEED := 5.0


func _scene_property(scene_path: String, node_path: String, property: String) -> Variant:
	var state: SceneState = (load(scene_path) as PackedScene).get_state()
	for node in state.get_node_count():
		if str(state.get_node_path(node)) != node_path:
			continue
		for prop in state.get_node_property_count(node):
			if state.get_node_property_name(node, prop) == property:
				return state.get_node_property_value(node, prop)
	return null


func _build_curb() -> GridMap:
	var library: MeshLibrary = load(GROUND_LIBRARY)
	var road := -1
	var sidewalk := -1
	for item in library.get_item_list():
		match library.get_item_name(item).strip_edges():
			ROAD_TILE: road = item
			SIDEWALK_TILE: sidewalk = item
	assert_int(road).override_failure_message("no %s tile" % ROAD_TILE).is_greater_equal(0)
	assert_int(sidewalk).override_failure_message("no %s tile" % SIDEWALK_TILE).is_greater_equal(0)

	var grid := GridMap.new()
	grid.mesh_library = library
	grid.cell_size = Vector3(8, 2, 8)
	for x in range(-1, 2):
		grid.set_cell_item(Vector3i(x, 0, 1), road)
		grid.set_cell_item(Vector3i(x, 0, 0), road)
		grid.set_cell_item(Vector3i(x, 0, -1), sidewalk)
		grid.set_cell_item(Vector3i(x, 0, -2), sidewalk)
	add_child(grid)
	auto_free(grid)
	return grid


# Walks a capsule off the road and onto the sidewalk, returning how far it rose.
func _walk_onto_sidewalk(grid: GridMap, floor_max_angle: float, capsule_height: float, capsule_y: float) -> float:
	var body := CharacterBody3D.new()
	body.floor_max_angle = floor_max_angle
	var capsule := CapsuleShape3D.new()
	capsule.radius = PLAYER_RADIUS
	capsule.height = capsule_height
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position = Vector3(0, capsule_y, 0)
	body.add_child(shape)
	grid.get_parent().add_child(body)
	auto_free(body)
	body.global_position = Vector3(0, 1.6, 3.0)

	for frame in 25:
		body.velocity = Vector3(0, body.velocity.y - GRAVITY * 0.0166667, 0)
		body.up_direction = Vector3.UP
		body.move_and_slide()
		await get_tree().physics_frame
	var road_y := body.global_position.y

	for frame in 95:
		body.velocity = Vector3(0, body.velocity.y - GRAVITY * 0.0166667, -WALK_SPEED)
		body.up_direction = Vector3.UP
		body.move_and_slide()
		await get_tree().physics_frame

	return body.global_position.y - road_y


func test_the_curb_is_still_a_tenth_of_a_metre() -> void:
	var library: MeshLibrary = load(GROUND_LIBRARY)
	var tops := {}
	for item in library.get_item_list():
		var item_name := library.get_item_name(item).strip_edges()
		if item_name != ROAD_TILE and item_name != SIDEWALK_TILE:
			continue
		var highest := -INF
		var shapes := library.get_item_shapes(item)
		var i := 0
		while i < shapes.size():
			if shapes[i] is ConcavePolygonShape3D:
				for vertex in (shapes[i] as ConcavePolygonShape3D).get_faces():
					highest = max(highest, (shapes[i + 1] as Transform3D * vertex).y)
			i += 2
		tops[item_name] = highest

	assert_float(tops[SIDEWALK_TILE] - tops[ROAD_TILE]).override_failure_message(
		"road/sidewalk tile heights changed; the step-up thresholds need revisiting: %s" % str(tops)
	).is_equal_approx(CURB_HEIGHT, 0.01)


func test_flat_player_walks_up_a_curb() -> void:
	var angle = _scene_property(FLAT_CONTROLLER, ".", "floor_max_angle")
	assert_bool(angle != null).override_failure_message(
		"FlatPlayerController no longer sets floor_max_angle; the 45 degree default stops the player dead at every curb"
	).is_true()

	var rose := await _walk_onto_sidewalk(_build_curb(), angle as float, 2.0, 0.85203)
	assert_float(rose).override_failure_message(
		"the flat player failed to step up the %.2fm curb (rose %.3fm)" % [CURB_HEIGHT, rose]
	).is_greater(CURB_HEIGHT * 0.8)


func test_vr_player_walks_up_a_curb() -> void:
	var angle = _scene_property(VR_CONTROLLER, "./PlayerBody", "floor_max_angle")
	assert_bool(angle != null).override_failure_message(
		"VrPlayerController no longer sets floor_max_angle on PlayerBody"
	).is_true()

	# godot-xr-tools gates uphill movement a second time on its own ground physics
	var physics = _scene_property(VR_CONTROLLER, "./PlayerBody", "physics")
	assert_bool(physics != null).override_failure_message(
		"VrPlayerController no longer overrides the godot-xr-tools ground physics; move_max_slope falls back to 45 degrees"
	).is_true()
	assert_float(physics.move_max_slope).override_failure_message(
		"move_max_slope must clear the 48.2 degree contact normal a 0.1m curb produces"
	).is_greater(48.5)

	# XRToolsPlayerBody builds its capsule at player_radius, hung at y = 0.8
	var rose := await _walk_onto_sidewalk(_build_curb(), angle as float, 1.6, 0.8)
	assert_float(rose).override_failure_message(
		"the VR player failed to step up the %.2fm curb (rose %.3fm)" % [CURB_HEIGHT, rose]
	).is_greater(CURB_HEIGHT * 0.8)
