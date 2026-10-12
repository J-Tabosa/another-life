extends Area2D

signal sleep_requested
@export var hint_key: StringName = &"BED_INTERACT"


func can_interact(player: CharacterBody2D) -> bool:
	return overlaps_body(player)


func interact(player: CharacterBody2D) -> void:
	if can_interact(player):
		sleep_requested.emit()
