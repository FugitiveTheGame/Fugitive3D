extends KinematicBody
class_name CopCar

onready var enterArea := $EnterArea as Area

const MIN_SPEED := 0.5
const MAX_SPEED := 20.0
const ACCELERATION := 35.0
const BREAK_SPEED := 30.0
const FRICTION := 10.0
const ROTATION := 1.0
const GRAVITY := pow(9.8, 2)

const CONE_WIDTH = cos(deg2rad(35.0))
const MAX_VISION_DISTANCE := 50.0
const MIN_VISION_DISTANCE := 0.0

var seats := []
var driver_seat: CarSeat
var velocity := Vector3()

var locked := true

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


func get_free_seat() -> CarSeat:
	var freeSeat: CarSeat = null
	
	for seat in seats:
		if seat.is_empty():
			freeSeat = seat
			break
	
	return freeSeat


func enter_car(player: FugitivePlayer):
	rpc("on_enter_car", player.id)


remotesync func on_enter_car(playerId: int):
	var seat := get_free_seat()
	if seat != null:
		var player = GameData.currentGame.get_player(playerId)
		
		var isHider = player.playerType == GameData.PlayerType.Hider
		# Car starts locked, first cop unlocks it
		if locked:
			if isHider:
				return
			else:
				locked = false
		elif isHider:
			if driver_seat.occupant != null:
				if driver_seat.occupant.playerType == GameData.PlayerType.Seeker:
					# Hider can't get in the car when a Seeker is driving
					return
		
		
		# Disable personal colission so you can be inside the car's colission shape
		player.playerShape.disabled = true
		
		get_parent().remove_child(player.playerController)
		add_child(player.playerController)
		player.playerController.transform = seat.transform
		
		player.car = self
		seat.occupant = player
		
		if seat.is_driver_seat:
			set_network_master(playerId)
		
		print("Car entered")
		
		player.playerController.on_car_entered(self)
		
		$DoorAudio.play()
	else:
		print("No free seats in car")


func exit_car(player: FugitivePlayer):
	rpc("on_exit_car", player.id)


remotesync func on_exit_car(playerId: int) -> bool:
	var carLeft: bool
	
	var player = GameData.currentGame.get_player(playerId)
	
	var seat = null
	for s in seats:
		if s.occupant == player:
			seat = s
			break
	
	if seat != null:
		player.car = null
		seat.occupant = null
		
		remove_child(player.playerController)
		
		get_parent().add_child(player.playerController)
		
		if seat.is_driver_seat:
			set_network_master(ServerNetwork.SERVER_ID)
		
		player.playerShape.disabled = false
		
		player.playerController.transform = transform
		player.playerController.transform.origin.y += 1.0
		player.playerController.transform.origin.x += 1.0
		
		player.playerController.on_car_exited(self)
		
		$DoorAudio.play()
		
		carLeft = true
	else:
		carLeft = false
	
	return carLeft


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


remotesync func on_lock():
	locked = true
	$LockAudio.play()


func process_input(forward: bool, backward: bool, left: bool, right: bool, breaking: bool, delta: float):
	var globalBasis := global_transform.basis
	
	var movement_speed := ACCELERATION * delta
	
	if forward:
		velocity.x -= globalBasis.z.x * movement_speed
		velocity.z -= globalBasis.z.z * movement_speed
	elif backward:
		velocity.x += globalBasis.z.x * movement_speed
		velocity.z += globalBasis.z.z * movement_speed
	
	if velocity.length() > MAX_SPEED:
		velocity = velocity.normalized() * MAX_SPEED
	
	if breaking:
		velocity = velocity - (velocity.normalized() * (BREAK_SPEED * delta))
	
	if velocity.length() > MIN_SPEED:
		var direction := 1.0
		if backward:
				direction = -1.0
		
		if left:
			rotate(Vector3(0.0, 1.0, 0.0), ROTATION * direction * delta)
		elif right:
			rotate(Vector3(0.0, 1.0, 0.0), -ROTATION * direction * delta)


puppet func network_update(networkPosition: Vector3, networkRotation: Vector3, networkVelocity: Vector3):
	translation = networkPosition
	rotation = networkRotation
	velocity = networkVelocity


func _physics_process(delta):
	if is_network_master():
		velocity.y -= GRAVITY * delta
		velocity = move_and_slide_with_snap(velocity, Vector3(0,-2,0), Vector3(0,1,0))
		
		velocity = velocity - (velocity.normalized() * (FRICTION * delta))
		if velocity.length() <= MIN_SPEED:
			velocity = Vector3()
		
		rpc_unreliable("network_update", translation, rotation, velocity)


func is_moving() -> bool:
	return Vector3(velocity.x, 0.0, velocity.y).length() > 0.01


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
	if get_tree().is_network_server():
		if has_occupants():
			# If the player we just collided with is a Seeker
			var collidedPlayer = body.get_player()
			if collidedPlayer.playerType == GameData.PlayerType.Seeker:
				# And the driver is a Hider
				if driver_seat.occupant != null and driver_seat.occupant.playerType == GameData.PlayerType.Hider:
					# Then kick everyone out of the car and lock it
					for seat in seats:
						if seat.occupant != null:
							print("Ejecting %d" % seat.occupant.id)
							exit_car(seat.occupant)
					
					lock()
