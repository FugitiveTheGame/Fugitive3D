# Fugitive 3D
It's Fugitive, with more Ds.

## Clients:
**Flat:** This is the normal 3D client

**VR:** This client should run on both Oculus Quest as well as PC VR

## Server:
Download the Server from here:
https://godotengine.org/download/server
(server, not headless!)

Extract it to: `<root>/export/server`

Then in Godot, add an Export preset:
`Linux/X11` named: `Linux - Server`

Select your new preset, and click `Export PCK/ZIP`
Export it as `data.pck` and save it to: `<root>/export/server`

Now if you're on Windows, you need Windows Subsystem for Linux (WSL) setup. I'm using Ubuntu as my distro on top of WSL:
WSL setup: https://docs.microsoft.com/en-us/windows/wsl/install-win10
Ubuntu WSL: https://ubuntu.com/wsl

With that setup, if you have Windows Explorer open to `<root>/export/server` you can Shift + Right Click and select `Open Linux shell here`

And execute this:
`./Godot_v3.2.1-stable_linux_server.64 --main-pack data.pck`

Personally I've created a shell script that contains that line called `run.sh` in that directory to make it quicker.
