extends Object
class_name FugitiveTeamResolver

enum PlayerType { Hider, Seeker, Unset }

const NUM_TEAMS := 2

static func get_num_teams() -> int:
	return NUM_TEAMS

static func get_team_name(teamId: int) -> String:
	var teamName: String
	match teamId:
		PlayerType.Hider:
			teamName = "Fugitive"
		PlayerType.Seeker:
			teamName = "Cop"
		_:
			teamName = "---"
	
	return teamName


static func get_random_team_layout(mapId: int, numPlayers: int) -> Array:
	var teams = []
	if numPlayers < 3:
		teams.push_back(1) # Seekers
		teams.push_back(numPlayers-1) # Hiders
	elif numPlayers < 6:
		teams.push_back(2) # Seekers
		teams.push_back(numPlayers-2) # Hiders
	else:
		teams.push_back(3) # Seekers
		teams.push_back(numPlayers-3) # Hiders
	
	return teams
