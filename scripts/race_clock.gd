extends Node2D

var start_counting = false

var _minutes = 0
var _seconds = 0
var _actualmil = 0


func _ready():
	visible = false


func _process(delta):
	if start_counting:
		_actualmil += (delta*1000)
		var milsecs = remap(_actualmil, 0, 1000, 0, 60)
		milsecs = floori(milsecs)
		if _actualmil >= 1000:
			_actualmil = 0
			_seconds += 1
		if _seconds >= 60:
			_seconds = 0
			_minutes += 1
		if _minutes >= 99:
			_minutes = 99
		$Label.text = "%01d:%02d:%02d" % [_minutes, _seconds, milsecs]
