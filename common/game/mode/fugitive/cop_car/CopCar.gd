extends KinematicBody
class_name CopCar

onready var enterArea := $EnterArea as Area

var seats := []

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


func enter_car(player: FugitivePlayer) -> bool:
	var seat := get_free_seat()
	if seat != null:
		# Disable personal colission so you can be inside the car's colission shape
		player.playerShape.disabled = true
		
		get_parent().remove_child(player.playerController)
		add_child(player.playerController)
		player.playerController.transform = seat.transform
		
		player.car = self
		seat.occupant = player
		
		print("Car entered")
		
		return true
	else:
		print("No free seats in car")
		return false


func exit_car(player: FugitivePlayer) -> bool:
	var carLeft := false
	
	for seat in seats:
		if seat.occupant == player:
			seat.occupant = null
			carLeft = true
			break
	
	if carLeft:
		player.playerShape.disabled = false
		
		player.car = null
		
		remove_child(player.playerController)
		get_parent().add_child(player.playerController)
		
		player.playerController.transform = transform
		player.playerController.transform.origin.y += 2.0
		player.playerController.transform.origin.x += 2.0
	
	return carLeft
