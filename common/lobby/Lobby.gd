extends Control
class_name Lobby

export(NodePath) var playerListPath: NodePath
onready var playerList := get_node(playerListPath) as VBoxContainer

export(NodePath) var mapSelectPath: NodePath
onready var mapSelect := get_node(mapSelectPath) as OptionButton

export(NodePath) var mapDescriptionPath: NodePath
onready var mapDescription := get_node(mapDescriptionPath) as RichTextLabel

var is_host := false
var is_starting := false


func _ready():
	ClientNetwork.connect("create_player", self, "create_player")
	ClientNetwork.connect("update_player", self, "update_player")
	ClientNetwork.connect("remove_player", self, "remove_player")
	ClientNetwork.connect("update_game_data", self, "update_game_data")
	
	ClientNetwork.connect("start_lobby_countdown", self, "on_start_lobby_countdown")
	ClientNetwork.connect("start_game", self, "on_start_game")
	
	populate_map_list()
	
	call_deferred("update_ui")


func populate_map_list():
	for map in Maps.directory:
		mapSelect.add_item(map[Maps.MAP_NAME])


func create_player(playerId: int):
	var existingPlayerNode := find_player_node(playerId)
	if existingPlayerNode != null:
		return
	
	print("Creating player in lobby")
	
	var player := GameData.get_player(playerId)
	var mode = Maps.get_mode_for_map(GameData.general[GameData.GENERAL_MAP])
	
	var playerListItem = preload("res://common/lobby/PlayerListItem.tscn")
	
	var playerNode = playerListItem.instance()
	playerNode.set_network_master(playerId)
	playerNode.set_name(str(playerId))
	playerList.add_child(playerNode)
	
	playerNode.connect("make_host", self, "on_make_host")
	playerNode.connect("kick_player", self, "on_kick_player")
	
	playerNode.populate(player, is_starting, is_host, mode)
	
	update_host()
	update_all_players()
	update_ui()


func update_player(playerId: int):
	update_host()
	update_all_players()
	update_ui()


func remove_player(playerId: int):
	var node := find_player_node(playerId)
	if node != null:
		playerList.remove_child(node)
	else:
		print("Lobby: remove_player: failed to find node for player: %d" % playerId)
	
	update_host()
	update_all_players()
	update_ui()


func repopulate_player(playerId: int):
	var player := GameData.get_player(playerId)
	var mode = Maps.get_mode_for_map(GameData.general[GameData.GENERAL_MAP])
	
	var node := find_player_node(playerId)
	if node != null:
		node.populate(player, is_starting, is_host, mode)
	else:
		print("repopulate_player() - Failed to get player node")


func find_player_node(playerId: int) -> Control:
	var playerNode: Control = null
	
	var nodeName := str(playerId)
	for child in playerList.get_children():
		if child.name == nodeName:
			playerNode = child
			break
	
	return playerNode


func update_game_data(generalData: Dictionary):
	var mapId = generalData[GameData.GENERAL_MAP]
	
	mapSelect.select(mapId)
	update_map_description(mapId)


func update_map_description(mapId: int):
	var resolver = Maps.get_team_resolver(mapId)
	var mapData = Maps.directory[mapId]
	
	var description := ""
	description += "Mode: %s |" % mapData[Maps.MAP_MODE]
	description += "Size: %s\n" % mapData[Maps.MAP_SIZE]
	
	description += "\nTeam Sizes:\n"
	
	var teamSizes = mapData[Maps.MAP_TEAM_SIZES]
	for teamId in teamSizes.size():
		var teamSize = teamSizes[teamId]
		description += "%s: %d\n" % [resolver.get_team_name(teamId), teamSize]
	
	description += "\nDescription:\n%s\n" % mapData[Maps.MAP_DESCRIPTION]
	
	mapDescription.text = description


func update_all_players():
	if not GameData.players.empty():
		for playerId in GameData.players:
			repopulate_player(playerId)
		
		# Ensure clients are in the same order for everyone
		var playerIds = GameData.players.keys()
		if playerIds.size() == playerList.get_children().size():
			playerIds.sort()
			for ii in range(playerIds.size()):
				var playerId = playerIds[ii]
				var node := find_player_node(playerId)
				if node != null:
					node.get_parent().move_child(node, ii)


func can_start() -> bool:
	var canStart := false
	
	var numSeekers := 0
	var numHiders := 0
	
	var players = GameData.get_players()
	
	var mapid = GameData.general[GameData.GENERAL_MAP]
	var teamSizes := Maps.get_team_sizes_for_map(mapid)
	var actualTeamSizes = []
	for ii in teamSizes.size():
		actualTeamSizes.push_back(0)
	
	if not players.empty():
		for player in players:
			var playerteam = player.get_type()
			actualTeamSizes[playerteam] += 1
	
	var teamSizesAreValid = true
	for ii in teamSizes.size():
		var maxSize = teamSizes[ii]
		var actualSize = actualTeamSizes[ii]
		
		if actualSize <= 0 or actualSize > maxSize:
			teamSizesAreValid = false
			break
	
	canStart = teamSizesAreValid
	
	return canStart


func on_start_game():
	print("on_start_game() MUST BE IMPLEMENTED")
	assert(false)


# Update if this local client is the host
func update_host():
	var host := GameData.get_host() as PlayerData
	if host != null and host.get_id() == get_tree().get_network_unique_id():
		is_host = true
	else:
		is_host = false


func update_ui():
	mapSelect.disabled = not is_host or is_starting


func on_start_lobby_countdown():
	is_starting = true
	update_all_players()
	update_ui()


func _on_MapButton_item_selected(id):
	GameData.general[GameData.GENERAL_MAP] = id
	update_map_description(id)
	ClientNetwork.update_game_data()


func on_make_host(playerId: int):
	ServerNetwork.make_host(playerId)


func on_kick_player(playerId: int):
	ServerNetwork.kick_player(playerId)
