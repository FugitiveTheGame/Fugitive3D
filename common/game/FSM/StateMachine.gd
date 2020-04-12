extends Node
class_name StateMachine

signal state_change(new_state, transition)

export(NodePath) var ownerPath: NodePath
onready var listener := get_node(ownerPath)

var current_state: State = null
var states := {}
var transitions := {}


func create_state(name: String) -> State:
	var state := State.new(name)
	states[name] = state
	return state


func create_transition(name: String, from: State, to: State) -> Transition:
	var transition := Transition.new(name, from, to)
	transitions[name] = transition
	return transition


func set_initial_state(state: State):
	current_state = state


func transition_by_name(name: String) -> bool:
	var transition := transitions[name] as Transition
	return transition(transition)


func transition(transition: Transition) -> bool:
	assert(transition.from == current_state)
	
	if transition.from == current_state:
		#call_deferred("do_transition", transition)
		do_transition(transition)
		return true
	else:
		
		print("Invalid transition for current state! Current State: %s Transition: %s" % [current_state.name, transition.name])
		return false


func do_transition(transition: Transition):
	current_state = transition.to
	emit_signal("state_change", current_state, transition)
	
	var transitionName = "on_transiton_%s" % transition.name
	var stateName = "on_state_%s" % current_state.name
	
	if owner.has_method(transitionName):
		owner.call(transitionName, current_state, transition)
	
	if owner.has_method(stateName):
		owner.call(stateName, current_state, transition)


func is_current_state(name: String) -> bool:
	return current_state == states[name]
