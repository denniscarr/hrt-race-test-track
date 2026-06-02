## Helper class for setting up finite state machines.
## Can be extended, or you can setup callback functions manually.
##
## To avoid writing a bunch of boilerplate, you can use the FsmController class to manage the states
## for you.
##
## IMPORTANT:
## For this to work, you have to manually call the process, physics_process and input functions
## from  some other script, or through FsmController.
class_name FsmState
extends RefCounted


## An optional name id. Can be useful for debugging, etc.
var name: String

## A function to call when this state is entered
var enter_callback: Callable = func(): pass

## A function to call during process frames
var process_callback: Callable = func(_delta: float): pass

## A function to call during physics process frames
var physics_process_callback: Callable = func(_delta: float): pass

## A function to call during network process ticks
var network_process_callback: Callable = func(_input: Dictionary): pass

## A function to call when the Godot _input event is invoked
var input_callback: Callable = func(_event: InputEvent): pass

## A function to call when the state is exited
var exit_callback: Callable = func(): pass


## Holds all the signal callbacks added with [add_signal_callback]
var _callbacks_by_signal: Dictionary[Signal, Callable]


## Call this when the state is first entered
func enter() -> void:
	# Add signal listeners
	for sig: Signal in _callbacks_by_signal:
		if not sig.is_connected(_callbacks_by_signal[sig]):
			sig.connect(_callbacks_by_signal[sig])

	enter_callback.call()


## Call this during the process frame
func process(delta: float) -> void:
	process_callback.call(delta)


## Call this during the physics process frame
func physics_process(delta: float) -> void:
	physics_process_callback.call(delta)


## Call this during network process
func network_process(input_dic: Dictionary) -> void:
	network_process_callback.call(input_dic)


## Call this from the Godot _input function
func input(event: InputEvent) -> void:
	input_callback.call(event)


## Call this just before changing to a different state
func exit() -> void:
	# Disconnect signal listeners
	for sig: Signal in _callbacks_by_signal:
		if sig.is_connected(_callbacks_by_signal[sig]):
			sig.disconnect(_callbacks_by_signal[sig])

	exit_callback.call()


## Adds a callback for the given signal. It will be automatically connected/disconnected when the
## FsmState is entered/exited.
func add_signal_callback(sig: Signal, callback: Callable):
	_callbacks_by_signal[sig] = callback
