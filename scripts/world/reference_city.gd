class_name ReferenceCity
extends RefCounted

const TEXTURE = preload("res://assets/world/fliegen_reference.png")
const SCALE := 6.0
static var _data: Dictionary = {}
static var _solids: Dictionary = {}
static var _land := PackedVector2Array()
static var _river := PackedVector2Array()


static func data() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/reference_city.json"))
		_land = WorldLayouts.road(_data.land, false)
		_river = WorldLayouts.road(_data.river, false)
	return _data


static func local_point(source: Array, crop: Rect2) -> Vector2:
	return (WorldLayouts.point(source) - crop.position) * SCALE


static func source_point(local: Vector2, crop: Rect2) -> Vector2:
	return local / SCALE + crop.position


static func water(point: Vector2) -> bool:
	data()
	return not Geometry2D.is_point_in_polygon(point, _land) or Geometry2D.is_point_in_polygon(point, _river)


static func on_road(point: Vector2, margin: float = 0) -> bool:
	for road in data().roads:
		for index in range(1, road.points.size()):
			var closest := Geometry2D.get_closest_point_to_segment(point, WorldLayouts.point(road.points[index - 1]), WorldLayouts.point(road.points[index]))
			if closest.distance_to(point) <= float(road.width) + margin:
				return true
	return false


static func collision_rects(crop: Rect2) -> Array[Rect2]:
	var key := str(crop)
	if _solids.has(key):
		return _solids[key]
	var result: Array[Rect2] = []
	var footprints: Array = data().extra_buildings.duplicate()
	for poi in data().pois:
		if poi.has("building"):
			footprints.append(poi.building)
	for footprint in footprints:
		var rect := WorldLayouts.rectangle(footprint).intersection(crop)
		if rect.has_area():
			result.append(Rect2((rect.position - crop.position) * SCALE, rect.size * SCALE))
	# Small water cells are merged into horizontal runs. Bridge/pier corridors
	# override water; the supplied illustration remains unchanged underneath.
	const CELL := 8
	for y in range(int(crop.position.y), int(crop.end.y), CELL):
		var run := -1
		for x in range(int(crop.position.x), int(crop.end.x) + CELL, CELL):
			var point := Vector2(x + CELL / 2.0, y + CELL / 2.0)
			var solid := x < crop.end.x and water(point) and not on_road(point, 8)
			if solid and run < 0:
				run = x
			elif not solid and run >= 0:
				result.append(Rect2((Vector2(run, y) - crop.position) * SCALE, Vector2(x - run, CELL) * SCALE))
				run = -1
	_solids[key] = result
	return result
