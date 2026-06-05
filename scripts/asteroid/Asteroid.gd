extends Area2D

enum Size { LARGE = 0, MEDIUM = 1, SMALL = 2 }

const HEALTH: Dictionary = { 0: 3, 1: 2, 2: 1 }
const SCALE_MAP: Dictionary = { 0: 1.8, 1: 1.0, 2: 0.55 }
const SPEED_RANGE: Dictionary = { 0: [30.0, 60.0], 1: [60.0, 110.0], 2: [110.0, 180.0] }

## Emitted when health reaches zero; provides world position and size index.
signal destroyed(position: Vector2, size: int)

## Size of this asteroid (Size enum value); set before adding to the scene tree.
@export var asteroid_size: int = Size.LARGE

var _health: int = 1
var _velocity: Vector2 = Vector2.ZERO
var _is_destroyed: bool = false

func _ready() -> void:
	_health = HEALTH[asteroid_size]
	scale = Vector2.ONE * SCALE_MAP[asteroid_size]

## Configures the drift velocity based on spawn position.
## Pass random_direction = true for fragments spawned in the play field.
func setup_velocity(spawn_position: Vector2, random_direction: bool = false) -> void:
	var range_vals: Array = SPEED_RANGE[asteroid_size]
	var speed := randf_range(range_vals[0], range_vals[1])
	if random_direction:
		_velocity = Vector2.from_angle(randf_range(0.0, TAU)) * speed
	else:
		var vp_size := get_viewport_rect().size
		var center := vp_size / 2.0
		var to_center := (center - spawn_position).normalized()
		var spread := randf_range(-PI / 3.0, PI / 3.0)
		_velocity = to_center.rotated(spread) * speed

func _process(delta: float) -> void:
	global_position += _velocity * delta
	_wrap_around()

func _wrap_around() -> void:
	var vp := get_viewport_rect().size
	var margin := 70.0
	if global_position.x < -margin:
		global_position.x = vp.x + margin
	elif global_position.x > vp.x + margin:
		global_position.x = -margin
	if global_position.y < -margin:
		global_position.y = vp.y + margin
	elif global_position.y > vp.y + margin:
		global_position.y = -margin

## Reduces health by amount; emits destroyed and frees the node when health hits zero.
func take_damage(amount: int) -> void:
	if _is_destroyed:
		return
	_health -= amount
	if _health <= 0:
		_is_destroyed = true
		destroyed.emit(global_position, asteroid_size)
		queue_free()
