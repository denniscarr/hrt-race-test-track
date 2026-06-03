## This controls the image of the horse that appears after a race is won
class_name VictoryImage
extends CanvasLayer

## Emitted when the image has been fully shown
signal image_shown()

## How long it takes for the horse image to be shown
@export var _image_show_duration: float = 1.0

## How long it takes for the horse's name to be shown
@export var _horse_name_show_duration: float = 1.0

## How long the screen lingers after the animation has finished
@export var _linger_duration: float = 3.0

## The material that both images use
@export var _material: ShaderMaterial

@export var _background_image: TextureRect

## The texture rect that will hold the horse's image
@export var _horse_image: TextureRect

## The label that will show the horse's name
@export var _horse_name_label: Label

## Helper property to set the masking parameter in the shader
var _material_alpha_cutoff: float:
	get:
		return _material_alpha_cutoff
	set(value):
		_material_alpha_cutoff = value
		_material.set_shader_parameter("alpha_test_cutoff", _material_alpha_cutoff)

var _tween: Tween


func _ready() -> void:
	_background_image.visible = false
	_horse_image.visible = false


## Does the animation where the image is shown and the winning horse gets slapped on it
func do_show_animation(horse_data: HorseData, cam_zoom: float = 1.0):
	# Fit in front of camera regardless of its position or zoom
	scale = Vector2.ONE * (1.0 / cam_zoom)

	_horse_image.visible = true
	_background_image.visible = true
	_material_alpha_cutoff = 0.0

	_horse_image.texture = horse_data.victory_texture
	_horse_name_label.text = horse_data.name
	_horse_name_label.add_theme_color_override("font_color", horse_data.color)

	if _tween:
		_tween.kill()

	_tween = get_tree().create_tween()
	_tween.tween_property(self, "_material_alpha_cutoff", 1.0, _image_show_duration)
	_tween.tween_callback(func(): _horse_name_label.visible = true)
	_tween.tween_property(_horse_name_label, "scale", Vector2.ONE, _horse_name_show_duration) \
	.from(Vector2.ZERO)

	await _tween.finished

	await get_tree().create_timer(_linger_duration).timeout

	image_shown.emit()
