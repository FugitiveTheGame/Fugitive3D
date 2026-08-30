extends XRToolsPlayerBody

# The game's collision body for a VR player. The role scenes hang the game's
# collision shape and a RemoteTransform3D for the Player entity off this node.

@export var playerPath: NodePath
@onready var player := (get_node(playerPath) as Player) if not playerPath.is_empty() else null


func get_player():
	return player
