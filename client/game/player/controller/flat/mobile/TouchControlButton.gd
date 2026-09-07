extends TouchScreenButton
class_name TouchControlButton

# An on-screen button that TouchControlsLayout places into a thumb-reachable
# cluster. Slots are fixed, so a button that comes and goes with the situation
# never shuffles the ones around it.

enum Slot {
	TopLeft,
	TopRight,
	# Stacked over the movement stick, for the left thumb
	AboveLeftStick,
	# Grid inboard of the look stick, for the right thumb
	BesideRightStick,
}

@export var slot: Slot = Slot.BesideRightStick

# Counted away from the cluster's corner: column 0 is nearest it horizontally,
# row 0 nearest it vertically
@export var slot_column := 0
@export var slot_row := 0
