extends Node

@export var _horses: Array[HorseData]
@export var _race_scenes: Array[PackedScene]


func _ready() -> void:
	# Pick a race track at random
	var race := _race_scenes.pick_random().instantiate() as RaceTrack
