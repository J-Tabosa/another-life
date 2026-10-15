extends "res://scripts/world/dialogue_npc.gd"

signal home_event_requested(actor: Area2D)
var actor_id: StringName


func interact(player: CharacterBody2D) -> void:
	if can_interact(player):
		home_event_requested.emit(self)
