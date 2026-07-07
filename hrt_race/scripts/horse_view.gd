## View script for a single horse
class_name HorseView
extends Node2D

@export_category("Node References")

@export var _main_sprite: Sprite2D

## Horse name abbreviation label for start of race
@export var _name_label: Label

var _horse_textures: Array[Texture2D] = []


func initialize(data: HorseData):
	_horse_textures.assign(data.textures)
	_main_sprite.texture = _horse_textures[0]
	_name_label.text = data.name_abrev


func get_current_texture() -> Texture2D:
	return _main_sprite.texture


## Called to update the horses look direction from their horse data textures
func set_look_direction(fixed_look_dir: SGFixedVector2):
	var look_dir := fixed_look_dir.to_float()

	# Only update if there is actual movement to prevent division by zero or default direction issues
	if look_dir.length_squared() > 0:
		var direction = Vector2(look_dir.x, -look_dir.y)  # flip y velocity
		var angle = direction.angle()  # Angle in radians (-PI to PI)
		var num_sprites = _horse_textures.size()

		# Adjust the angle so 0 radians corresponds to the first sprite direction.
		# This part depends on which direction your first sprite (index 0) represents.
		# Assuming index 0 is "right" (0 radians), we can proceed directly.
		# If index 0 is "up" (-PI/2 radians), you would need an offset (e.g., angle += PI/2).

		# Convert angle from range [-PI, PI] to [0, 2*PI]
		if angle > 0:
			angle += 2 * PI

		# Calculate the size of each angle slice for a given sprite
		var angle_slice = (2 * PI) / num_sprites

		# Determine the index by dividing the angle by the slice size
		# and casting to an integer.
		var new_look_index = int(angle / angle_slice)

		# Ensure the index is within the array bounds (should be handled by the int cast but as a
		# safeguard)
		new_look_index = wrapi(new_look_index, 0, num_sprites)

		_main_sprite.texture = _horse_textures[new_look_index]


func set_name_label_visible(p_visible: bool):
	_name_label.visible = p_visible
