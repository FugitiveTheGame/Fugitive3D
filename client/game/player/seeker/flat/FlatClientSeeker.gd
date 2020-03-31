extends Seeker

func _ready():
	var playerController = find_node("PlayerController", false, false)
	if playerController != null:
		print("FlatClientSeeker setting player node")
		playerController.player = self


func set_not_local_player():
	.set_not_local_player()
	var controller = $PlayerController
	remove_child(controller)
	controller.queue_free()
