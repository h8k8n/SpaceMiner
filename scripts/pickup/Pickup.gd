extends Area2D

## Amount of cargo this pickup adds when collected.
@export var amount: int = 1
## Amount of fuel this pickup restores when collected (0 = no fuel).
@export var fuel_amount: float = 0.0

## Emitted when the pickup is successfully collected.
signal collected(amount: int)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	var consumed := false
	if amount > 0 and body.has_method("try_collect"):
		if body.try_collect(amount):
			consumed = true
	if fuel_amount > 0.0 and body.has_method("refuel"):
		body.refuel(fuel_amount)
		consumed = true
	if consumed:
		collected.emit(amount)
		queue_free()
