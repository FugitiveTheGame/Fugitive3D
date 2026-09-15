# Development

## Quick Dev
To truly test things out, you need to run the server, spin up and connect multiple clients. It can all be done on one box, but it makes itteration times quite slow.

To allow for much quicker itteration times, there is a scene called: `Game-dev.tscn`

You can run this scene directly, and it will load the map: `TestMap01_dev.tscn`

You can just edit `Game-dev.gd` to change which map it loads, but it can't load just any normal map. Take a look at `TestMap01_dev.tscn` and `TestMap01_dev.gd` to see what needs to be done to make a map loadable locally.

### Setting up a map for local testing
1. Open `Game-dev.gd` and change the map path to the map you wish to load.
2. Run the `Game-dev.tsch` scene directly ( **F6** )

### Running the VR client from the editor
OpenXR is only enabled for exports tagged `vr`, so flat and server builds no
longer talk to the OpenXR loader at all. An editor run has to turn it back on
by hand: put `--xr-mode on --vr` in *Project Settings > Editor > Run > Main Run
Args*. Without `--xr-mode on` the client logs `OpenXR failed to initialize` and
drops back to the flat menu.

`xr/openxr/extensions/hand_tracking` in `project.godot` is not a Godot 4.7
setting. The `godotopenxrvendors` GDExtension still reads it, so declaring it
keeps `Property not found` out of editor runs. Exported builds print it once
anyway, because the extension reads it before the packed settings are loaded.

## Local testing with real clients
There are scripts in `extras/scripts` to accelerate this:
- `build_and_run_all.bat` will re-export both FlatClient and Server for Windows, then run the server, and then run 3 clients, all of whom will auto-connect to the server, each with unique names.
- `run_all.bat` will just run 3 clients, all of whom will auto-connect to the server, each with unique names.
- `run_client.bat` will run a single client, accepting 2 parameters:
	1) Player Name
	2) IP address to connect to
- `run_server.bat` will run a windows server

## Running a server from the Godot editor

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

## AI Fugitives

On the server each bot walks a 2m grid built from the map's ground tiles and a physics probe (`common/game/mode/fugitive/ai/NavGrid.gd`), which costs roads and street-lit cells higher so routes favour yards and cover. The behaviour itself lives in `server/game/mode/fugitive/ai/AiHiderBrain.gd`: sprint for the safe zone during the headstart, walk it afterwards, crouch behind cover when a cop is in view or was seen recently, flee when caught in the light, and detour to unfreeze a nearby teammate when that does not cost it its own escape. Since the round is won the moment every hider still on their feet is home, a bot never turns back for a friend once it is the last one out, nor on the last of the clock. A bot only knows about cops it has a line of sight to, or a car within earshot.

The difficulty picked in the lobby selects a profile in `common/game/mode/fugitive/ai/AiDifficulty.gd` that the brain and body read: how fast the bot moves, how often it thinks, how far it notices a cop and how long it remembers one, how choosy it is about hiding spots, whether its routes bend around cops it has seen, whether it will sprint at all once the cops are out, and how often it wanders off its route on the way in. Easy bots dawdle and drift, hard bots beeline at full speed and plan around every cop they have seen.

## Fugitive Mapping Best Practices
- A Fugitive can maximally run/walk about 90 meters in 10 seconds (*Each ground tile is 8x8 meters*)
- Your head start timer probably souldn't be less than 10 seconds, but can be higher as dictates by where i your map you want the fugitives to be able to reach by the time the cops catch up
- A futitive should be able to get to some sort of decision point by the time cops can catch up to them
- Win zone should have multiple entrences, or there should be multiple win zones
- Use cluster of tall features (such as pine trees) to break up sight lines, this allows hiders to break line of sight when being chased.
- Features need to break sight lines and give choice, so in a chase, a hider has a chance of escape.
- Features should provide escape routes through the use of "police features" which force the police to either expend stamina or go a longer way around. Especially good if that longer way forces them to break line of sight with the Fugitive through the use of tall features.
