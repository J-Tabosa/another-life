class_name ReferenceRenderer
extends RefCounted

# Source coordinates are shared by rendering, collisions, doors and the map.
# All scenery below is geometric placeholder art; the reference stays in M.
static func draw(area: Node2D, crop: Rect2) -> void:
	var data := ReferenceCity.data()
	area.draw_set_transform(-crop.position * ReferenceCity.SCALE, 0, Vector2.ONE * ReferenceCity.SCALE)
	area.draw_rect(Rect2(crop.position, crop.size), Color("468daf"))
	area.draw_colored_polygon(WorldLayouts.road(data.land, false), Color("75935f"))
	area.draw_colored_polygon(WorldLayouts.road(data.river, false), Color("468daf"))
	# Distinct parks/courtyards and coast follow the illustration's footprints.
	for rect in [[627,95,285,164],[1192,117,237,176],[953,490,230,112],[45,608,365,183],[28,792,360,150],[140,359,242,207]]:
		area.draw_rect(WorldLayouts.rectangle(rect), Color("8eab69"))
	var sand := PackedVector2Array([Vector2(1440,373),Vector2(1408,480),Vector2(1360,590),Vector2(1333,680),Vector2(1315,774),Vector2(1355,800),Vector2(1380,735),Vector2(1425,690),Vector2(1385,637),Vector2(1400,530),Vector2(1464,385)])
	area.draw_colored_polygon(sand, Color("d8c391"))
	area.draw_rect(Rect2(418,840,125,58), Color("d8c391"))
	area.draw_rect(Rect2(913,778,411,132), Color("9b9587"))
	for road in data.roads:
		if road.id == "railway":
			continue
		var curve := Curve2D.new()
		curve.bake_interval = 2
		for index in range(road.points.size()):
			var point := WorldLayouts.point(road.points[index])
			var tangent := Vector2.ZERO
			if index > 0 and index < road.points.size() - 1:
				tangent = (WorldLayouts.point(road.points[index + 1]) - WorldLayouts.point(road.points[index - 1])) / 8
			curve.add_point(point, -tangent, tangent)
		var path := curve.get_baked_points()
		var width := float(road.width) * 2
		var trail: bool = road.id in ["camping_access", "hidden_beach_access", "amusement", "park_paths", "maple_paths", "campus_paths"]
		area.draw_polyline(path, Color("beb79c"), width + 5, true)
		area.draw_polyline(path, Color("a99c77") if trail else Color("626d70"), width, true)
		if not trail:
			area.draw_polyline(path, Color("989d90"), 0.5, true)
	for bridge in [[478,355,57,19],[471,515,64,20],[470,679,91,23]]:
		area.draw_rect(WorldLayouts.rectangle(bridge), Color("ae8661"))
	var railway: Array = data.roads[-1].points
	var rails := WorldLayouts.road(railway, false)
	area.draw_polyline(rails, Color("6c665d"), 8, true)
	area.draw_polyline(rails, Color("c5b997"), 5, true)
	area.draw_polyline(rails, Color("5b5a55"), 1, true)
	var footprints: Array = data.extra_buildings.duplicate()
	for poi in data.pois:
		if poi.has("building"):
			footprints.append(poi.building)
	var colors := [Color("b68771"),Color("819aa0"),Color("c5b07b"),Color("9e8da5")]
	for index in range(footprints.size()):
		var rect := WorldLayouts.rectangle(footprints[index])
		area.draw_rect(Rect2(rect.position + Vector2(3,5),rect.size), Color(0,0,0,0.19))
		area.draw_rect(rect, colors[index % colors.size()])
		area.draw_rect(Rect2(rect.position,Vector2(rect.size.x,7)),Color("dad2b2"))
		area.draw_rect(Rect2(rect.position + Vector2(4,rect.size.y-9),Vector2(rect.size.x-8,5)),Color("405e70"))
	# Landmark silhouettes remain placeholders, including non-building venues.
	for field in [[143,427,67,76],[1293,390,59,69]]:
		var rect := WorldLayouts.rectangle(field)
		area.draw_rect(rect,Color("5e9e6d"))
		area.draw_rect(rect.grow(-4),Color("d8d8ae"),false,0.8)
		area.draw_line(Vector2(rect.position.x,rect.get_center().y),Vector2(rect.end.x,rect.get_center().y),Color("d8d8ae"),0.8)
	for center in [Vector2(795,249), Vector2(780,492)]:
		area.draw_circle(center,13,Color("d2c18d"))
		area.draw_circle(center,9,Color("69a8bc"))
	area.draw_circle(Vector2(1055,547),28,Color("69a8bc"))
	for center in [Vector2(145,637),Vector2(235,661),Vector2(330,683)]:
		area.draw_arc(center,25,0,TAU,32,Color("e0bd79"),3,true)
		area.draw_line(center-Vector2(16,-29),center+Vector2(16,29),Color("896647"),2)
	for center in [Vector2(82,827),Vector2(166,856),Vector2(268,878)]:
		area.draw_colored_polygon(PackedVector2Array([center+Vector2(-12,9),center+Vector2(0,-11),center+Vector2(12,9)]),Color("d1a16b"))
	area.draw_rect(Rect2(1531,60,13,52),Color("e2d5b7"))
	area.draw_rect(Rect2(1531,78,13,10),Color("b96b58"))
	for point in [Vector2(1045,830),Vector2(1150,852)]:
		area.draw_line(point, point-Vector2(0,40),Color("d3aa59"),3)
		area.draw_line(point-Vector2(0,40),point+Vector2(36,-40),Color("d3aa59"),3)
		area.draw_line(point+Vector2(30,-40),point+Vector2(30,-15),Color("d3aa59"),1)
	for index in range(4):
		area.draw_rect(Rect2(1180+index*18,870,15,13), colors[index])
	# Decorative forest samples are stable across sector seams and stay away
	# from the catalogued streets, landmarks and building footprints.
	var random := RandomNumberGenerator.new()
	random.seed = 7341
	for index in range(1500):
		var point := Vector2(random.randf_range(7,1610),random.randf_range(7,963))
		if not crop.grow(10).has_point(point) or ReferenceCity.water(point) or ReferenceCity.on_road(point,12):
			continue
		var blocked := false
		for footprint in footprints:
			if WorldLayouts.rectangle(footprint).grow(6).has_point(point):
				blocked = true
				break
		for poi in data.pois:
			if WorldLayouts.point(poi.at).distance_to(point) < 20:
				blocked = true
		if not blocked:
			area.draw_circle(point,5,Color("456946"))
			area.draw_circle(point-Vector2(1,2),3.5,Color("62854d"))
	area.draw_set_transform(Vector2.ZERO)
	for poi in data.pois:
		if poi.id == "university" and area.region_id != &"overview":
			continue # The entrance/destination already labels this exact spot.
		if poi.sector == String(area.region_id) or area.region_id == &"overview":
			var position := ReferenceCity.local_point(poi.at,crop) + Vector2(-80,-50)
			area.draw_string(ThemeDB.fallback_font,position,area.tr("PLACE_"+String(poi.id).to_upper()),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("fff0c7"))
