extends KinematicBody
class_name CopCar

onready var enterArea := $EnterArea as Area

const MIN_SPEED := 0.5
const MAX_SPEED := 20.0
const ACCELERATION := 35.0
const BREAK_SPEED := 30.0
const FRICTION := 10.0
const ROTATION := 1.0

var seats := []
var driver_seat: CarSeat
var velocity := Vector3()

var locked := true


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
	else:
		print("No free seats in car")


func exit_car(player: FugitivePlayer):
	rpc("on_exit_car", player.id)


remotesync func on_exit_car(playerId: int) -> bool:
	var carLeft := false
	
	var player = GameData.currentGame.get_player(playerId)
	
	var seat = null
	for s in seats:
		if s.occupant == player:
			seat = s
			carLeft = true
			break
	
	if carLeft:
		print("Car exited")
		
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
	
	return carLeft


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


puppet func network_update(networkPosition: Vector3, networkRotation: Vector3):
	translation = networkPosition
	rotation = networkRotation


func _physics_process(delta):
	if is_network_master():
		velocity = move_and_slide(velocity, Vector3(0,1,0))
		
		velocity = velocity - (velocity.normalized() * (FRICTION * delta))
		if velocity.length() <= MIN_SPEED:
			velocity = Vector3()
		
		rpc_unreliable("network_update", translation, rotation)
