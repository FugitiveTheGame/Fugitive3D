extends Node
class_name ServerReporter

const BASE_URL := "https://fugitivethegame.online/server_stats.php"
const SERVER_ID_PATH := "user://SERVER_ID"

onready var request := $HTTPRequest

var serverId: String

var serverName: String
var externalIp: String = "[private]"
var serverPort: int


static func get_instance(tree: SceneTree):
	return tree.root.get_node("ServerReporter")


func _enter_tree():
	# Load or create unique server ID
	var dir := Directory.new()
	if dir.file_exists(SERVER_ID_PATH):
		print("Reading server id")
		
		var file := File.new()
		file.open(SERVER_ID_PATH, File.READ)
		serverId = file.get_as_text()
		file.close()
	else:
		print("Creating server id")
		serverId = UUID.v4()
		
		var file := File.new()
		file.open(SERVER_ID_PATH, File.WRITE)
		file.store_line(serverId)
		file.close()
	
	print("Server ID: " + serverId)



func configure(ip, port: int, thisName: String):
	if ip != null:
		externalIp = ip
	serverPort = port
	serverName = thisName.percent_encode()


func add_url_params(params: Dictionary) -> String:
	var url := BASE_URL
	
	var first := true
	for paramName in params:
		var value
		
		var pValue = params[paramName]
		if pValue is Dictionary:
			value = JSON.print(pValue).percent_encode()
		else:
			value = str(params[paramName]).percent_encode()
		
		if first:
			url += "?"
			first = false
		else:
			url += "&"
		url += "%s=%s" % [paramName.percent_encode(), value]
	
	return url


func report_game_start(numPlayers: int, numFugitives: int, numCops: int, mapName: String):
	print("report_game_start")
	
	var eventData := {
		"num_fugitives" : numFugitives,
		"num_cops" : numCops
	}
	
	var params := {
		"server_id" : serverId,
		"server_name" : serverName,
		"event" : "game_start",
		"num_players" : numPlayers,
		"map_name": mapName,
		"event_data" : eventData
	}
	var url := add_url_params(params)
	
	request.request(url)


func report_game_end(numPlayers: int, numFugitives: int, numCops: int, mapName: String, winningTeam: int, secondsleft: int):
	print("report_game_end")
	
	var eventData := {
		"winning_team" : winningTeam,
		"game_length_s": secondsleft,
		"num_fugitives" : numFugitives,
		"num_cops" : numCops
	}
	
	var params := {
		"server_id" : serverId,
		"server_name" : serverName,
		"event" : "game_end",
		"num_players" : numPlayers,
		"map_name": mapName,
		"event_data" : eventData
	}
	var url := add_url_params(params)
	
	request.request(url)


func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	print_debug("Server report sent: %d" % response_code)
