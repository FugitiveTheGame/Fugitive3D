extends KinematicBody
class_name CopCar

onready var enterArea := $EnterArea as Area

const SPEED := 20.0

var seats := []
var velocity := Vector3()


func _ready():
	add_to_group(Groups.CARS)
	
	# Add seat positions to array
	for seat in $Seats.get_children():
		if seat is CarSeat:
			seats.append(seat)


func get_free_seat() -> CarSeat:
	var freeSeat: CarSeat = null
	
	for seat in seats:
		if seat.is_empty():
			print("Found empty seat")
			freeSeat = seat
			break
	
	return freeSeat


func enter_car(player: FugitivePlayer):
	rpc("on_enter_car", player.get_network_master())


remotesync func on_enter_car(playerId: int):
	var seat := get_free_seat()
	if seat != null:
		var player = GameData.currentGame.get_player(playerId)
		
		# Disable personal colission so you can be inside the car's colission shape
		player.playerShape.disabled = true
		
		get_parent().remove_child(player.playerController)
		add_child(player.playerController)
		player.playerController.transform = seat.transform
		
		player.car = self
		seat.occupant = player
		
		if seat.is_driver_seat:
			set_network_master(player.get_network_master())
		
		print("Car entered")
		
		player.playerController.on_car_entered(self)
	else:
		print("No free seats in car")


func exit_car(player: FugitivePlayer):
	rpc("on_exit_car", player.get_network_master())


remotesync func on_exit_car(playerId: int) -> bool:
	var carLeft := false
	
	var player = GameData.currentGame.get_player(playerId)
	
	var seat = null
	for s in seats:
		if s.occupant == player:
			seat = s
			seat.occupant = null
			carLeft = true
			break
	
	if carLeft:
		player.playerShape.disabled = false
		
		player.car = null
		
		if seat.is_driver_seat:
			set_network_master(ServerNetwork.SERVER_ID)
		
		remove_child(player.playerController)
		get_parent().add_child(player.playerController)
		
		player.playerController.transform = transform
		player.playerController.transform.origin.y += 2.0
		player.playerController.transform.origin.x += 2.0
		
		player.playerController.on_car_exited(self)
	
	return carLeft


puppet func network_update(networkPosition: Vector3, networkRotation: Vector3):
	translation = networkPosition
	rotation = networkRotation


func _process(delta):
	if get_tree().get_network_unique_id() == get_network_master():
		velocity = move_and_slide(velocity, Vector3(0,1,0))
		
		rpc_unreliable("network_update", translation, rotation)
