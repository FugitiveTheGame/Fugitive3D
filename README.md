# Fugitive 3D
It's Fugitive, with more Ds.

## Clients:
#### Flat:
_This is the normal 3D client_

__Controls:__
- WASD - Movement
- Ctrl - Crouch
- Space - Jump
- Q (hold) - Cops Lock car
- E - Get in or out of car
- F - Toggle flashlight


#### VR:
_This client should run on both Oculus Quest as well as PC VR_

__Controls:__
- Left Stick - Movement
- Real Crouch - Crouch
- Real Jump - Jump
- X (hold) - Cops Lock car
- B - Get in or out of car
- Y - Toggle flashlight


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

To change the port that the server binds to, add this argument: `--port xxxxx`

Personally I've created a shell script that contains that line called `run.sh` in that directory to make it quicker.

## Server Arguments:
`--port xxxxx` The port to bind to, default is `31000`
`--name "My Server"` The name to show in the server browser
`--public` advertises to the public Server Repository.

## Quick Dev
To truly test things out, you need to run the server, spin up and connect multiple clients. It can all be done on one box, but it makes itteration times quite slow.

To allow for much quicker itteration times, there is a scene called: `Game-dev.tscn`

You can run this scene directly, and it will load the map: `TestMap01_dev.tscn`

You can just edit `Game-dev.gd` to change which map it loads, but it can't load just any normal map. Take a look at `TestMap01_dev.tscn` and `TestMap01_dev.gd` to see what needs to be done to make a map loadable locally.

### Setting up a map for local testing
1. Open `Game-dev.gd` and change the map path to the map you wish to load.
2. Run the `Game-dev.tsch` scene directly ( **F6** )

## Local testing with real clients
There are scripts in `extras/scripts` to accelerate this:
- `build_and_run_all.bat` will re-export both FlatClient and Server for Windows, then run the server, and then run 3 clients, all of whom will auto-connect to the server, each with unique names.
- `run_all.bat` will just run 3 clients, all of whom will auto-connect to the server, each with unique names.
- `run_client.bat` will run a single client, accepting 2 parameters:
	1) Player Name
	2) IP address to connect to
- `run_server.bat` will run a windows server