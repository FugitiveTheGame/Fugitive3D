class_name FugitiveNavGrid
extends RefCounted

# A 2m walkability grid over a FugitiveMap, built once per game on the
# server. Ground tiles say what a cell is (road, yard, building) and a physics
# probe says whether a player-sized body fits there, which catches trees,
# bushes, rocks and house walls that spill past their own tile. Costs steer
# paths off the open road, out of street light, and along whatever blocks a
# line of sight.

const CELL_SIZE := 2.0
const GROUND_TILE_SIZE := 8.0

# Walls and see-through walls: the static geometry a player body collides
# with. Other players and cars come and go.
const PROBE_MASK := 2 | 4
# A standing player body, checked at the cell centre where a path crosses
const PROBE_BOTTOM := 0.45
const PROBE_TOP := 1.5
const PROBE_HALF_WIDTH := 0.35
# Trimesh shapes only report their surface, so a probe fully inside a house
# or a pool sees nothing. Anything tall enough to catch a ray dropped on the
# cell centre from above is not ground.
const CEILING_RAY_TOP := 12.0
const CEILING_RAY_BOTTOM := -1.0
const MAX_GROUND_HEIGHT := 0.35

const COST_YARD := 1.0
const COST_ROAD := 3.0
const COST_LIT := 3.0
const COVER_DISCOUNT := 0.7

const INVALID_CELL := Vector2i(1 << 30, 1 << 30)

var astar := AStarGrid2D.new()
var region := Rect2i()

# Cells a body cannot occupy because something solid sits there, as opposed
# to cells that simply have no ground
var _obstacle := {}
var _cover := {}
var _cost := {}
var _lit := {}
var _temporary_blocks := {}

const BLOCK_DURATION_MSEC := 15_000
# Cells, so 2 keeps a path at least 4m from a cop's cell centre, beyond the
# 3m arrest radius
const DANGER_RADIUS := 2


static func build(map: Node3D, space: PhysicsDirectSpaceState3D) -> FugitiveNavGrid:
	var grid := FugitiveNavGrid.new()
	grid._build(map, space)
	return grid


func world_to_cell(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x / CELL_SIZE), floori(pos.z / CELL_SIZE))


func cell_to_world(cell: Vector2i, y := 0.0) -> Vector3:
	return Vector3((cell.x + 0.5) * CELL_SIZE, y, (cell.y + 0.5) * CELL_SIZE)


func is_walkable(cell: Vector2i) -> bool:
	return region.has_point(cell) and not astar.is_point_solid(cell)


func is_cover(cell: Vector2i) -> bool:
	return _cover.get(cell, false)


func is_lit(cell: Vector2i) -> bool:
	return _lit.get(cell, false)


func cost(cell: Vector2i) -> float:
	return _cost.get(cell, INF)


func nearest_walkable(cell: Vector2i, max_radius := 4) -> Vector2i:
	if is_walkable(cell):
		return cell
	for radius in range(1, max_radius + 1):
		var best := INVALID_CELL
		var best_distance := INF
		for dx in range(-radius, radius + 1):
			for dz in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dz)) != radius:
					continue
				var candidate := cell + Vector2i(dx, dz)
				var distance := Vector2(dx, dz).length_squared()
				if is_walkable(candidate) and distance < best_distance:
					best = candidate
					best_distance = distance
		if best != INVALID_CELL:
			return best
	return INVALID_CELL


# Walkable cells whose centre lies within radius of a world position
func walkable_cells_within(center: Vector3, radius: float) -> Array:
	var cells := []
	var cells_radius := ceili(radius / CELL_SIZE)
	var origin := world_to_cell(center)
	for dx in range(-cells_radius, cells_radius + 1):
		for dz in range(-cells_radius, cells_radius + 1):
			var cell := origin + Vector2i(dx, dz)
			if is_walkable(cell) and cell_to_world(cell).distance_to(Vector3(center.x, 0.0, center.z)) <= radius:
				cells.push_back(cell)
	return cells


# World waypoints from one position to another, snapping both ends to the
# nearest walkable cell. For this query only, the cells under the positions
# in avoid (other players) are routed around, and so is a ring of
# DANGER_RADIUS cells around each position in danger (cops, whose reach is
# wider than they are). Keeping clear can seal the only corridor, so the
# ring shrinks a cell at a time, then the other players are ignored too,
# until a route exists. Empty when there is none at all.
func find_path(from: Vector3, to: Vector3, avoid: Array = [], danger: Array = []) -> PackedVector3Array:
	_expire_blocks()
	var start := nearest_walkable(world_to_cell(from))
	var goal := nearest_walkable(world_to_cell(to))
	if start == INVALID_CELL or goal == INVALID_CELL:
		return PackedVector3Array()

	var radius := DANGER_RADIUS
	var cells := _path_cells(start, goal, avoid, danger, radius)
	while cells.is_empty() and not danger.is_empty() and radius > 0:
		radius -= 1
		cells = _path_cells(start, goal, avoid, danger, radius)
	if cells.is_empty() and not avoid.is_empty():
		cells = _path_cells(start, goal, [], [], 0)
	return _cells_to_path(cells, start, from)


func _path_cells(start: Vector2i, goal: Vector2i, avoid: Array, danger: Array, danger_radius: int) -> Array:
	var closed := {}
	for position in avoid:
		closed[world_to_cell(position)] = true
	for position in danger:
		var center := world_to_cell(position)
		for dx in range(-danger_radius, danger_radius + 1):
			for dz in range(-danger_radius, danger_radius + 1):
				closed[center + Vector2i(dx, dz)] = true

	var reopened := []
	for cell in closed:
		if cell != start and cell != goal and is_walkable(cell):
			astar.set_point_solid(cell, true)
			reopened.push_back(cell)

	var cells := astar.get_id_path(start, goal)

	for cell in reopened:
		astar.set_point_solid(cell, false)
	return cells


func _cells_to_path(cells: Array, start: Vector2i, from: Vector3) -> PackedVector3Array:
	var path := PackedVector3Array()
	for ii in range(1, cells.size()):
		path.push_back(cell_to_world(cells[ii]))
	# A goal one cell away yields only the start, which still means "go there"
	if path.is_empty() and cells.size() == 1 and start != world_to_cell(from):
		path.push_back(cell_to_world(start))
	return path


# A body stuck against something the probe missed marks the cell so the next
# few paths go around it. The block lapses, because what it ran into is as
# likely another player as a piece of the map.
func block_cell(cell: Vector2i):
	if is_walkable(cell):
		astar.set_point_solid(cell, true)
		_temporary_blocks[cell] = Time.get_ticks_msec() + BLOCK_DURATION_MSEC


func _expire_blocks():
	var now := Time.get_ticks_msec()
	for cell in _temporary_blocks.keys():
		if now >= _temporary_blocks[cell]:
			astar.set_point_solid(cell, false)
			_temporary_blocks.erase(cell)


func _build(map: Node3D, space: PhysicsDirectSpaceState3D):
	var ground := _find_ground_gridmap(map)
	assert(ground != null, "FugitiveNavGrid needs a ground GridMap")

	var used := ground.get_used_cells()
	assert(not used.is_empty(), "Ground GridMap has no cells")

	var cells_per_tile := int(GROUND_TILE_SIZE / CELL_SIZE)
	var lo := Vector2i(1 << 30, 1 << 30)
	var hi := Vector2i(-(1 << 30), -(1 << 30))
	for tile in used:
		lo = Vector2i(mini(lo.x, tile.x), mini(lo.y, tile.z))
		hi = Vector2i(maxi(hi.x, tile.x), maxi(hi.y, tile.z))

	region = Rect2i(lo * cells_per_tile, (hi - lo + Vector2i.ONE) * cells_per_tile)
	astar.region = region
	astar.cell_size = Vector2(CELL_SIZE, CELL_SIZE)
	astar.offset = Vector2(CELL_SIZE, CELL_SIZE) * 0.5
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()
	astar.fill_solid_region(region, true)

	var library := ground.mesh_library
	for tile in used:
		var item_name := library.get_item_name(ground.get_cell_item(tile)).strip_edges()
		if _tile_is_building(item_name):
			continue
		var base_cost := COST_ROAD if item_name.begins_with("road") else COST_YARD
		for dx in cells_per_tile:
			for dz in cells_per_tile:
				var cell := Vector2i(tile.x * cells_per_tile + dx, tile.z * cells_per_tile + dz)
				astar.set_point_solid(cell, false)
				_cost[cell] = base_cost

	_probe_obstacles(space)
	_mark_cover()
	_mark_lights(map)

	for cell in _cost:
		astar.set_point_weight_scale(cell, _cost[cell])


func _find_ground_gridmap(map: Node3D) -> GridMap:
	var found: GridMap = null
	for node in map.find_children("*", "GridMap", true, false):
		var grid := node as GridMap
		if is_equal_approx(grid.cell_size.x, GROUND_TILE_SIZE):
			found = grid
			break
	return found


# Wall tiles are yards with a low wall along one edge, so the probe handles
# them cell by cell
static func _tile_is_building(item_name: String) -> bool:
	return item_name.begins_with("house") or item_name.begins_with("apartment")


func _probe_obstacles(space: PhysicsDirectSpaceState3D):
	var shape := BoxShape3D.new()
	shape.size = Vector3(PROBE_HALF_WIDTH * 2.0, PROBE_TOP - PROBE_BOTTOM, PROBE_HALF_WIDTH * 2.0)

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = PROBE_MASK
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var probe_y := (PROBE_TOP + PROBE_BOTTOM) * 0.5
	for cell in _cost.keys():
		var center := cell_to_world(cell)
		query.transform = Transform3D(Basis.IDENTITY, center + Vector3(0.0, probe_y, 0.0))
		if not space.intersect_shape(query, 1).is_empty() or _something_tall_at(space, center):
			astar.set_point_solid(cell, true)
			_obstacle[cell] = true
			_cost.erase(cell)


func _something_tall_at(space: PhysicsDirectSpaceState3D, center: Vector3) -> bool:
	var from := center + Vector3(0.0, CEILING_RAY_TOP, 0.0)
	var to := center + Vector3(0.0, CEILING_RAY_BOTTOM, 0.0)
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, PROBE_MASK))
	return not hit.is_empty() and hit.position.y > MAX_GROUND_HEIGHT


# A walkable cell touching something solid has a side to hide behind
func _mark_cover():
	for cell in _cost.keys():
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if _obstacle.has(cell + offset):
				_cover[cell] = true
				_cost[cell] *= COVER_DISCOUNT
				break


func _mark_lights(map: Node3D):
	var tree := map.get_tree()
	if tree == null:
		return
	for light in tree.get_nodes_in_group(Groups.LIGHTS):
		var range_value: float = 0.0
		if "illumination_range" in light:
			range_value = light.illumination_range
		elif "max_vision_distance" in light:
			range_value = light.max_vision_distance
		if range_value <= 0.0:
			continue
		var origin: Vector3 = light.global_transform.origin
		for cell in walkable_cells_within(origin, range_value):
			if not _lit.has(cell):
				_lit[cell] = true
				_cost[cell] += COST_LIT
