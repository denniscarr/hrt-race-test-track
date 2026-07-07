## Controller for an individual level/course
class_name RaceTrack
extends SGFixedNode2D

## Emitted when a horse grabs a goal, ending the race and triggering the victory sequence.
signal goal_grabbed(horse: Horse)

## Emitted when the race sequence is completely finished and the game is ready to move on
signal race_over(winning_horse: HorseData)

signal horse_hit_horse(horse_a: Horse, horse_b: Horse)

signal horse_hit_wall(horse: Horse)

enum State { IDLE, COUNTDOWN, RACE, VICTORY }

@export_category("Packed Scenes")

## Add a reference to the packed scene used to instantiate all horses
@export var _horse_packed_scene: PackedScene

@export_category("Tweakables")

## How long the initial countdown takes
@export var _countdown_duration: float = 20.0

@export_category("Internal Node References")

## Parent spawn points to this. Spawn points should just be plain old Node2Ds that are used as
## position references when spawning the horses.
@export var _spawn_point_holder: Node2D

## Reference to the parent that holds the gates which appear on the map before the horses start
## running. Everything parented to this will get turned off when the race starts.
@export var _gate_holder: Node2D

## Reference to the parent node that holds all goals in the level. Usually there is just one, but
## you can add others if you want. Just make sure they're added to this holder.
@export var _goal_holder: Node2D

## A reference to the sprite that shows the levels walls. This will also define the level's
## collision shape.
@export var _wall_sprite: Sprite2D

@export var _countdown_timer: CountdownTimer

## The thing that shows the winning horse when the race ends
@export var _victory_image: VictoryImage

@export var _collision_manager: LevelCollision

## Time scale to be applied to all gameplay stuff. Meant to be used during QTEs or hitpause.
var time_scale: int = SGFixed.ONE

var current_state: State:
	get:
		return _current_state

var horses: Array[Horse]:
	get:
		return _horses

## A reference to the winning horse. Assigned when a horse grabs the goal.
var winning_horse: Horse:
	get:
		return _winning_horse

var victory_image: VictoryImage:
	get:
		return _victory_image

var paused: bool:
	get:
		return _paused

var goals: Array[Goal]:
	get:
		return _goals

## Cached references to all the horses in the level
var _horses: Array[Horse]

var _winning_horse: Horse

var _paused: bool

var _horse_by_name: Dictionary[String, Horse]

var _goals: Array[Goal]

var _current_state: State = State.IDLE

## The camera used during victory animations
var _race_cam: Camera2D

var _race_cam_tween: Tween


func _ready():
	$LevelText.visible = false


# Here to be overridden
func _process(delta: float):
	pass


## Deletes all Goal nodes in the race track and replaces them with instances of
## [override_scene]. Call this before [initialize].[br]
## [override_scene]'s root script must extend Goal.
func apply_goal_override(override_scene: PackedScene):
	for i: int in range(_goal_holder.get_child_count()):
		var child := _goal_holder.get_child(i)
		if not (child is Goal):
			continue
		var old_goal := child as Goal

		var override := override_scene.instantiate()
		if not (override is Goal):
			push_error("apply_goal_override only works with scenes that extend Goal.")
			return
		var new_goal := override as Goal

		old_goal.get_parent().add_child(new_goal)
		new_goal.fixed_position = old_goal.fixed_position

		old_goal.get_parent().remove_child(old_goal)
		old_goal.queue_free()


## Deletes the CountdownTimer node in the race track and replaces it with an instance of
## [override_scene]. Call this before [initialize].[br]
## [override_scene]'s root script must extend CountdownTimer.
func apply_countdown_timer_override(override_scene: PackedScene):
	var override := override_scene.instantiate()
	if not (override is CountdownTimer):
		push_error(
			"apply_countdown_timer_override only works with scenes that extend CountdownTimer",
		)
		return

	var new_timer := override as CountdownTimer
	var old_timer := _countdown_timer

	old_timer.get_parent().add_child(new_timer)
	old_timer.get_parent().remove_child(old_timer)
	old_timer.queue_free()

	_countdown_timer = new_timer


## Sets a camera to be used during animations, like the victory animation.[br]
## This camera will become managed and have tweens attached to it, so be careful if you're applying
## your own tweens/movement logic to it.[br]
## Ideally, call this before initialize. If there is no camera assigned, certain animations won't
## play.
func set_race_cam(cam: Camera2D):
	_race_cam = cam


## Initializes level. Call this after any override functions.
func initialize(horse_datas: Array[HorseData]):
	if _race_cam:
		_race_cam.zoom = Vector2.ONE

	_spawn_horses(horse_datas)
	_collision_manager.generate_collision(_wall_sprite.texture)

	# Connect up so we recognize when a horse has reached the goal
	for i: int in range(_goal_holder.get_child_count()):
		var child := _goal_holder.get_child(i)
		if child is Goal:
			var goal = child as Goal
			goal.grabbed_by_horse.connect(_on_goal_grabbed_by_horse)
			_goals.push_back(goal)

	_countdown_timer.countdown_finished.connect(start_race)
	_victory_image.image_shown.connect(_on_victory_image_image_shown)


## Starts the pre-race countdown. The race will automatically start at the end of the countdown.
func start_countdown():
	if _current_state == State.COUNTDOWN:
		return

	_current_state = State.COUNTDOWN
	_countdown_timer.start_countdown(_countdown_duration)


func start_race():
	if _current_state == State.RACE:
		return

	_current_state = State.RACE

	_countdown_timer.finish_countdown()
	$AudioStreamPlayer2D.play()
	$RaceClock.show()
	$RaceClock.start_counting = true
	$LevelText.show()

	_gate_holder.visible = false

	for horse: Horse in _horses:
		horse.start_moving()


func set_paused(p_paused: bool):
	_paused = p_paused
	$RaceClock.start_counting = !p_paused
	$AudioStreamPlayer2D.stream_paused = p_paused
	for horse: Horse in _horses:
		horse.toggle_paused(p_paused)


func get_horse_by_name(horse_name: String) -> Horse:
	if _horse_by_name.has(horse_name):
		return _horse_by_name[horse_name]
	return null


## Creates all horses in a random order at random spawn points
func _spawn_horses(horse_datas: Array[HorseData]):
	var shuffled_horses := horse_datas.duplicate()
	shuffled_horses.shuffle()

	var shuffled_spawn_points := _spawn_point_holder.get_children()
	shuffled_spawn_points.shuffle()

	# Spawn horses
	for i: int in range(0, shuffled_horses.size()):
		var horse_data := shuffled_horses[i] as HorseData

		if i > shuffled_spawn_points.size() - 1:
			printerr("not enough spawn points in this level!!!!!")
			return

		var new_horse := _horse_packed_scene.instantiate() as Horse
		$HorseHolder.add_child(new_horse)
		new_horse.initialize(horse_data)
		_horses.push_back(new_horse)
		_horse_by_name[horse_data.name_abrev] = new_horse

		var spawn_point := shuffled_spawn_points[i] as SGFixedNode2D
		new_horse.set_global_fixed_position(spawn_point.get_global_fixed_position())
		new_horse.sync_to_physics_engine()

		new_horse.hit_horse.connect(_on_horse_hit_horse)
		new_horse.hit_wall.connect(_on_horse_hit_wall)


func _start_victory():
	_current_state = State.VICTORY

	$AudioStreamPlayer2D.stop()

	for horse: Horse in _horses:
		horse.stop_moving()

	_do_win_animation()


## Does the animation for when a horse has won the race
func _do_win_animation():
	# If the race cam was not set, skip the zoom animation
	if _race_cam == null:
		_victory_image.do_show_animation(_winning_horse.horse_data)
		return

	if _race_cam_tween:
		_race_cam_tween.kill()

	_race_cam_tween = create_tween()
	_race_cam_tween.tween_interval(1.5)
	_race_cam_tween.set_trans(Tween.TransitionType.TRANS_SINE)
	_race_cam_tween.set_ease(Tween.EaseType.EASE_IN)
	_race_cam_tween.tween_property(_race_cam, "zoom", Vector2.ONE * 15, 2.0)
	(
		_race_cam_tween
		. tween_callback(
			_victory_image.do_show_animation.bind(_winning_horse.horse_data, _race_cam),
		)
	)


func _on_goal_grabbed_by_horse(horse: Horse):
	_winning_horse = horse
	$RaceClock.start_counting = false
	$AudioStreamPlayer2D.stream = horse.horse_data.victory_theme
	$AudioStreamPlayer2D.play()
	horse.win()
	goal_grabbed.emit(horse)
	_start_victory()


func _on_victory_image_image_shown():
	_current_state = State.IDLE
	race_over.emit(_winning_horse.horse_data)


func _on_horse_hit_horse(horse_a: Horse, horse_b: Horse):
	horse_hit_horse.emit(horse_a, horse_b)


func _on_horse_hit_wall(horse: Horse):
	horse_hit_wall.emit(horse)
