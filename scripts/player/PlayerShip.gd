extends CharacterBody2D

## Maximum movement speed in pixels per second.
@export var max_speed: float = 400.0
## Thrust force applied when accelerating forward.
@export var thrust: float = 600.0
## Rotation speed in radians per second.
@export var rotation_speed: float = 3.0
## Velocity damping factor applied each frame (simulates space drag).
@export var damping: float = 0.98

var _joystick_input: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	var input_dir := _get_input()

	# Rotate the ship based on horizontal input
	rotation += input_dir.x * rotation_speed * delta

	# Apply thrust in the ship's facing direction based on vertical input
	if input_dir.y < 0.0:
		velocity += Vector2.UP.rotated(rotation) * thrust * (-input_dir.y) * delta

	# Apply damping to simulate space drift, then clamp to max speed
	velocity *= damping
	velocity = velocity.limit_length(max_speed)

	move_and_collide(velocity * delta)

## Returns the active input direction, preferring joystick over keyboard.
func _get_input() -> Vector2:
	if _joystick_input.length() > 0.1:
		return _joystick_input
	return Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

## Receives direction from VirtualJoystick; call with Vector2.ZERO to stop.
func set_joystick_input(direction: Vector2) -> void:
	_joystick_input = direction
