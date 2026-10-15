extends Area2D

signal dialogue_requested(data: DialogueData)
var title_key: StringName
var hint_key: StringName = &"CITY_INSPECT_PLACE"


func _ready() -> void:
	add_to_group("interactables")
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 85
	collision.shape = shape
	add_child(collision)
	collision_layer = 0
	collision_mask = 1


func can_interact(player: CharacterBody2D) -> bool:
	return overlaps_body(player)


func interact(player: CharacterBody2D) -> void:
	if can_interact(player):
		var dialogue := DialogueData.new()
		dialogue.speaker_key = title_key
		dialogue.line_keys = PackedStringArray([String(title_key), "CITY_UNIVERSITY_ACCESS" if title_key == &"PLACE_UNIVERSITY" else "CITY_PLACE_RESERVED"])
		dialogue_requested.emit(dialogue)


func _draw() -> void:
	draw_arc(Vector2.ZERO, 20, 0, TAU, 24, Color("fff1ae"), 3, true)
