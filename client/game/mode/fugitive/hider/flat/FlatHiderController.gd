extends "res://client/game/mode/fugitive/FlatFugitiveController.gd"


# Hiders auto-show the map when frozen
func show_map(show: bool):
	if player.frozen:
		overviewMapHud.visible = true
	else:
		overviewMapHud.visible = show
