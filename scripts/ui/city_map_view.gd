extends Control

var source_position := Vector2(-1, -1)


func _draw() -> void:
	var factor := minf(size.x / 1620.0, size.y / 971.0)
	var map_size := Vector2(1620, 971) * factor
	var origin := (size - map_size) / 2
	draw_texture_rect(ReferenceCity.TEXTURE, Rect2(origin, map_size), false)
	if source_position.x >= 0:
		var point := origin + source_position * factor
		draw_circle(point, 7, Color.BLACK)
		draw_circle(point, 5, Color("ff5353"))
