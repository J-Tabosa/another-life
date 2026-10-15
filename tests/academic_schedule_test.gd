extends SceneTree

var checks := 0
var failures := 0
var lab: Node2D


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


func click(button: Button) -> void:
	await settle()
	var motion := InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = motion.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await settle()


func run() -> void:
	Engine.max_fps = 120
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	lab = load("res://scenes/lab/scale_lab.tscn").instantiate()
	lab.test_storage_root = "user://test_runs/academic_" + str(Time.get_ticks_usec())
	root.add_child(lab)
	lab.time_manager.set_process(false)
	var clock: TimeManager = lab.time_manager
	var schedule: AcademicSchedule = lab.academics
	var morning: Dictionary = schedule.sessions[0]
	var afternoon: Dictionary = schedule.sessions[1]
	var panel: AcademicPanel = lab.academic_panel
	var events: Array[int] = []
	var finished: Array[String] = []
	clock.minute_changed.connect(func(value: int) -> void: events.append(value))
	schedule.session_finished.connect(func(_day: int, session: String, status: String) -> void: finished.append(session + ":" + status))
	check(morning.start == 540 and morning.end == 720 and afternoon.start == 780 and afternoon.end == 1020, "approved morning and afternoon hours")
	check(not schedule.attend(), "cannot attend before start")
	lab._open_academics()
	check(panel.visible and panel.attend_button.disabled and panel.wait_button.disabled, "agenda consultable at home without attending or waiting")
	lab._attend_class()
	lab._wait_for_class()
	check(clock.world_minutes == 360, "controller rejects academic actions outside classroom")
	panel.close()
	lab.change_area(&"classroom", &"door")
	lab.player.position = lab.area.get_node("LessonPoint").position
	await settle()
	var interaction := InputEventAction.new()
	interaction.action = &"interact"
	interaction.pressed = true
	lab._unhandled_input(interaction)
	check(panel.visible and not lab.player.controls_enabled and not clock.running, "E lesson point opens modal agenda and freezes controls")
	check(not panel.wait_button.disabled and panel.attend_button.disabled, "early arrival offers explicit wait")
	events.clear()
	await click(panel.wait_button)
	check(clock.world_minutes == 540 and events.size() == 180 and events[0] == 361 and events[-1] == 540, "real GUI wait advances every minute to 09h")
	check(not panel.attend_button.disabled and panel.wait_button.disabled, "09h enables class and prevents skipping it via wait")
	check(not schedule.wait_for_class() and clock.world_minutes == 540, "schedule also rejects waiting past an ongoing class")
	events.clear()
	await click(panel.attend_button)
	check(lab.first_lesson_pending and clock.world_minutes == 540, "first attendance opens professor introduction before advancing")
	for _line in range(lab.PROFESSOR_INTRO.line_keys.size()):
		lab.dialogue_panel.advance()
	check(schedule.professor_intro_seen, "completed professor introduction is recorded")
	check(clock.world_minutes == 720 and events.size() == 180, "real GUI attendance advances to noon with intermediate minutes")
	check(schedule.status(0, morning) == "present" and finished == ["morning:present"], "morning present event emitted once at end")
	check(SaveManager.validate_state(lab.snapshot()), "academic state accepted by save validator")
	check(not schedule.attend() and schedule.present.size() == 1, "cannot attend completed shift twice")
	await click(panel.wait_button)
	check(clock.world_minutes == 780, "lunch wait advances to 13h")
	clock.advance_minutes(20)
	await click(panel.attend_button)
	check(lab.question_panel.visible and clock.world_minutes == 800, "afternoon asks first question before completing attendance")
	await click(lab.question_panel.options[1])
	await click(lab.question_panel.close_button)
	check(clock.world_minutes == 1020 and schedule.present["0:afternoon"] == 800, "late arrival recorded and remainder advances to 17h")
	check(schedule.status(0, afternoon) == "present" and panel.wait_button.disabled, "both shifts present and no overnight wait")
	check(lab.save_manager.save_slot("manual", lab.snapshot()), "manual save includes attendance")
	var manual := FileAccess.get_file_as_string(lab.save_manager.storage_root.path_join("manual.json"))
	panel.close()
	check(lab.debug_jump(1440 + 1020), "debug can skip a teaching day")
	check(schedule.status(1, morning) == "absent" and schedule.status(1, afternoon) == "absent", "both skipped classes become absent")
	check(schedule.status(0, morning) == "present", "jump preserves earlier attendance")
	check(schedule.present.size() == 2, "absences use compact cursor rather than unbounded rows")
	check(lab.save_manager.set_autosave(true), "autosave enabled in isolated test directory")
	lab._autosave()
	check(FileAccess.get_file_as_string(lab.save_manager.storage_root.path_join("manual.json")) == manual, "autosave never overwrites manual history")
	check(await lab.load_slot("manual"), "manual load with fade succeeds")
	check(clock.world_minutes == 1020 and schedule.present.size() == 2 and schedule.status(1, morning) == "future", "loading rolls back time and attendance cursor together")
	if "--capture" in OS.get_cmdline_user_args():
		lab._open_academics()
		await settle()
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://docs/screenshots/academic_agenda.png") == OK, "render academic agenda")
		panel.close()
	check(await lab.load_slot("auto") and schedule.status(1, afternoon) == "absent", "auto restores skipped-day absences")
	check(lab.debug_jump(4 * 1440 + 1020), "weekday cursor progresses")
	check(schedule.status(4, morning) == "absent", "Friday absent without participation")
	check(lab.debug_jump(5 * 1440 + 600), "advance to Saturday")
	check(schedule.status(5, morning) == "no_class" and not schedule.attend() and schedule.wait_duration() == 0, "weekend has no attendance or wait")
	for day in [30, 31, 36, 113, 119]:
		check(not AcademicSchedule.teaching_day(day, 0), "canonical vacation day %d has no class" % day)
	check(AcademicSchedule.teaching_day(39, 0) and AcademicSchedule.teaching_day(112, 0), "weekdays outside vacation teach normally")
	check(lab.debug_jump(7 * 1440 + 239), "prepare mandatory outside sleep before classes")
	lab.change_area(&"street", &"door")
	clock._process(1)
	await settle()
	check(lab.sleep_manager.pending and lab.area_id == &"room", "04h still forces return home")
	lab._choose_sleep(false)
	check(clock.world_minutes == 7 * 1440 + 720 and schedule.status(7, morning) == "absent", "forced sleep until noon records missed morning class")
	var state: Dictionary = lab.snapshot()
	var invalid := state.duplicate(true)
	invalid.academics.present["7:morning"] = 7 * 1440 + 500
	check(not SaveManager.validate_state(invalid), "save rejects presence before session starts")
	invalid = state.duplicate(true)
	invalid.academics.evaluated_until = clock.world_minutes + 1
	check(not SaveManager.validate_state(invalid), "save rejects history beyond world clock")
	for version in [1, 2]:
		var legacy := state.duplicate(true)
		legacy.schema_version = version
		legacy.erase("academics")
		legacy.player.area = "street"
		legacy.player.x = 480
		legacy.player.y = 402
		check(SaveManager._write_json(lab.save_manager.storage_root.path_join("manual.json"), legacy), "write fixture schema %d" % version)
		var original := FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json"))
		var migrated: Dictionary = lab.save_manager.load_slot("manual")
		check(migrated.get("schema_version") == 3 and migrated.player.y == WorldLayouts.region("street").spawns.door[1], "legacy %d migrates outside to new safe spawn" % version)
		check(migrated.academics.started_at == clock.world_minutes and migrated.academics.present.is_empty(), "legacy %d does not invent earlier absences" % version)
		check(FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json")) == original, "migration %d leaves original bytes untouched" % version)
	var old_route := state.duplicate(true)
	old_route.schema_version = 1
	old_route.erase("academics")
	old_route.player.area = "route"
	old_route.player.x = 12560
	old_route.player.y = 800
	SaveManager._write_json(lab.save_manager.storage_root.path_join("manual.json"), old_route)
	var route: Dictionary = lab.save_manager.load_slot("manual")
	check(not route.is_empty() and Vector2(route.player.x,route.player.y) == WorldLayouts.point(WorldLayouts.region("route").spawns.door), "legacy long-route coordinates validate against historical bounds before migration")
	check(route.world.minutes == old_route.world.minutes and route.world.fraction == old_route.world.fraction and route.world.weekday_offset == old_route.world.weekday_offset and route.sleep.alarm_minutes == old_route.sleep.alarm_minutes and route.lab.tile_size == old_route.lab.tile_size, "migration preserves clock fraction alarm and tile values")
	old_route.schema_version = 2
	old_route.player.area = "classroom"
	old_route.player.x = 700
	old_route.player.y = 820
	SaveManager._write_json(lab.save_manager.storage_root.path_join("manual.json"), old_route)
	var hall: Dictionary = lab.save_manager.load_slot("manual")
	check(not hall.is_empty() and hall.player.x == 700 and hall.player.y == 820, "unchanged interiors retain exact legacy coordinates")
	old_route.player.x = 99999
	SaveManager._write_json(lab.save_manager.storage_root.path_join("manual.json"), old_route)
	check(lab.save_manager.load_slot("manual").is_empty(), "out-of-bounds legacy file is rejected before migration")
	check(lab.debug_jump(9998 * 120 * 1440 + 1020), "large debug jump reconciles without per-day expansion")
	check(schedule.present.size() == 2 and SaveManager.validate_state(lab.snapshot()), "large calendar history remains small and valid")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
