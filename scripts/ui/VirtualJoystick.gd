extends Control

## Emitted on drag events with a normalised direction, and with Vector2.ZERO on release.
signal moved(direction: Vector2)
## Emitted when the finger lifts off the joystick.
signal released()

## Minimum drag distance (px) before registering movement.
@export var dead_zone: float = 10.0
## Maximum drag radius (px) from the touch origin.
@export var radius: float = 60.0

@onready var _base: Control = $Base
@onready var _stick: Control = $Base/Stick

var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO

func _ready() -> void:
	_base.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)

func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed and _touch_index == -1:
		_touch_index = event.index
		_center = event.position
		_base.global_position = _center - _base.size / 2.0
		_base.visible = true
		_stick.position = _base.size / 2.0 - _stick.size / 2.0
	elif not event.pressed and event.index == _touch_index:
		_touch_index = -1
		_base.visible = false
		moved.emit(Vector2.ZERO)
		released.emit()

func _on_drag(event: InputEventScreenDrag) -> void:
	if event.index != _touch_index:
		return
	var safe_radius := maxf(radius, 1.0)
	var offset: Vector2 = event.position - _center
	if offset.length() > safe_radius:
		offset = offset.normalized() * safe_radius
	_stick.position = _base.size / 2.0 - _stick.size / 2.0 + offset
	if offset.length() > dead_zone:
		moved.emit(offset / safe_radius)
	else:
		moved.emit(Vector2.ZERO)
