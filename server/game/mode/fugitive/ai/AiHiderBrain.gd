class_name AiHiderBrain
extends Node

# Decides where a bot fugitive goes. Runs on the server a few times a second
# and hands the body a target, a crouch flag and a sprint flag.
#
# The server knows where every cop is, so the bot deliberately limits what it
# admits to knowing: a cop on foot has to be in view, a car only has to be
# within earshot, and the visibility the game already computes for every
# hider doubles as "something is shining on me".

enum Mode { WAIT, ADVANCE, HIDE, FLEE, RESCUE, ESCAPED }

const THINK_INTERVAL := 0.2
const REPATH_INTERVAL := 3.0

const SEE_DISTANCE := 25.0
const HEAR_CAR_DISTANCE := 45.0
const PANIC_DISTANCE := 9.0
const CAUTION_DISTANCE := 20.0
const CROUCH_DISTANCE := 14.0
const RESCUE_DISTANCE := 35.0
const HIDE_SEARCH_RADIUS := 12.0
const FLEE_MIN_RADIUS := 10.0
const FLEE_SEARCH_RADIUS := 24.0
const SAFE_ZONE_DASH_DISTANCE := 20.0
const SAFE_ZONE_SETTLE_DISTANCE := 0.5
const SAFE_ZONE_SETTLE_PROGRESS := 0.05
const MAX_SPOT_CANDIDATES := 40

const SPRINT_START_STAMINA := 40.0
const SPRINT_STOP_STAMINA := 15.0
const EXPOSED_VISIBILITY := 0.05

# A cop that ducks out of view is still assumed to be about for this long,
# otherwise a bot behind cover stands straight back up and walks into them
const THREAT_MEMORY := 5.0

const STUCK_TIME := 1.5
const STUCK_DISTANCE := 0.3
const GOAL_CHANGE_DISTANCE := 2.0
const CLOSE_ENOUGH_TO_WALK_STRAIGHT := 3.0
const RESCUE_ARRIVE_DISTANCE := 0.3

# Players and walls, the same layers the flashlight raycaster sees
const LOS_MASK := 3
const EYE_HEIGHT := 1.5
const CROUCH_EYE_HEIGHT := 0.9

var controller: AiHiderController
var player: Hider
var game: ServerFugitiveGame
var grid: FugitiveNavGrid

var mode := Mode.WAIT
var path := PackedVector3Array()
var path_goal := Vector3()
var think_accumulator := 0.0
var repath_timer := 0.0
var stuck_timer := 0.0
var last_position := Vector3()
var sprinting := false
var hold_position := false
var remembered_threat = null
var threat_memory_left := 0.0
var settle_last_position := Vector3()
var settled := false

# Each bot is a little more or less nervous than the next
var caution_distance := CAUTION_DISTANCE
var panic_distance := PANIC_DISTANCE


func _ready():
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	think_accumulator = rng.randf() * THINK_INTERVAL
	caution_distance = CAUTION_DISTANCE * rng.randf_range(0.8, 1.2)
	panic_distance = PANIC_DISTANCE * rng.randf_range(0.8, 1.2)


func _physics_process(delta):
	# The body this brain drives is the parent, whose own onready references
	# only exist once the whole scene is ready
	if grid == null:
		controller = get_parent()
		player = controller.get_player()
		game = GameData.currentGame as ServerFugitiveGame
		grid = game.get_nav_grid(controller.get_world_3d().direct_space_state)
		last_position = controller.global_transform.origin
		return

	think_accumulator += delta
	repath_timer += delta
	if think_accumulator < THINK_INTERVAL:
		return

	var elapsed := think_accumulator
	think_accumulator = 0.0
	_think(elapsed)


func _think(elapsed: float):
	if not controller.can_move():
		_set_mode(Mode.WAIT)
		_stop()
		controller.want_crouch = false
		return

	if player.is_in_winzone():
		_settle_in_safe_zone()
		return

	_update_sprint_allowance()
	_check_stuck(elapsed)

	var my_pos := controller.global_transform.origin
	var threat = _current_threat(elapsed)
	var exposed := player.current_visibility > EXPOSED_VISIBILITY

	# Nothing can touch a hider inside the safe zone, so from this close the
	# only sensible move is straight in, cop or no cop
	if my_pos.distance_to(_nearest_win_zone_center()) < SAFE_ZONE_DASH_DISTANCE:
		_dash_for_safe_zone()
	elif threat != null and threat.distance < panic_distance and exposed:
		_flee(threat)
	# A flight already under way is seen through rather than second-guessed
	# every tick as the light comes and goes
	elif mode == Mode.FLEE and threat != null and threat.distance < caution_distance and not _flight_finished():
		_flee(threat)
	elif threat != null and threat.distance < caution_distance:
		_hide(threat)
	else:
		var frozen_friend = _nearest_frozen_teammate(my_pos)
		if frozen_friend != null:
			_rescue(frozen_friend)
		else:
			_advance()


func _flee(threat: Dictionary):
	var my_pos := controller.global_transform.origin
	var changed := _set_mode(Mode.FLEE)
	if changed or path.is_empty():
		var spot = _best_flee_spot(threat)
		if spot != null:
			_go_to(spot, true)
		else:
			# Nowhere clever to run, just put distance between us
			var away: Vector3 = (my_pos - threat.position).normalized() * FLEE_SEARCH_RADIUS
			_go_to(my_pos + away, true)
	else:
		_go_to(path_goal)
	controller.want_crouch = false
	controller.want_sprint = sprinting


func _hide(threat: Dictionary):
	var my_pos := controller.global_transform.origin
	var exposed := player.current_visibility > EXPOSED_VISIBILITY
	var here := grid.world_to_cell(my_pos)
	var changed := _set_mode(Mode.HIDE)

	# Already tucked away and unseen: stay put
	if not exposed and (hold_position or (grid.is_cover(here) and not _can_be_seen_from(threat.position, my_pos))):
		hold_position = true
		_stop()
	else:
		hold_position = false
		# A spot already chosen is kept until it is reached or the cop can see
		# it, otherwise every tick under the light would pick a new one
		var spot_is_blown := exposed and _can_be_seen_from(threat.position, path_goal)
		if changed or not controller.has_target or spot_is_blown:
			var spot = _best_hide_spot(threat)
			if spot != null:
				_go_to(spot, changed)
			else:
				_advance_path()
		else:
			_go_to(path_goal)

	controller.want_crouch = threat.distance < CROUCH_DISTANCE
	controller.want_sprint = false


func _rescue(friend: FugitivePlayer):
	_set_mode(Mode.RESCUE)
	hold_position = false
	_go_to(friend.playerController.global_transform.origin, false, RESCUE_ARRIVE_DISTANCE)
	controller.want_crouch = false
	controller.want_sprint = false


# Stopping on the edge of the zone leaves a body in the doorway for the next
# bot in, so keep walking to the centre. Whoever gets there first holds it
# and the rest settle for good wherever they bump to a halt around them.
func _settle_in_safe_zone():
	var my_pos := controller.global_transform.origin
	var center := _nearest_win_zone_center()
	# The first tick inside only takes aim; progress is judged from then on
	if _set_mode(Mode.ESCAPED):
		settled = false
		settle_last_position = my_pos
		controller.set_target(center, SAFE_ZONE_SETTLE_DISTANCE)
	elif not settled:
		var blocked := controller.has_target and my_pos.distance_to(settle_last_position) < SAFE_ZONE_SETTLE_PROGRESS
		settle_last_position = my_pos
		if _horizontal_distance(my_pos, center) <= SAFE_ZONE_SETTLE_DISTANCE or blocked:
			settled = true
		else:
			controller.set_target(center, SAFE_ZONE_SETTLE_DISTANCE)

	if settled:
		_stop()
	controller.want_crouch = true
	controller.want_sprint = false


func _dash_for_safe_zone():
	_set_mode(Mode.ADVANCE)
	hold_position = false
	_advance_path()
	controller.want_crouch = false
	controller.want_sprint = sprinting


func _flight_finished() -> bool:
	return path.is_empty() and controller.reached_target()


func _advance():
	_set_mode(Mode.ADVANCE)
	hold_position = false
	_advance_path()
	controller.want_crouch = false
	# Sprinting lights a hider up from far away, so only do it while the cops
	# are still locked in
	var headstart := game.current_state() == FugitiveStateMachine.STATE_PLAYING_HEADSTART
	controller.want_sprint = sprinting and headstart


func _advance_path():
	var goal := _nearest_win_zone_center()
	_go_to(goal)


func _stop():
	path = PackedVector3Array()
	controller.clear_target()
	controller.want_sprint = false


func _set_mode(new_mode: Mode) -> bool:
	if new_mode == mode:
		return false
	print("Bot %s: %s" % [player.playerShape.get_name_label().text, Mode.keys()[new_mode]])
	mode = new_mode
	path = PackedVector3Array()
	hold_position = false
	return true


func _update_sprint_allowance():
	if sprinting and player.stamina < SPRINT_STOP_STAMINA:
		sprinting = false
	elif not sprinting and player.stamina > SPRINT_START_STAMINA:
		sprinting = true


# Walk the current path toward goal, replanning when the goal moved, the path
# went stale, or the caller insists
func _go_to(goal: Vector3, force_repath := false, arrive := AiHiderController.DEFAULT_ARRIVE_DISTANCE):
	var my_pos := controller.global_transform.origin
	var needs_path := force_repath or path.is_empty() \
		or goal.distance_to(path_goal) > GOAL_CHANGE_DISTANCE \
		or repath_timer > REPATH_INTERVAL

	if needs_path:
		path = grid.find_path(my_pos, goal, _other_player_positions(), _known_threat_positions())
		path_goal = goal
		repath_timer = 0.0

	while path.size() > 1 and _horizontal_distance(my_pos, path[0]) <= AiHiderController.DEFAULT_ARRIVE_DISTANCE:
		path.remove_at(0)

	if path.is_empty():
		if _horizontal_distance(my_pos, goal) <= CLOSE_ENOUGH_TO_WALK_STRAIGHT:
			controller.set_target(goal, arrive)
		else:
			controller.clear_target()
	elif path.size() == 1:
		# The last waypoint is the goal cell, so head for the goal itself
		controller.set_target(goal, arrive)
	else:
		controller.set_target(path[0])


func _check_stuck(elapsed: float):
	var my_pos := controller.global_transform.origin
	if controller.has_target and not controller.reached_target():
		if my_pos.distance_to(last_position) < STUCK_DISTANCE:
			stuck_timer += elapsed
		else:
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
	last_position = my_pos

	if stuck_timer > STUCK_TIME:
		stuck_timer = 0.0
		var target_cell := grid.world_to_cell(controller.move_target)
		# Never wall off the goal itself, only a waypoint on the way there
		if target_cell != grid.world_to_cell(path_goal):
			grid.block_cell(target_cell)
		path = PackedVector3Array()
		repath_timer = REPATH_INTERVAL


# The cop this bot is aware of, if any, so paths keep well clear of them
func _known_threat_positions() -> Array:
	if remembered_threat == null:
		return []
	return [remembered_threat.position]


# Where everyone else is standing right now, so paths bend around them
func _other_player_positions() -> Array:
	var positions := []
	for other in game.players.values():
		if other != player and other.playerController != null:
			positions.push_back(other.playerController.global_transform.origin)
	return positions


func _horizontal_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))


func _nearest_win_zone_center() -> Vector3:
	var my_pos := controller.global_transform.origin
	var best := my_pos
	var best_distance := INF
	for zone in game.map.get_win_zones():
		var center: Vector3 = zone.global_transform.origin
		var distance := my_pos.distance_to(center)
		if distance < best_distance:
			best = center
			best_distance = distance
	return best


# The cop in view right now, or the last one seen while the memory of them
# lasts, measured from where they were last spotted. Null when neither.
func _current_threat(elapsed: float):
	var seen = _nearest_threat()
	if seen != null:
		remembered_threat = seen
		threat_memory_left = THREAT_MEMORY
		return seen

	if remembered_threat == null:
		return null

	threat_memory_left -= elapsed
	# The cop may have left the game since they were last seen
	if threat_memory_left <= 0.0 or not is_instance_valid(remembered_threat.node) or remembered_threat.node.frozen:
		remembered_threat = null
		return null

	remembered_threat.distance = controller.global_transform.origin.distance_to(remembered_threat.position)
	return remembered_threat


# The closest cop this bot admits to knowing about, or null
func _nearest_threat():
	var my_pos := controller.global_transform.origin
	var best = null
	for seeker in get_tree().get_nodes_in_group(Seeker.GROUP):
		if seeker.frozen:
			continue
		var position: Vector3 = seeker.playerController.global_transform.origin
		var distance := my_pos.distance_to(position)
		var noticed := false
		if seeker.car != null:
			noticed = distance <= HEAR_CAR_DISTANCE
		elif distance <= SEE_DISTANCE:
			noticed = _has_line_of_sight(_eye_position(), _eye_position_of(seeker), seeker.playerBody)
		if noticed and (best == null or distance < best.distance):
			best = { "node": seeker, "position": position, "distance": distance }
	return best


func _nearest_frozen_teammate(my_pos: Vector3):
	var best = null
	var best_distance := RESCUE_DISTANCE
	for hider in get_tree().get_nodes_in_group(Hider.GROUP):
		if hider == player or not hider.frozen or hider.is_in_winzone():
			continue
		var distance := my_pos.distance_to(hider.playerController.global_transform.origin)
		if distance < best_distance:
			best = hider
			best_distance = distance
	return best


func _eye_position() -> Vector3:
	return player.get_current_shape().head.global_transform.origin


func _eye_position_of(other: FugitivePlayer) -> Vector3:
	return other.get_current_shape().head.global_transform.origin


func _has_line_of_sight(from: Vector3, to: Vector3, expected: Node) -> bool:
	var space := controller.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to, LOS_MASK, [controller.get_rid()])
	var hit := space.intersect_ray(query)
	return hit.is_empty() or hit.collider == expected


# Whether a viewer standing at viewer_pos has a clear line to a crouching
# body at spot
func _can_be_seen_from(viewer_pos: Vector3, spot: Vector3) -> bool:
	var space := controller.get_world_3d().direct_space_state
	var from := viewer_pos + Vector3(0.0, EYE_HEIGHT, 0.0)
	var to := Vector3(spot.x, spot.y + CROUCH_EYE_HEIGHT, spot.z)
	var query := PhysicsRayQueryParameters3D.create(from, to, LOS_MASK & ~1)
	return space.intersect_ray(query).is_empty()


func _nearby_candidates(center: Vector3, radius: float) -> Array:
	var cells: Array = grid.walkable_cells_within(center, radius)
	cells.shuffle()
	if cells.size() > MAX_SPOT_CANDIDATES:
		cells.resize(MAX_SPOT_CANDIDATES)
	return cells


# A nearby cell the cop cannot see, ideally behind something and on the way
# to the safe zone. Null when there is none.
func _best_hide_spot(threat: Dictionary):
	var my_pos := controller.global_transform.origin
	var goal := _nearest_win_zone_center()
	var best = null
	var best_score := INF
	for cell in _nearby_candidates(my_pos, HIDE_SEARCH_RADIUS):
		var spot: Vector3 = grid.cell_to_world(cell, my_pos.y)
		if _can_be_seen_from(threat.position, spot):
			continue
		var score := spot.distance_to(my_pos)
		score -= spot.distance_to(threat.position) * 0.5
		score += spot.distance_to(goal) * 0.1
		if not grid.is_cover(cell):
			score += 6.0
		if grid.is_lit(cell):
			score += 10.0
		if score < best_score:
			best = spot
			best_score = score
	return best


# A cell well away from the cop, preferably out of their sight and toward
# the safe zone. Null when there is none.
func _best_flee_spot(threat: Dictionary):
	var my_pos := controller.global_transform.origin
	var goal := _nearest_win_zone_center()
	var away: Vector3 = (my_pos - threat.position).normalized()
	var best = null
	var best_score := INF
	for cell in _nearby_candidates(my_pos, FLEE_SEARCH_RADIUS):
		var spot: Vector3 = grid.cell_to_world(cell, my_pos.y)
		var offset := spot - my_pos
		if offset.length() < FLEE_MIN_RADIUS:
			continue
		var score := -offset.normalized().dot(away) * 10.0
		score -= spot.distance_to(threat.position) * 0.5
		score += spot.distance_to(goal) * 0.1
		if grid.is_lit(cell):
			score += 10.0
		if _can_be_seen_from(threat.position, spot):
			score += 8.0
		if score < best_score:
			best = spot
			best_score = score
	return best
