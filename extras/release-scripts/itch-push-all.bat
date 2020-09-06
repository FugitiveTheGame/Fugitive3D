@echo off
setlocal

echo Current Version:
type vesion.txt & echo. 

SET /P AREYOUSURE=Did you update vesion.txt (Y/[N])?
IF /I "%AREYOUSURE%" NEQ "Y" GOTO END

echo --=== Setup Windows Flat DLLs ===--
powershell Copy-Item -Path ../win-dependencies/vcruntime140.dll -Destination ../../export/client/flat/windows/
powershell Copy-Item -Path ../win-dependencies/vcruntime140_1.dll -Destination ../../export/client/flat/windows/

echo --=== Setup Windows VR DLLs ===--
powershell Copy-Item -Path ../win-dependencies/vcruntime140.dll -Destination ../../export/client/vr/windows/
powershell Copy-Item -Path ../win-dependencies/vcruntime140_1.dll -Destination ../../export/client/vr/windows/

echo --=== Setup Windows Server DLLs ===--
powershell Copy-Item -Path ../win-dependencies/vcruntime140.dll -Destination ../../export/server/windows/
powershell Copy-Item -Path ../win-dependencies/vcruntime140_1.dll -Destination ../../export/server/windows/

:CLIENTS_FLAT
echo --=== Flat clients ===--
butler push --ignore godot_oculus.dll --ignore libgodot_openvr.dll --ignore openvr_api.dll ..\..\export\client\flat\windows stumpy-dog-studios/fugitive-3d:windows-flat --userversion-file vesion.txt
butler push --ignore libgodot_openvr.so --ignore libopenvr_api.so ..\..\export\client\flat\linux stumpy-dog-studios/fugitive-3d:linux-flat --userversion-file vesion.txt
butler push ..\..\export\client\flat\osx stumpy-dog-studios/fugitive-3d:osx-flat --userversion-file vesion.txt
butler push releases/Fugitive3D_Client_Flat_Android.apk stumpy-dog-studios/fugitive-3d:android-flat --userversion-file vesion.txt

:CLIENTS_VR
echo --=== VR Clients ===--
butler push ..\..\export\client\vr\windows stumpy-dog-studios/fugitive-3d:windows-vr --userversion-file vesion.txt
butler push releases/Fugitive3D_Client_VR_Quest.apk stumpy-dog-studios/fugitive-3d:quest-vr --userversion-file vesion.txt

:SERVERS
echo --=== Servers ===--
butler push --ignore godot_oculus.dll --ignore libgodot_openvr.dll --ignore openvr_api.dll ..\..\export\server\windows stumpy-dog-studios/fugitive-3d:windows-server --userversion-file vesion.txt
butler push --ignore libgodot_openvr.so --ignore libopenvr_api.so ..\..\export\server\linux stumpy-dog-studios/fugitive-3d:linux-server --userversion-file vesion.txt
butler push ..\..\export\server\osx stumpy-dog-studios/fugitive-3d:osx-server --userversion-file vesion.txt

:END
endlocal