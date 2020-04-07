# Fugitive 3D
It's Fugitive, with more Ds.

## Clients:
**Flat:** This is the normal 3D client

**VR:** This client should run on both Oculus Quest as well as PC VR

## Server:
Download the Server [from here](https://godotengine.org/download/server)
(server, not headless!)

Extract it to: `<root>/export/server` 

Then in Godot, add an Export preset:
`Linux/X11` named: `Linux - Server`

Select your new preset, and click `Export PCK/ZIP`
Export it as `data.pck` and save it to: `<root>/export/server`

Now if you're on Windows, you need Windows Subsystem for Linux (WSL) setup. I'm using Ubuntu as my distro on top of WSL:

[WSL setup](https://docs.microsoft.com/en-us/windows/wsl/install-win10)

[Ubuntu WSL](https://ubuntu.com/wsl)

With that setup, if you have Windows Explorer open to `<root>/export/server` you can Shift + Right Click and select `Open Linux shell here`

And execute this:
`./Godot_v3.2.1-stable_linux_server.64 --main-pack data.pck`

Personally I've created a shell script that contains that line called `run.sh` in that directory to make it quicker.

## Quick Dev
To truly test things out, you need to run the server, spin up and connect multiple clients. It can all be done on one box, but it makes itteration times quite slow.

To allow for much quicker itteration times, there is a scene called: `Game-dev.tscn`

You can run this scene directly, and it will load the map: `TestMap01_dev.tscn`

You can just edit `Game-dev.gd` to change which map it loads, but it can't load just any normal map. Take a look at `TestMap01_dev.tscn` and `TestMap01_dev.gd` to see what needs to be done to make a map loadable locally.

### Setting up a map for local testing
Create a new scene that inherits from the map you wish to load locally. Add some instances of `RemoteHider.tscn` to the `Players` node. Then add an instance of either `FlatClientSeeker.tscn` or `FlatClientHider.tscn`.

Next you need to extend the script on the scene root.
You need to manually initialze some of the game data, and then unpause the game:

```gdscript
func _ready():
	GameData.add_player(1, "real player", GameData.PlayerType.Seeker)
	$Players/local_player.set_network_master(1)
	$Players/local_player.set_name(str(1))
	
	GameData.add_player(2, "dumb donkey 0", GameData.PlayerType.Hider)
	$Players/hider_00.set_network_master(2)
	$Players/hider_00.set_name(str(2))
	
	GameData.add_player(3, "dumb donkey 1", GameData.PlayerType.Hider)
	$Players/hider_01.set_network_master(3)
	$Players/hider_01.set_name(str(3))
	
	get_tree().paused = false
```
