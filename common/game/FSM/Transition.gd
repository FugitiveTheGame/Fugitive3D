extends Object
class_name Transition

var name: String
var from: State
var to: State

func _init(_name: String, _from: State, _to: State):
	self.name = _name
	self.from = _from
	self.to = _to
