extends Node
class_name FugitivePlayerDataUtility


const STATS := "stats"
const OVERALL_STATS := "overall_stats"
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

static func calculate_match_score_player_id(playerId: int) -> int:
	return calculate_match_score(GameData.get_player(playerId))
	
static func calculate_overall_score_player_id(playerId: int) -> int:
	return calculate_overall_score(GameData.get_player(playerId))
	
static func calculate_match_score(playerData: PlayerData) -> int:
	return _calculate_score_from_bucket(playerData, STATS)

static func calculate_overall_score(playerData: PlayerData) -> int:
	return _calculate_score_from_bucket(playerData, OVERALL_STATS)

static func get_match_stats(playerData: PlayerData) -> Dictionary:
	return _get_stats_bucket(playerData, STATS)

static func get_overall_stats(playerData: PlayerData) -> Dictionary:
	return _get_stats_bucket(playerData, OVERALL_STATS)

static func increment_stat_for_player_id(playerId: int, identifier: String, step: int = 1):
	print("STATS - Incrementing %s for player %s" % [identifier, playerId])
	increment_stat(GameData.get_player(playerId), identifier, step)

static func get_match_stat(playerData: PlayerData, stat_key: String) -> int:
	return _get_stat_from_bucket_name(playerData, stat_key, STATS)
	
static func get_overall_stat(playerData: PlayerData, stat_key: String) -> int:
	return _get_stat_from_bucket_name(playerData, stat_key, OVERALL_STATS)

static func increment_stat(playerData: PlayerData, identifier: String, step: int = 1):
	var stats = _get_stats_bucket(playerData, STATS)
	var overallStats = _get_stats_bucket(playerData, OVERALL_STATS)
	
	if not stats.has(identifier):
		print("STATS - New stat %s for player %s" % [identifier, playerData.get_id()])
		stats[identifier] = 0
	stats[identifier] += step
	
	if not overallStats.has(identifier):
		overallStats[identifier] = 0
	overallStats[identifier] += step
	
	print("STATS - Incrementing stat %s for player %s.  New value: %d" % [identifier, playerData.get_id(), stats[identifier]])
	ClientNetwork.update_player(playerData)


static func reset_stats():
	for player in GameData.get_players():
		reset_stats_for_player(player)


static func reset_stats_for_player(playerData: PlayerData):
	print("STATS - Resetting stats for player %s" % playerData.get_id())
	playerData.player_data_dictionary[STATS] = {}
	ClientNetwork.update_player(playerData)

### PRIVATE METHODS

static func _calculate_score_from_bucket(playerData: PlayerData, bucketName: String) -> int:
	var score := 0
	
	var escape_multiplier := 3
	var win_multiplier := 2
	
	var stats = _get_stats_bucket(playerData, bucketName)
	if not stats.empty():
		score += _get_stat_from_bucket(playerData, stats, STAT_HIDER_FROZEN)
		score += _get_stat_from_bucket(playerData, stats, STAT_HIDER_UNFREEZER)
		score += _get_stat_from_bucket(playerData, stats, STAT_HIDER_UNFROZEN)
		score += _get_stat_from_bucket(playerData, stats, STAT_SEEKER_FROZEN)
		score += _get_stat_from_bucket(playerData, stats, STAT_HIDER_ESCAPED) * escape_multiplier
		score += _get_stat_from_bucket(playerData, stats, STAT_WINS) * win_multiplier
	
	return score
	
static func _get_stats_bucket(playerData: PlayerData, bucketName: String) -> Dictionary:
	if not playerData.player_data_dictionary.has(bucketName):
		print("STATS - No %s stats for player %s" % [bucketName, playerData.get_id()])
		playerData.player_data_dictionary[bucketName] = {}
	
	return playerData.player_data_dictionary[bucketName]

static func _get_stat_from_bucket_name(playerData: PlayerData, stat_key: String, bucketName: String) -> int:
	var stats := _get_stats_bucket(playerData, bucketName)
	if stats.has(stat_key):
		return stats[stat_key]
	else:
		return 0

static func _get_stat_from_bucket(playerData: PlayerData, bucket: Dictionary, stat_key: String) -> int:
	if bucket != null and bucket.has(stat_key):
		return bucket[stat_key]
	else:
		return 0
