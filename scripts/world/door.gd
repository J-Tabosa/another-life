extends Area2D

signal transition_requested(target_area: StringName, spawn_id: StringName)

@export var target_area: StringName
@export var spawn_id: StringName = &"door"
@export var hint_key: StringName = &"LAB_INTERACT"
@export var label_key: StringName


func can_interact(player: CharacterBody2D) -> bool:
	return overlaps_body(player)


func interact(player: CharacterBody2D) -> void:
	if can_interact(player):
		transition_requested.emit(target_area, spawn_id)


func _draw() -> void:
	if label_key.is_empty():
		draw_arc(Vector2.ZERO, 18, 0, TAU, 16, Color("fff1ae"), 3, true)
	if not label_key.is_empty():
		draw_rect(Rect2(-48, -16, 96, 32), Color("d5bc7e"))
		draw_string(ThemeDB.fallback_font, Vector2(-90, -30), tr(label_key), HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
