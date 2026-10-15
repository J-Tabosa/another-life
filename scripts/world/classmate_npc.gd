extends "res://scripts/world/dialogue_npc.gd"

signal meeting_requested(actor: Area2D)


func interact(player: CharacterBody2D) -> void:
	if can_interact(player):
		meeting_requested.emit(self)
