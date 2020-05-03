extends Control

signal make_host(playerId)
signal kick_player(playerId)

var playerInfo: PlayerData = null

onready var teamButton := $TeamButton as OptionButton
var curTeamResolver = null


func _ready():
	$HostMenuButton.get_popup().connect("id_pressed", self, "on_id_pressed")


func populate(player: PlayerData, is_starting: bool, is_host: bool, game_mode: Dictionary):
	playerInfo = player
	var playerId = player.get_id()
	
	$NameLabel.text = player.get_name()
	$HostIndicator.visible = player.get_is_host()
	
	var iconPath := PlatformTypeUtils.platform_type_icon(player.get_platform_type())
	$PlatformIndicator.texture = load(iconPath)
	
	curTeamResolver = game_mode[Maps.MODE_TEAM_RESOLVER]
	
	teamButton.clear()
	
	for ii in curTeamResolver.get_num_teams():
		var teamname = curTeamResolver.get_team_name(ii)
		teamButton.add_item(teamname, ii)
	
	var playerType := player.get_type()
	teamButton.selected = playerType
	
	if (is_host or ClientNetwork.is_local_player(playerId)) and not is_starting:
		teamButton.disabled = false
	else:
		teamButton.disabled = true
	
	$HostMenuButton.visible = is_host
	$HostMenuButton.disabled = playerId == GameData.get_current_player_id()


func _on_TeamButton_item_selected(id):
	ServerNetwork.change_player_type(playerInfo.get_id(), id)


func on_id_pressed(id):
	match id:
		0:
			emit_signal("make_host", playerInfo.get_id())
		1:
			emit_signal("kick_player", playerInfo.get_id())
