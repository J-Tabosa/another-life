extends Area2D

signal dialogue_requested(data: DialogueData)

@export var dialogue: DialogueData
@export var hint_key: StringName = &"LAB_TALK"


func can_interact(player: CharacterBody2D) -> bool:
	return dialogue != null and overlaps_body(player)


func interact(player: CharacterBody2D) -> void:
	if can_interact(player):
		dialogue_requested.emit(dialogue)


func _draw() -> void:
	# Generic laboratory placeholder; no canonical NPC identity or final art.
	draw_rect(Rect2(-20, -48, 40, 40), Color("99c3e0"))
	draw_string(ThemeDB.fallback_font, Vector2(-64, -96), tr("LAB_NPC"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
