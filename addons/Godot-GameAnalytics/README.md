# Godot-GameAnalytics

Based of the code from Cristiano Reis Monteiro at https://github.com/Montecri/Godot-GameAnalytics

The plugin automatically adds the GameAnalytics as an AutoLoad script.

```GDScript
  # configure the keys
	GameAnalytics.game_key = "asd123"
	GameAnalytics.secret_key = "abccsd"

  # Start the session
	GameAnalytics.start_session()

  # Queue events, when we have enough events, we will submit them to the server
	GameAnalytics.queue_event(...event)

  # Stop the session when the user presses the home or back button (TODO: We could probably do this automatically)
	GameAnalytics.stop_session()
```

TODO:
  * Enable GZip compression (partially done / commented out)
  * Handle more default annotations, such as os version, ios id