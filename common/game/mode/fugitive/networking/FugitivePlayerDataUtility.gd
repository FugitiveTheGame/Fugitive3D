extends Node


func get_stats(playerData: PlayerData) -> Dictionary:
	if !playerData.player_data_dictionary.has("stats"):
		print("STATS - No stats for player %s" % playerData.get_id())
		playerData.player_data_dictionary.stats = {}
	
	return playerData.player_data_dictionary.stats
	
func increment_stat_for_player_id(playerId: int, identifier: String):
	print("STATS - Incrementing %s for player %s" % [identifier, playerId])
	increment_stat(GameData.get_player(playerId), identifier)
	
func increment_stat(playerData: PlayerData, identifier: String):
	var stats = get_stats(playerData)
	if !stats.has(identifier):
		print("STATS - New stat %s for player %s" % [identifier, playerData.get_id()])
		stats[identifier] = 0
	stats[identifier] += 1
	print("STATS - Incrementing stat %s for player %s.  New value: %d" % [identifier, playerData.get_id(), stats[identifier]])
	ClientNetwork.update_player(playerData)

func reset_stats():
	for player in GameData.get_players():
		reset_stats_for_player(player)

func reset_stats_for_player(playerData: PlayerData):
	print("STATS - Resetting stats for player %s" % playerData.get_id())
	playerData.player_data_dictionary.stats = {}
	ClientNetwork.update_player(playerData)
