extends "res://client/game/mode/fugitive/VrFugitiveController.gd"


# Hiders auto-show the map when frozen
func show_map(show: bool):
	if player.frozen and player.gameStarted and not player.gameEnded:
		overviewMapHud.visible = true
	else:
		overviewMapHud.visible = show
