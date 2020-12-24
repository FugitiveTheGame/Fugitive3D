1) Apply credentials patch in git
2) Export All from Godot (Release)
3) run pack-releases.bat (this requires Godot on your path)
4) Update version.txt (in this dir)
5) run itch-push-all.bat (this requires itch butler to be setup)
6) Upload Quest build to GitHub releases
7) Upload Google Play build to Google Play (binaries in: export\client\flat\android\google_play)
8) Upload Rift build to Oculus.com [waiting on aproval]
9) Upload Rift build to Stean [waiting on aproval]
10) Update latest_version.json (on fugitive webserver)
11) Log into fugitivegameserver00
	11a) Run ~/scripts/update_servers.sh