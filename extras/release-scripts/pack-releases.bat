@echo off

powershell New-Item -Path "." -Name "releases" -ItemType "directory"

echo --=== Packing Windows Flat ===--
powershell Remove-Item releases/Fugitive3D_Client_Flat_Windows.zip
powershell Remove-Item ../../export/client/flat/windows/godot_oculus.dll
powershell Remove-Item ../../export/client/flat/windows/libgodot_openvr.dll
powershell Remove-Item ../../export/client/flat/windows/openvr_api.dll
powershell Copy-Item -Path ../win-dependencies/vcruntime140.dll -Destination ../../export/client/flat/windows/
powershell Copy-Item -Path ../win-dependencies/vcruntime140_1.dll -Destination ../../export/client/flat/windows/
powershell Compress-Archive -Path ../../export/client/flat/windows/* -CompressionLevel Optimal -DestinationPath releases/Fugitive3D_Client_Flat_Windows.zip


echo --=== Packing Linux Flat ===--
powershell Remove-Item releases/Fugitive3D_Client_Flat_Linux.zip
powershell Remove-Item ../../export/client/flat/linux/libgodot_openvr.so
powershell Remove-Item ../../export/client/flat/linux/libopenvr_api.so
powershell Compress-Archive -Path ../../export/client/flat/linux/* -CompressionLevel Optimal -DestinationPath releases/Fugitive3D_Client_Flat_Linux.zip


echo --=== Packing OSX Flat ===--
powershell Remove-Item releases/Fugitive3D_Client_Flat_OSX.zip
powershell Copy-Item -Path ../../export/client/flat/osx/Fugitive3D_Client_Flat_OSX.zip -Destination releases/Fugitive3D_Client_Flat_OSX.zip


echo --=== Packing Android Flat ===--
powershell Remove-Item releases/Fugitive3D_Client_Flat_Android.apk
powershell Copy-Item -Path ../../export/client/flat/android/Fugitive3D_Client_Flat_Android.apk -Destination releases/Fugitive3D_Client_Flat_Android.apk


echo --=== Packing Quest VR ===--
powershell Remove-Item releases/Fugitive3D_Client_VR_Quest.apk
powershell Copy-Item -Path ../../export/client/vr/quest/Fugitive3D_Client_VR_Quest.apk -Destination releases/Fugitive3D_Client_VR_Quest.apk


echo --=== Packing Windows VR ===--
powershell Remove-Item releases/Fugitive3D_Client_VR_Windows.zip
powershell Copy-Item -Path ../win-dependencies/vcruntime140.dll -Destination ../../export/client/vr/windows/
powershell Copy-Item -Path ../win-dependencies/vcruntime140_1.dll -Destination ../../export/client/vr/windows/
powershell Compress-Archive -Path ../../export/client/vr/windows/* -CompressionLevel Optimal -DestinationPath releases/Fugitive3D_Client_VR_Windows.zip

echo --=== Packing Oculus PCVR ===--
powershell Remove-Item releases/Fugitive3D_Client_VR_Oculus_Windows.zip
powershell Copy-Item -Path ../win-dependencies/vcruntime140.dll -Destination ../../export/client/vr/windows/
powershell Copy-Item -Path ../win-dependencies/vcruntime140_1.dll -Destination ../../export/client/vr/windows/
powershell Remove-Item ../../export/client/vr/oculus-rift/openvr_api.dll
powershell Remove-Item ../../export/client/vr/oculus-rift/libgodot_openvr.dll
powershell Compress-Archive -Path ../../export/client/vr/oculus-rift/* -CompressionLevel Optimal -DestinationPath releases/Fugitive3D_Client_VR_Oculus_Windows.zip

echo --=== Packing Windows Server ===--
powershell Remove-Item releases/Fugitive3D_Server_Windows.zip
powershell Remove-Item ../../export/server/windows/godot_oculus.dll
powershell Remove-Item ../../export/server/windows/libgodot_openvr.dll
powershell Remove-Item ../../export/server/windows/openvr_api.dll
powershell Compress-Archive -Path ../../export/server/windows/* -CompressionLevel Optimal -DestinationPath releases/Fugitive3D_Server_Windows.zip


echo --=== Packing Linux Server ===--
powershell Remove-Item releases/Fugitive3D_Server_Linux.zip
powershell Remove-Item ../../export/server/linux/libgodot_openvr.so
powershell Remove-Item ../../export/server/linux/libopenvr_api.so
powershell Compress-Archive -Path ../../export/server/linux/* -CompressionLevel Optimal -DestinationPath releases/Fugitive3D_Server_Linux.zip


echo --=== Packing OSX Server ===--
powershell Remove-Item releases/Fugitive3D_Server_OSX.zip
powershell Copy-Item -Path ../../export/server/osx/Fugitive3D_Server_OSX.x86_64.zip -Destination releases/Fugitive3D_Server_OSX.x86_64.zip

PAUSE