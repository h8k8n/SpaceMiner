extends Control

@onready var _play_button: Button = %PlayButton
@onready var _quit_button: Button = %QuitButton
@onready var _continue_button: Button = %ContinueButton

func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_continue_button.visible = SaveManager.has_save()

func _on_play_pressed() -> void:
	SaveManager.delete_save()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
