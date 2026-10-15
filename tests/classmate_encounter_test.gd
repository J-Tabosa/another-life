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
	event.keycode = code
	event.physical_keycode = code
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
	var motion := InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = motion.position
		event.pressed = pressed
		event.button_index = MOUSE_BUTTON_LEFT
		root.push_input(event, true)
		await process_frame
	await settle()


func finish_dialogue() -> void:
	var lines: int = lab.dialogue_panel._line_keys.size() - lab.dialogue_panel._line_index
	for line in range(lines):
		await key(KEY_E if line == lines - 1 else KEY_ENTER)


func walk_to(target: Vector2) -> bool:
	var deadline := Time.get_ticks_usec() + 7_000_000
	while lab.player.position.distance_to(target) > 10:
		var direction: Vector2 = target - lab.player.position
		for action in ["move_left", "move_right", "move_up", "move_down"]:
			Input.action_release(action)
		if absf(direction.x) > 5:
			Input.action_press("move_right" if direction.x > 0 else "move_left")
		if absf(direction.y) > 5:
			Input.action_press("move_down" if direction.y > 0 else "move_up")
		await physics_frame
		if Time.get_ticks_usec() > deadline:
			break
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
	await settle()
	return lab.player.position.distance_to(target) <= 12


func prepare(minutes: int, area: StringName) -> void:
	lab._restore_state(initial.duplicate(true))
	lab.time_manager.restore_clock(minutes, 0.375)
	lab.change_area(area, &"door")
	await settle()


func actor() -> Area2D:
	return lab.area.get_node_or_null("Classmate") as Area2D


func capture(name: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://docs/screenshots/" + name + ".png") == OK, "render " + name)


func run() -> void:
	Engine.max_fps = 120
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	lab = load("res://scenes/lab/scale_lab.tscn").instantiate()
	lab.test_storage_root = "user://test_runs/classmate_" + str(Time.get_ticks_usec())
	root.add_child(lab)
	lab.time_manager.set_process(false)
	lab.fade.duration = 0.03
	initial = lab.snapshot()
	var clock: TimeManager = lab.time_manager
	var meeting: ClassmateEncounter = lab.classmate
	var panel: DialoguePanel = lab.dialogue_panel
	var memories: Array[StringName] = []
	meeting.remembered.connect(func(id: StringName, _minutes: int) -> void: memories.append(id))
	await prepare(360, &"classroom")
	check(actor() != null and actor().marker_key == &"CLASSMATE_MARKER", "classmate placeholder is present in classroom before class")
	check(meeting.met_at == -1 and meeting.lunch_at == -1, "new game knows neither conversation")
	lab._open_classmate_dialogue(null)
	lab._open_classmate_dialogue(actor())
	check(not panel.active, "remote or missing actor cannot open classmate encounter")
	check(await walk_to(Vector2(1040,820)) and await walk_to(Vector2(988,756)), "classmate physically reachable from classroom doorway")
	await key(KEY_E)
	check(panel.active and panel.get_node("Panel/Line").text == tr("CLASSMATE_INTRO_01"), "E opens first contact in Portuguese")
	check(not lab.player.controls_enabled and not clock.running, "first contact pauses controls and natural time")
	clock._process(90)
	await key(KEY_R)
	await key(KEY_T)
	await key(KEY_M)
	lab.request_transition(&"room", &"door")
	check(clock.world_minutes == 360 and lab.area_id == &"classroom" and not lab.city_map.visible, "dialogue blocks time activity map scale and transitions")
	check(not lab.debug_jump(720), "debug cannot skip a pending social encounter")
	await key(KEY_E, true)
	check(panel.get_node("Panel/Line").text == tr("CLASSMATE_INTRO_01"), "held E does not skip first contact")
	await key(KEY_ESCAPE)
	check(not panel.active and meeting.met_at == -1 and memories.is_empty(), "Escape cancels without discovering or recording anything")
	await key(KEY_E)
	await capture("classmate_introduction")
	await finish_dialogue()
	check(meeting.met_at == 360 and meeting.lunch_at == -1 and memories == [&"intro"], "only completed first contact records known meeting date")
	check(clock.world_minutes == 360 and clock.get_clock_state().fraction == 0.375 and lab.academics.present.is_empty(), "conversation costs no time fraction or academic attendance")
	check(not meeting.remember(&"intro"), "first meeting cannot be awarded twice")
	await key(KEY_E)
	check(panel.get_node("Panel/Line").text == tr("CLASSMATE_WAITING_01"), "repeat outside lunch reminds player of public meeting place")
	await finish_dialogue()
	check(memories.size() == 1 and meeting.lunch_at == -1, "early repeat is not the lunch conversation")
	var met_state: Dictionary = lab.snapshot()
	check(lab.save_manager.save_slot("manual", met_state), "manual saves completed first contact")
	var manual_bytes := FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json"))
	check(await walk_to(Vector2(700,720)) and await walk_to(Vector2(700,240)), "lesson point physically reachable from classmate")
	await key(KEY_E)
	await click(lab.academic_panel.wait_button)
	check(clock.world_minutes == 540 and actor() != null, "waiting to 09h keeps colleague in classroom")
	await click(lab.academic_panel.attend_button)
	await finish_dialogue()
	check(clock.world_minutes == 720 and lab.academics.professor_intro_seen and lab.academics.present.has("0:morning"), "professor introduction and morning class remain functional")
	check(actor() == null and meeting.lunch_at == -1, "at noon classmate leaves classroom without fabricating a lunch conversation")
	lab.academic_panel.close()
	check(await walk_to(Vector2(700,820)) and await walk_to(Vector2(700,920)), "walk from class to classroom exit")
	await key(KEY_E)
	check(lab.area_id == &"university" and actor() != null, "same classmate found in hall at noon after real door transition")
	check(await walk_to(Vector2(1240,640)) and await walk_to(Vector2(800,640)) and await walk_to(Vector2(850,660)), "lunch spot reachable through hall with physics movement")
	check(lab.save_manager.set_autosave(true), "enable optional auto only for completed lunch")
	await key(KEY_E)
	check(panel.get_node("Panel/Line").text == tr("CLASSMATE_LUNCH_01"), "noon hall interaction opens distinct lunch dialogue")
	await capture("classmate_lunch")
	await click(panel.get_node("Panel/Next"))
	await click(panel.get_node("Panel/Next"))
	await click(panel.get_node("Panel/Close"))
	check(meeting.lunch_at == -1 and memories.size() == 1 and clock.world_minutes == 720, "mouse close on last lunch line cancels without time or memory")
	check(not FileAccess.file_exists(lab.save_manager.storage_root.path_join("auto.json")), "opening or cancelling does not silently autosave")
	await key(KEY_E)
	await finish_dialogue()
	check(meeting.met_at == 360 and meeting.lunch_at == 720 and memories == [&"intro",&"lunch"], "two different encounters complete on same game day")
	check(clock.world_minutes == 720 and clock.get_clock_state().fraction == 0.375 and lab.academics.present.size() == 1, "lunch talk preserves time fraction and attendance")
	var auto: Dictionary = lab.save_manager.load_slot("auto")
	check(auto.classmate.met_at == 360 and auto.classmate.lunch_at == 720, "auto contains both known conversation dates")
	check(FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json")) == manual_bytes, "lunch autosave never overwrites earlier manual")
	var auto_bytes := FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("auto.json"))
	await key(KEY_E)
	check(panel.get_node("Panel/Line").text == tr("CLASSMATE_REPEAT_01"), "completed lunch uses short repeat instead of replaying initial scenes")
	await finish_dialogue()
	check(memories.size() == 2 and FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("auto.json")) == auto_bytes, "repeat creates no duplicate memories or auto writes")
	await key(KEY_E)
	check(await lab.load_slot("manual"), "valid load interrupts an active colleague conversation")
	check(not panel.active and meeting.met_at == 360 and meeting.lunch_at == -1 and actor() != null and lab.area_id == &"classroom", "manual rollback restores earlier encounter and correct NPC location")
	check(await lab.load_slot("auto"), "completed lunch auto reloads")
	check(meeting.lunch_at == 720 and lab.area_id == &"university" and actor() != null and not panel.active, "load preserves lunch without replay or lost actor")
	# Old schema 3 has no encounter block and must not inherit future knowledge.
	var old := lab.snapshot() as Dictionary
	old.erase("classmate")
	SaveManager._write_json(lab.save_manager.storage_root.path_join("manual.json"), old)
	var original := FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json"))
	check(await lab.load_slot("manual"), "pre-P2-05 schema-three save remains compatible")
	check(meeting.met_at == -1 and meeting.lunch_at == -1 and FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json")) == original, "older save defaults to unknown without rewriting original")
	lab.player.position = actor().position
	await settle()
	await key(KEY_E)
	await finish_dialogue()
	check(meeting.met_at == 720 and meeting.lunch_at == -1, "first contact may happen at lunch without skipping its introduction")
	await key(KEY_E)
	await finish_dialogue()
	check(meeting.met_at == 720 and meeting.lunch_at == 720, "second interaction still gives lunch opportunity on same day")
	var valid: Dictionary = lab.snapshot()
	for malformed in [{"met_at":"yes","lunch_at":-1},{"met_at":721,"lunch_at":-1},{"met_at":-1,"lunch_at":720},{"met_at":750,"lunch_at":720},{"met_at":360,"lunch_at":600}]:
		var bad := valid.duplicate(true)
		bad.classmate = malformed
		check(not SaveManager.validate_state(bad), "reject malformed/future/reversed/outside-lunch encounter " + str(malformed))
	lab.save_manager.set_autosave(false)
	# Cancellation by map replacement must not run a narrative continuation.
	await prepare(360, &"classroom")
	lab.player.position = actor().position
	await settle()
	await key(KEY_E)
	lab.change_area(&"university", &"door")
	check(not panel.active and meeting.met_at == -1 and meeting.lunch_at == -1, "area replacement safely cancels pending first contact")
	# Presence is driven by the clock, regardless of player knowledge.
	for boundary in [359,360,719,720,779,780,1019,1020]:
		await prepare(boundary, &"classroom")
		var expected := "" if boundary < 360 or boundary >= 1020 else ("university" if boundary >= 720 and boundary < 780 else "classroom")
		check((actor() != null) == (expected == "classroom"), "classroom presence at minute " + str(boundary))
		lab.change_area(&"university", &"door")
		check((actor() != null) == (expected == "university"), "hall presence at minute " + str(boundary))
		check(meeting.met_at == -1 and meeting.lunch_at == -1, "schedule reveals no offscreen conversation at " + str(boundary))
	for day in [5,6,30,36,113,119]:
		await prepare(day*1440+720, &"university")
		check(actor() == null and meeting.conversation().is_empty(), "no lunch encounter on weekend/vacation day " + str(day))
	# Missing lunch has no permanent lock; both conversations stay optional.
	lab._restore_state(met_state)
	clock.restore_clock(780)
	check(meeting.lunch_at == -1 and meeting.conversation() == &"waiting", "missed lunch is not awarded after the window closes")
	lab.debug_jump(1440+720)
	lab.change_area(&"university", &"door")
	lab.player.position = actor().position
	await settle()
	await key(KEY_E)
	await finish_dialogue()
	check(meeting.lunch_at == 1440+720 and meeting.met_at == 360, "missed lunch remains available on a later teaching day")
	check(SaveManager.validate_state(lab.snapshot()), "final encounter state remains valid after later-day fallback")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
