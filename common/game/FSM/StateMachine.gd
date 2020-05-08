extends Node
class_name StateMachine

signal state_change(new_state, transition)

export(NodePath) var listenerPath: NodePath
var listener: Node

var current_state: State = null
var states := {}
var transitions := {}


func _enter_tree():
	listener = get_node(listenerPath)


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
	if transition.from == current_state:
		#call_deferred("do_transition", transition)
		do_transition(transition)
		return true
	else:
		print("Invalid transition for current state! Current State: %s Transition: %s" % [current_state.name, transition.name])
		assert(transition.from == current_state)
		return false


func do_transition(transition: Transition):
	current_state = transition.to
	emit_signal("state_change", current_state, transition)
	
	var transitionName = "on_transiton_%s" % transition.name
	var stateName = "on_state_%s" % current_state.name
	
	if listener.has_method(transitionName):
		listener.call(transitionName, current_state, transition)
	
	if listener.has_method(stateName):
		listener.call(stateName, current_state, transition)


func is_current_state(name: String) -> bool:
	return current_state == states[name]
