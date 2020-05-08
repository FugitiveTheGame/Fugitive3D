extends Node
class_name FugitivePlayerDataUtility


const STATS := "stats"
const STAT_HIDER_FROZEN := "hider_frozen"
const STAT_HIDER_UNFREEZER := "hider_unfreezer"
const STAT_HIDER_UNFROZEN := "hider_unfrozen"
const STAT_HIDER_ESCAPED := "hider_escaped"
const STAT_SEEKER_FROZEN := "seeker_frozen"
const STAT_GAMES := "games"
const STAT_WINS := "wins"

const human_readable = {
	STAT_HIDER_FROZEN: "Times Captured",
	STAT_HIDER_UNFREEZER: "Allies Rescued",
	STAT_HIDER_UNFROZEN: "Times Rescued",
	STAT_HIDER_ESCAPED: "Times Escaped",
	STAT_SEEKER_FROZEN: "Fugitives Arrested",
	STAT_GAMES: "Games",
	STAT_WINS: "Wins"
}


static func get_stat_name(statId: String) -> String:
	return human_readable[statId]


static func calculate_score_player_id(playerId: int) -> int:
	return calculate_score(GameData.get_player(playerId))


static func calculate_score(playerData: PlayerData) -> int:
	var score := 0
	
	var escape_multiplier := 3
	var win_multiplier := 2
	
	var stats = get_stats(playerData)
	if not stats.empty():
		score += get_stat(playerData, STAT_HIDER_FROZEN)
		score += get_stat(playerData, STAT_HIDER_UNFREEZER)
		score += get_stat(playerData, STAT_HIDER_UNFROZEN)
		score += get_stat(playerData, STAT_SEEKER_FROZEN)
		score += get_stat(playerData, STAT_HIDER_ESCAPED) * 3
		score += get_stat(playerData, STAT_WINS) * 2
	
	return score


static func get_stats(playerData: PlayerData) -> Dictionary:
	if not playerData.player_data_dictionary.has(STATS):
		print("STATS - No stats for player %s" % playerData.get_id())
		playerData.player_data_dictionary.stats = {}
	
	return playerData.player_data_dictionary.stats


static func get_stat(playerData: PlayerData, stat_key: String) -> int:
	var stats := get_stats(playerData)
	if stats.has(stat_key):
		return stats[stat_key]
	else:
		return 0


static func increment_stat_for_player_id(playerId: int, identifier: String, step: int = 1):
	print("STATS - Incrementing %s for player %s" % [identifier, playerId])
	increment_stat(GameData.get_player(playerId), identifier, step)


static func increment_stat(playerData: PlayerData, identifier: String, step: int = 1):
	var stats = get_stats(playerData)
	if not stats.has(identifier):
		print("STATS - New stat %s for player %s" % [identifier, playerData.get_id()])
		stats[identifier] = 0
	stats[identifier] += step
	print("STATS - Incrementing stat %s for player %s.  New value: %d" % [identifier, playerData.get_id(), stats[identifier]])
	ClientNetwork.update_player(playerData)


static func reset_stats():
	for player in GameData.get_players():
		reset_stats_for_player(player)


static func reset_stats_for_player(playerData: PlayerData):
	print("STATS - Resetting stats for player %s" % playerData.get_id())
	playerData.player_data_dictionary.stats = {}
	ClientNetwork.update_player(playerData)
