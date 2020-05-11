extends "res://client/game/mode/fugitive/hud/mapview/MapHudBase.gd"

const localPlayerColor := Color.red
const hiderColor := Color.orange
const hiderFrozenColor := Color.lightblue
const seekerColor := Color.blue
const carColor := Color.whitesmoke


func _draw():
	var localPlayer := GameData.currentGame.localPlayer as FugitivePlayer
	
	# Draw this players team members
	var remotePlayers = null
	if localPlayer.playerType == FugitiveTeamResolver.PlayerType.Hider:
		remotePlayers = get_tree().get_nodes_in_group(Hider.GROUP)
	else:
		remotePlayers = get_tree().get_nodes_in_group(Seeker.GROUP)
	
	for remotePlayer in remotePlayers:
		if remotePlayer.id != localPlayer.id:
			var remotePos = remotePlayer.global_transform.origin
			var remoteCoord = to_map_coord(remotePos)
			
			var color: Color
			match remotePlayer.playerType:
				FugitiveTeamResolver.PlayerType.Hider:
					if remotePlayer.frozen:
						color = hiderFrozenColor
					else:
						color = hiderColor
				FugitiveTeamResolver.PlayerType.Seeker:
					color = seekerColor
				_:
					color = Color.black
			
			draw_circle(remoteCoord, 10.0, color)
	
	# Draw the local player
	var globalTransform := localPlayer.global_transform
	var playerPos := globalTransform.origin
	var playerCoord = to_map_coord(playerPos)
	var angle = Utils.get_map_rotation(globalTransform)
	
	draw_set_transform(playerCoord, angle, Vector2(1.0, 1.0))
	draw_colored_polygon(playerShape, localPlayerColor)
	draw_set_transform(Vector2(), 0.0, Vector2(1.0, 1.0))
	
	# Draw the cop cars if you are a cop
	if localPlayer.playerType == FugitiveTeamResolver.PlayerType.Seeker:
		var cars = get_tree().get_nodes_in_group(Groups.CARS)
		for car in cars:
			var carTransform = car.global_transform
			var carPos = carTransform.origin
			var carCoord = to_map_coord(carPos)
			var carAngle = Utils.get_map_rotation(carTransform)
			
			var carSize := Vector2(10.0, 20.0)
			var rect := Rect2(Vector2(-(carSize.x/2.0), -(carSize.y/2.0)), carSize)
			draw_set_transform(carCoord, carAngle, Vector2(1.0, 1.0))
			draw_rect(rect, carColor)
			draw_set_transform(Vector2(), 0.0, Vector2(1.0, 1.0))
