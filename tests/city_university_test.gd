extends SceneTree

var checks := 0
var failures := 0
var lab: Node2D
var capture_enabled := false

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)
	else:
		print("PASS: " + description)

func settle() -> void:
	for tick in range(4):
		await physics_frame
	while lab.transitioning:
		await process_frame
	await process_frame

func interact(name: String) -> void:
	lab.player.position = lab.area.get_node(name).position
	await settle()
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	lab._unhandled_input(event)
	await settle()

func walk_to(target: Vector2) -> bool:
	var deadline := Time.get_ticks_usec() + 5_000_000
	var tolerance: float = lab.player.speed * Engine.time_scale / 60 + 5
	while lab.player.position.distance_to(target) > tolerance:
		var direction: Vector2 = target - lab.player.position
		for action in ["move_left", "move_right", "move_up", "move_down"]:
			Input.action_release(action)
		if absf(direction.x) > tolerance / 2:
			Input.action_press("move_right" if direction.x > 0 else "move_left")
		if absf(direction.y) > tolerance / 2:
			Input.action_press("move_down" if direction.y > 0 else "move_up")
		await physics_frame
		if Time.get_ticks_usec() > deadline or lab.sleep_manager.pending:
			break
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
	await physics_frame
	return lab.player.position.distance_to(target) <= tolerance + 3

func walk_main() -> void:
	var reachable := true
	for point in lab.area.layout.main:
		if not await walk_to(WorldLayouts.point(point)):
			reachable = false
			print("BLOCKED at ", lab.player.position, " towards ", point)
			break
	check(reachable, "physical walking of reference road in " + String(lab.area_id))

func accessibility() -> void:
	const CELL := 48
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO, Vector2i(lab.area.map_size / CELL) + Vector2i.ONE)
	grid.cell_size = Vector2(CELL, CELL)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for obstacle in lab.area.solids:
		var rect: Rect2 = obstacle.grow(16)
		for x in range(maxi(0, ceili(rect.position.x / CELL)), mini(grid.region.end.x, floori(rect.end.x / CELL) + 1)):
			for y in range(maxi(0, ceili(rect.position.y / CELL)), mini(grid.region.end.y, floori(rect.end.y / CELL) + 1)):
				grid.set_point_solid(Vector2i(x, y))
	var origin := Vector2i((lab.area.get_node("Spawns/door").position / CELL).round())
	for poi in ReferenceCity.data().pois:
		if poi.sector != String(lab.area_id):
			continue
		var marker: Area2D = lab.area.get_node("Place_" + poi.id)
		var destination := Vector2i((marker.position / CELL).round())
		check(not grid.get_id_path(origin, destination).is_empty(), "connected walkable approach to " + poi.name)
		lab.player.position = marker.position
		await settle()
		check(marker.can_interact(lab.player), "physical overlap at " + poi.name)
		marker.interact(lab.player)
		check(lab.dialogue_panel.active, "inspection available at " + poi.name)
		lab.dialogue_panel.close()
	for door in lab.area.layout.doors:
		var destination: Dictionary = WorldLayouts.region(door.target) if door.target != "room" else {}
		if destination.has("reference_crop"):
			var spawn := WorldLayouts.point(destination.spawns[door.spawn])
			var blocked := false
			for obstacle in ReferenceCity.collision_rects(WorldLayouts.rectangle(destination.reference_crop)):
				if obstacle.intersects(Rect2(spawn - Vector2(12,14), Vector2(24,14))):
					blocked = true
			check(not blocked, "safe arrival from " + String(lab.area_id) + "/" + door.name)
	# Validate road centerlines against the actual physics world, including
	# every bridge and every side street. Rails are scenery, not a footpath.
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = lab.player.get_node("CollisionShape2D").shape
	query.exclude = [lab.player.get_rid()]
	var crop := WorldLayouts.rectangle(lab.area.layout.reference_crop)
	for road in ReferenceCity.data().roads:
		if road.id == "railway":
			continue
		var blocked_at: Array[Vector2] = []
		var sampled := 0
		for index in range(1, road.points.size()):
			var from := WorldLayouts.point(road.points[index-1])
			var to := WorldLayouts.point(road.points[index])
			var steps := maxi(1, ceili(from.distance_to(to) / 8))
			for step in range(steps+1):
				var source := from.lerp(to, float(step)/steps)
				if not crop.grow(-10).has_point(source):
					continue
				sampled += 1
				query.transform = Transform2D(0, (source-crop.position)*6-Vector2(0,7))
				if not lab.area.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty():
					blocked_at.append(source)
		if sampled:
			check(blocked_at.is_empty(), "physics road clearance " + String(lab.area_id) + "/" + road.id)
			if not blocked_at.is_empty():
				print("ROAD BLOCKS ", road.id, ": ", blocked_at)

func capture(name: String) -> void:
	if not capture_enabled:
		return
	await settle()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://docs/screenshots/" + name + ".png") == OK, "render " + name)


func overview_geometry() -> void:
	if not capture_enabled:
		return
	var camera: Camera2D = lab.player.get_node("Camera2D")
	camera.enabled = false
	# The full crop is drawn ONLY for this review screenshot.
	var overview := Node2D.new()
	root.add_child(overview)
	var sector: Node2D = lab.AREAS[&"campus"].instantiate()
	sector.layout = WorldLayouts.region("campus").duplicate(true)
	sector.layout.reference_crop = [0,0,1620,971]
	sector.map_size = Vector2(9720,5826)
	sector.exterior = true
	sector.region_id = &"overview"
	overview.add_child(sector)
	var review_camera := Camera2D.new()
	review_camera.position = Vector2(4860,2913)
	review_camera.zoom = Vector2.ONE * 0.12
	overview.add_child(review_camera)
	review_camera.make_current()
	lab.get_node("HUD").hide()
	lab.get_node("World").hide()
	lab.player.hide()
	await capture("reference_geometry_overview")
	lab.get_node("HUD").show()
	lab.get_node("World").show()
	lab.player.show()
	overview.queue_free()
	camera.enabled = true
	camera.make_current()
	await process_frame

func run() -> void:
	Engine.max_fps = 120
	Engine.time_scale = 6
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	capture_enabled = "--capture" in OS.get_cmdline_user_args()
	lab = load("res://scenes/lab/scale_lab.tscn").instantiate()
	lab.test_storage_root = "user://test_runs/city_" + str(Time.get_ticks_usec())
	root.add_child(lab)
	lab.fade.duration = 0.22 if capture_enabled else 0.03
	lab.time_manager.set_process(false)
	check(ReferenceCity.TEXTURE.get_size() == Vector2(1620, 971) and ReferenceCity.SCALE == 6, "original image and uniform 6x scale")
	check(ReferenceCity.data().pois.size() == 22 and ReferenceCity.data().roads.size() == 34, "22 landmarks and 34 mapped road/path/rail segments")
	for id in [&"street", &"route", &"campus"]:
		lab.change_area(id, &"door")
		await settle()
		var crop := WorldLayouts.rectangle(lab.area.layout.reference_crop)
		check(lab.area.map_size == crop.size * 6 and lab.area.exterior, "reference proportions and exterior in " + String(id))
		check(lab.player.get_node("Camera2D").zoom == Vector2.ONE and lab.player.scale == Vector2.ONE, "unchanged character and camera scale in " + String(id))
		await accessibility()
		lab.player.position = lab.area.get_node("Spawns/door").position
		await capture("reference_" + String(id))
	# Every seam, including alternate routes, is usable in both directions.
	for id in [&"street", &"route", &"campus"]:
		var doors: Array = WorldLayouts.region(String(id)).doors.duplicate(true)
		for portal in doors:
			if portal.target not in ["street", "route", "campus"]:
				continue
			lab.change_area(id, &"door")
			var before_transition: Dictionary = lab.time_manager.get_clock_state()
			await interact(portal.name)
			check(lab.area_id == StringName(portal.target) and lab.player.position == WorldLayouts.point(lab.area.layout.spawns[portal.spawn]), "reversible street transition " + String(id) + "/" + portal.name)
			check(lab.time_manager.get_clock_state() == before_transition and lab.player.controls_enabled, "street transition preserves time and controls")
	await overview_geometry()
	lab.change_area(&"room", &"door")
	await interact("Door")
	check(lab.area_id == &"street" and lab.journey.active, "home exit begins commute")
	var before: int = lab.time_manager.world_minutes
	lab.time_manager.set_process(true)
	if "--walk" in OS.get_cmdline_user_args():
		Engine.time_scale = 1
	await walk_main()
	await interact("RouteDoor")
	check(lab.area_id == &"route", "neighborhood to center fade transition")
	await walk_main()
	await interact("CampusDoor")
	check(lab.area_id == &"campus", "center to west sector fade transition")
	await walk_main()
	check(not lab.journey.result.is_empty() and lab.time_manager.world_minutes > before and lab.time_manager.world_minutes < 540, "walking finishes university arrival before 09h")
	print("COMMUTE: ", lab.journey.result)
	Engine.time_scale = 6
	lab.time_manager.set_process(false)
	await capture("reference_university")
	await interact("HallDoor")
	check(lab.area_id == &"university" and not lab.time_manager.running, "hall entry freezes natural time")
	await interact("DialogueNPC")
	check(lab.dialogue_panel.active, "university guide remains accessible")
	lab.dialogue_panel.close()
	await interact("ClassroomDoor")
	check(lab.area_id == &"classroom" and not lab.time_manager.running, "History classroom still accessible")
	await interact("LessonPoint")
	check(lab.academic_panel.visible, "lesson point opens actual academic agenda")
	lab.academic_panel.close()
	await interact("Door")
	await interact("Door")
	await interact("Door")
	await interact("Door")
	await interact("Door")
	check(lab.area_id == &"room", "complete return through all five portals")
	lab.change_area(&"street", &"door")
	lab.fade.covered.connect(func() -> void: check(not lab.player.controls_enabled and not lab.time_manager.running and lab.fade.shade.color.a > 0.99, "fade covers transition with frozen movement/time"), CONNECT_ONE_SHOT)
	lab.request_transition(&"route", &"door")
	await settle()
	check(lab.area_id == &"route" and not lab.transitioning and not lab.fade.active, "fade completes and releases controls")
	lab.city_map.region_id = lab.area_id
	lab.city_map.player_position = lab.player.position
	lab.city_map.open()
	check(not lab.player.controls_enabled and not lab.time_manager.running, "overview pauses outdoor movement and time")
	await capture("reference_overview")
	lab.city_map.close()
	Engine.time_scale = 1
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
