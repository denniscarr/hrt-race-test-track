class_name HorseData
extends Resource

## Full name that is displayed on the victory screen
@export var _name: String = "horse"

## 3 character breviated name shown before each race starts
@export var _name_abv: String = "HRS"

## Set all the horses textures. They should start with the eyes facing right and continue
## counter-clockwise from tehre.
@export var _textures: Array[Texture2D]

## The horse's signature color. Used to color text on the victory screen (and maybe other stuff
## later)
@export var _color: Color = Color.WHITE

## Texture that shows up on the victory screen
@export var _victory_texture: Texture2D

## Theme that plays once the horse touches the goal
@export var _victory_theme: AudioStream

## SFX that plays when horse reaches goal
@export var _neigh: AudioStream = preload("res://hrt_race/audio/sfx/horsenei.wav")

## Set the horse's move base_speed
@export var _fixed_base_speed: int = 65536

## Set how often the horse's speed increases
@export var _speed_increase_ticks: int = 1200

## Set how much the horse's speed increases every [_speed_increase_ticks]
@export var _fixed_speed_increase_amount: int = 16384

## Set the horse's starting direction as an angle in degrees. 0 = right and it goes clockwise.
@export_range(0, 32) var _start_dir: int = 0

@export var _fixed_bounce_randomness: int = 983040

## The horse's full given name
var name: String:
	get:
		return _name

## The textures used by the horse
var textures: Array[Texture2D]:
	get:
		return _textures

## The horse's signature color
var color: Color:
	get:
		return _color

## The horse's base move speed
var base_speed: int:
	get:
		return _fixed_base_speed

## How often the horse's speed increases during a race
var speed_increase_ticks: int:
	get:
		return _speed_increase_ticks

## How much the speed increases by every [speed_increase_ticks]
var speed_increase_amount: int:
	get:
		return _fixed_speed_increase_amount

## The horse's starting direction as a number from 0 to 32 corresponding to one of the horse's
## animation frames
var start_dir: int:
	get:
		return _start_dir

## 3 character breviated name shown before each race starts
var name_abrev: String:
	get:
		return _name_abv

var bounce_randomness: int:
	get:
		return _fixed_bounce_randomness

## The texture that will appear on the victory screen when the horse wins a race
var victory_texture: Texture2D:
	get:
		return _victory_texture

var victory_theme: AudioStream:
	get:
		return _victory_theme

var neigh: AudioStream:
	get:
		return _neigh
