class_name WayfindingSign
extends Node2D

@export var line_keys: Array[StringName] = [&"WAYFIND_HORIZONTE", &"WAYFIND_HOME"]


func _draw() -> void:
	# Non-solid placeholder: never obstruct the walking corridor.
	draw_rect(Rect2(-4, -16, 8, 24), Color("dfd5b5"))
	draw_rect(Rect2(-160, -92, 320, 76), Color("243a43"))
	draw_rect(Rect2(-160, -92, 320, 76), Color("dfd5b5"), false, 2)
	for index in range(line_keys.size()):
		draw_string(ThemeDB.fallback_font, Vector2(-148, -65 + index * 24), tr(line_keys[index]), HORIZONTAL_ALIGNMENT_LEFT, 296, 18, Color("fff3cf"))
