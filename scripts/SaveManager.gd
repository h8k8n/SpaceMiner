extends Node

const SAVE_PATH := "user://savegame.json"

## Saves player resources and upgrade levels to disk.
func save_game(player: CharacterBody2D) -> void:
	var data := {
		"cargo": player.cargo,
		"upgrade_levels": player.upgrade_levels.duplicate(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Could not open save file for writing.")
		return
	file.store_string(JSON.stringify(data))
	file.close()

## Loads saved data from disk. Returns an empty Dictionary if no save exists.
func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Could not open save file for reading.")
		return {}
	var text := file.get_as_text()
	file.close()
	var result = JSON.parse_string(text)
	if result is Dictionary:
		return result
	return {}

## Returns true if a save file exists on disk.
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## Deletes the save file from disk. Used when starting a new game.
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
