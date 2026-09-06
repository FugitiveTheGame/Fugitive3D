extends GdUnitTestSuite

# The bot walkability grid is built from a real map: ground tiles decide what
# a cell is, a physics probe decides whether a body fits, and costs push paths
# off the road and out of the light.

const LITTLETON := "res://common/game/maps/littleton/Littleton.scn"

var map: Node3D
var grid: FugitiveNavGrid


func before() -> void:
	map = (load(LITTLETON) as PackedScene).instantiate()
	add_child(map)
	# The physics server needs a step to register the map's colliders
	await get_tree().physics_frame
	await get_tree().physics_frame
	grid = FugitiveNavGrid.build(map, map.get_world_3d().direct_space_state)


func after() -> void:
	map.queue_free()


func _ground() -> GridMap:
	for node in map.find_children("*", "GridMap", true, false):
		if is_equal_approx(node.cell_size.x, FugitiveNavGrid.GROUND_TILE_SIZE):
			return node
	return null


func _tile_center_named(prefix: String) -> Vector3:
	var ground := _ground()
	for tile in ground.get_used_cells():
		var item_name: String = ground.mesh_library.get_item_name(ground.get_cell_item(tile)).strip_edges()
		if item_name.begins_with(prefix):
			return ground.global_transform * ground.map_to_local(tile)
	return Vector3(NAN, NAN, NAN)


func _win_zone_center() -> Vector3:
	return map.get_win_zones()[0].global_transform.origin


func test_every_spawn_point_is_walkable() -> void:
	for spawn in map.get_hider_spawns() + map.get_seeker_spawns():
		var cell := grid.world_to_cell(spawn.global_transform.origin)
		assert_bool(grid.is_walkable(cell)).override_failure_message(
			"Spawn %s at %s is not walkable" % [spawn.name, spawn.global_transform.origin]).is_true()


func test_the_win_zone_is_walkable() -> void:
	assert_bool(grid.is_walkable(grid.world_to_cell(_win_zone_center()))).is_true()


func test_houses_are_solid() -> void:
	var center := _tile_center_named("house")
	assert_bool(is_nan(center.x)).is_false()
	assert_bool(grid.is_walkable(grid.world_to_cell(center))).is_false()


func test_roads_cost_more_than_yards() -> void:
	var road := grid.world_to_cell(_tile_center_named("road_straight"))
	var yard := grid.world_to_cell(_tile_center_named("yard_grass_only"))
	assert_bool(grid.is_walkable(road)).is_true()
	assert_bool(grid.is_walkable(yard)).is_true()
	assert_float(grid.cost(road)).is_greater(grid.cost(yard))


func test_street_lights_make_cells_expensive() -> void:
	var lights := get_tree().get_nodes_in_group(Groups.LIGHTS)
	assert_array(lights).is_not_empty()

	var light: Node3D = lights[0]
	var beside_light := light.global_transform.origin + Vector3(1.5, 0.0, 0.0)
	var cell := grid.nearest_walkable(grid.world_to_cell(beside_light))
	assert_bool(grid.is_lit(cell)).is_true()

	var yard := grid.world_to_cell(_tile_center_named("yard_grass_only"))
	assert_float(grid.cost(cell)).is_greater(grid.cost(yard))


func test_a_path_leads_from_spawn_to_the_win_zone() -> void:
	var start: Vector3 = map.get_hider_spawns()[0].global_transform.origin
	var path := grid.find_path(start, _win_zone_center())

	assert_int(path.size()).is_greater(10)

	# Waypoints are neighbouring cell centres, at most a diagonal apart
	var previous: Vector3 = path[0]
	for point in path:
		assert_bool(grid.is_walkable(grid.world_to_cell(point))).is_true()
		assert_float(Vector2(point.x, point.z).distance_to(Vector2(previous.x, previous.z))).is_less_equal(3.0)
		previous = point

	assert_float(path[path.size() - 1].distance_to(_win_zone_center())).is_less(3.0)


func test_blocking_a_cell_reroutes_the_next_path() -> void:
	var start: Vector3 = map.get_hider_spawns()[0].global_transform.origin
	var first := grid.find_path(start, _win_zone_center())
	var blocked := grid.world_to_cell(first[3])

	grid.block_cell(blocked)
	var second := grid.find_path(start, _win_zone_center())

	assert_bool(grid.is_walkable(blocked)).is_false()
	for point in second:
		assert_bool(grid.world_to_cell(point) == blocked).is_false()
