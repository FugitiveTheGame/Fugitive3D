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
			var data = heartbeat[playerId]
			
			var nextData
			if (currentIndex + 1) < fugitiveGame.history.stateHistoryArray.size():
				var nextHeartbeat = fugitiveGame.history.stateHistoryArray[currentIndex + 1] as Dictionary
				nextData = nextHeartbeat[playerId]
			else:
				nextData = data
			
			var percentage_to_next_frame = min(timeSinceFrameChange / (1.0 / framesPerSecond), 1.0)
			
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
		var heartbeat := fugitiveGame.history.stateHistoryArray[currentIndex] as Dictionary
		var nextHeartbeat := heartbeat
		
		if (currentIndex + 1) < fugitiveGame.history.stateHistoryArray.size():
			nextHeartbeat = fugitiveGame.history.stateHistoryArray[currentIndex + 1] as Dictionary
			
		for entityId in heartbeat:
			var entry := heartbeat[entityId] as Dictionary
			
			var interpolatedPosition := entry.position as Vector2
			var interpolatedAngle := entry.orientation as float
			
			if nextHeartbeat.has(entityId):
				var nextEntry = nextHeartbeat[entityId] as Dictionary
				var percentage_to_next_frame = min(timeSinceFrameChange / (1.0 / framesPerSecond), 1.0)
				interpolatedPosition = lerp(entry.position, nextEntry.position, percentage_to_next_frame)
				interpolatedAngle = lerp_angle(entry.orientation, nextEntry.orientation, percentage_to_next_frame)
			
			match entry.entryType:
				FugitiveEnums.EntityType.Player:
					var teamColor := Color.magenta
					
					var playerData = fugitiveGame.history.player_summaries[entityId] as PlayerData
					
					match playerData.get_type():
						FugitiveTeamResolver.PlayerType.Hider:
							teamColor = Color.orange
							
							if (entry.frozen):
								teamColor = Color.cyan
						FugitiveTeamResolver.PlayerType.Seeker:
							teamColor = Color.blue
				
					draw_set_transform(to_map_coord_vector2(interpolatedPosition), interpolatedAngle, Vector2(1.2, 1.2))
					draw_colored_polygon(playerShape, teamColor)
					draw_set_transform(to_map_coord_vector2(interpolatedPosition), interpolatedAngle, Vector2(1.0, 1.0))
					draw_colored_polygon(playerShape, currentPlayerColorDictionary[entityId])
					draw_set_transform(Vector2(), 0.0, Vector2(1.0, 1.0))
				FugitiveEnums.EntityType.Car:
					var carSize := Vector2(10.0, 20.0)
					var rect := Rect2(Vector2(-(carSize.x/2.0), -(carSize.y/2.0)), carSize)
					draw_set_transform(to_map_coord_vector2(interpolatedPosition), interpolatedAngle, Vector2(1.0, 1.0))
					draw_rect(rect, Color.white)
					draw_set_transform(Vector2(), 0.0, Vector2(1.0, 1.0))
				_:
					print("ERROR: Unrecognized history entry %s" % entry.entryType)


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
