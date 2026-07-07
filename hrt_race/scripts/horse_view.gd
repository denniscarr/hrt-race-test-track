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
func set_look_direction(fixed_dir: SGFixedVector2):
	var reversed_y = SGFixed.vector2(fixed_dir.x, fixed_dir.y * -1)
	var horse_dir = Horse.fixed_dir_to_horse_dir(reversed_y)
	var i := floori(remap(horse_dir, 0, 32, 0, _horse_textures.size() - 1))
	_main_sprite.texture = _horse_textures[i]


func set_name_label_visible(p_visible: bool):
	_name_label.visible = p_visible
