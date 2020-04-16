extends Object
class_name TimeUtils


static func format_seconds_for_display(timeInSeconds: float) -> String:
	var secondsLeft := floor(timeInSeconds) as int
	secondsLeft = max(secondsLeft, 0.0) as int
	
	var minutesLeft: int = secondsLeft / 60
	var remainingSeconds: int = secondsLeft - (minutesLeft * 60)
	
	var formatted := "%d:%02d" % [minutesLeft, remainingSeconds]
	
	return formatted
