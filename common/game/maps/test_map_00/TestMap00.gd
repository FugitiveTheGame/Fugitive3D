extends "res://common/game/mode/default/GameMode_Default.gd"

func _ready():
	GameData.add_player(1, "real player", GameData.PlayerType.Seeker)
	$Players/local_player.set_network_master(1)
	$Players/local_player.set_name(str(1))
	
	GameData.add_player(2, "dumb donkey 0", GameData.PlayerType.Hider)
	$Players/hider00.set_network_master(2)
	$Players/hider00.set_name(str(2))
	
	GameData.add_player(3, "dumb donkey 1", GameData.PlayerType.Hider)
	$Players/hider01.set_network_master(3)
	$Players/hider01.set_name(str(3))
	
	get_tree().paused = false
