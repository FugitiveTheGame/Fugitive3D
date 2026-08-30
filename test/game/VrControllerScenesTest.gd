extends GdUnitTestSuite

# The VR rig was rebuilt on OpenXR and godot-xr-tools. These checks catch
# broken scene references, missing scripts and dangling signal connections
# without needing a headset: instantiating resolves all of them.

const SCENES := [
	"res://client/game/player/controller/vr/VrPlayerController.tscn",
	"res://client/game/mode/fugitive/VrFugitiveController.tscn",
	"res://client/game/mode/fugitive/hider/vr/VrHiderController.tscn",
	"res://client/game/mode/fugitive/seeker/vr/VrSeekerController.tscn",
	"res://client/vr_menu_player/VrMenuPlayer.tscn",
	"res://client/main_menu/vr/VrClientMainMenu.tscn",
	"res://client/lobby/vr/VrLobby.tscn",
]


func test_vr_controller_scenes_instantiate():
	for path in SCENES:
		var scene := load(path) as PackedScene
		assert_object(scene).override_failure_message("Could not load %s" % path).is_not_null()

		var node: Node = auto_free(scene.instantiate())
		assert_object(node).override_failure_message("Could not instantiate %s" % path).is_not_null()


func test_role_scenes_wire_the_game_nodes():
	for path in [SCENES[2], SCENES[3]]:
		var node: Node = auto_free((load(path) as PackedScene).instantiate())

		var player := node.get_node("Player")
		assert_object(player).override_failure_message("%s has no Player" % path).is_not_null()

		var body := node.get_node("PlayerBody")
		assert_object(body).override_failure_message("%s has no PlayerBody" % path).is_not_null()
		assert_object(body.get_node("CollisionShape3D")) \
			.override_failure_message("%s PlayerBody has no game shape" % path).is_not_null()
		assert_object(body.get_node("RemoteTransform3D")) \
			.override_failure_message("%s PlayerBody has no RemoteTransform3D" % path).is_not_null()
