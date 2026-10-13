extends Area2D

signal reached(body: Node2D)


func _ready() -> void:
	body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			reached.emit(body)
	)


func _draw() -> void:
	draw_rect(Rect2(-64, -36, 128, 72), Color(0.95, 0.87, 0.57, 0.2))
	draw_rect(Rect2(-64, -36, 128, 72), Color("dfd5b5"), false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(-132, -110), tr("WAYFIND_ARRIVAL"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
