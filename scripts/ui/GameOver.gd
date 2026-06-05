extends Control

## Emitted when the player wants to retry.
signal retry_requested()
## Emitted when the player wants to go to the main menu.
signal main_menu_requested()

@onready var _retry_button: Button = %RetryButton
@onready var _main_menu_button: Button = %MainMenuButton
@onready var _score_label: Label = %ScoreLabel

func _ready() -> void:
	_retry_button.pressed.connect(_on_retry_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)

## Shows the game over screen with the player's final cargo score.
func show_result(cargo: int) -> void:
	_score_label.text = "Resources Collected: %d" % cargo
	show()

func _on_retry_pressed() -> void:
	retry_requested.emit()

func _on_main_menu_pressed() -> void:
	main_menu_requested.emit()
