@echo off
cd ../../

:: Build the client
taskkill /IM "FlatClient.exe" /F
godot.windows.opt.tools.64.exe --export-debug "Client Flat - Windows" export/client/flat/windows/FlatClient.exe

:: Build the server
taskkill /IM "Server.exe" /F
godot.windows.opt.tools.64.exe --export-debug "Server - Windows" export/server/windows/Server.exe

:: Run a server with connected clients
cd extras/scripts
start cmd /k run_all.bat