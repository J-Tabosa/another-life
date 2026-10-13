class_name WorldLayouts
extends RefCounted

static var _regions: Dictionary = {}


static func region(id: String) -> Dictionary:
	if _regions.is_empty():
		_regions = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/regions.json"))
	return _regions.get(id, {})


static func point(value: Array) -> Vector2:
	return Vector2(value[0], value[1])


static func rectangle(value: Array) -> Rect2:
	return Rect2(value[0], value[1], value[2], value[3])


static func bounds(id: String) -> Vector2:
	return Vector2(960, 640) if id == "room" else point(region(id).get("size", [0, 0]))


static func road(points: Array, smooth: bool = true) -> PackedVector2Array:
	var curve := Curve2D.new()
	curve.bake_interval = 24
	for index in range(points.size()):
		var position := point(points[index])
		var tangent := Vector2.ZERO
		if smooth and index > 0 and index < points.size() - 1:
			tangent = (point(points[index + 1]) - point(points[index - 1])) / 6.0
		curve.add_point(position, -tangent, tangent)
	return curve.get_baked_points()
