## One of the items that the horses are competing to grab
class_name Goal
extends SGArea2D

## Emitted when a horse grabs this goal
signal grabbed_by_horse(horse_who_grabbed_me: Horse)

@export_category("Node References")

@export var _sprite: Sprite2D

var _eaten: bool = false


func _ready() -> void:
	# Create collision
	var colliders := GeomUtil.create_sgpolygons_from_texture(_sprite.texture, 2.0)
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
