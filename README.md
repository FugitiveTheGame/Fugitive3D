# Fugitive 3D
It's Fugitive, with more Ds.

## Clients:
Download Releases here:
- https://wavesonics.itch.io/fugitive-3d
- https://sidequestvr.com/app/1192
- https://play.google.com/store/apps/details?id=com.darkrockstudios.games.fugitive3d

#### Flat:
_This is the normal 3D client_

__Controls:__
- WASD - Movement
- Ctrl - Crouch
- Space - Jump
- Q (hold) - Cops Lock car
- E - Get in or out of car
- F - Toggle flashlight
- M (hold) - Map


#### VR:
_This client should run on both Oculus Quest as well as PC VR_

__Controls:__
On Foot:
- Left Stick - Movement
- Real Crouch - Crouch
- [Not in VR] - Jump
- A - Sprint
- B - Toggle flashlight
- X (hold) - Cops Lock car
- Left Stick In - Map
- Y - Toggle HUD (_Better FPS on Quest with HUD off_)

In Car:
- Left Stick - Movement
- Left Trigger - Honk Horn
- A - Get in or out of car
- Right Trigger - Break Car



## Server:

### Docker

The quickest way to run a dedicated server. Every release publishes
`ghcr.io/fugitivethegame/fugitive3d-server` (tags `X.Y.Z` and `latest`):

```bash
docker run -d --name fugitive3d -p 31000:31000/udp \
  -e SERVER_NAME="My Server" \
  ghcr.io/fugitivethegame/fugitive3d-server:latest
```

Or with `docker/compose.yaml`, which also persists the server's identity
across restarts:

```bash
cd docker
docker compose up -d
docker compose logs -f    # expect "Server started."
```

Environment: `SERVER_NAME`, `SERVER_PORT` (default `31000`, UDP) and
`SERVER_FLAGS` for anything else, such as `--public`. Players on the same LAN
see the server in the in-game browser automatically; `--public` lists it for
everyone, and needs the UDP port forwarded to the host, because the server
repository pings it back at boot and the server exits if that fails.

To build the image yourself from a release: `docker build --build-arg
VERSION=v0.8.0 -t fugitive3d-server docker/`.

### From the Godot editor

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

## Releasing

Releases are built and published by GitHub Actions
(`.github/workflows/release.yml`). Push an annotated semver tag and the
workflow does the rest:

```bash
git tag -a v0.8.0 -m "Fugitive 3D 0.8.0" -m "What changed, one item per line."
git push origin v0.8.0
```

The tag body becomes the release notes, the Google Play "What's new" text and
the Discord announcement, so write it for players. The workflow:

1. Exports every preset in `export_presets.cfg` headlessly with the Godot
   version in `.godot-version`, stamping `X.Y.Z` into the presets and an
   Android version code of `major*10000 + minor*100 + patch` (`v0.8.0` is
   `800`). `GAME_VERSION` in `common/UserData.gd` is the network protocol
   number and is bumped by hand, separately.
2. Creates the GitHub release with every build attached: zipped desktop
   builds (binary, `.pck`, GDExtension libraries, and the MSVC runtime on
   Windows), the two APKs and the Play AAB.
3. Pushes the itch.io channels with butler and uploads the AAB to the Google
   Play production track with fastlane.
4. Publishes the dedicated server as a Docker image (see below) and tells the
   official game servers to install the new Linux server build.
5. Posts to the Discord release channel. If that step is the only failure,
   the `Announce Release` workflow re-sends it for a given tag.

Three legs can also be run on their own from the Actions tab, to retry one
that failed without repeating a whole release. Each takes a tag and works on
any tag that already has a release:

- `Publish to Google Play` uploads that release's AAB. It defaults to the
  internal track with "validate only" checked, which exercises the service
  account without publishing, so it doubles as the credential check. Uncheck
  it to promote a build to another track.
- `Update Game Servers` installs a tag on the official servers, which is also
  how you roll them back and how to check the webhook without releasing.
- `Announce Release` posts the Discord message.

Windows builds currently ship without an embedded executable icon or version
metadata. Godot 4.7 rewrites those into the .exe itself, having dropped
rcedit, and that code aborts when the Linux export host writes a Windows
executable, taking the whole export with it. The Windows Godot does it fine,
so re-enabling `application/modify_resources` on the four Windows presets
depends on either a Godot fix or moving those presets to a Windows runner.

### Secrets

Set these under the repository's Actions secrets:

| Secret | Purpose |
| --- | --- |
| `GAME_KEYS_JSON` | Contents of `keys.json` (see `keys.json.example`); packed into the client |
| `ANDROID_KEYSTORE_BASE64` | The upload keystore, base64 encoded |
| `ANDROID_KEYSTORE_ALIAS` | Key alias in that keystore |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password (key password must match; Godot signs with one) |
| `BUTLER_API_KEY` | itch.io API key |
| `GOOGLE_PLAY_JSON` | Play Console service account JSON with release rights on the app |
| `SERVER_DEPLOY_WEBHOOK_URL` | Base URL of the game servers' webhook receiver |
| `SERVER_DEPLOY_WEBHOOK_SECRET` | Shared secret that signs the server update request |
| `DISCORD_WEBHOOK` | Discord channel webhook URL |

### Dry runs

Run the `Release` workflow by hand from any branch with `dry_run` checked
(the default). It builds and packages everything and uploads the result as
the `release-artifacts` workflow artifact without publishing anywhere.

The same scripts run locally, which is the fastest way to debug an export:

```bash
VERSION=0.0.1 VERSION_CODE=1 bash .github/scripts/set-version.sh
GODOT_BIN=/path/to/godot bash .github/scripts/export-all.sh
VERSION=0.0.1 VERSION_CODE=1 bash .github/scripts/package-artifacts.sh
```

Android exports need `JAVA_HOME` and `ANDROID_HOME` set before the first
Godot run, a `keys.json` in the project root, and the release keystore in
`GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `_USER` and `_PASSWORD`. Restore
`export_presets.cfg` afterwards; `set-version.sh` edits it in place.

## Server Arguments:
- `--port xxxxx` The port to bind to, default is `31000`
- `--name "My Server"` The name to show in the server browser
- `--public` advertises to the public Server Repository.
- `--nolan` prevents advertising to LAN clients
- `--nostats` prevents reporting of anonymous gameplay stats
- `--fps` print server FPS to log periodically


## AI Fugitives

The host (the first player to join, until they leave) is the server's admin and the only one who can add AI players, from the lobby's `Add AI Fugitive` button and the Easy / Medium / Hard picker beside it, or remove them through the Kick menu. The server enforces this regardless of what a client sends. The same lobby panel serves flat and VR clients. Bots only ever play as Fugitives, count toward the map's Fugitive team size, and can be removed with the same Kick menu as a human. They are driven entirely by the dedicated server: clients see them as ordinary remote hiders.

On the server each bot walks a 2m grid built from the map's ground tiles and a physics probe (`common/game/mode/fugitive/ai/NavGrid.gd`), which costs roads and street-lit cells higher so routes favour yards and cover. The behaviour itself lives in `server/game/mode/fugitive/ai/AiHiderBrain.gd`: sprint for the safe zone during the headstart, walk it afterwards, crouch behind cover when a cop is in view or was seen recently, flee when caught in the light, and detour to unfreeze a nearby teammate when that does not cost it its own escape. Since the round is won the moment every hider still on their feet is home, a bot never turns back for a friend once it is the last one out, nor on the last of the clock. A bot only knows about cops it has a line of sight to, or a car within earshot.

The difficulty picked in the lobby selects a profile in `common/game/mode/fugitive/ai/AiDifficulty.gd` that the brain and body read: how fast the bot moves, how often it thinks, how far it notices a cop and how long it remembers one, how choosy it is about hiding spots, whether its routes bend around cops it has seen, whether it will sprint at all once the cops are out, and how often it wanders off its route on the way in. Easy bots dawdle and drift, hard bots beeline at full speed and plan around every cop they have seen.

## Quick Dev
To truly test things out, you need to run the server, spin up and connect multiple clients. It can all be done on one box, but it makes itteration times quite slow.

To allow for much quicker itteration times, there is a scene called: `Game-dev.tscn`

You can run this scene directly, and it will load the map: `TestMap01_dev.tscn`

You can just edit `Game-dev.gd` to change which map it loads, but it can't load just any normal map. Take a look at `TestMap01_dev.tscn` and `TestMap01_dev.gd` to see what needs to be done to make a map loadable locally.

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

## Fugitive Mapping Best Practices
- A Fugitive can maximally run/walk about 90 meters in 10 seconds (*Each ground tile is 8x8 meters*)
- Your head start timer probably souldn't be less than 10 seconds, but can be higher as dictates by where i your map you want the fugitives to be able to reach by the time the cops catch up
- A futitive should be able to get to some sort of decision point by the time cops can catch up to them
- Win zone should have multiple entrences, or there should be multiple win zones
- Use cluster of tall features (such as pine trees) to break up sight lines, this allows hiders to break line of sight when being chased.
- Features need to break sight lines and give choice, so in a chase, a hider has a chance of escape.
- Features should provide escape routes through the use of "police features" which force the police to either expend stamina or go a longer way around. Especially good if that longer way forces them to break line of sight with the Fugitive through the use of tall features.
