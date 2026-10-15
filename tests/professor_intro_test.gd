extends SceneTree

var checks := 0
var failures := 0
var lab: Node2D
var initial: Dictionary


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


func key(code: Key, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	event.echo = echo
	event.device = InputEvent.DEVICE_ID_KEYBOARD
	Input.parse_input_event(event.duplicate())
	await process_frame
	event.pressed = false
	event.echo = false
	Input.parse_input_event(event)
	await settle()


func click(button: Button) -> void:
	var center := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = center
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = center
		event.pressed = pressed
		event.button_index = MOUSE_BUTTON_LEFT
		root.push_input(event, true)
		await process_frame
	await settle()


func complete_intro() -> void:
	for _line in range(lab.PROFESSOR_INTRO.line_keys.size() - 1):
		await key(KEY_ENTER)
	await key(KEY_E)


func prepare_class(minutes: int = 540) -> void:
	lab._restore_state(initial.duplicate(true))
	lab.time_manager.restore_clock(minutes, 0.375)
	lab.change_area(&"classroom", &"door")
	lab.player.position = lab.area.get_node("LessonPoint").position
	await settle()


func capture(name: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await settle()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://docs/screenshots/" + name + ".png") == OK, "render " + name)


func run() -> void:
	Engine.max_fps = 120
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	lab = load("res://scenes/lab/scale_lab.tscn").instantiate()
	lab.test_storage_root = "user://test_runs/professor_" + str(Time.get_ticks_usec())
	root.add_child(lab)
	lab.time_manager.set_process(false)
	lab.fade.duration = 0.03
	initial = lab.snapshot()
	var clock: TimeManager = lab.time_manager
	var schedule: AcademicSchedule = lab.academics
	var dialogue: DialoguePanel = lab.dialogue_panel
	var panel: AcademicPanel = lab.academic_panel
	var events: Array[int] = []
	var outcomes: Array[bool] = []
	clock.minute_changed.connect(func(value: int) -> void: events.append(value))
	dialogue.finished.connect(func(completed: bool) -> void: outcomes.append(completed))
	await prepare_class(360)
	var teacher: Area2D = lab.area.get_node("DialogueNPC")
	check(teacher.marker_key == &"PROFESSOR_MARKER" and teacher.dialogue.speaker_key == &"PROFESSOR_SPEAKER", "classroom contains generic History professor placeholder")
	Input.action_press("move_right")
	for tick in range(64):
		await physics_frame
	Input.action_release("move_right")
	await settle()
	check(teacher.can_interact(lab.player), "professor reachable through classroom with actual movement")
	await key(KEY_E)
	check(dialogue.active and dialogue.get_node("Panel/Speaker").text == tr("PROFESSOR_SPEAKER"), "E opens translated professor greeting")
	check(clock.world_minutes == 360 and not schedule.professor_intro_seen and schedule.present.is_empty(), "casual greeting grants no time presence or introduction flag")
	await key(KEY_ESCAPE)
	check(outcomes == [false] and not dialogue.active and not panel.visible, "greeting cancellation reports false without opening agenda")
	await key(KEY_E)
	await key(KEY_ENTER)
	await key(KEY_ENTER)
	check(outcomes == [false,true] and not schedule.professor_intro_seen, "completed casual greeting still does not consume first lesson")
	await prepare_class()
	await key(KEY_E)
	check(panel.visible and not dialogue.active, "lesson point opens agenda before first attendance")
	await click(panel.attend_button)
	check(lab.first_lesson_pending and dialogue.active and not panel.visible, "real participation click opens introduction")
	check(dialogue.get_node("Panel/Line").text == tr("PROFESSOR_INTRO_01"), "introduction starts on first translated line")
	check(clock.world_minutes == 540 and schedule.present.is_empty() and not schedule.professor_intro_seen, "starting introduction reserves no attendance and spends no time")
	check(not lab.player.controls_enabled and not clock.running, "introduction freezes movement and natural time")
	var position_before: Vector2 = lab.player.position
	clock._process(90)
	await key(KEY_R)
	await key(KEY_T)
	await key(KEY_M)
	lab.request_transition(&"room", &"door")
	check(clock.world_minutes == 540 and lab.player.position == position_before and lab.area_id == &"classroom" and not lab.city_map.visible, "dialogue blocks activities scale map and scene transitions")
	check(not lab.debug_jump(780), "debug cannot move clock underneath pending introduction")
	lab._attend_class()
	await key(KEY_E, true)
	check(dialogue.get_node("Panel/Line").text == tr("PROFESSOR_INTRO_01") and schedule.present.is_empty(), "repeat attendance and held E cannot duplicate or skip introduction")
	await key(KEY_ENTER)
	check(dialogue.get_node("Panel/Line").text == tr("PROFESSOR_INTRO_02"), "Enter advances introductory dialogue")
	await key(KEY_ESCAPE)
	check(panel.visible and not dialogue.active and not lab.first_lesson_pending, "Escape cancels introduction and returns to agenda")
	check(clock.world_minutes == 540 and schedule.present.is_empty() and not schedule.professor_intro_seen, "cancellation spends no time and leaves first lesson available")
	check(not FileAccess.file_exists(lab.save_manager.storage_root.path_join("auto.json")), "autosave off writes no implicit introduction save")
	await click(panel.attend_button)
	for _line in range(lab.PROFESSOR_INTRO.line_keys.size() - 1):
		await click(dialogue.get_node("Panel/Next"))
	await click(dialogue.get_node("Panel/Close"))
	check(panel.visible and clock.world_minutes == 540 and not schedule.professor_intro_seen, "mouse close on final line cancels rather than completing the class")
	var pre_intro: Dictionary = lab.snapshot()
	check(lab.save_manager.save_slot("manual", pre_intro), "can save unchanged pre-introduction state in isolated slot")
	await click(panel.attend_button)
	check(await lab.load_slot("manual"), "valid load can interrupt introduction")
	check(not lab.first_lesson_pending and not dialogue.active and not panel.visible and not schedule.professor_intro_seen and schedule.present.is_empty(), "load cancels pending continuation without awarding presence")
	lab._open_academics()
	await click(panel.attend_button)
	lab.change_area(&"university", &"door")
	check(not lab.first_lesson_pending and not dialogue.active and not schedule.professor_intro_seen and clock.world_minutes == 540, "internal area replacement safely cancels introduction")
	await prepare_class()
	check(lab.save_manager.set_autosave(true), "enable separate autosave for completion test")
	lab._open_academics()
	await click(panel.attend_button)
	await capture("professor_introduction")
	events.clear()
	await complete_intro()
	check(clock.world_minutes == 720 and events.size() == 180 and events[0] == 541 and events[-1] == 720, "last line advances first lesson minute by minute to noon")
	check(schedule.professor_intro_seen and schedule.present.get("0:morning") == 540, "completion records introduction and morning attendance together")
	check(clock.get_clock_state().fraction == 0.375, "intro and class preserve fractional natural time")
	check(panel.visible and not dialogue.active and not lab.first_lesson_pending and not clock.running, "completion returns to agenda with interior time frozen")
	check(SaveManager.validate_state(lab.snapshot()), "completed introduction snapshot validates")
	var auto: Dictionary = lab.save_manager.load_slot("auto")
	check(auto.academics.professor_intro_seen and auto.academics.present.has("0:morning"), "auto atomically contains both narrative flag and attendance")
	check(not lab.save_manager.load_slot("manual").academics.professor_intro_seen, "auto never changes earlier manual introduction state")
	dialogue.advance()
	check(clock.world_minutes == 720 and schedule.present.size() == 1, "extra advance after completion cannot award another class")
	await capture("professor_first_lesson_done")
	await click(panel.wait_button)
	await click(panel.attend_button)
	check(clock.world_minutes == 1020 and not dialogue.active and schedule.present.size() == 2, "afternoon attendance does not repeat completed introduction")
	check(await lab.load_slot("auto"), "completed introduction reloads successfully")
	check(schedule.professor_intro_seen and not dialogue.active, "load preserves completed introduction without replay")
	check(await lab.load_slot("manual"), "pre-introduction manual save restores earlier state")
	check(not schedule.professor_intro_seen and clock.world_minutes == 540, "manual rollback restores eligibility rather than leaking future completion")
	# P2-03 schema 3 files lack the new optional flag, with no coordinate migration.
	var old: Dictionary = pre_intro.duplicate(true)
	old.academics.erase("professor_intro_seen")
	SaveManager._write_json(lab.save_manager.storage_root.path_join("manual.json"), old)
	check(await lab.load_slot("manual"), "unmodified P2-03 schema-three save remains loadable")
	check(not schedule.professor_intro_seen and lab.player.position == Vector2(old.player.x,old.player.y), "older schema-three save defaults flag false and keeps exact position")
	var invalid: Dictionary = lab.snapshot()
	invalid.academics.professor_intro_seen = "yes"
	check(not SaveManager.validate_state(invalid), "save validator rejects malformed narrative flag")
	lab.save_manager.set_autosave(false)
	await prepare_class(800)
	lab._open_academics()
	await click(panel.attend_button)
	check(dialogue.active and lab.first_lesson_pending, "missed morning still permits introduction in first attended afternoon")
	await complete_intro()
	check(clock.world_minutes == 1020 and schedule.professor_intro_seen and schedule.status(0,schedule.sessions[0]) == "absent" and schedule.present.get("0:afternoon") == 800, "late fallback preserves missed morning and records afternoon entry")
	await prepare_class(5*1440+540)
	lab._open_academics()
	lab._attend_class()
	check(not dialogue.active and not lab.first_lesson_pending and not schedule.professor_intro_seen, "weekend cannot trigger introductory class")
	await prepare_class(30*1440+540)
	lab._open_academics()
	lab._attend_class()
	check(not dialogue.active and schedule.present.is_empty(), "vacation cannot trigger introductory class")
	await prepare_class(1440+550)
	lab._open_academics()
	await click(panel.attend_button)
	await complete_intro()
	check(clock.world_minutes == 1440+720 and schedule.professor_intro_seen and schedule.status(0,schedule.sessions[0]) == "absent", "first attendance on later day remains possible without changing past absences")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
