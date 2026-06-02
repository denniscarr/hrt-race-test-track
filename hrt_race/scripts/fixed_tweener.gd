## A rollback-safe alternative to Godot's tweening system. Add this node wherever and use it for
## your tweens.
## This is far from feature-parity with Godot's system. We'll add functionality as we need it.
class_name FixedTweener
extends Node

## Emitted when the most recent tween you started has finished
signal finished

## Returns the total duration of the current tween
var duration: int:
	get:
		return _fixed_duration

## Returns the amount of time that has elapsed within the current tween
var elapsed_time: int:
	get:
		return _fixed_elapsed

## Whether a tween is currently running
var is_tweening: int:
	get:
		return _is_tweening

var _fixed_duration: int
var _fixed_elapsed: int
var _is_tweening: bool

## The node whose property we are tweening
var _target_node: Node

## The path to the property we are tweening within [_target_node]
var _prop_path: NodePath

## The value at the beginning of the current tween
var _start_value: Variant

## The value at the end of the current tween
var _end_value: Variant

## If true, the node will convert the target property to a float before setting it
var _convert_to_float: bool = false

## The ease being used for the current tween
var _ease_type: FixedEase.EaseType

## The speed scale being applied to the current tween
var _speed_scale: int = SGFixed.ONE

# NOTE: All this commented-out stuff is not necessary for determinism, but IS necessary for
# network play. I'm leaving it here in case we ever want to add multiplayer to the game.

# func _ready() -> void:
#     add_to_group("network_sync")
#     SyncManager.set_groups_for_node(self )

# func _save_state() -> Dictionary:
#     var state := {}

#     state["is_tweening"] = _is_tweening

#     # To save processor time, don't store any other info if we're not tweening
#     if not _is_tweening:
#         return state

#     state["target_node_path"] = _target_node.get_path()
#     state["prop_path"] = _prop_path
#     state["start_value"] = _start_value
#     state["end_value"] = _end_value
#     state["fixed_elapsed"] = _fixed_elapsed
#     state["fixed_duration"] = _fixed_duration
#     state["ease_type"] = _ease_type
#     state["speed_scale"] = _speed_scale
#     state["convert_to_float"] = _convert_to_float

#     return {}

# func _load_state(state: Dictionary):
#     _is_tweening = state["is_tweening"]

#     # If we're not tweening, we don't need to load any other info
#     if not _is_tweening:
#         return

#     _target_node = get_node(state["target_node_path"])
#     _prop_path = state["prop_path"]
#     _start_value = state["start_value"]
#     _end_value = state["end_value"]
#     _fixed_elapsed = state["fixed_elapsed"]
#     _fixed_duration = state["fixed_duration"]
#     _ease_type = state["ease_type"]
#     _speed_scale = state["speed_scale"]
#     _convert_to_float = state["convert_to_float"]


# Change to _network_process if we want to enable multiplayer
func _physics_process(delta):
	if not _is_tweening:
		return

	_fixed_elapsed += SGFixed.mul(SGFixed.DELTA, _speed_scale)

	# Convert the elapsed time into a value from 0 to 1 and apply easing
	var t := SGFixed.ONE if _fixed_duration == 0 else SGFixed.div(_fixed_elapsed, _fixed_duration)
	t = FixedEase.ease_func_by_ease_type[_ease_type].call(t)

	# If we've reached the end of the current tween, set the property to its final value and stop
	if t >= SGFixed.ONE:
		_target_node.set_indexed(_prop_path, _end_value)
		finished.emit()
		kill()
		return

	# Do different things for different property types.
	# Add new things here as needed.
	if _end_value is SGFixedVector2:
		var v2 := (_start_value as SGFixedVector2).linear_interpolate(_end_value, t)

		if _convert_to_float:
			_target_node.set_indexed(_prop_path, v2.to_float())
		else:
			_target_node.set_indexed(_prop_path, v2)

	elif typeof(_end_value) == TYPE_INT:
		var result: int = SGFixed.lerp(_start_value as int, _end_value, t)

		if _convert_to_float:
			_target_node.set_indexed(_prop_path, SGFixed.to_float(result))
		else:
			_target_node.set_indexed(_prop_path, result)


## Tweens a property in [p_node] from its current value to [p_final_val]
func tween_property(
	p_node: Node,
	p_prop_path: NodePath,
	p_final_val: Variant,
	p_fixed_duration: int,
	p_ease: FixedEase.EaseType = FixedEase.EaseType.LINEAR,
	p_convert_to_float = false
):
	# Fail out of the property could not be found.
	if p_node.get_indexed(p_prop_path) == null:
		push_error("oopsies")
		return

	_is_tweening = true

	_fixed_elapsed = 0
	_target_node = p_node
	_prop_path = p_prop_path
	_start_value = _target_node.get_indexed(_prop_path)
	_end_value = p_final_val
	_fixed_duration = p_fixed_duration
	_ease_type = p_ease
	_convert_to_float = p_convert_to_float


## Sets the speed scale applied to the current tween. Use this to apply hitpause/slo-mo if needed.
func set_speed_scale(fixed_speed_scale: int):
	_speed_scale = fixed_speed_scale


## Immediately end the current tween
func kill():
	_is_tweening = false
	_target_node = null
	_prop_path = ""
	_start_value = null
	_end_value = null
	_fixed_duration = 0
	_speed_scale = SGFixed.ONE
	_fixed_elapsed = 0
