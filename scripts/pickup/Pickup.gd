extends Area2D

## Amount of cargo this pickup adds when collected.
@export var amount: int = 1

## Emitted when the pickup is successfully collected.
signal collected(amount: int)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("try_collect"):
		if body.try_collect(amount):
			collected.emit(amount)
			queue_free()
