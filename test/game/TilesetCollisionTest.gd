extends GdUnitTestSuite

# Every ground tile must stop a player standing on it. Godot 4 trimesh shapes
# are one-sided by default, which silently removed collision from most yard
# and house tiles and dropped players through the map.
const GROUND_LIBRARY := "res://common/game/tilesets/suburban_neighborhood/suburban_neighborhood_ground.meshlib.res"
const GROUND_LAYER := 2


func test_every_ground_tile_is_solid_underfoot() -> void:
	var library: MeshLibrary = load(GROUND_LIBRARY)
	assert_object(library).is_not_null()

	var grid := GridMap.new()
	grid.mesh_library = library
	grid.cell_size = Vector3(8, 2, 8)
	grid.collision_layer = GROUND_LAYER
	add_child(grid)
	auto_free(grid)

	# Space the tiles out so neighbours cannot cover for a broken one
	var items := library.get_item_list()
	for i in items.size():
		grid.set_cell_item(Vector3i(i * 4, 0, 0), items[i])

	await await_millis(100)

	var space := grid.get_world_3d().direct_space_state
	var not_solid := []
	for i in items.size():
		var at: Vector3 = grid.global_transform * grid.map_to_local(Vector3i(i * 4, 0, 0))
		var query := PhysicsRayQueryParameters3D.create(
			at + Vector3(0, 5, 0), at - Vector3(0, 5, 0), GROUND_LAYER)
		if space.intersect_ray(query).is_empty():
			not_solid.append(library.get_item_name(items[i]))

	assert_array(not_solid).override_failure_message(
		"Tiles with no collision underfoot: %s" % str(not_solid)).is_empty()
