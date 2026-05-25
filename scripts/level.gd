## Controller for an individual level/course
class_name Level
extends SGFixedNode2D

## Emitted when the race sequence is completely finished and the game is ready to move on
signal race_over(winning_horse: HorseData)

enum State { IDLE, COUNTDOWN, RACE, VICTORY }

@export_category("Tweakables")

## How long the initial countdown takes
@export var _countdown_duration: float = 20.0

@export_category("Node References")

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

@export var _fixed_tweener: FixedTweener

@export var _collision_manager: LevelCollision

@export_category("Packed Scenes")

## Add a reference to the packed scene used to instantiate all horses
@export var _horse_packed_scene: PackedScene

var current_state: State:
	get:
		return _current_state

var horses: Array[Horse]:
	get:
		return _horses

var victory_image: VictoryImage:
	get:
		return _victory_image

var race_paused: bool:
	get:
		return _race_paused

var goal: Goal:
	get:
		return _goal

## The overall timescale that should be used by all gameplay objects
var time_scale: int:
	get:
		# If there are ever other things that affect time scale, we can factor them in here
		return _fixed_qte_time_scale

## Cached references to all the horses in the level
var _horses: Array[Horse]

## A reference to the winning horse. Assigned when a horse grabs the goal.
var _winning_horse: Horse

var _race_paused: bool

var _horse_by_name: Dictionary[String, Horse]

var _goal: Goal

## Time scale to be applied to all gameplay stuff during the QTE slow-mo
var _fixed_qte_time_scale: int = SGFixed.ONE

var _current_state: State = State.IDLE


func _ready():
	$LevelText.visible = false

	# Connect up so we recognize when a horse has reached the goal
	for i: int in range(_goal_holder.get_child_count()):
		var child := _goal_holder.get_child(i)
		if child is Goal:
			_goal = child as Goal
			goal.grabbed_by_horse.connect(_on_goal_grabbed_by_horse)

	_countdown_timer.countdown_finished.connect(start_race)
	_victory_image.image_shown.connect(_on_victory_image_image_shown)


# Here to be overridden
func _process(delta: float):
	pass


## Initializes level. Call this right after instantiating it.
func initialize(horse_datas: Array[HorseData]):
	_spawn_horses(horse_datas)
	_collision_manager.generate_collision(_wall_sprite.texture)
	BetEventBus.level_initialized.emit()


## Starts the pre-race countdown
func start_countdown():
	_current_state = State.COUNTDOWN
	_countdown_timer.start_countdown(_countdown_duration)


func start_race():
	_current_state = State.RACE

	$AudioStreamPlayer2D.play()
	$RaceClock.show()
	$RaceClock.start_counting = true
	$LevelText.show()

	_gate_holder.visible = false

	BetManager.random_zone = 0

	for horse: Horse in _horses:
		horse.start_moving()

	BetEventBus.race_started.emit()


func start_victory():
	_current_state = State.VICTORY

	$AudioStreamPlayer2D.stop()

	for horse: Horse in _horses:
		horse.stop_moving()

	_do_win_animation()


func toggle_race_paused(p_paused: bool):
	_race_paused = p_paused
	$RaceClock.start_counting = !p_paused
	$AudioStreamPlayer2D.stream_paused = p_paused
	for horse: Horse in _horses:
		horse.toggle_paused(p_paused)


func get_horse_by_name(horse_name: String) -> Horse:
	if _horse_by_name.has(horse_name):
		return _horse_by_name[horse_name]
	return null


func tween_qte_time_scale(fixed_from: int, fixed_to: int, fixed_duration: int):
	_fixed_qte_time_scale = fixed_from
	_fixed_tweener.kill()
	_fixed_tweener.tween_property(self, "_fixed_qte_time_scale", fixed_to, fixed_duration)


func reset_qte_time_scale():
	_fixed_qte_time_scale = SGFixed.ONE


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


## Does the animation for when a horse has won the race
func _do_win_animation():
	await get_tree().create_timer(1.5).timeout

	await (
		RaceCamera
		. instance
		. zoom_tween(
			15,
			2.0,
			Tween.EaseType.EASE_IN,
			Tween.TransitionType.TRANS_SINE,
		)
		. finished
	)

	_victory_image.do_show_animation(_winning_horse.horse_data)


func _on_goal_grabbed_by_horse(horse: Horse):
	_winning_horse = horse
	$AudioStreamPlayer2D.stream = horse.horse_data.victory_theme
	$AudioStreamPlayer2D.play()
	horse.win()

	start_victory()


func _on_victory_image_image_shown():
	_current_state = State.IDLE
	race_over.emit(_winning_horse.horse_data)


# Here to be overridden
func _on_horse_hit_horse(horse_a: Horse, horse_b: Horse):
	pass


# Here to be overridden
func _on_horse_hit_wall(horse: Horse):
	pass
