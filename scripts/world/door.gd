extends Area2D

signal transition_requested(target_area: StringName, spawn_id: StringName)

@export var target_area: StringName
@export var spawn_id: StringName = &"door"
@export var hint_key: StringName = &"LAB_INTERACT"


func can_interact(player: CharacterBody2D) -> bool:
	return overlaps_body(player)


func interact(player: CharacterBody2D) -> void:
	if can_interact(player):
		transition_requested.emit(target_area, spawn_id)
