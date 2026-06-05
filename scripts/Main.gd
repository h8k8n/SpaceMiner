extends Node2D

const BulletScene: PackedScene = preload("res://scenes/bullet/Bullet.tscn")
const AsteroidScene: PackedScene = preload("res://scenes/asteroid/Asteroid.tscn")
const PickupScene: PackedScene = preload("res://scenes/pickup/Pickup.tscn")
const FuelPickupScene: PackedScene = preload("res://scenes/pickup/FuelPickup.tscn")

## Maximum number of active asteroids (fragments count toward the total).
const MAX_ASTEROIDS: int = 8
## Number of large asteroids placed at game start.
const INITIAL_ASTEROIDS: int = 3

@onready var _player := $PlayerShip
@onready var _joystick: Control = $HUD/VirtualJoystick
@onready var _fire_button: Button = $HUD/FireButton
@onready var _spawn_timer: Timer = $SpawnTimer
@onready var _cargo_label: Label = $HUD/CargoLabel
@onready var _fuel_bar: ProgressBar = $HUD/FuelBar

var _asteroid_count: int = 0

func _ready() -> void:
	randomize()
	_joystick.moved.connect(_player.set_joystick_input)
	_player.fired.connect(_on_player_fired)
	_player.cargo_changed.connect(_on_cargo_changed)
	_player.fuel_changed.connect(_on_fuel_changed)
	_fire_button.pressed.connect(_player.fire)
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_cargo_label.text = "Cargo: 0/%d" % _player.max_cargo
	_fuel_bar.max_value = _player.max_fuel
	_fuel_bar.value = _player.fuel
	for i in range(INITIAL_ASTEROIDS):
		_spawn_asteroid(0)

func _on_player_fired(pos: Vector2, dir: Vector2) -> void:
	var bullet := BulletScene.instantiate()
	add_child(bullet)
	bullet.init(pos, dir)

func _on_spawn_timer_timeout() -> void:
	if _asteroid_count < MAX_ASTEROIDS:
		_spawn_asteroid(0)

func _spawn_asteroid(size: int) -> void:
	var spawn_pos := _random_edge_position()
	var asteroid := AsteroidScene.instantiate()
	asteroid.asteroid_size = size
	add_child(asteroid)
	asteroid.global_position = spawn_pos
	asteroid.setup_velocity(spawn_pos)
	asteroid.destroyed.connect(_on_asteroid_destroyed)
	_asteroid_count += 1

func _spawn_fragment(spawn_pos: Vector2, size: int) -> void:
	if _asteroid_count >= MAX_ASTEROIDS:
		return
	var asteroid := AsteroidScene.instantiate()
	asteroid.asteroid_size = size
	add_child(asteroid)
	var offset := Vector2(randf_range(-25.0, 25.0), randf_range(-25.0, 25.0))
	asteroid.global_position = spawn_pos + offset
	asteroid.setup_velocity(spawn_pos + offset, true)
	asteroid.destroyed.connect(_on_asteroid_destroyed)
	_asteroid_count += 1

func _on_asteroid_destroyed(pos: Vector2, size: int) -> void:
	_asteroid_count -= 1
	if size == 0:  # LARGE splits into two MEDIUM
		_spawn_fragment(pos, 1)
		_spawn_fragment(pos, 1)
	elif size == 1:  # MEDIUM splits into two SMALL
		_spawn_fragment(pos, 2)
		_spawn_fragment(pos, 2)
	else:  # SMALL: no further fragments, drops a pickup
		_spawn_pickup(pos)

func _spawn_pickup(pos: Vector2) -> void:
	var pickup: Area2D
	if randf() < 0.4:
		pickup = FuelPickupScene.instantiate()
	else:
		pickup = PickupScene.instantiate()
	add_child(pickup)
	pickup.global_position = pos

func _on_cargo_changed(current: int, maximum: int) -> void:
	_cargo_label.text = "Cargo: %d/%d" % [current, maximum]

func _on_fuel_changed(current: float, maximum: float) -> void:
	_fuel_bar.value = current

func _random_edge_position() -> Vector2:
	var vp := get_viewport_rect().size
	match randi() % 4:
		0: return Vector2(randf_range(0.0, vp.x), -55.0)
		1: return Vector2(randf_range(0.0, vp.x), vp.y + 55.0)
		2: return Vector2(-55.0, randf_range(0.0, vp.y))
		_: return Vector2(vp.x + 55.0, randf_range(0.0, vp.y))
