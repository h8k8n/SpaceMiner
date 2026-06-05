extends Control

## Emitted when the player closes the upgrade menu.
signal closed

## Upgrade definitions – each has an id, display label, description, and resource costs per level.
## There are 3 levels per upgrade (indices 0, 1, 2).
const UPGRADES: Array = [
	{
		"id": "speed",
		"label": "Engine Boost",
		"description": "Max speed +80",
		"costs": [3, 5, 8],
	},
	{
		"id": "cargo",
		"label": "Cargo Hold",
		"description": "Cargo capacity +5",
		"costs": [2, 4, 7],
	},
	{
		"id": "fuel",
		"label": "Fuel Tank",
		"description": "Max fuel +25",
		"costs": [2, 4, 6],
	},
	{
		"id": "laser",
		"label": "Laser Upgrade",
		"description": "Laser damage +1",
		"costs": [4, 6, 9],
	},
]

@onready var _resource_label: Label = %ResourceLabel
@onready var _close_button: Button = %CloseButton
@onready var _upgrades_container: VBoxContainer = %UpgradesContainer
@onready var _save_button: Button = %SaveButton

var _player: CharacterBody2D = null
var _level_labels: Array = []
var _cost_labels: Array = []
var _buy_buttons: Array = []

## Call this before showing the menu to bind it to the player node.
func setup(player: CharacterBody2D) -> void:
	_player = player
	_build_rows()
	_refresh()

func _ready() -> void:
	_close_button.pressed.connect(_on_close_pressed)
	_save_button.pressed.connect(_on_save_pressed)

func _on_close_pressed() -> void:
	closed.emit()
	hide()

func _on_save_pressed() -> void:
	if _player != null:
		SaveManager.save_game(_player)

## Builds one row per upgrade inside _upgrades_container (called once after setup).
func _build_rows() -> void:
	for child in _upgrades_container.get_children():
		child.queue_free()
	_level_labels.clear()
	_cost_labels.clear()
	_buy_buttons.clear()

	for i in range(UPGRADES.size()):
		var upg: Dictionary = UPGRADES[i]

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl := Label.new()
		name_lbl.text = upg["label"]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = upg["description"]
		desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(desc_lbl)

		var level_lbl := Label.new()
		level_lbl.custom_minimum_size = Vector2(70, 0)
		level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(level_lbl)

		var cost_lbl := Label.new()
		cost_lbl.custom_minimum_size = Vector2(80, 0)
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(cost_lbl)

		var buy_btn := Button.new()
		buy_btn.custom_minimum_size = Vector2(70, 0)
		buy_btn.pressed.connect(_on_buy_pressed.bind(i))
		row.add_child(buy_btn)

		_upgrades_container.add_child(row)
		_level_labels.append(level_lbl)
		_cost_labels.append(cost_lbl)
		_buy_buttons.append(buy_btn)

		# Separator between rows (not after the last one)
		if i < UPGRADES.size() - 1:
			_upgrades_container.add_child(HSeparator.new())

## Refreshes all labels and button states to reflect the current player stats.
func _refresh() -> void:
	if _player == null:
		return
	_resource_label.text = "Resources: %d" % _player.cargo
	for i in range(UPGRADES.size()):
		var upg: Dictionary = UPGRADES[i]
		var current_level: int = _player.upgrade_levels.get(upg["id"], 0)
		var max_level: int = upg["costs"].size()
		_level_labels[i].text = "Lv %d/%d" % [current_level, max_level]
		if current_level >= max_level:
			_buy_buttons[i].text = "MAX"
			_buy_buttons[i].disabled = true
			_cost_labels[i].text = ""
		else:
			var cost: int = upg["costs"][current_level]
			_cost_labels[i].text = "Cost: %d" % cost
			_buy_buttons[i].text = "Buy"
			_buy_buttons[i].disabled = _player.cargo < cost

func _on_buy_pressed(index: int) -> void:
	if _player == null:
		return
	var upg: Dictionary = UPGRADES[index]
	var current_level: int = _player.upgrade_levels.get(upg["id"], 0)
	if current_level >= upg["costs"].size():
		return
	var cost: int = upg["costs"][current_level]
	if not _player.spend_cargo(cost):
		return
	_player.apply_upgrade(upg["id"])
	_refresh()
