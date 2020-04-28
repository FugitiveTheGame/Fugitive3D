extends Control

var playerInfo = null

onready var teamButton := $TeamButton as OptionButton
var curTeamResolver = null

func populate(player, is_starting: bool, is_host: bool, game_mode: Dictionary):
	playerInfo = player
	
	var playerId = playerInfo[GameData.PLAYER_ID]
	
	$NameLabel.text = playerInfo[GameData.PLAYER_NAME]
	$HostLabel.visible = playerInfo[GameData.PLAYER_HOST]
	
	curTeamResolver = game_mode[Maps.MODE_TEAM_RESOLVER]
	
	teamButton.clear()
	print("teams: %d" % curTeamResolver.get_num_teams())
	for ii in curTeamResolver.get_num_teams():
		var teamname = curTeamResolver.get_team_name(ii)
		print("name: %s" % teamname)
		teamButton.add_item(teamname, ii)
	
	var playerType = playerInfo[GameData.PLAYER_TYPE]
	teamButton.selected = playerType
	
	if (is_host or ClientNetwork.is_local_player(playerId)) and not is_starting:
		teamButton.disabled = false
	else:
		teamButton.disabled = true


func _on_TeamButton_item_selected(id):
	ServerNetwork.change_player_type(playerInfo[GameData.PLAYER_ID], id)
