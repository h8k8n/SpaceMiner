extends Control

## Emitted when the player resumes the game.
signal resumed()
## Emitted when the player wants to open the upgrade menu.
signal upgrade_requested()
## Emitted when the player wants to go to the main menu.
signal main_menu_requested()
## Emitted when the pause key is pressed while in-game (not in this menu).
signal pause_toggled()

@onready var _resume_button: Button = %ResumeButton
@onready var _upgrade_button: Button = %UpgradeButton
@onready var _save_button: Button = %SaveButton
@onready var _main_menu_button: Button = %MainMenuButton

var _player: CharacterBody2D = null

## Bind this menu to the player node so it can trigger a save.
func setup(player: CharacterBody2D) -> void:
	_player = player

func _ready() -> void:
	_resume_button.pressed.connect(_on_resume_pressed)
	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	_save_button.pressed.connect(_on_save_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		if visible:
			_on_resume_pressed()
		else:
			pause_toggled.emit()
		get_viewport().set_input_as_handled()

func _on_resume_pressed() -> void:
	resumed.emit()
	hide()

func _on_upgrade_pressed() -> void:
	upgrade_requested.emit()
	hide()

func _on_save_pressed() -> void:
	if _player != null:
		SaveManager.save_game(_player)

func _on_main_menu_pressed() -> void:
	main_menu_requested.emit()
