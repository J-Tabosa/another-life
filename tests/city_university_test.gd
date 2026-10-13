extends SceneTree

const LAB := preload("res://scenes/lab/scale_lab.tscn")
var checks: int = 0
var failures: int = 0
var lab: Node2D
var fade_captured: bool = false
var capturing: bool = false
var detail_captures: Dictionary = {}


func _initialize() -> void:
	run.call_deferred()


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error(description)


func settle() -> void:
	for tick in range(4):
		await physics_frame
	while lab.transitioning:
		await process_frame
	await process_frame


func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.device = InputEvent.DEVICE_ID_KEYBOARD
	event.pressed = true
	Input.parse_input_event(event.duplicate())
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await settle()


func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://docs/screenshots/" + filename) == OK, "rendered " + filename)


func overview(id: String) -> void:
	var player_camera: Camera2D = lab.player.get_node("Camera2D")
	player_camera.enabled = false
	var camera := Camera2D.new()
	camera.position = lab.area.map_size / 2
	var factor := minf(1280 / lab.area.map_size.x, 720 / lab.area.map_size.y) * 0.95
	camera.zoom = Vector2(factor, factor)
	lab.area.add_child(camera)
	camera.make_current()
	lab.get_node("HUD").hide()
	await process_frame
	await capture("city_" + id + "_overview.png")
	lab.get_node("HUD").show()
	camera.queue_free()
	player_camera.enabled = true
	player_camera.make_current()
	await process_frame


func walk_to(target: Vector2) -> bool:
	var deadline := Time.get_ticks_usec() + 5_000_000
	var tolerance := maxf(8, lab.player.speed * Engine.time_scale / 60 + 2)
	while lab.player.position.distance_to(target) > tolerance:
		var direction: Vector2 = target - lab.player.position
		for action in ["move_left", "move_right", "move_up", "move_down"]:
			Input.action_release(action)
		Input.action_press("move_right" if direction.x > 0 else "move_left", minf(1, absf(direction.x) / 24))
		Input.action_press("move_down" if direction.y > 0 else "move_up", minf(1, absf(direction.y) / 24))
		await physics_frame
		if Time.get_ticks_usec() > deadline or lab.sleep_manager.pending:
			break
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
	await physics_frame
	return lab.player.position.distance_to(target) <= tolerance + 3


func main_road(reverse: bool = false) -> void:
	var points: PackedVector2Array = lab.area.paths[0]
	if reverse:
		points.reverse()
	var reachable := true
	for index in range(0, points.size(), 4):
		if not await walk_to(points[index]):
			reachable = false
			break
		if capturing and not reverse and lab.area_id == &"route":
			var point := points[index]
			var detail := ""
			if absf(point.x - 1900) < 130 and point.y > 2200 and point.y < 2650:
				detail = "bridge"
			elif absf(point.x - 2900) < 100 and absf(point.y - 1460) < 150:
				detail = "ramp"
			if not detail.is_empty() and not detail_captures.has(detail):
				detail_captures[detail] = true
				await capture("city_" + detail + ".png")
	if reachable:
		reachable = await walk_to(points[-1])
	check(reachable, "physically traversed curved main road of " + String(lab.area_id) + (" in reverse" if reverse else ""))
	if not reachable:
		print("BLOCKED AT: ", lab.player.position)
		quit(1)


func door(name: String, target: StringName) -> void:
	var portal: Area2D = lab.area.get_node(name)
	check(await walk_to(portal.position) and portal.can_interact(lab.player), "walked to " + name)
	var old_area: StringName = lab.area_id
	var before: Dictionary = lab.time_manager.get_clock_state()
	var inspect_start := func() -> void:
		before.clear()
		before.merge(lab.time_manager.get_clock_state())
	lab.fade.started.connect(inspect_start)
	var inspect_cover := func() -> void:
		check(lab.area_id == old_area and lab.fade.shade.color.a == 1 and not lab.player.controls_enabled, "fade-out covers old map before swapping")
		check(lab.time_manager.get_clock_state() == before, "fade preserves clock and fractional time")
		if capturing and not fade_captured:
			fade_captured = true
			await capture("city_fade_black.png")
	lab.fade.covered.connect(inspect_cover)
	await key(KEY_E)
	lab.fade.covered.disconnect(inspect_cover)
	lab.fade.started.disconnect(inspect_start)
	check(lab.area_id == target and not lab.transitioning and not lab.fade.shade.visible, "fade-in finishes at " + String(target))
	check(lab.get_node("World").get_child_count() == 1 and lab.player.controls_enabled, "one active map and controls restored")


func run() -> void:
	Engine.max_fps = 60
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	capturing = "--capture" in OS.get_cmdline_user_args()
	lab = LAB.instantiate()
	lab.test_storage_root = "user://test_runs/city_" + str(Time.get_ticks_usec())
	root.add_child(lab)
	lab.fade.duration = 0.22 if capturing else 0.03
	Engine.time_scale = 1 if "--walk" in OS.get_cmdline_user_args() else 6
	await settle()
	await door("Door", &"street")
	if capturing:
		await capture("city_residential.png")
		await overview("street")
	await main_road()
	check(lab.area.layout.roads.size() == 4 and lab.area.layout.signs.size() == 2, "neighborhood has side streets, an alternate loop and only junction signs")
	await door("RouteDoor", &"route")
	if capturing:
		await overview("route")
	await main_road()
	check(lab.area.layout.ramps.size() == 1 and lab.area.layout.bridges.size() == 1, "river route includes traversable ramp and bridge")
	check(lab.area.layout.signs.size() == 2, "long route avoids repeated signage")
	await door("CampusDoor", &"campus")
	if capturing:
		await overview("campus")
	await main_road()
	check(not lab.journey.active and not lab.journey.result.is_empty(), "full journey finishes at university entrance")
	var arrival: Dictionary = lab.journey.result
	check(arrival.arrival_minutes < 540, "curved urban journey remains viable before 09h")
	print("CITY_WALK: %.3fs wall, +%d game minutes, %02d:%02d, margin %dmin, time_scale %.0f" % [arrival.seconds, arrival.minutes, int(arrival.arrival_minutes) / 60, int(arrival.arrival_minutes) % 60, arrival.margin_minutes, Engine.time_scale])
	if capturing:
		await capture("city_campus.png")
	await door("HallDoor", &"university")
	Engine.time_scale = 6
	var frozen: int = lab.time_manager.world_minutes
	lab.time_manager._process(120)
	check(not lab.time_manager.running and lab.time_manager.world_minutes == frozen, "university hall freezes natural time")
	if capturing:
		await capture("city_hall.png")
	check(await walk_to(Vector2(650, 600)), "hall guide is reachable")
	await key(KEY_E)
	check(lab.dialogue_panel.active and lab.dialogue_panel.get_node("Panel/Speaker").text == tr("CITY_GUIDE"), "guide conversation opens through shared interaction")
	await key(KEY_ESCAPE)
	check(lab.time_manager.world_minutes == frozen, "interior exploration and conversation consume no natural time")
	await main_road()
	await door("ClassroomDoor", &"classroom")
	await main_road()
	await key(KEY_E)
	check(lab.dialogue_panel.active and not lab.time_manager.running, "classroom lesson access opens placeholder dialogue without starting a schedule")
	await key(KEY_ESCAPE)
	if capturing:
		await capture("city_classroom.png")
	check(lab.save_manager.save_slot("manual", lab.snapshot()), "new interior is saved using schema two")
	check((await lab.load_slot("manual")) and lab.area_id == &"classroom" and not lab.time_manager.running, "classroom save reload preserves frozen interior")
	await main_road(true)
	await door("Door", &"university")
	await main_road(true)
	await door("Door", &"campus")
	await main_road(true)
	await door("Door", &"route")
	await main_road(true)
	await door("Door", &"street")
	await main_road(true)
	await door("Door", &"room")
	check(not lab.time_manager.running and not lab.journey.active, "return home ends walking and freezes time")
	# Migrate an actual legacy file without overwriting its bytes.
	var old: Dictionary = lab.snapshot()
	old.schema_version = 1
	old.player.area = "route"
	old.player.x = 12560
	old.player.y = 800
	var file := FileAccess.open(lab.save_manager.storage_root.path_join("manual.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	var original := FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json"))
	var restored_at_finish: Dictionary = {}
	lab.fade.finished.connect(func() -> void: restored_at_finish.merge(lab.time_manager.get_clock_state()), CONNECT_ONE_SHOT)
	check((await lab.load_slot("manual")) and lab.player.position == Vector2(240, 2800), "legacy straight-route save migrates to safe curved-map entrance")
	check(restored_at_finish.minutes == old.world.minutes and restored_at_finish.weekday_offset == old.world.weekday_offset and absf(restored_at_finish.fraction - old.world.fraction) < 0.000001 and FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json")) == original, "migration preserves gameplay values and leaves original file untouched")
	lab.change_area(&"classroom", &"door")
	lab.debug_jump((lab.time_manager.world_minutes / 1440 + 1) * 1440 + 240)
	await settle()
	check(lab.area_id == &"room" and lab.sleep_manager.was_outside and lab.sleep_panel.visible, "04h inside university returns home with fade and compulsory outside sleep")
	lab.sleep_panel.skip_button.pressed.emit()
	check(lab.time_manager.get_calendar().hour == 12, "university compulsory sleep wakes at 12h")
	check(not FileAccess.file_exists(lab.save_manager.storage_root.path_join("auto.json")), "autosave off remains respected through city transitions")
	# Separate fixtures after the full walking trial: every reserved side road
	# must also be traversable, and river/cliff barriers must remain solid.
	lab.time_manager.set_process(false)
	for id in [&"street", &"route", &"campus"]:
		lab.change_area(id, &"door")
		for index in range(1, lab.area.paths.size()):
			var path: PackedVector2Array = lab.area.paths[index]
			lab.player.position = path[0]
			await settle()
			var reachable := true
			for point_index in range(0, path.size(), 4):
				if not await walk_to(path[point_index]):
					reachable = false
					break
			check(reachable and await walk_to(path[-1]), "reserved side street %d in %s is accessible" % [index, id])
	lab.change_area(&"route", &"door")
	lab.player.position = Vector2(1760, 2000)
	await settle()
	Input.action_press("move_right")
	for tick in range(12):
		await physics_frame
	Input.action_release("move_right")
	check(lab.player.position.x <= 1788, "river blocks crossing away from bridge")
	lab.player.position = Vector2(3400, 1600)
	await settle()
	Input.action_press("move_up")
	for tick in range(12):
		await physics_frame
	Input.action_release("move_up")
	check(lab.player.position.y >= 1570, "cliff blocks climbing away from ramp")
	Engine.time_scale = 1
	lab.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
