extends Node2D

const BulletScene: PackedScene = preload("res://scenes/bullet/Bullet.tscn")
const AsteroidScene: PackedScene = preload("res://scenes/asteroid/Asteroid.tscn")
const PickupScene: PackedScene = preload("res://scenes/pickup/Pickup.tscn")
const FuelPickupScene: PackedScene = preload("res://scenes/pickup/FuelPickup.tscn")

## Maximum number of active asteroids (fragments count toward the total).
const MAX_ASTEROIDS: int = 8
## Number of large asteroids placed at game start.
const INITIAL_ASTEROIDS: int = 3
## Warning threshold: fraction of max below which warnings appear.
const WARNING_FUEL_RATIO: float = 0.25
const WARNING_HEALTH_RATIO: float = 0.30

@onready var _player := $PlayerShip
@onready var _joystick: Control = $HUD/VirtualJoystick
@onready var _fire_button: Button = $HUD/FireButton
@onready var _pause_button: Button = $HUD/PauseButton
@onready var _upgrade_menu: Control = $HUD/UpgradeMenu
@onready var _pause_menu: Control = $HUD/PauseMenu
@onready var _game_over: Control = $HUD/GameOver
@onready var _spawn_timer: Timer = $SpawnTimer
@onready var _cargo_label: Label = $HUD/StatsPanel/MarginContainer/VBox/CargoRow/CargoLabel
@onready var _fuel_bar: ProgressBar = $HUD/StatsPanel/MarginContainer/VBox/FuelRow/FuelBar
@onready var _health_bar: ProgressBar = $HUD/StatsPanel/MarginContainer/VBox/HealthRow/HealthBar
@onready var _low_fuel_warning: Label = $WarningLayer/LowFuelWarning
@onready var _low_health_warning: Label = $WarningLayer/LowHealthWarning
@onready var _cargo_full_warning: Label = $WarningLayer/CargoFullWarning

var _asteroid_count: int = 0
var _warning_blink_timer: float = 0.0
var _is_paused: bool = false

func _ready() -> void:
	randomize()
	# Apply persisted save data before wiring up UI signals so labels initialise correctly.
	var save_data: Dictionary = SaveManager.load_game()
	if not save_data.is_empty():
		_player.apply_save_data(save_data)
	_joystick.moved.connect(_player.set_joystick_input)
	_player.fired.connect(_on_player_fired)
	_player.cargo_changed.connect(_on_cargo_changed)
	_player.fuel_changed.connect(_on_fuel_changed)
	_player.health_changed.connect(_on_health_changed)
	_player.died.connect(_on_player_died)
	_fire_button.pressed.connect(_player.fire)
	_pause_button.pressed.connect(_on_pause_button_pressed)
	_upgrade_menu.closed.connect(_on_upgrade_menu_closed)
	_pause_menu.resumed.connect(_on_pause_resumed)
	_pause_menu.upgrade_requested.connect(_on_upgrade_from_pause)
	_pause_menu.main_menu_requested.connect(_on_go_to_main_menu)
	_pause_menu.pause_toggled.connect(_on_pause_button_pressed)
	_pause_menu.setup(_player)
	_game_over.retry_requested.connect(_on_retry)
	_game_over.main_menu_requested.connect(_on_go_to_main_menu)
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	# Initialise HUD values.
	_cargo_label.text = "%d / %d" % [_player.cargo, _player.max_cargo]
	_fuel_bar.max_value = _player.max_fuel
	_fuel_bar.value = _player.fuel
	_health_bar.max_value = _player.max_health
	_health_bar.value = _player.health
	for i in range(INITIAL_ASTEROIDS):
		_spawn_asteroid(0)

func _process(delta: float) -> void:
	# Blink warning labels every 0.5 seconds when their condition is met.
	_warning_blink_timer += delta
	if _warning_blink_timer >= 0.5:
		_warning_blink_timer = 0.0
		var low_fuel := _fuel_bar.value / _fuel_bar.max_value < WARNING_FUEL_RATIO
		var low_health := _health_bar.value / _health_bar.max_value < WARNING_HEALTH_RATIO
		var cargo_full := _player.cargo >= _player.max_cargo
		_low_fuel_warning.visible = low_fuel and not _low_fuel_warning.visible
		_low_health_warning.visible = low_health and not _low_health_warning.visible
		_cargo_full_warning.visible = cargo_full and not _cargo_full_warning.visible

func _on_player_fired(pos: Vector2, dir: Vector2, damage: int) -> void:
	var bullet := BulletScene.instantiate()
	add_child(bullet)
	bullet.init(pos, dir, damage)

func _on_pause_button_pressed() -> void:
	if _game_over.visible or _upgrade_menu.visible:
		return
	_is_paused = not _is_paused
	get_tree().paused = _is_paused
	if _is_paused:
		_pause_menu.show()
	else:
		_pause_menu.hide()

func _on_pause_resumed() -> void:
	_is_paused = false
	get_tree().paused = false

func _on_upgrade_from_pause() -> void:
	_is_paused = false
	get_tree().paused = false
	_upgrade_menu.setup(_player)
	_upgrade_menu.show()

func _on_upgrade_menu_closed() -> void:
	pass

func _on_go_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _on_retry() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

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
	_cargo_label.text = "%d / %d" % [current, maximum]

func _on_fuel_changed(current: float, maximum: float) -> void:
	_fuel_bar.max_value = maximum
	_fuel_bar.value = current

func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current

func _on_player_died() -> void:
	_spawn_timer.stop()
	_game_over.show_result(_player.cargo)

func _random_edge_position() -> Vector2:
	var vp := get_viewport_rect().size
	match randi() % 4:
		0: return Vector2(randf_range(0.0, vp.x), -55.0)
		1: return Vector2(randf_range(0.0, vp.x), vp.y + 55.0)
		2: return Vector2(-55.0, randf_range(0.0, vp.y))
		_: return Vector2(vp.x + 55.0, randf_range(0.0, vp.y))
