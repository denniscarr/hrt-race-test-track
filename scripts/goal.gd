## One of the items that the horses are competing to grab
class_name Goal
extends SGArea2D

## Emitted when a horse grabs this goal
signal grabbed_by_horse(horse_who_grabbed_me: Horse)

@export_category("Node References")

@export var _sprite: Sprite2D
@export var _near_radius: float = 100
@export var _far_radius: float = 200

var _near_radius_squared: float = -1
var near_radius_squared: float:
	get:
		if _near_radius_squared < 0:
			_near_radius_squared = pow(_near_radius, 2)
		return _near_radius_squared

var _far_radius_squared: float = -1
var far_radius_squared: float:
	get:
		if _far_radius_squared < 0:
			_far_radius_squared = pow(_far_radius, 2)
		return _far_radius_squared

var _eaten: bool = false
var _distance_circle_on: bool
var _far_distance: bool


func _ready() -> void:
	# Create collision
	var colliders := Util.create_sgpolygons_from_texture(_sprite.texture, 2.0)
	for collider: SGCollisionPolygon2D in colliders:
		add_child(collider)


func _physics_process(delta: float) -> void:
	if _eaten:
		return
	sync_to_physics_engine()
	var bodies := get_overlapping_bodies()
	for body: SGFixedNode2D in bodies:
		if body is Horse:
			# Get eaten by a horse
			grabbed_by_horse.emit(body)
			_eaten = true


func toggle_distance_circle(toggle_on: bool, far_distance: bool):
	_distance_circle_on = toggle_on
	_far_distance = far_distance
	queue_redraw()


func _draw():
	if _distance_circle_on:
		var _light_blue: Color = Color("478cbf", 0.5)
		draw_circle(
			Vector2(0, 0),
			\
			_far_radius if _far_distance else _near_radius,
			_light_blue,
		)
