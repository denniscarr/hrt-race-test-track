## This class can be used to help manage [FsmState]s more easily.
class_name FsmController
extends RefCounted

## The key for the current state, or null if [switch_state] has never been called.
var current_state_key: Variant:
	get:
		return _current_state_key

## When [register_state] is called the states and their keys go in here.
var _states_by_key: Dictionary[Variant, FsmState] = {}

## The key for the current state
var _current_state_key: Variant


## Adds the specified state to the state machine, storing it with the specified key. This doesn't
## change to the specified state. You need to call [switch_state] for that. [br]
## Suggested keys: Enum or StringName. Strings will automatically be converted to StringName.
func register_state(key: Variant, state: FsmState):
	# Convert strings into string names for efficiency
	if typeof(key) == TYPE_STRING:
		key = StringName(key)

	if _states_by_key.has(key):
		push_error("Key has already been registered: %s" % key)
		return

	_states_by_key[key] = state


## Calls [process_callback] of the current state
func process_tick(delta: float):
	if get_current_state():
		get_current_state().process(delta)


## Calls [physics_process_callback] of the current state
func physics_tick(delta: float):
	if get_current_state():
		get_current_state().physics_process(delta)


## Calls [network_process_callback] of the current state
func network_tick(input: Dictionary):
	if get_current_state():
		get_current_state().network_process(input)


## Switch to the state with the specified key. The state/key must have been added with
## [register_state] before calling this function.
## The states themselves should be set up to call this function at the appropriate time.
func switch_state(new_state_key: Variant):
	# Any string keys will have been converted to StringName by [register_state]
	if typeof(new_state_key) == TYPE_STRING:
		new_state_key = StringName(new_state_key)

	if not _states_by_key.has(new_state_key):
		push_error("Key not found: %s" % new_state_key)
		return

	if new_state_key == _current_state_key:
		return

	if get_current_state():
		get_current_state().exit()

	_current_state_key = new_state_key

	get_current_state().enter()


## Changes to the specified state without calling enter or exit. Use this when rolling back to
## a previous state.[br]
## [forced_state_key] must have been added with [register_state] before calling this function.
func force_state(forced_state_key: Variant):
	# Any string keys will have been converted to StringName by [register_state]
	if typeof(forced_state_key) == TYPE_STRING:
		forced_state_key = StringName(forced_state_key)

	if not _states_by_key.has(forced_state_key):
		push_error("Key not found: %s" % forced_state_key)
		return

	_current_state_key = forced_state_key


## Returns a reference to the current state, or [null] if [switch_state] has not yet been
## successfully called.
func get_current_state() -> FsmState:
	if _states_by_key.has(_current_state_key):
		return _states_by_key[_current_state_key]

	return null
