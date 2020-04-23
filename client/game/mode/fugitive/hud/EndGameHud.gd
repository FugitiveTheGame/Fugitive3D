extends Control

func _ready():
	$HidersLabel.hide()
	$SeekersLabel.hide()
	
	hide()


func team_won(winningTeam: int):
	match winningTeam:
		GameData.PlayerType.Hider:
			$HidersLabel.show()
			$SeekersLabel.hide()
		GameData.PlayerType.Seeker:
			$HidersLabel.hide()
			$SeekersLabel.show()
		_:
			print("Invalid winning team: %d" % winningTeam)
			assert(false)
	
	show()
