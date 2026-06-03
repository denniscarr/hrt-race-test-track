## Controller for one single horse
class_name Horse
extends SGCharacterBody2D

signal hit_horse(me: Horse, them: Horse)

signal hit_wall(me: Horse)

const MAX_BOUNCE_ATTEMPTS: int = 100

@export var _view: HorseView

## The horse's data construct
var horse_data: HorseData:
	get:
		return _horse_data

var view: HorseView:
	get:
		return _view

## Whether the horse is currently moving
var _is_moving: bool

## The horse's current move speed
var _fixed_move_speed: int

## Cached reference to the horse's data resource
var _horse_data: HorseData

## Used to time out speed increase intervals
var _fixed_speed_increase_timer: int

## Hard speed multiplier used by some abilities. (I think)
var _fixed_speed_multiplier: int = SGFixed.ONE

## Used to apply slow-mo (or theoretically fast-mo too) during game events
var _fixed_fx_speed_multiplier: int = SGFixed.ONE

## The number of times the horse's speed has increased due to time progressing in the current
## race.
var _speed_increases: int = 0

var _horses_bounced_off_this_tick: Array[Horse]

@onready var _sfx_bump = $AudioStreamPlayer2D


func _ready():
	pass


func _physics_process(delta: float):
	_horses_bounced_off_this_tick.clear()

	if not _is_moving:
		return

	# Increase speed every so often
	_fixed_speed_increase_timer -= 1
	if _fixed_speed_increase_timer <= 0:
		_speed_increases += 1
		_fixed_speed_increase_timer = _horse_data.speed_increase_ticks

	recalculate_speed()

	# Move & bounce off walls
	var collision := move_and_collide(velocity)
	if collision:
		var got_stuck = _bounce(collision.get_normal())

		if got_stuck:
			print("bounce fail")

		# Don't emit any events if the bounce failed
		if not got_stuck:
			_check_horse_collision(collision)
			_check_wall_collision(collision)

		# Update look dir
		_view.set_look_direction(velocity)


## Initializes the horse. Call right after instantiating it.
func initialize(data: HorseData):
	_horse_data = data

	_view.initialize(data)
	_view.set_look_direction(_get_start_dir())

	var collision_polys := GeomUtil.create_sgpolygons_from_texture(_horse_data.textures[0], 4.0)
	for poly: SGCollisionPolygon2D in collision_polys:
		add_child(poly)


## Call when the race starts to make the horse start moving.
func start_moving():
	_is_moving = true
	_fixed_move_speed = _horse_data.base_speed
	velocity = _get_start_dir().mul(_fixed_move_speed)
	_fixed_speed_increase_timer = _horse_data.speed_increase_ticks
	view.set_name_label_visible(false)


## Call when the race ends to make the horse stop moving.
func stop_moving():
	_is_moving = false
	_fixed_move_speed = 0
	velocity.x = 0
	velocity.y = 0


func get_direction_degrees(horse: Horse):
	var direction_vector: Vector2 = horse.global_position - global_position
	return rad_to_deg(atan2(direction_vector.y, direction_vector.x))


func set_direction(fixed_degrees: int):
	var radians := SGFixed.deg_to_rad(fixed_degrees)
	velocity = velocity.rotated(radians)
	_view.set_look_direction(velocity)


## Note that using this will break determinism. If you want to keep it, use [set_direction] with a
## pre-calculated fixed point number.
func set_direction_lossy(degrees: float):
	var fixed_degrees: int = SGFixed.ONE * degrees
	set_direction(fixed_degrees)


## Gives the horse a completely random direction
func randomize_direction():
	var randomness := SGFixed.deg_to_rad(SGFixed.ONE * 360)
	var rand_angle := randi_range(-randomness, randomness)
	velocity = velocity.rotated(rand_angle)
	_view.set_look_direction(velocity)


func reverse_direction():
	velocity = velocity.rotated(SGFixed.deg_to_rad(SGFixed.ONE * 180))
	_view.set_look_direction(velocity)


func toggle_paused(p_paused: bool):
	_is_moving = !p_paused


func win():
	$AudioStreamPlayer2DPitchRand.stream = horse_data.neigh
	$AudioStreamPlayer2DPitchRand.play()


func increment_speed_multiplier(fixed_amount: int):
	# 6554 = 0.1 in fixed
	_fixed_speed_multiplier = max(_fixed_speed_multiplier + fixed_amount, 6554)
	recalculate_speed()


## Recalculates and immediately updates the horse's speed to match its current state.
func recalculate_speed():
	_fixed_move_speed = _get_move_speed()
	velocity = velocity.normalized()
	velocity.imul(_fixed_move_speed)


func get_current_speed() -> int:
	return velocity.length()


func get_current_speed_lossy() -> float:
	return SGFixed.to_float(velocity.length())


func hit_by_other_horse(other_horse: Horse, collision_normal: SGFixedVector2):
	if _horses_bounced_off_this_tick.has(other_horse):
		return

	_horses_bounced_off_this_tick.push_back(other_horse)

	var opposite_normal := collision_normal.mul(-1)
	var to_other := fixed_position.sub(other_horse.fixed_position)
	to_other = to_other.normalized()
	velocity = to_other
	_bounce(opposite_normal)


## Called when the horse collides with something to make it bounce in another direction
## Returns true in the rare scenario where the horse gets stuck in place due to not finding
## an open direction to move to.
func _bounce(collision_normal: SGFixedVector2, attempts: int = 0) -> bool:
	if attempts > MAX_BOUNCE_ATTEMPTS:
		print("Could not find open space to bounce to")
		return true

	# Get a bounce direction by applying a random rotation to the base bounce
	var randomness := SGFixed.deg_to_rad(horse_data.bounce_randomness)
	var rand_angle := randi_range(-randomness, randomness)
	var base_bounce_dir := velocity.bounce(collision_normal).normalized()
	var rand_bounce_dir := base_bounce_dir.rotated(rand_angle)

	# Update velocity to match random direction
	velocity = rand_bounce_dir.mul(_fixed_move_speed).mul(_fixed_fx_speed_multiplier)

	# Move just a smidge and check if we immediately hit another collider
	# TODO: This was originally used the 'test' param from the native GD function.
	# SGPhysics doesn't have that. How did I handle this in Smush?
	var collision := move_and_collide(velocity)
	if collision:
		# If we did, bounce again using the normal from that collision
		return _bounce(collision.get_normal(), attempts + 1)

	# Success. We found an empty direction to bounce in.
	_sfx_bump.play()
	return false


## Returns the direction that the horse should move in at the start of the race
func _get_start_dir() -> SGFixedVector2:
	var fixed_start_dir: int = horse_data.start_dir
	# 32 is the number of possible starting directions in the clickteam version
	var pi_thing := SGFixed.div(SGFixed.PI * 2, 32)
	var r := SGFixed.mul(-fixed_start_dir, pi_thing)
	var start_dir := SGFixedVector2.right().rotated(r)
	return start_dir


## Checks the specified collision is with another horse and if so registers it with the BetEventBus
func _check_horse_collision(p_collision: SGKinematicCollision2D):
	var collider = p_collision.get_collider()
	if collider is Horse:
		var horse := collider as Horse
		if not _horses_bounced_off_this_tick.has(horse):
			_horses_bounced_off_this_tick.push_back(horse)
			horse.hit_by_other_horse(self, p_collision.normal)
		hit_horse.emit(self, horse)


func _check_wall_collision(p_collision: SGKinematicCollision2D):
	# "LevelWall" is added to the data property of the wall colliders when they're created in
	# level_collision.gd
	var collider_data = SGPhysics2DServer.collision_object_get_data(p_collision.collider_rid)
	if collider_data is String && collider_data.contains("LevelWall"):
		hit_wall.emit(self)


func _set_speed_multiplier(mult: int):
	_fixed_speed_multiplier = mult
	recalculate_speed()


## Calculates the speed the horse should move at based on its current state
func _get_move_speed() -> int:
	var fixed_speed := _horse_data.base_speed + _speed_increases * horse_data.speed_increase_amount
	fixed_speed = SGFixed.mul(fixed_speed, _fixed_speed_multiplier)
	return fixed_speed
