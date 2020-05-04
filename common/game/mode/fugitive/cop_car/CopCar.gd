extends KinematicBody
class_name CopCar

onready var enterArea := $EnterArea as Area

const MIN_SPEED := 0.5
const MAX_SPEED := 25.0
const ACCELERATION := 35.0
const BREAK_SPEED := 20.0
const FRICTION := 10.0
const FRICTION_BREAKING := 2.5
const ROTATION := 2.0
const GRAVITY := pow(9.8, 2)

const CONE_WIDTH = cos(deg2rad(35.0))
const MAX_VISION_DISTANCE := 50.0
const MIN_VISION_DISTANCE := 0.0

var seats := []
var driver_seat: CarSeat
var velocity := Vector3()
var isBreaking := false

var locked := true

var mutex := Mutex.new()

onready var headlight_ray_caster := $RayCast as RayCast
onready var drivingAudio := $DrivingAudio as AudioStreamPlayer3D


func _ready():
	add_to_group(Groups.CARS)
	
	# Add seat positions to array
	for seat in $Seats.get_children():
		if seat is CarSeat:
			seats.append(seat)
			
			if seat.is_driver_seat:
				driver_seat = seat


func get_free_seat() -> int:
	var freeSeat: int = -1
	
	for ii in range(seats.size()):
		var seat = seats[ii]
		if seat.is_empty():
			freeSeat = ii
			break
	
	return freeSeat


func car_enter_failed():
	rpc("on_car_enter_failed")


remotesync func on_car_enter_failed():
	$DoorLockedAudio.play()


# Clients locally request to enter
func request_enter_car(player: FugitivePlayer):
	rpc_id(ServerNetwork.SERVER_ID, "on_request_enter_car", player.id)


# The servers decides if user can enter, and what seat they will enter into
remotesync func on_request_enter_car(playerId: int):
	if not get_tree().is_network_server():
		return
	
	mutex.lock()
	
	print("on_request_enter_car")
	
	var seatIndex := get_free_seat()
	if seatIndex > -1:
		var seat = seats[seatIndex]
		var player = GameData.currentGame.get_player(playerId)
		
		var isHider = player.playerType == FugitiveTeamResolver.PlayerType.Hider
		# Car starts locked, first cop unlocks it
		if locked:
			if isHider:
				car_enter_failed()
				return
			else:
				locked = false
		elif isHider:
			if driver_seat.occupant != null:
				if driver_seat.occupant.playerType == FugitiveTeamResolver.PlayerType.Seeker:
					# Hider can't get in the car when a Seeker is driving
					car_enter_failed()
					return
		
		print("Server: it's okay to enter the car")
		rpc("on_car_entered", playerId, seatIndex)
	else:
		print("No free seats in car")
		car_enter_failed()
	
	mutex.unlock()


# Then it tells all clients what player is entering what seat in the car
remotesync func on_car_entered(playerId: int, seatIndex: int):
	mutex.lock()
	var player = GameData.currentGame.get_player(playerId)
	var seat = seats[seatIndex]
		
	var isHider = player.playerType == FugitiveTeamResolver.PlayerType.Hider
	# Car starts locked, first cop unlocks it
	if locked:
		if isHider:
			return
		else:
			locked = false
		
	# Disable personal colission so you can be inside the car's colission shape
	player.playerShape.disabled = true
	
	get_parent().remove_child(player.playerController)
	add_child(player.playerController)
	player.playerController.transform = seat.transform
	
	player.car = self
	seat.occupant = player
	
	if seat.is_driver_seat:
		set_network_master(playerId, false)
	
	print("Car entered")
	
	player.playerController.on_car_entered(self)
	
	$DoorAudio.play()
	mutex.unlock()


func request_exit_car(player: FugitivePlayer):
	rpc_id(ServerNetwork.SERVER_ID, "on_request_exit_car", player.id)


remotesync func on_request_exit_car(playerId: int):
	if not get_tree().is_network_server():
		return
	
	mutex.lock()
	var player = GameData.currentGame.get_player(playerId)
	
	# Server validates that this is ok, then tells all clients what to do
	var seatIndex := find_occupants_seat(player)
	if seatIndex > -1:
		rpc("on_exit_car", player.id, seatIndex)
	mutex.unlock()


remotesync func on_exit_car(playerId: int, seatIndex: int):
	mutex.lock()
	var player = GameData.currentGame.get_player(playerId)
	
	var seat = seats[seatIndex]
	
	if seat != null:
		player.car = null
		seat.occupant = null
		
		remove_child(player.playerController)
		
		get_parent().add_child(player.playerController)
		
		if seat.is_driver_seat:
			set_network_master(ServerNetwork.SERVER_ID, false)
		
		player.playerShape.disabled = false
		
		player.playerController.transform = transform
		player.playerController.transform.origin.y += 1.0
		player.playerController.transform.origin.x += 1.0
		player.playerController.transform.origin.z += 1.0
		
		player.playerController.on_car_exited(self)
		
		$DoorAudio.play()
		print("Car exited")
	else:
		print("ERROR: Failed to exit car. Player: %d seat: %d" % [playerId, seatIndex])
	mutex.unlock()


func find_occupants_seat(player: FugitivePlayer) -> int:
	var seatIndex := -1
	for ii in range(seats.size()):
		var seat = seats[ii]
		if seat.occupant == player:
			seatIndex = ii
			break
	return seatIndex


func eject_all_occupants():
	rpc("on_eject_all_occupants")


# Then kick everyone out of the car and lock it
remotesync func on_eject_all_occupants():
	for seatIndex in range(seats.size()):
		var seat = seats[seatIndex]
		if seat.occupant != null:
			print("Ejecting %d" % seat.occupant.id)
			# Do this locally, don't call exit_car()
			on_exit_car(seat.occupant.id, seatIndex)
	
	lock()


func has_occupants() -> bool:
	var occupants := 0
	for seat in seats:
		if not seat.is_empty():
			occupants += 1
	
	return occupants > 0


func is_driver(playerId: int) -> bool:
	return driver_seat.occupant != null and driver_seat.occupant.id == playerId


func lock() -> bool:
	if not locked and not has_occupants():
		rpc("on_lock")
		return true
	else:
		return false


func process_breaking(nowBreaking: bool, delta: float):
	if nowBreaking:
		velocity = velocity - (velocity.normalized() * (BREAK_SPEED * delta))
	
	# If we're chaning state
	if nowBreaking != isBreaking:
		isBreaking = nowBreaking
		
		# And the new state is breaking, AND we're moving fast
		if isBreaking and is_moving_fast():
			rpc("on_breaking")


remotesync func on_breaking():
	$BreakAudio.play()


remotesync func on_lock():
	locked = true
	$LockAudio.play()


func process_input(forward: bool, backward: bool, left: bool, right: bool, breaking: bool, delta: float):
	var globalBasis := global_transform.basis
	
	var movement_speed := ACCELERATION * delta
	
	if forward and not breaking:
		velocity.x -= globalBasis.z.x * movement_speed
		velocity.z -= globalBasis.z.z * movement_speed
	elif backward and not breaking:
		velocity.x += globalBasis.z.x * movement_speed
		velocity.z += globalBasis.z.z * movement_speed
	
	var movementSpeed := get_movment_speed()
	if movementSpeed > MAX_SPEED:
		velocity = velocity.normalized() * MAX_SPEED
	
	process_breaking(breaking, delta)
	
	if movementSpeed > MIN_SPEED:
		var direction := 1.0
		
		var angle := (-transform.basis.z).dot(velocity.normalized())
		if sign(angle) < 0.0:
			direction = -1.0
		
		# Turning speed is a function of speed
		var rotationSpeed := ROTATION * (movementSpeed / MAX_SPEED)
		
		if left:
			rotate(Vector3(0.0, 1.0, 0.0), rotationSpeed * direction * delta)
		elif right:
			rotate(Vector3(0.0, 1.0, 0.0), -rotationSpeed * direction * delta)


puppet func network_update(networkPosition: Vector3, networkRotation: Vector3, networkVelocity: Vector3):
	translation = networkPosition
	rotation = networkRotation
	velocity = networkVelocity


func _physics_process(delta):
	if get_tree().network_peer != null and is_network_master():
		velocity.y -= GRAVITY * delta
		velocity = move_and_slide_with_snap(velocity, Vector3(0,-2,0), Vector3(0,1,0))
		
		# Apply friction to counter sideways drift
		if not isBreaking:
			# Apply friction in oposition to sideways dift until it is zero'd out
			var dir := velocity.normalized()
			var cosAngle := acos((-transform.basis.z).dot(dir))
			dir.rotated(Vector3(0.0, 1.0, 0.0), -(cosAngle*3.0))
			velocity -= dir * (FRICTION * delta)
		# When breaking, apply friction head on, no bias against sliding
		else:
			# FRICTION_BREAKING: Apply less fricton when breaking to allow power sliding
			velocity = velocity - (velocity.normalized() * (FRICTION_BREAKING * delta))

		if not GameData.currentGame.is_game_over():
			rpc_unreliable("network_update", translation, rotation, velocity)
	else:
		# Client side prediction
		velocity = move_and_slide_with_snap(velocity, Vector3(0,-2,0), Vector3(0,1,0))


func get_movment_speed() -> float:
	return Vector3(velocity.x, 0.0, velocity.z).length()


func is_moving() -> bool:
	return get_movment_speed() > MIN_SPEED


func is_moving_fast() -> bool:
	return get_movment_speed() > (MAX_SPEED * 0.90)


func honk_horn():
	rpc("on_honk_horn")


remotesync func on_honk_horn():
	$HornAudio.play()


func _process(delta):
	# Make movement noises if moving
	if self.is_moving() and not driver_seat.is_empty():
		if not drivingAudio.playing:
			drivingAudio.playing = true
	else:
		if drivingAudio.playing:
			drivingAudio.playing = false


func process_hider(hider: Hider):
	# If the hider is in a car, just skip them
	if hider.car != null:
		return
	
	# Distance between Hider and Seeker
	var distance = global_transform.origin.distance_to(hider.playerController.global_transform.origin)
	
	# TODO: CLOSE_PROXIMITY_DISTANCE is a hack, see issue #14
	if distance <=  MAX_VISION_DISTANCE:
		# Cast a ray between the seeker's flashlight and this hider
		var curHiderShape = hider.get_current_shape().head
		var look_vec := headlight_ray_caster.to_local(curHiderShape.global_transform.origin)
		
		headlight_ray_caster.cast_to = look_vec
		headlight_ray_caster.force_raycast_update()
		
		# Only if ray is colliding. If it's not, and we try to do logic,
		# wierd stuff happens
		if(headlight_ray_caster.is_colliding()):
			
			var bodySeen = headlight_ray_caster.get_collider()
			
			# If the ray hits a wall or something else first, then this Hider is fully occluded
			if(bodySeen == hider.playerBody):
				# Calculate the angle of this ray from the cetner of the Flashlight's FOV
				var look_angle := Vector3(0.0, 0.0, -1.0).dot(look_vec.normalized())
				
				############################################
				# Begin visibility calculations
				############################################
				
				# At a given distance, fade the hider out
				var distance_visibility: float
				
				# Hider is too far away, make invisible regardless of FOV visibility
				if distance > MAX_VISION_DISTANCE:
					distance_visibility = 0.0
				# Hider is at the edge of distance visibility, calculate how close to the edge they are
				elif distance > MIN_VISION_DISTANCE:
					var shiftedDistance = distance - MIN_VISION_DISTANCE
					distance_visibility = 1.0 - (shiftedDistance / (MAX_VISION_DISTANCE-MIN_VISION_DISTANCE))
				# Hider is well with-in visible distance, we won't modify the FOV visibility at all
				else:
					distance_visibility = 1.0
				
				# If hider is in the center of Seeker's FOV, they are fully visible
				# otherwise, they will gradually fade out the further out to the edges
				# of the FOV they are. Outside the FOV cone, they are invisible.
				var rangeShifted = clamp(look_angle - CONE_WIDTH, 0.0, CONE_WIDTH)
				var rangeMapped = rangeShifted / (1.0 - CONE_WIDTH)
				var fov_visibility = rangeMapped
				
				# FOV visibility can be faded out if at edge of distance visibility
				var percent_visible: float = fov_visibility * distance_visibility
				percent_visible = clamp(percent_visible, 0.0, 1.0)
				
				# The hider's set visibility method will handle the visible effects of this
				hider.update_visibility(percent_visible)


func _on_EnterArea_body_entered(body):
	# Server authoritative
	if get_tree().network_peer != null and get_tree().is_network_server():
		if has_occupants():
			# If the player we just collided with is a Seeker
			var collidedPlayer = body.get_player()
			if collidedPlayer.playerType == FugitiveTeamResolver.PlayerType.Seeker:
				var hasHiders := false
				for seat in seats:
					if seat.occupant != null and driver_seat.occupant.playerType == FugitiveTeamResolver.PlayerType.Hider:
						hasHiders = true
						break
				
				# If the car has ANY hiders in it, eject everyone
				if hasHiders:
					eject_all_occupants()
