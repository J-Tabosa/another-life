extends SceneTree

const LAB := preload("res://scenes/lab/scale_lab.tscn")
var checks: int = 0
var failures: int = 0


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
	for frame in range(2):
		await process_frame


func interact(lab: Node2D, portal_name: String) -> void:
	lab.player.position = lab.area.get_node(portal_name).position
	await settle()
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	lab._unhandled_input(event)
	await settle()


func capture(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://docs/screenshots/" + name) == OK, "rendered " + name)


func run() -> void:
	Engine.max_fps = 60
	var lab: Node2D = LAB.instantiate()
	lab.test_storage_root = "user://test_runs/travel_" + str(Time.get_ticks_usec())
	root.add_child(lab)
	var clock: TimeManager = lab.time_manager
	clock.set_process(false)
	var camera: Camera2D = lab.player.get_node("Camera2D")
	check(ProjectSettings.get_setting("display/window/stretch/mode") == "disabled" and camera.zoom == Vector2.ONE, "fullscreen uses pixel-sized world with zoom one")
	for size in [Vector2i(960, 540), Vector2i(1366, 768), Vector2i(1920, 1080)]:
		root.mode = Window.MODE_WINDOWED
		root.size = size
		await settle()
		check(camera.zoom == Vector2.ONE and lab.player.scale == Vector2.ONE and root.content_scale_mode == Window.CONTENT_SCALE_MODE_DISABLED, "world scale stays fixed at %dx%d" % [size.x, size.y])
		check(lab.get_node("HUD/ClockPanel").position.y == root.get_visible_rect().size.y - 32 and lab.get_node("HUD/ClockPanel").size.x == root.get_visible_rect().size.x, "HUD follows viewport dimensions at %dx%d" % [size.x, size.y])
	root.size = Vector2i(1280, 720)
	await settle()
	lab.change_area(&"street", &"door")
	await interact(lab, "RouteDoor")
	check(lab.area_id == &"route" and clock.running and camera.limit_right == 12800 and camera.limit_bottom == 1600, "street portal opens a large external route and extends camera limits")
	var from: Vector2 = lab.player.position
	var start_minutes := clock.world_minutes
	var started := Time.get_ticks_usec()
	# Physics movement reaches the far portal at the production speed. Real-time
	# option uses automatic ticks; short default verifies a section plus portals.
	var real_walk := "--walk" in OS.get_cmdline_user_args()
	clock.set_process(real_walk)
	Input.action_press("move_right")
	var destination := 12590.0 if real_walk else from.x + 400.0
	while lab.player.position.x < destination and Time.get_ticks_usec() - started < 85_000_000:
		await physics_frame
	Input.action_release("move_right")
	await settle()
	var duration := (Time.get_ticks_usec() - started) / 1_000_000.0
	check(lab.player.position.x >= destination and lab.player.position.y == from.y, "walking follows the unobstructed route with real collision physics")
	print("WALK: %.3fs, %.1fpx, +%d game minutes" % [duration, lab.player.position.x - from.x, clock.world_minutes - start_minutes])
	if real_walk:
		check(clock.world_minutes - start_minutes >= 68 and clock.world_minutes - start_minutes <= 72, "full journey takes about seventy game minutes using natural ticks")
		check(lab.area.get_node("CampusDoor").can_interact(lab.player), "far campus portal is reachable by walking")
		var event := InputEventAction.new()
		event.action = &"interact"
		event.pressed = true
		lab._unhandled_input(event)
		await settle()
	else:
		await interact(lab, "CampusDoor")
	check(lab.area_id == &"campus" and camera.limit_right == 2400 and clock.running and not lab.travel_result.is_empty(), "campus arrival preserves date and records trip duration")
	await interact(lab, "Door")
	check(lab.area_id == &"route" and lab.player.position == Vector2(12560, 800), "campus exit returns to correct end of the route")
	await interact(lab, "Door")
	check(lab.area_id == &"street" and lab.player.position == Vector2(776, 432), "route exit returns to the residential marker")
	clock.set_process(false)
	if "--capture" in OS.get_cmdline_user_args():
		for season in range(4):
			lab.debug_jump((600 + season * 30) * 1440 + 360)
			lab.change_area(&"campus", &"door")
			lab.player.position = Vector2(1400, 800)
			await capture("season_%d.png" % season)
		lab._open_debug()
		await capture("calendar_debug.png")
		lab.debug_panel.close()
		lab.change_area(&"street", &"door")
		lab.debug_jump(800 * 1440 + 239)
		clock._process(1)
		await capture("forced_sleep.png")
		lab.sleep_panel.skip_button.pressed.emit()
		root.mode = Window.MODE_FULLSCREEN
		await capture("fullscreen_scale.png")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
