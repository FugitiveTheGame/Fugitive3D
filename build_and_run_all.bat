@echo off
# Build the client
taskkill /IM "FlatClient.exe" /F
godot.windows.opt.tools.64.exe --export-debug "Client Flat - Windows Desktop" export\client\flat\windows\FlatClient.exe

# Build the server
taskkill /IM "Server.exe" /F
godot.windows.opt.tools.64.exe --export-debug "Server - Windows Desktop" export/server/Server.exe

# Run a whole game
start cmd /k run_all.bat