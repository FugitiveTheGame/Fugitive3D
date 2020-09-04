@echo off
setlocal

echo Current Version:
type vesion.txt & echo. 

SET /P AREYOUSURE=Did you update vesion.txt (Y/[N])?
IF /I "%AREYOUSURE%" NEQ "Y" GOTO END

echo --=== Flat clients ===--

butler push --ignore godot_oculus.dll --ignore libgodot_openvr.dll --ignore openvr_api.dll ..\..\export\client\flat\windows stumpy-dog-studios/fugitive-3d:windows-flat-beta --userversion-file vesion.txt
::butler push releases/Fugitive3D_Client_Flat_Linux.zip stumpy-dog-studios/fugitive-3d:linux-flat-beta --userversion-file vesion.txt
::butler push releases/Fugitive3D_Client_Flat_OSX.zip stumpy-dog-studios/fugitive-3d:osx-flat-beta --userversion-file vesion.txt
::butler push releases/Fugitive3D_Client_Flat_Android.apk stumpy-dog-studios/fugitive-3d:android-flat-beta --userversion-file vesion.txt

::echo --=== VR Clients ===--
::butler push releases/Fugitive3D_Client_VR_Windows.zip stumpy-dog-studios/fugitive-3d:windows-vr-beta --userversion-file vesion.txt
::butler push releases/Fugitive3D_Client_VR_Quest.apk stumpy-dog-studios/fugitive-3d:quest-vr-beta --userversion-file vesion.txt

::echo --=== Servers ===--
butler push --ignore godot_oculus.dll --ignore libgodot_openvr.dll --ignore openvr_api.dll ..\..\export\server\windows stumpy-dog-studios/fugitive-3d:windows-server-beta --userversion-file vesion.txt
::butler push releases/Fugitive3D_Server_Linux.zip stumpy-dog-studios/fugitive-3d:linux-server-beta --userversion-file vesion.txt
::butler push releases/Fugitive3D_Server_OSX.x86_64.zip stumpy-dog-studios/fugitive-3d:osx-server-beta --userversion-file vesion.txt

:END
endlocal