extends Area2D

signal dialogue_requested(data: DialogueData)
signal lesson_requested
@export var dialogue: DialogueData
var hint_key: StringName = &"CITY_ACCESS_LESSON"


func can_interact(player: CharacterBody2D) -> bool:
	return overlaps_body(player)


func interact(player: CharacterBody2D) -> void:
	if can_interact(player):
		lesson_requested.emit()


func _draw() -> void:
	draw_rect(Rect2(-40, -24, 80, 48), Color("d9bb78"))
	draw_string(ThemeDB.fallback_font, Vector2(-100, -110), tr("CITY_LESSON_PLACEHOLDER"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
