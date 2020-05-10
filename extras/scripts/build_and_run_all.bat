@echo off
cd ../../

:: Build the client
taskkill /IM "Fugitive3D_Client_Flat_Windows.exe" /F
godot.windows.opt.tools.64.exe --export-debug "Client Flat - Windows" export/client/flat/windows/Fugitive3D_Client_Flat_Windows.exe

:: Build the server
taskkill /IM "Fugitive3D_Server_Windows.exe" /F
godot.windows.opt.tools.64.exe --export-debug "Server - Windows" export/server/windows/Fugitive3D_Server_Windows.exe

:: Run a server with connected clients
cd extras/scripts
start cmd /k run_all.bat