@echo off
setlocal

echo Current Version:
type vesion.txt & echo. 

SET /P AREYOUSURE=Did you update vesion.txt (Y/[N])?
IF /I "%AREYOUSURE%" NEQ "Y" GOTO END

echo --=== Flat clients ===--
butler push releases/Fugitive3D_Client_Flat_Windows.zip stumpy-dog-studios/fugitive-3d:windows-flat --userversion-file vesion.txt
butler push releases/Fugitive3D_Client_Flat_Linux.zip stumpy-dog-studios/fugitive-3d:linux-flat --userversion-file vesion.txt
butler push releases/Fugitive3D_Client_Flat_OSX.zip stumpy-dog-studios/fugitive-3d:osx-flat --userversion-file vesion.txt
butler push releases/Fugitive3D_Client_Flat_Android.apk stumpy-dog-studios/fugitive-3d:android-flat --userversion-file vesion.txt

echo --=== VR Clients ===--
butler push releases/Fugitive3D_Client_VR_Windows.zip stumpy-dog-studios/fugitive-3d:windows-vr --userversion-file vesion.txt
butler push releases/Fugitive3D_Client_VR_Quest.apk stumpy-dog-studios/fugitive-3d:quest-vr --userversion-file vesion.txt

echo --=== Servers ===--
butler push releases/Fugitive3D_Server_Windows.zip stumpy-dog-studios/fugitive-3d:windows-server --userversion-file vesion.txt
butler push releases/Fugitive3D_Server_Linux.zip stumpy-dog-studios/fugitive-3d:linux-server --userversion-file vesion.txt
butler push releases/Fugitive3D_Server_OSX.x86_64.zip stumpy-dog-studios/fugitive-3d:osx-server --userversion-file vesion.txt

:END
endlocal