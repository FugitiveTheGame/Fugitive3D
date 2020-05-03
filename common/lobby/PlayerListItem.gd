extends Control

var playerInfo: PlayerData = null

onready var teamButton := $TeamButton as OptionButton
var curTeamResolver = null

func populate(player: PlayerData, is_starting: bool, is_host: bool, game_mode: Dictionary):
	playerInfo = player
	var playerId = player.get_id()
	
	$NameLabel.text = player.get_name()
	$HostIndicator.visible = player.get_is_host()
	
	var image = Image.new()
	var iconPath := PlatformTypeUtils.platform_type_icon(player.get_platform_type())
	image.load(iconPath)
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	$PlatformIndicator.texture = texture
	
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


func _on_TeamButton_item_selected(id):
	ServerNetwork.change_player_type(playerInfo.get_id(), id)
