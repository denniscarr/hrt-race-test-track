class_name AudioStreamPlayer2DPitchRand
extends AudioStreamPlayer2D

@export var _pitch_min: float
@export var _pitch_max: float

func play_random():
	pitch_scale = randf_range(_pitch_min, _pitch_max)
	play()
