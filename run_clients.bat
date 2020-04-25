@echo off
taskkill /IM "FlatClient.exe" /F
#godot.exe --export-debug "Client Flat - Windows Desktop" export\client\flat\windows\FlatClient.exe
start cmd /k run_client.bat bbbbbbbbbbbbb 127.0.0.1
timeout /t 1
start cmd /k run_client.bat ccccccccccccc 127.0.0.1
timeout /t 1
start cmd /k run_client.bat d_d_d_d_d_d_d 127.0.0.1