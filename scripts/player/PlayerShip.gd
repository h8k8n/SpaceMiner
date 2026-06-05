extends CharacterBody2D

## Maximum movement speed in pixels per second.
@export var max_speed: float = 400.0
## Thrust force applied when accelerating forward.
@export var thrust: float = 600.0
## Rotation speed in radians per second.
@export var rotation_speed: float = 3.0
## Velocity damping factor applied each frame (simulates space drag).
@export var damping: float = 0.98
## Minimum seconds between consecutive shots.
@export var fire_cooldown: float = 0.25
## Maximum number of resource units the cargo hold can store.
@export var max_cargo: int = 10
## Maximum fuel capacity.
@export var max_fuel: float = 100.0
## Fuel drained per second while thrusting.
@export var fuel_drain_rate: float = 10.0

## Emitted when the ship fires; carries the muzzle position, shot direction, and damage.
signal fired(position: Vector2, direction: Vector2, damage: int)
## Emitted when cargo changes; carries current amount and maximum capacity.
signal cargo_changed(current: int, maximum: int)
## Emitted when fuel changes; carries current fuel and maximum fuel.
signal fuel_changed(current: float, maximum: float)

var _joystick_input: Vector2 = Vector2.ZERO
var _fire_timer: float = 0.0
## Current cargo amount.
var cargo: int = 0
## Current fuel level.
var fuel: float = 100.0
## Damage dealt by each laser shot; increased by laser upgrades.
var laser_damage: int = 1
## Current upgrade level for each stat (0 = base, max 3).
var upgrade_levels: Dictionary = {"speed": 0, "cargo": 0, "fuel": 0, "laser": 0}

# Base (un-upgraded) stat values stored at startup for save/load reconstruction.
var _base_max_speed: float
var _base_max_cargo: int
var _base_max_fuel: float

func _ready() -> void:
	_base_max_speed = max_speed
	_base_max_cargo = max_cargo
	_base_max_fuel = max_fuel

func _physics_process(delta: float) -> void:
	var input_dir := _get_input()

	# Rotate the ship based on horizontal input
	rotation += input_dir.x * rotation_speed * delta

	# Apply thrust in the ship's facing direction based on vertical input; requires fuel
	if input_dir.y < 0.0 and fuel > 0.0:
		var thrust_factor := -input_dir.y
		velocity += Vector2.UP.rotated(rotation) * thrust * thrust_factor * delta
		var prev_fuel := fuel
		fuel = max(0.0, fuel - fuel_drain_rate * thrust_factor * delta)
		if fuel != prev_fuel:
			fuel_changed.emit(fuel, max_fuel)

	# Apply damping to simulate space drift, then clamp to max speed
	velocity *= damping
	velocity = velocity.limit_length(max_speed)

	move_and_slide()

	if _fire_timer > 0.0:
		_fire_timer = max(0.0, _fire_timer - delta)
	if Input.is_action_just_pressed("mine"):
		fire()

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

## Fires a bullet in the ship's current facing direction.
func fire() -> void:
	if _fire_timer > 0.0:
		return
	_fire_timer = fire_cooldown
	var direction := Vector2.UP.rotated(rotation)
	fired.emit(global_position + direction * 35.0, direction, laser_damage)

## Tries to add amount to cargo. Returns true if collected, false if cargo is full.
func try_collect(amount: int) -> bool:
	if cargo >= max_cargo:
		return false
	cargo = min(cargo + amount, max_cargo)
	cargo_changed.emit(cargo, max_cargo)
	return true

## Refuels the ship. Pass amount=-1 to fill completely.
func refuel(amount: float = -1.0) -> void:
	if amount < 0.0:
		fuel = max_fuel
	else:
		fuel = min(fuel + amount, max_fuel)
	fuel_changed.emit(fuel, max_fuel)

## Spends the given amount of cargo as upgrade currency.
## Returns true if successful, false if not enough cargo.
func spend_cargo(amount: int) -> bool:
	if cargo < amount:
		return false
	cargo -= amount
	cargo_changed.emit(cargo, max_cargo)
	return true

## Applies the next level of the specified upgrade.
func apply_upgrade(upgrade_id: String) -> void:
	upgrade_levels[upgrade_id] += 1
	match upgrade_id:
		"speed":
			max_speed += 80.0
		"cargo":
			max_cargo += 5
			cargo_changed.emit(cargo, max_cargo)
		"fuel":
			max_fuel += 25.0
			fuel_changed.emit(fuel, max_fuel)
		"laser":
			laser_damage += 1

## Restores player state from a save data dictionary produced by SaveManager.
func apply_save_data(data: Dictionary) -> void:
	upgrade_levels = data.get("upgrade_levels", {"speed": 0, "cargo": 0, "fuel": 0, "laser": 0}).duplicate()
	# Rebuild derived stats from the original base export values and upgrade levels.
	max_speed = _base_max_speed + upgrade_levels.get("speed", 0) * 80.0
	max_cargo = _base_max_cargo + upgrade_levels.get("cargo", 0) * 5
	max_fuel = _base_max_fuel + upgrade_levels.get("fuel", 0) * 25.0
	laser_damage = 1 + upgrade_levels.get("laser", 0)
	cargo = mini(data.get("cargo", 0), max_cargo)
