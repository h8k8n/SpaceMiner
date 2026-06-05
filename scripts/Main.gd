extends Node2D

@onready var _player: CharacterBody2D = $PlayerShip
@onready var _joystick: Control = $HUD/VirtualJoystick

func _ready() -> void:
	_joystick.moved.connect(_player.set_joystick_input)
