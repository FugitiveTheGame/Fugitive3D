@echo off

FOR %%i IN (1 2 3) DO (
	start cmd /k run_client.bat %%i%%i%%i%%i%%i%%i%%i 127.0.0.1
	timeout /t 1
)

exit