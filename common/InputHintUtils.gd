extends Object
class_name InputHintUtils

# Turns input actions into the short prompts the on-screen hints display.
# Reads the InputMap so a rebound action shows its real key.

enum Device { Keyboard, Gamepad }

const HINT_LABEL := "label"
const HINT_ACTION := "action"
const HINT_HOLD := "hold"
const HINT_KEYBOARD := "keyboard"
const HINT_GAMEPAD := "gamepad"

const UNBOUND := "--"

# Godot spells these out at more length than fits in a hint chip
const KEYCODE_NAMES := {
	KEY_ESCAPE: "Esc",
	KEY_CTRL: "Ctrl",
	KEY_SHIFT: "Shift",
	KEY_ALT: "Alt",
	KEY_SPACE: "Space",
	KEY_TAB: "Tab",
	KEY_ENTER: "Enter",
	KEY_BACKSPACE: "Bksp",
}

const JOY_BUTTON_NAMES := {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back",
	JOY_BUTTON_GUIDE: "Guide",
	JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "L Stick",
	JOY_BUTTON_RIGHT_STICK: "R Stick",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-Pad Up",
	JOY_BUTTON_DPAD_DOWN: "D-Pad Down",
	JOY_BUTTON_DPAD_LEFT: "D-Pad Left",
	JOY_BUTTON_DPAD_RIGHT: "D-Pad Right",
}

const JOY_AXIS_NAMES := {
	JOY_AXIS_LEFT_X: "Left Stick",
	JOY_AXIS_LEFT_Y: "Left Stick",
	JOY_AXIS_RIGHT_X: "Right Stick",
	JOY_AXIS_RIGHT_Y: "Right Stick",
	JOY_AXIS_TRIGGER_LEFT: "LT",
	JOY_AXIS_TRIGGER_RIGHT: "RT",
}

# A gamepad stick resting off-centre should not steal the prompts from the keyboard
const JOY_MOTION_LAMBDA := 0.5


static func hint(action: String, label: String, hold := false) -> Dictionary:
	return {
		HINT_ACTION: action,
		HINT_LABEL: label,
		HINT_HOLD: hold,
	}


# For prompts with no single action behind them, such as WASD movement
static func composite(keyboard: String, gamepad: String, label: String) -> Dictionary:
	return {
		HINT_KEYBOARD: keyboard,
		HINT_GAMEPAD: gamepad,
		HINT_LABEL: label,
		HINT_HOLD: false,
	}


static func hint_prompt(hint_data: Dictionary, device: int) -> String:
	if hint_data.has(HINT_KEYBOARD):
		return hint_data[HINT_KEYBOARD] if device == Device.Keyboard else hint_data[HINT_GAMEPAD]

	var action: String = hint_data.get(HINT_ACTION, "")
	return keyboard_prompt(action) if device == Device.Keyboard else gamepad_prompt(action)


static func hint_label(hint_data: Dictionary) -> String:
	var label: String = hint_data.get(HINT_LABEL, "")
	return "%s (hold)" % label if hint_data.get(HINT_HOLD, false) else label


static func keyboard_prompt(action: String) -> String:
	for event in action_events(action):
		if event is InputEventKey:
			return keycode_name(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
		if event is InputEventMouseButton:
			return mouse_button_name(event.button_index)
	return UNBOUND


static func gamepad_prompt(action: String) -> String:
	for event in action_events(action):
		if event is InputEventJoypadButton:
			return JOY_BUTTON_NAMES.get(event.button_index, "Button %d" % event.button_index)
		if event is InputEventJoypadMotion:
			return JOY_AXIS_NAMES.get(event.axis, "Axis %d" % event.axis)
	return UNBOUND


static func action_events(action: String) -> Array:
	if action.is_empty() or not InputMap.has_action(action):
		return []
	return InputMap.action_get_events(action)


static func keycode_name(keycode: int) -> String:
	if KEYCODE_NAMES.has(keycode):
		return KEYCODE_NAMES[keycode]
	return OS.get_keycode_string(keycode)


static func mouse_button_name(button_index: int) -> String:
	match button_index:
		MOUSE_BUTTON_LEFT:
			return "LMB"
		MOUSE_BUTTON_RIGHT:
			return "RMB"
		MOUSE_BUTTON_MIDDLE:
			return "MMB"
	return "Mouse %d" % button_index


# The device an event should switch the prompts to, or -1 when it says nothing
# about which device is in the player's hands
static func device_for_event(event: InputEvent) -> int:
	if event is InputEventKey or event is InputEventMouseButton:
		return Device.Keyboard
	if event is InputEventJoypadButton:
		return Device.Gamepad
	if event is InputEventJoypadMotion and absf(event.axis_value) > JOY_MOTION_LAMBDA:
		return Device.Gamepad
	return -1
