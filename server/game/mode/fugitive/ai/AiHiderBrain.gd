class_name AiHiderBrain
extends Node

# Decides where a bot fugitive goes. Runs on the server a few times a second
# and hands the body a target, a crouch flag and a sprint flag.
#
# The server knows where every cop is, so the bot deliberately limits what it
# admits to knowing: a cop on foot has to be in view, a car only has to be
# within earshot, and the visibility the game already computes for every
# hider doubles as "something is shining on me". How far it sees, how long it
# remembers, how fast and how directly it moves all come from the difficulty
# profile chosen for it in the lobby.

enum Mode { WAIT, ADVANCE, HIDE, FLEE, RESCUE, ESCAPED }

const REPATH_INTERVAL := 3.0

const HEAR_CAR_DISTANCE := 45.0
const HIDE_SEARCH_RADIUS := 12.0
const FLEE_MIN_RADIUS := 10.0
const FLEE_SEARCH_RADIUS := 24.0
const FLEE_SEEN_PENALTY := 8.0
const SAFE_ZONE_SETTLE_DISTANCE := 0.5
const SAFE_ZONE_SETTLE_PROGRESS := 0.05

const SPRINT_START_STAMINA := 40.0
const SPRINT_STOP_STAMINA := 15.0
const EXPOSED_VISIBILITY := 0.05

const STUCK_TIME := 1.5
const STUCK_DISTANCE := 0.3
const GOAL_CHANGE_DISTANCE := 2.0
const CLOSE_ENOUGH_TO_WALK_STRAIGHT := 3.0
const RESCUE_ARRIVE_DISTANCE := 0.3
# How much ground a bot will add to its own way in to go and unfreeze someone
const RESCUE_DETOUR_BUDGET := 15.0
# With less than this left on the clock it banks its own escape instead
const RESCUE_CLOCK_RESERVE := 45.0
# A detour is a whim, so it only has to be roughly reached
const DETOUR_ARRIVE_DISTANCE := 2.0
# A detour shorter than this share of the radius is not worth the walk
const DETOUR_MIN_FRACTION := 0.5

# Players and walls, the same layers the flashlight raycaster sees
const LOS_MASK := 3
const EYE_HEIGHT := 1.5
const CROUCH_EYE_HEIGHT := 0.9

var controller: AiHiderController
var player: Hider
var game: ServerFugitiveGame
var grid: FugitiveNavGrid
var profile: AiDifficulty
var rng := RandomNumberGenerator.new()

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
# A spot off the route the bot has decided to wander past on the way in
var detour_goal = null


func _ready():
	rng.randomize()


func _physics_process(delta):
	# The body this brain drives is the parent, whose own onready references
	# only exist once the whole scene is ready
	if grid == null:
		controller = get_parent()
		player = controller.get_player()
		game = GameData.currentGame as ServerFugitiveGame
		grid = game.get_nav_grid(controller.get_world_3d().direct_space_state)
		last_position = controller.global_transform.origin
		_apply_difficulty()
		return

	think_accumulator += delta
	repath_timer += delta
	if think_accumulator < profile.think_interval:
		return

	var elapsed := think_accumulator
	think_accumulator = 0.0
	_think(elapsed)


# The body's profile is this bot's own copy, so its nerves can be jittered in
# place and no two bots break cover at quite the same distance
func _apply_difficulty():
	profile = controller.profile
	profile.caution_distance *= rng.randf_range(0.8, 1.2)
	profile.panic_distance *= rng.randf_range(0.8, 1.2)
	think_accumulator = rng.randf() * profile.think_interval


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
	if my_pos.distance_to(_nearest_win_zone_center()) < profile.safe_zone_dash_distance:
		_dash_for_safe_zone()
	elif threat != null and threat.distance < profile.panic_distance and exposed:
		_flee(threat)
	# A flight already under way is seen through rather than second-guessed
	# every tick as the light comes and goes
	elif mode == Mode.FLEE and threat != null and threat.distance < profile.caution_distance and not _flight_finished():
		_flee(threat)
	elif threat != null and threat.distance < profile.caution_distance:
		_hide(threat)
	else:
		var frozen_friend = _rescue_candidate(my_pos)
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
	controller.want_sprint = sprinting and _may_sprint()


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

	controller.want_crouch = threat.distance < profile.crouch_distance
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
	controller.want_sprint = sprinting and _may_sprint()


func _flight_finished() -> bool:
	return path.is_empty() and controller.reached_target()


func _advance():
	_set_mode(Mode.ADVANCE)
	hold_position = false
	_advance_path(true)
	controller.want_crouch = false
	# Sprinting lights a hider up from far away, so only do it while the cops
	# are still locked in
	controller.want_sprint = sprinting and _in_headstart()


func _in_headstart() -> bool:
	return game.current_state() == FugitiveStateMachine.STATE_PLAYING_HEADSTART


# Whether a burst of speed is on the table right now: always while the cops
# are locked in, afterwards only for a profile willing to be that visible
func _may_sprint() -> bool:
	return profile.sprints_after_headstart or _in_headstart()


# Head for the safe zone, by way of a detour when the profile allows one and
# the caller does
func _advance_path(allow_detour := false):
	if allow_detour:
		_update_detour()
		if detour_goal != null:
			_go_to(detour_goal, false, DETOUR_ARRIVE_DISTANCE)
			if controller.has_target:
				return
			# The grid has no route to it, so the whim is dropped on the spot
			detour_goal = null
	else:
		detour_goal = null
	_go_to(_nearest_win_zone_center())


# A detour under way is finished before another is rolled for, and a new one
# is only rolled for when the route is about to be replanned anyway
func _update_detour():
	var my_pos := controller.global_transform.origin
	if detour_goal != null:
		if _horizontal_distance(my_pos, detour_goal) <= DETOUR_ARRIVE_DISTANCE:
			detour_goal = null
		return
	if profile.detour_chance <= 0.0 or repath_timer < REPATH_INTERVAL:
		return
	if rng.randf() < profile.detour_chance:
		detour_goal = _random_detour_spot(my_pos)


# A random walkable cell a fair way off that is out of the street light and
# not a step toward any cop the bot is keeping clear of. Null when there is
# none nearby.
func _random_detour_spot(my_pos: Vector3):
	var min_distance := profile.detour_radius * DETOUR_MIN_FRACTION
	var threats := _known_threat_positions()
	for cell in _nearby_candidates(my_pos, profile.detour_radius):
		if grid.is_lit(cell):
			continue
		var spot: Vector3 = grid.cell_to_world(cell, my_pos.y)
		if _horizontal_distance(my_pos, spot) < min_distance:
			continue
		if _closer_to_any(spot, my_pos, threats):
			continue
		return spot
	return null


func _closer_to_any(spot: Vector3, my_pos: Vector3, positions: Array) -> bool:
	for position in positions:
		if spot.distance_to(position) < my_pos.distance_to(position):
			return true
	return false


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
	detour_goal = null
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


# The cop this bot is aware of, if any, so paths keep well clear of them.
# A bot that does not plan around cops walks its route regardless.
func _known_threat_positions() -> Array:
	if remembered_threat == null or not profile.keeps_clear_of_cops:
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
		threat_memory_left = profile.threat_memory
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
		elif distance <= profile.see_distance:
			noticed = _has_line_of_sight(_eye_position(), _eye_position_of(seeker), seeker.playerBody)
		if noticed and (best == null or distance < best.distance):
			best = { "node": seeker, "position": position, "distance": distance }
	return best


# Who to go and unfreeze, if anyone. The round is won the moment every hider
# still on their feet is home, so a bot that is the last one out throws that
# away by turning back, and so does one that spends the end of the clock on a
# friend. Short of that, a friend is worth only so much of a detour.
func _rescue_candidate(my_pos: Vector3):
	if profile.rescue_distance <= 0.0 or _last_hider_out() or _clock_is_short():
		return null

	var goal := _nearest_win_zone_center()
	var my_goal_distance := my_pos.distance_to(goal)
	var best = null
	var best_distance := profile.rescue_distance
	for hider in get_tree().get_nodes_in_group(Hider.GROUP):
		if hider == player or not hider.frozen or hider.is_in_winzone():
			continue
		var friend_pos: Vector3 = hider.playerController.global_transform.origin
		var distance := my_pos.distance_to(friend_pos)
		if distance >= best_distance:
			continue
		if distance + friend_pos.distance_to(goal) - my_goal_distance > RESCUE_DETOUR_BUDGET:
			continue
		best = hider
		best_distance = distance
	return best


# Whether every other hider is frozen or already home, which leaves this
# bot's own walk in as the only thing the round is waiting on
func _last_hider_out() -> bool:
	for hider in get_tree().get_nodes_in_group(Hider.GROUP):
		if hider != player and not hider.frozen and not hider.is_in_winzone():
			return false
	return true


func _clock_is_short() -> bool:
	var timer := game.map.get_timelimit_timer() as Timer
	return timer != null and not timer.is_stopped() and timer.time_left < RESCUE_CLOCK_RESERVE


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
	if cells.size() > profile.spot_candidates:
		cells.resize(profile.spot_candidates)
	return cells


# The spot pickers below rank [score, position] pairs on everything that is
# cheap to know, then spend raycasts on the ranked list in order of promise
func _lower_score_first(a: Array, b: Array) -> bool:
	return a[0] < b[0]


# A nearby cell the cop cannot see, ideally behind something and on the way
# to the safe zone. Null when there is none.
func _best_hide_spot(threat: Dictionary):
	var my_pos := controller.global_transform.origin
	var goal := _nearest_win_zone_center()
	var ranked := []
	for cell in _nearby_candidates(my_pos, HIDE_SEARCH_RADIUS):
		var spot: Vector3 = grid.cell_to_world(cell, my_pos.y)
		var score := spot.distance_to(my_pos)
		score -= spot.distance_to(threat.position) * 0.5
		score += spot.distance_to(goal) * 0.1
		if not grid.is_cover(cell):
			score += 6.0
		if grid.is_lit(cell):
			score += 10.0
		ranked.push_back([score, spot])
	ranked.sort_custom(_lower_score_first)
	# Being out of sight is a must, so the first unseen spot is the best one
	for entry in ranked:
		if not _can_be_seen_from(threat.position, entry[1]):
			return entry[1]
	return null


# A cell well away from the cop, preferably out of their sight and toward
# the safe zone. Null when there is none.
func _best_flee_spot(threat: Dictionary):
	var my_pos := controller.global_transform.origin
	var goal := _nearest_win_zone_center()
	var away: Vector3 = (my_pos - threat.position).normalized()
	var ranked := []
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
		ranked.push_back([score, spot])
	ranked.sort_custom(_lower_score_first)
	var best = null
	var best_score := INF
	# Being seen only costs points, so once a spot cannot win on its cheap
	# score alone neither can anything ranked after it
	for entry in ranked:
		if entry[0] >= best_score:
			break
		var score: float = entry[0]
		if _can_be_seen_from(threat.position, entry[1]):
			score += FLEE_SEEN_PENALTY
		if score < best_score:
			best = entry[1]
			best_score = score
	return best
