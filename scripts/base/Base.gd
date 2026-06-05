extends Node2D

func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)

## Refuels any ship that enters the base docking zone.
func _on_body_entered(body: Node2D) -> void:
	if body.has_method("refuel"):
		body.refuel()
