1) Apply credentials patch in git
2) Increment version codes on all exports in Godot
3) Export All from Godot (Release)
4) run pack-releases.bat (this requires Godot on your path)
5) Update version.txt (in this dir)
6) run itch-push-all.bat (this requires itch butler to be setup)
7) Upload Quest build to GitHub releases
8) Upload Google Play build to Google Play (binaries in: export\client\flat\android\google_play)
9) Upload Rift build to Oculus.com [waiting on aproval]
10) Upload Rift build to Stean [waiting on aproval]
11) Update latest_version.json (on fugitive webserver)
12) Log into fugitivegameserver00
	11a) Run ~/scripts/update_servers.sh