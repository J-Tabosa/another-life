extends SceneTree

const LAB := preload("res://scenes/lab/scale_lab.tscn")
var checks: int = 0
var failures: int = 0
var walked_pixels: float = 0.0
var lab: Node2D


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
	await process_frame


func walk_to(target: Vector2) -> void:
	var deadline := Time.get_ticks_usec() + 85_000_000
	while lab.player.position.distance_to(target) > maxf(10, lab.player.speed * Engine.time_scale / 60.0 + 1):
		var direction: Vector2 = target - lab.player.position
		for action in ["move_left", "move_right", "move_up", "move_down"]:
			Input.action_release(action)
		Input.action_press("move_right" if direction.x > 0 else "move_left", minf(1, absf(direction.x) / 24))
		Input.action_press("move_down" if direction.y > 0 else "move_up", minf(1, absf(direction.y) / 24))
		var before: Vector2 = lab.player.position
		await physics_frame
		walked_pixels += lab.player.position.distance_to(before)
		if Time.get_ticks_usec() > deadline:
			break
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
	await settle()
	check(lab.player.position.distance_to(target) <= maxf(16, lab.player.speed * Engine.time_scale / 60.0 + 2), "walked to %s in %s without teleporting" % [target, lab.area_id])


func use_portal(name: String, expected_area: StringName) -> void:
	var portal: Area2D = lab.area.get_node(name)
	await walk_to(portal.position)
	check(portal.can_interact(lab.player), "walked into actual overlap of " + name)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.keycode = KEY_E
	event.device = InputEvent.DEVICE_ID_KEYBOARD
	event.pressed = true
	Input.parse_input_event(event.duplicate())
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await settle()
	check(lab.area_id == expected_area, "E transitioned to " + String(expected_area))


func capture(filename: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://docs/screenshots/" + filename) == OK, "rendered " + filename)


func reach_entrance() -> void:
	await use_portal("Door", &"street")
	check(lab.journey.active and lab.journey.origin == &"home", "measurement begins at the home exit")
	check(lab.area.get_node("Directions").line_keys == [&"WAYFIND_HORIZONTE", &"WAYFIND_HOME_UP"], "residential sign points to campus and back home")
	if "--capture" in OS.get_cmdline_user_args() and lab.journey.start_minutes < 420:
		await capture("signposted_street.png")
	await use_portal("RouteDoor", &"route")
	var signs: Array[Node] = lab.area.get_node("RouteSigns").get_children()
	check(signs.size() == 19 and signs[0].line_keys == [&"WAYFIND_HORIZONTE", &"WAYFIND_HOME"], "route has repeated bidirectional signs")
	check(signs[1].position.x - signs[0].position.x < 960, "sign spacing fits the smallest tested viewport")
	if "--capture" in OS.get_cmdline_user_args() and lab.journey.start_minutes < 420:
		await capture("signposted_route.png")
	await use_portal("CampusDoor", &"campus")
	check(lab.journey.active and lab.journey.result.is_empty(), "entering the patio alone does not finish the home-to-building trial")
	await walk_to(Vector2(1504, 800))
	await walk_to(Vector2(1504, 680))
	check(lab.area.get_node("EntranceArrival").overlaps_body(lab.player) and not lab.journey.active, "building entrance destination is reached by physical walking")


func run() -> void:
	Engine.max_fps = 60
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	lab = LAB.instantiate()
	lab.test_storage_root = "user://test_runs/signposted_" + str(Time.get_ticks_usec())
	root.add_child(lab)
	await settle()
	# Default runs the production physics/clock accelerated; --walk keeps 1:1
	# real time for the first entire home-to-entrance journey.
	Engine.time_scale = 1.0 if "--walk" in OS.get_cmdline_user_args() else 8.0
	await reach_entrance()
	var arrival: Dictionary = lab.journey.result.duplicate()
	check(arrival.origin == &"home" and arrival.arrival_minutes < 9 * 60 and arrival.minutes >= 70 and arrival.minutes <= 90, "06h departure reaches the building before 09h at production speed")
	check(arrival.margin_minutes >= 90 and lab._journey_text().contains("antes das 09h"), "arrival displays a comfortable margin without recording attendance")
	print("HOME_TO_ENTRANCE: %.3fs wall, %.1fpx, +%d game minutes, arrival %02d:%02d, margin %dmin, time_scale %.0f" % [arrival.seconds, walked_pixels, arrival.minutes, int(arrival.arrival_minutes) / 60, int(arrival.arrival_minutes) % 60, arrival.margin_minutes, Engine.time_scale])
	if "--capture" in OS.get_cmdline_user_args():
		await capture("signposted_arrival.png")
		root.size = Vector2i(960, 540)
		await capture("signposted_arrival_960.png")
		check(lab.get_node("HUD/Info").get_line_count() <= 3, "arrival HUD fits three lines above controls at 960x540")
		root.size = Vector2i(1280, 720)
		lab.player.position = Vector2(800, 800)
		await capture("signposted_campus.png")
		# Restore the capture-only pose; never used in the walking measurement.
		lab.player.position = Vector2(1504, 680)
		await settle()
	# Return over the same real passages, using accelerated physics/clock.
	Engine.time_scale = 8
	await walk_to(Vector2(1504, 800))
	await walk_to(Vector2(1504, 680))
	check(lab.journey.result == arrival, "re-entering arrival zone does not rewrite a completed trial")
	await walk_to(Vector2(1504, 800))
	await use_portal("Door", &"route")
	await use_portal("Door", &"street")
	await use_portal("Door", &"room")
	check(not lab.time_manager.running and not lab.journey.active and lab.journey.result.is_empty(), "return home freezes time and resets the walking trial")
	# Deliberately late departure: no deadline lock or academic consequences.
	lab.debug_jump(8 * 60)
	await reach_entrance()
	check(lab.journey.result.arrival_minutes > 9 * 60 and lab._journey_text().contains("depois das 09h"), "late departure still reaches the destination and shows delay")
	check(lab.player.controls_enabled and not lab.sleep_manager.pending, "late arrival never blocks exploration or starts an academic system")
	# Diagnostic trials never survive time jumps, loads or lab teleports.
	lab.change_area(&"route", &"door")
	check(lab.journey.origin == &"route", "starting at the route is identified as a partial trial")
	lab.debug_jump(lab.time_manager.world_minutes + 5)
	check(not lab.journey.active and lab.journey.result.is_empty(), "debug time jump invalidates the trial")
	lab.change_area(&"room", &"door")
	lab.change_area(&"street", &"door")
	var compare := InputEventAction.new()
	compare.action = &"compare_scale"
	compare.pressed = true
	lab._unhandled_input(compare)
	check(not lab.journey.active and lab.journey.result.is_empty(), "tile comparison teleport invalidates the trial")
	lab.change_area(&"route", &"door")
	var sign_count: int = lab.area.get_node("RouteSigns").get_child_count()
	for tile in [32, 64]:
		lab.area.tile_size = tile
		lab.area.rebuild()
	check(lab.area.get_node("RouteSigns").get_child_count() == sign_count and lab.player.scale == Vector2.ONE and lab.player.get_node("Camera2D").zoom == Vector2.ONE, "32/64 rebuild preserves signs and pixel scale")
	check(lab.save_manager.save_slot("manual", lab.snapshot()), "existing save schema accepts the signposted route")
	check(lab.load_slot("manual") and not lab.journey.active and lab.journey.result.is_empty(), "load restores gameplay while invalidating diagnostic measurement")
	check(not lab.save_manager.autosave_enabled and not FileAccess.file_exists(lab.save_manager.storage_root.path_join("auto.json")), "walking never enables or writes an unsolicited autosave")
	Engine.time_scale = 1
	lab.queue_free()
	await settle()
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
