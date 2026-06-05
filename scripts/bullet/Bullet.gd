extends Area2D

## Speed of the bullet in pixels per second.
@export var speed: float = 800.0
## Time in seconds before the bullet auto-destroys.
@export var lifetime: float = 2.0

var _direction: Vector2 = Vector2.ZERO
var _time_alive: float = 0.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)

## Initialises the bullet's start position and travel direction.
func init(start_position: Vector2, direction: Vector2) -> void:
	global_position = start_position
	_direction = direction.normalized()
	rotation = _direction.angle() + PI / 2.0

func _process(delta: float) -> void:
	global_position += _direction * speed * delta
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(1)
	queue_free()
