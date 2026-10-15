extends Node2D

@export var region_id: StringName = &"street"
var layout: Dictionary
var map_size: Vector2
var exterior: bool
var tile_size: int = 32
var solids: Array[Rect2] = []
var collision_root: Node2D
var paths: Array[PackedVector2Array] = []


func _ready() -> void:
	if layout.is_empty():
		prepare()
	rebuild()


func prepare() -> void:
	layout = WorldLayouts.region(String(region_id))
	map_size = WorldLayouts.point(layout.size)
	exterior = layout.exterior
	paths.append(WorldLayouts.road(layout.main, exterior))
	for points in layout.roads:
		paths.append(WorldLayouts.road(points, exterior))
	var spawns := Node2D.new()
	spawns.name = "Spawns"
	add_child(spawns)
	for key in layout.spawns:
		var marker := Marker2D.new()
		marker.name = key
		marker.position = WorldLayouts.point(layout.spawns[key])
		spawns.add_child(marker)
	for data in layout.doors:
		var portal: Area2D = preload("res://scenes/world/door.tscn").instantiate()
		portal.name = data.name
		portal.position = WorldLayouts.point(data.at)
		portal.target_area = StringName(data.target)
		portal.spawn_id = StringName(data.spawn)
		portal.hint_key = StringName(data.hint)
		portal.label_key = StringName(data.get("label", data.hint))
		add_child(portal)
	for data in layout.signs:
		var sign_node: Node2D = preload("res://scenes/world/wayfinding_sign.tscn").instantiate()
		sign_node.position = WorldLayouts.point(data[0])
		sign_node.line_keys.assign(data[1])
		add_child(sign_node)
	if layout.has("npc"):
		var npc: Area2D = preload("res://scenes/world/dialogue_npc.tscn").instantiate()
		npc.name = "DialogueNPC"
		npc.position = WorldLayouts.point(layout.npc.at)
		npc.dialogue = load("res://data/dialogues/" + layout.npc.dialogue + ".tres")
		if region_id == &"university":
			npc.marker_key = &"CITY_GUIDE"
		add_child(npc)
	if layout.has("arrival"):
		var destination := preload("res://scenes/world/journey_destination.tscn").instantiate()
		destination.name = "EntranceArrival"
		destination.position = WorldLayouts.point(layout.arrival)
		add_child(destination)
	if layout.has("lesson"):
		var lesson := preload("res://scenes/world/interaction_point.tscn").instantiate()
		lesson.name = "LessonPoint"
		lesson.position = WorldLayouts.point(layout.lesson)
		add_child(lesson)
	if layout.has("reference_crop"):
		var crop := WorldLayouts.rectangle(layout.reference_crop)
		for data in ReferenceCity.data().pois:
			if data.sector != String(region_id):
				continue
			var marker := Area2D.new()
			marker.set_script(preload("res://scripts/world/place_marker.gd"))
			marker.name = "Place_" + data.id
			marker.position = ReferenceCity.local_point(data.at, crop)
			marker.title_key = StringName("PLACE_" + String(data.id).to_upper())
			add_child(marker)


func rebuild() -> void:
	if is_instance_valid(collision_root):
		remove_child(collision_root)
		collision_root.queue_free()
	collision_root = Node2D.new()
	add_child(collision_root)
	solids = [Rect2(0, 0, map_size.x, 32), Rect2(0, map_size.y - 32, map_size.x, 32), Rect2(0, 0, 32, map_size.y), Rect2(map_size.x - 32, 0, 32, map_size.y)]
	if layout.has("reference_crop"):
		solids.append_array(ReferenceCity.collision_rects(WorldLayouts.rectangle(layout.reference_crop)))
	for category in ["buildings", "water", "cliffs"]:
		for data in layout[category]:
			solids.append(WorldLayouts.rectangle(data))
	for rect in solids:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = rect.size
		shape.shape = rectangle
		body.position = rect.get_center()
		body.add_child(shape)
		collision_root.add_child(body)
	queue_redraw()


func _draw() -> void:
	if layout.is_empty():
		return
	if layout.has("reference_crop"):
		ReferenceRenderer.draw(self, WorldLayouts.rectangle(layout.reference_crop))
		return
	draw_rect(Rect2(Vector2.ZERO, map_size), Color("526f57") if exterior else Color("927f66"))
	for category in ["terraces", "plazas", "water"]:
		var color: Color = {"terraces": Color("6e885f"), "plazas": Color("a29779"), "water": Color("487e9b")}[category]
		for data in layout[category]:
			draw_rect(WorldLayouts.rectangle(data), color)
	for rect_data in layout.cliffs:
		var rect := WorldLayouts.rectangle(rect_data)
		draw_rect(rect, Color("5c5547"))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 16)), Color("b2a07b"))
	for index in range(paths.size()):
		var width := 180.0 if index == 0 else 124.0
		draw_polyline(paths[index], Color("b5ad96"), width + 48, true)
		draw_polyline(paths[index], Color("646d70") if exterior else Color("a99880"), width, true)
	for data in layout.bridges:
		var rect := WorldLayouts.rectangle(data)
		draw_rect(rect, Color("ad926b"))
		for x in range(int(rect.position.x), int(rect.end.x), 24):
			draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color("746551"), 2)
	for data in layout.ramps:
		var rect := WorldLayouts.rectangle(data)
		draw_rect(rect, Color("b4a78c"))
		for y in range(int(rect.position.y), int(rect.end.y), 32):
			draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color("776953"), 3)
	var colors := [Color("956c58"), Color("a3956d"), Color("677e8b"), Color("8b817e")]
	for index in range(layout.buildings.size()):
		var rect := WorldLayouts.rectangle(layout.buildings[index])
		draw_rect(Rect2(rect.position + Vector2(14, 18), rect.size), Color(0, 0, 0, 0.18))
		draw_rect(rect, colors[index % colors.size()])
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, minf(32, rect.size.y))), Color("ccc0a1"))
		if exterior:
			for x in range(int(rect.position.x + 32), int(rect.end.x - 24), 80):
				draw_rect(Rect2(x, rect.end.y - 48, 32, 22), Color("b4cfce"))
	for data in layout.trees:
		var point := WorldLayouts.point(data)
		draw_rect(Rect2(point, Vector2(12, 28)), Color("6d5742"))
		draw_circle(point + Vector2(6, -6), 42, Color("385642"))
		draw_circle(point + Vector2(-10, -22), 24, Color("668263"))
	for data in layout.labels:
		draw_string(ThemeDB.fallback_font, WorldLayouts.point(data[0]), tr(data[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("fff1d2"))
