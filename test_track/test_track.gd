extends Node

@export var _horses: Array[HorseData]
@export var _race_scenes: Array[PackedScene]
@export var _num_horses_in_race: int = 7

var _race_track: RaceTrack

@onready var _cam := $Camera2D as Camera2D


func _ready() -> void:
	# Pick horses at random
	var horse_bag := _horses.duplicate()
	horse_bag.shuffle()
	var horses: Array[HorseData] = []
	for i: int in range(0, _num_horses_in_race):
		if horse_bag.size() == 0:
			push_warning("Too many horses!")
			break
		horses.push_back(horse_bag.pop_front())

	# Pick a race track at random
	_race_track = _race_scenes.pick_random().instantiate() as RaceTrack
	add_child(_race_track)

	_race_track.set_race_cam(_cam)
	_race_track.initialize(horses)
	_race_track.start_countdown()


func _input(event: InputEvent) -> void:
	if _race_track != null and event is InputEventKey:
		if event.is_action_released("debug_skip"):
			match _race_track.current_state:
				# Allow skip countdown
				RaceTrack.State.COUNTDOWN:
					_race_track.start_race()
				# Allow skip race
				RaceTrack.State.RACE:
					_debug_skip_to_victory()


func _debug_skip_to_victory():
	# Pick a random winning horse
	var winner := _race_track.horses.pick_random() as Horse
	_race_track._winning_horse = winner

	# Force-set some things in the race track
	_race_track.get_node("RaceClock").start_counting = false
	_race_track.get_node("AudioStreamPlayer2D").stream = winner.horse_data.victory_theme
	_race_track.get_node("AudioStreamPlayer2D").play()

	winner.win()
	_race_track.goal_grabbed.emit(winner)

	# In a debug method, I hereby grant access to private members
	_race_track._start_victory()
