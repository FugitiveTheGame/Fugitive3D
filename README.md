# Fugitive 3D
It's Fugitive, with more Ds.

- [Development](docs/DEVELOPMENT.md): quick dev scenes, running the VR client from the editor, local multi-client testing, AI internals and mapping guidelines
- [How to release](docs/HOW-TO-RELEASE.md): tag-driven releases, the manual workflows, secrets and dry runs

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


## AI Fugitives

The host (the first player to join, until they leave) is the server's admin and the only one who can add AI players, from the lobby's `Add AI Fugitive` button and the Easy / Medium / Hard picker beside it, or remove them through the Kick menu. The server enforces this regardless of what a client sends. The same lobby panel serves flat and VR clients. Bots only ever play as Fugitives, count toward the map's Fugitive team size, and can be removed with the same Kick menu as a human. They are driven entirely by the dedicated server: clients see them as ordinary remote hiders.

How the bots think is covered in [Development](docs/DEVELOPMENT.md#ai-fugitives).

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
VERSION=0.8.0 -t fugitive3d-server docker/`.

To run a server from the Godot editor instead, see
[Development](docs/DEVELOPMENT.md#running-a-server-from-the-godot-editor).

### Server Arguments:
- `--port xxxxx` The port to bind to, default is `31000`
- `--name "My Server"` The name to show in the server browser
- `--public` advertises to the public Server Repository.
- `--nolan` prevents advertising to LAN clients
- `--nostats` prevents reporting of anonymous gameplay stats
- `--fps` print server FPS to log periodically

## 🪨 Dark Rock Studios

[**Dark Rock Studios**](https://darkrock.studio/) is all about building **Free and Open Source Software**.

🐛 Found bugs?  
💡 Have suggestions?  
📚 Want to help translate?  
🎮 Interested in our other apps?  
👉 Join our community of Open Source enthusiasts on [**Discord**](https://discord.gg/49Kj5mMj6d)!
