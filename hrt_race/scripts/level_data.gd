## Data for an individual level/course
class_name LevelData
extends Resource


@export var _texture: Texture2D

@export var _song: AudioStream

var texture: Texture2D:
	get: return _texture

var song: AudioStream:
	get: return _song
