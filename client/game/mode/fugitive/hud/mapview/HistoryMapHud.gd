extends "res://client/game/mode/fugitive/hud/mapview/MapHudBase.gd"
class_name HistoryMapHud
onready var fugitiveGame := GameData.currentGame as FugitiveGame

export(NodePath) var replayLegendPath: NodePath
onready var replayLegend := get_node(replayLegendPath) as VBoxContainer


var PlayerLegendEntryTemplate = preload("res://client/game/mode/fugitive/hud/PlayerLegendEntry.tscn")

var currentIndex := 0
var timeSinceFrameChange := 0.0
var framesPerSecond := 1.0
var isPlaying := false

const maxTrailSize := 40

var playerColors := [ 
	Color.red,
	Color.blue,
	Color.yellow,
	Color.green,
	Color.brown,
	Color.purple,
	Color.orange,
	Color.pink,
	Color.magenta,
	Color.gold,
	Color.gray,
	Color.cyan,
	Color.lavender,
	Color.white,
	Color.plum,
	Color.beige
]

var currentPlayerColorDictionary = {}

func _ready():
	drawStreetNames = false
	
	var playerIndex := 0
	currentPlayerColorDictionary = {}
	for player in GameData.get_players():
		currentPlayerColorDictionary[player.get_id()] = playerColors[playerIndex]
		playerIndex += 1


func getMaxFrameIndex() -> int:
	return fugitiveGame.history.stateHistoryArray.size() - 1


func getFrameSpeed() -> float:
	return framesPerSecond


func setFrameSpeed(speed : float):
	framesPerSecond = speed


func stop():
	isPlaying = false


func togglePlay() -> bool:
	isPlaying = !isPlaying
	return isPlaying


func setIndex(index : int):
	if index < fugitiveGame.history.stateHistoryArray.size():
		currentIndex = index
		call_deferred("updateLedgend")


func getIndex() -> int:
	return currentIndex


func loadReplayLegend():
	for node in replayLegend.get_children():
		node.queue_free()
	
	for playerId in currentPlayerColorDictionary:
		var playerData = fugitiveGame.history.player_summaries[playerId] as PlayerData
		var newEntry = PlayerLegendEntryTemplate.instance()
		newEntry.initialize(playerData, currentPlayerColorDictionary[playerId])
		replayLegend.add_child(newEntry)


func updateLedgend():
	if currentIndex < fugitiveGame.history.stateHistoryArray.size():
		var heartbeat := fugitiveGame.history.stateHistoryArray[currentIndex] as Dictionary
		
		for playerId in fugitiveGame.history.player_summaries.keys():
			# Ensure this player exists in this heartbeat
			# The player could have disconnected before this point in the game
			if heartbeat.has(playerId):
				# Get current heartbeat
				var data = heartbeat[playerId]
				
				# Get next heartbeat data for interpolation
				var nextData
				if (currentIndex + 1) < fugitiveGame.history.stateHistoryArray.size():
					var nextHeartbeat = fugitiveGame.history.stateHistoryArray[currentIndex + 1] as Dictionary
					if nextHeartbeat.has(playerId):
						nextData = nextHeartbeat[playerId]
					else:
						nextData = data
				else:
					nextData = data
				
				# Calculate the weight for interpolation
				var percentage_to_next_frame = min(timeSinceFrameChange / (1.0 / framesPerSecond), 1.0)
				
				# Get the ledgend UI node to update
				var node := find_ledgend_item(playerId)
				if node != null:
					node.populate(data, nextData, percentage_to_next_frame)


func find_ledgend_item(playerId) -> Control:
	var node: Control = null
	
	for ledgendItem in replayLegend.get_children():
		if ledgendItem.playerDataChosen.get_id() == playerId:
			node = ledgendItem
			break
	
	return node


func _draw():
	if currentIndex < fugitiveGame.history.stateHistoryArray.size():
		# Get the current hearbeat
		var heartbeat := fugitiveGame.history.stateHistoryArray[currentIndex] as Dictionary
		
		# Get the next heart beat if it exists so we can use it for interpolation
		var nextHeartbeat: Dictionary
		if (currentIndex + 1) < fugitiveGame.history.stateHistoryArray.size():
			nextHeartbeat = fugitiveGame.history.stateHistoryArray[currentIndex + 1] as Dictionary
		# Must be the last heartbeat, use the current one which will result in no interpolation
		else:
			nextHeartbeat = heartbeat
		
		# Process each entity in this heart beat
		for entityId in heartbeat:
			var entry := heartbeat[entityId] as Dictionary
			
			var interpolatedPosition: Vector2
			var interpolatedAngle: float
			
			# Ensure next heart beat 
			if nextHeartbeat.has(entityId):
				var nextEntry = nextHeartbeat[entityId] as Dictionary
				var percentage_to_next_frame = min(timeSinceFrameChange / (1.0 / framesPerSecond), 1.0)
				interpolatedPosition = lerp(entry.position, nextEntry.position, percentage_to_next_frame)
				interpolatedAngle = lerp_angle(entry.orientation, nextEntry.orientation, percentage_to_next_frame)
			# Next heart beat doesn't contain this entity, it was probably a player who disconnected
			# Use the current heartbeat data which will result in no interpolation
			else:
				interpolatedPosition = entry.position as Vector2
				interpolatedAngle = entry.orientation as float
			
			match entry.entryType:
				FugitiveEnums.EntityType.Player:
					var playerData = fugitiveGame.history.player_summaries[entityId] as PlayerData
					
					# Outer color for the player triangle
					# This represents the team they are one
					var teamColor: Color
					match playerData.get_type():
						FugitiveTeamResolver.PlayerType.Hider:
							teamColor = Color.orange
							
							if (entry.frozen):
								teamColor = Color.cyan
						FugitiveTeamResolver.PlayerType.Seeker:
							teamColor = Color.blue
						_:
							teamColor = Color.magenta
					

					# This is a unique color for this specific player so you can identify
					# who is who from the ledgend
					var playerColor := currentPlayerColorDictionary[entityId] as Color
					
					# Draw the location history prior to this point in time
					draw_trail(playerColor, entityId)
					
					# Draw this players triangle
					draw_set_transform(to_map_coord_vector2(interpolatedPosition), interpolatedAngle, Vector2(1.2, 1.2))
					# Outter triangle
					draw_colored_polygon(playerShape, teamColor)
					draw_set_transform(to_map_coord_vector2(interpolatedPosition), interpolatedAngle, Vector2(1.0, 1.0))
					# Inner triangle
					draw_colored_polygon(playerShape, playerColor)
					draw_set_transform(Vector2(), 0.0, Vector2(1.0, 1.0))
				FugitiveEnums.EntityType.Car:
					# Draw the car
					var carSize := Vector2(10.0, 20.0)
					var rect := Rect2(Vector2(-(carSize.x/2.0), -(carSize.y/2.0)), carSize)
					draw_set_transform(to_map_coord_vector2(interpolatedPosition), interpolatedAngle, Vector2(1.0, 1.0))
					draw_rect(rect, Color.white)
					draw_set_transform(Vector2(), 0.0, Vector2(1.0, 1.0))
				_:
					print("ERROR: Unrecognized history entry %s" % entry.entryType)


func draw_trail(playerColor: Color, entityId):
	# Calculate trail length
	var trailSize: int
	if currentIndex <= maxTrailSize:
		trailSize = currentIndex -1
	else:
		trailSize = maxTrailSize
	
	# Don't try to draw unless we have at leat two points
	if trailSize > 1:
		# Copy the player color so we don't modify the original while drawing the trail
		var trailColor := Color(playerColor.to_rgba32())
		var trailPoints := PoolVector2Array()
		var trailColors := PoolColorArray()
		
		# Calculate the trail
		for ii in trailSize:
			var oldHeartbeat := fugitiveGame.history.stateHistoryArray[currentIndex-ii] as Dictionary
			var oldEntry := oldHeartbeat[entityId] as Dictionary
			var oldCoord := to_map_coord_vector2(oldEntry.position)
			trailPoints.append(oldCoord)
			
			# Fade it out the further back in time the point is
			trailColor.a = 1.0 - (float(ii) / float(maxTrailSize))
			trailColors.append(Color(trailColor.to_rgba32()))
		
		# Draw the trail behind the player
		draw_polyline_colors(trailPoints, trailColors, 2.0, true)


# Go to the next frame if it's playing
func _process(delta):
	if (isPlaying
		and (timeSinceFrameChange + delta) >= (1.0 / framesPerSecond)
		and currentIndex < fugitiveGame.history.stateHistoryArray.size() - 1):
		currentIndex += 1
		timeSinceFrameChange = 0
	else:
		timeSinceFrameChange += delta
	
	if visible:
		updateLedgend()
