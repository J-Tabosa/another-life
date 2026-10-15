extends Area2D

signal dialogue_requested(data: DialogueData)

@export var dialogue: DialogueData
@export var hint_key: StringName = &"LAB_TALK"
@export var marker_key: StringName = &"LAB_NPC_MARKER"
@export var marker_offset := Vector2(-32, -96)
@export var marker_color := Color("99c3e0")


func can_interact(player: CharacterBody2D) -> bool:
	return dialogue != null and overlaps_body(player)


func interact(player: CharacterBody2D) -> void:
	if can_interact(player):
		dialogue_requested.emit(dialogue)


func _draw() -> void:
	# Generic laboratory placeholder; no canonical NPC identity or final art.
	draw_rect(Rect2(-20, -48, 40, 40), marker_color)
	draw_string(ThemeDB.fallback_font, marker_offset, tr(marker_key), HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
