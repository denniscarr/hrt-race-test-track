## Controls the countdown timer that bounces around the screen at the beginning of a race.
class_name CountdownTimer
extends Node2D

## Emitted when the countdown has finished
signal countdown_finished

## How fast the bouncing timer moves
@export var _speed: float = 100.0

## Assign all the textures that should be shown during the countdown sequence, from first (place
## your bets in...) to last (go!)
@export var _countdown_textures: Array[Texture2D]

## The clips that play during the coundown, in order. eg "place your bets, 10, 9, 8, 7..."
@export var _countdown_sounds: Array[AudioStream]

@export_category("Node References")
@export var _sprite: Sprite2D
@export var _audio_player: AudioStreamPlayer2D
@export var _bouncing_body: CharacterBody2D

## General purpose timer
var _timer: float

# Used for tracking phase progression
var _num_phases: int
var _phase_index: int
var _min_phase_time: float

var _fsm_controller: FsmController


func _ready():
	_fsm_controller = FsmController.new()
	_fsm_controller.register_state("idle", _define_idle_state())
	_fsm_controller.switch_state("idle")
	_bouncing_body.visible = false


func _process(delta: float):
	_fsm_controller.process_tick(delta)


## Starts counting down the timer
func start_countdown(countdown_time: float):
	visible = true
	_num_phases = max(_countdown_sounds.size(), _countdown_textures.size())
	_min_phase_time = countdown_time / _num_phases
	_phase_index = 0
	_go_to_next_phase()

	# Start bounding around the screen
	_bouncing_body.visible = true
	_bouncing_body.velocity = Vector2.RIGHT.rotated(randf_range(0, PI * 2)) * _speed


## Finishes the countdown and hides the timer.[br]
## Can be called early intentionally to skip to the end of the countdown and emit
## [countdown_finished].
func finish_countdown():
	_bouncing_body.visible = false
	countdown_finished.emit()
	_fsm_controller.switch_state("idle")


func _physics_process(_delta: float):
	var collision = _bouncing_body.move_and_collide(_bouncing_body.velocity)
	if collision:
		_bouncing_body.velocity = _bouncing_body.velocity.bounce(collision.get_normal())
		_bouncing_body.velocity = _bouncing_body.velocity.normalized() * _speed


func _go_to_next_phase():
	if _phase_index >= _num_phases:
		finish_countdown()
		return

	# Create a new state for the next phase and switch to it
	var key := "countdown_%s" % str(_phase_index)
	_fsm_controller.register_state(key, _define_countdown_state(_phase_index))
	_fsm_controller.switch_state(key)

	_phase_index += 1


func _define_countdown_state(index: int):
	var state := FsmState.new()

	state.enter_callback = func():
		_audio_player.stop()
		if _countdown_sounds.size() >= index + 1:
			_audio_player.stream = _countdown_sounds[index]
			_audio_player.play()

		if _countdown_textures.size() >= index + 1:
			_sprite.texture = _countdown_textures[index]

		_timer = 0

	state.process_callback = func(delta: float):
		_timer += delta
		var audio_finished := (
			_timer >= _audio_player.stream.get_length()
			if _audio_player.stream != null
			else _timer >= 2.0 # failsafe
		)
		if _timer >= _min_phase_time and audio_finished:
			_go_to_next_phase()

	return state


func _define_idle_state():
	var state := FsmState.new()
	return state
