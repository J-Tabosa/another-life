extends SceneTree

var checks := 0
var failures := 0
var lab: Node2D
var storage: String
var real_walk: bool = false


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
	var deadline := Time.get_ticks_msec() + 5000
	while lab.transitioning and Time.get_ticks_msec() < deadline:
		await process_frame
	await process_frame


func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.unicode = code if code >= KEY_SPACE and code <= KEY_Z else 0
	event.device = InputEvent.DEVICE_ID_KEYBOARD
	event.pressed = true
	Input.parse_input_event(event.duplicate())
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await settle()


func type_text(value: String) -> void:
	for character in value:
		var event := InputEventKey.new()
		event.unicode = character.unicode_at(0)
		event.device = InputEvent.DEVICE_ID_KEYBOARD
		event.pressed = true
		root.push_input(event.duplicate(), true)
		await process_frame
		event.pressed = false
		root.push_input(event, true)
		await process_frame


func click(button: Button) -> void:
	var parent := button.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			parent.ensure_control_visible(button)
		parent = parent.get_parent()
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


func button_with_text(node: Node, text_value: String) -> Button:
	if node is Button and node.text == text_value:
		return node
	for child in node.get_children():
		var found := button_with_text(child, text_value)
		if found != null:
			return found
	return null


func walk_to(target: Vector2) -> bool:
	var tolerance: float = lab.player.speed * Engine.time_scale / 60 + 5
	var deadline := Time.get_ticks_msec() + (30000 if real_walk else 6000)
	while lab.player.position.distance_to(target) > tolerance:
		var direction: Vector2 = target - lab.player.position
		for action in ["move_left", "move_right", "move_up", "move_down"]:
			Input.action_release(action)
		if absf(direction.x) > tolerance / 2:
			Input.action_press("move_right" if direction.x > 0 else "move_left")
		if absf(direction.y) > tolerance / 2:
			Input.action_press("move_down" if direction.y > 0 else "move_up")
		await physics_frame
		if Time.get_ticks_msec() > deadline or lab.sleep_manager.pending:
			break
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
	await settle()
	var reached: bool = lab.player.position.distance_to(target) <= tolerance + 3
	if not reached:
		print("BLOCKED: ", lab.area_id, " at ", lab.player.position, " target ", target)
	return reached


func use_node(node_name: String, offset: Vector2 = Vector2.ZERO) -> bool:
	var target := lab.area.get_node_or_null(node_name) as Area2D
	if target == null or not await walk_to(target.position + offset):
		check(false, "reachable interaction: " + String(lab.area_id) + "/" + node_name)
		return false
	if lab._interaction_target() != target:
		check(false, "correct nearest interaction: " + node_name)
		return false
	await key(KEY_E)
	return true


func door(node_name: String, expected: StringName) -> bool:
	var used := await use_node(node_name)
	var arrived: bool = used and lab.area_id == expected and not lab.transitioning and not lab.fade.active
	check(arrived, "walk + E + fade arrives at " + String(expected))
	return arrived


func follow_main(reverse: bool = false) -> bool:
	var points: Array = lab.area.layout.main.duplicate(true)
	if reverse:
		points.reverse()
	for point in points:
		if not await walk_to(WorldLayouts.point(point)):
			check(false, "continuous road walk in " + String(lab.area_id))
			return false
	check(true, "continuous road walk in " + String(lab.area_id))
	return true


func finish_dialogue() -> void:
	var remaining: int = lab.dialogue_panel._line_keys.size() - lab.dialogue_panel._line_index
	for line in range(remaining):
		await key(KEY_E if line == remaining - 1 else KEY_ENTER)


func new_game(tile: int, directory: String) -> void:
	if is_instance_valid(lab):
		lab.queue_free()
		for tick in range(4):
			await physics_frame
	lab = load("res://scenes/lab/scale_lab.tscn").instantiate()
	lab.tile_size = tile
	lab.test_storage_root = directory
	root.add_child(lab)
	lab.fade.duration = 0.04
	await settle()


func capture(name: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await settle()
	RenderingServer.force_draw(false)
	check(root.get_texture().get_image().save_png("res://docs/screenshots/" + name + ".png") == OK, "render " + name)


func play_day(tile: int, enable_auto: bool) -> bool:
	print("DAY ONE: tile ", tile, " auto ", enable_auto)
	var directory := storage.path_join(str(tile))
	await new_game(tile, directory)
	check(lab.area_id == &"room" and lab.time_manager.world_minutes == 360 and lab.player.controls_enabled, "fresh playable game begins at home 06h")
	await key(KEY_C)
	lab.debug_panel.name_edit.grab_focus()
	await type_text("João " + str(tile))
	lab.debug_panel.name_edit.release_focus()
	var chosen_name := "João " + str(tile)
	check(lab.protagonist_name == chosen_name, "real name field accepts chosen Unicode name")
	if enable_auto:
		await click(lab.debug_panel.autosave)
	check(lab.save_manager.autosave_enabled == enable_auto, "player chooses autosave explicitly")
	await key(KEY_ESCAPE)
	if not await use_node("Father", Vector2(45,0)):
		return false
	check(lab.dialogue_panel.active and lab.dialogue_panel.get_node("Panel/Line").text.contains(chosen_name) and not lab.dialogue_panel.get_node("Panel/Line").text.contains("{player_"), "father addresses chosen name through translated context")
	await finish_dialogue()
	if not await use_node("Sister", Vector2(45,0)):
		return false
	await finish_dialogue()
	check(lab.home_introductions.greetings.size() == 2 and lab.home_introductions.discovered.is_empty() and lab.time_manager.world_minutes == 360, "morning family conversations complete without time or premature hobbies")
	if not await door("Door", &"street"):
		return false
	var departed := Time.get_ticks_msec()
	if not await follow_main() or not await door("RouteDoor", &"route") or not await follow_main() or not await door("CampusDoor", &"campus") or not await follow_main():
		return false
	check(lab.time_manager.world_minutes > 360 and lab.time_manager.world_minutes < 540, "actual outdoor walking advances clock and reaches campus before 09h")
	print("OUTBOUND: ", (Time.get_ticks_msec()-departed)/1000.0, "s real; arrival ", lab.time_manager.world_minutes)
	if not await door("HallDoor", &"university") or not await follow_main() or not await door("ClassroomDoor", &"classroom") or not await follow_main() or not await use_node("LessonPoint"):
		return false
	check(lab.academic_panel.visible and not lab.time_manager.running, "classroom lesson point opens schedule with interior clock stopped")
	await click(lab.academic_panel.wait_button)
	check(lab.time_manager.world_minutes == 540, "explicit wait reaches morning class")
	await click(lab.academic_panel.attend_button)
	await key(KEY_ESCAPE)
	check(lab.academic_panel.visible and lab.academics.present.is_empty() and not lab.academics.professor_intro_seen, "cancelled first lesson can be retried without losing attendance opportunity")
	await click(lab.academic_panel.attend_button)
	await finish_dialogue()
	check(lab.time_manager.world_minutes == 720 and lab.academics.professor_intro_seen and lab.academics.present.size() == 1, "professor introduction completes morning class at noon")
	await key(KEY_ESCAPE)
	if not await follow_main(true) or not await door("Door", &"university") or not await walk_to(Vector2(1240,640)) or not await walk_to(Vector2(845,640)) or not await use_node("Classmate", Vector2(45,0)):
		return false
	await finish_dialogue()
	check(lab.classmate.met_at == 720 and lab.classmate.lunch_at == -1, "first colleague contact remains possible in hall after morning class")
	await key(KEY_E)
	await key(KEY_ESCAPE)
	check(lab.classmate.lunch_at == -1 and lab.time_manager.world_minutes == 720, "cancelled lunch can be resumed during same paused interval")
	await key(KEY_E)
	await finish_dialogue()
	check(lab.classmate.lunch_at == 720 and lab.time_manager.world_minutes == 720, "second hall conversation completes lunch encounter")
	if not await walk_to(Vector2(800,640)) or not await walk_to(Vector2(1240,640)) or not await door("ClassroomDoor", &"classroom") or not await follow_main() or not await use_node("LessonPoint"):
		return false
	await click(lab.academic_panel.wait_button)
	await click(lab.academic_panel.attend_button)
	check(lab.question_panel.visible and lab.time_manager.world_minutes == 780, "afternoon class offers first question")
	await key(KEY_ESCAPE)
	check(lab.academic_panel.visible and lab.academics.question_answers.is_empty(), "unanswered question safely returns to schedule")
	await click(lab.academic_panel.attend_button)
	await click(lab.question_panel.options[1 if tile == 32 else 0])
	var question_id: String = ClassQuestionBank.first().id
	check(lab.time_manager.world_minutes == 1020 and lab.academics.present.size() == 2 and lab.academics.question_answers[question_id].correct == (tile == 32), "correct or wrong answer concludes same afternoon with normal presence")
	await key(KEY_ENTER)
	await key(KEY_ESCAPE)
	if not await follow_main(true) or not await door("Door", &"university") or not await walk_to(Vector2(1240,640)) or not await walk_to(Vector2(800,640)) or not await door("Door", &"campus"):
		return false
	if not await follow_main(true) or not await door("Door", &"route") or not await follow_main(true) or not await door("Door", &"street") or not await follow_main(true) or not await door("Door", &"room"):
		return false
	check(lab.time_manager.world_minutes > 1020 and lab.time_manager.world_minutes < 1380 and lab.area.has_node("Father") and lab.area.has_node("Sister"), "walking back arrives in time for optional evening family scenes")
	var returned: int = lab.time_manager.world_minutes
	if not await use_node("Father", Vector2(45,0)):
		return false
	await finish_dialogue()
	if not await use_node("Sister", Vector2(45,0)):
		return false
	await finish_dialogue()
	if not await walk_to(Vector2(480,430)) or not await use_node("MusicCorner", Vector2(45,0)):
		return false
	await finish_dialogue()
	check(lab.home_introductions.discovered.size() == 3 and lab.time_manager.world_minutes == returned, "all three hobbies are discovered on return without consuming indoor time")
	await key(KEY_H)
	check(lab.hobbies_panel.visible and lab.hobbies_panel.discoveries.text.contains(tr("HOBBY_MUSIC")), "interests accessible at end of continuous day")
	await key(KEY_ESCAPE)
	if not await walk_to(Vector2(480,430)) or not await walk_to(Vector2(320,430)) or not await use_node("Bed", Vector2(lab.area.furniture[0].size.x/2+32,0)):
		return false
	check(lab.sleep_manager.pending and lab.sleep_panel.visible and lab.sleep_panel.target.text.contains(tr("WEEKDAY_TUE")), "bed offers save and next-morning date after complete day")
	await key(KEY_ESCAPE)
	check(not lab.sleep_manager.pending and lab.player.controls_enabled and lab.time_manager.world_minutes == returned, "end-day sleep choice can be cancelled without trapping player")
	await key(KEY_E)
	if tile == 64:
		lab.sleep_panel.hour.value = 7
		lab.sleep_panel.minute.value = 15
	var expected_wake := 1440 + (435 if tile == 64 else 360)
	check(lab.sleep_manager.wake_target() == expected_wake, "wake preview follows selected alarm")
	if tile == 32:
		await capture("day_one_bed")
	if tile == 64:
		await key(KEY_1)
	else:
		await click(lab.sleep_panel.save_button)
	check(not lab.sleep_manager.pending and not lab._modal_open() and lab.player.controls_enabled and lab.time_manager.world_minutes == expected_wake, "save-and-sleep reaches playable next morning")
	check(lab.time_manager.get_calendar().day == 2 and lab.time_manager.get_calendar().weekday == 1, "sleep changes date and weekday correctly")
	var manual: Dictionary = lab.save_manager.load_slot("manual")
	check(not manual.is_empty() and manual.sleep.pending and manual.world.minutes == returned and manual.player.name == chosen_name, "manual contains actual before-bed state and chosen name")
	var manual_bytes := FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json"))
	check(lab.home_introductions.discovered.size() == 3 and lab.classmate.lunch_at == 720 and lab.academics.present.size() == 2 and lab.academics.question_answers.size() == 1, "waking retains all family social and academic progress")
	var auto: Dictionary = lab.save_manager.load_slot("auto")
	check((not auto.is_empty() and not auto.sleep.pending and auto.world.minutes == expected_wake) if enable_auto else not FileAccess.file_exists(lab.save_manager.storage_root.path_join("auto.json")), "autosave respects opt-in and captures awakened state only when enabled")
	check(await walk_to(Vector2(350,400)), "player can physically move after waking")
	if tile == 32:
		await capture("day_one_next_morning")
	# Restart the actual scene against persisted slots, rather than restoring a fixture.
	await new_game(tile, directory)
	check(lab.time_manager.world_minutes == 360 and lab.home_introductions.discovered.is_empty() and FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json")) == manual_bytes, "restart begins fresh without silently loading or overwriting slots")
	await key(KEY_C)
	await click(button_with_text(lab.debug_panel, tr("LOAD_MANUAL")))
	check(lab.sleep_manager.pending and lab.sleep_panel.visible and lab.time_manager.world_minutes == returned and lab.protagonist_name == chosen_name and lab.dialogue_panel.text_context.player_name == chosen_name, "load manual restores pending sleep name and dialogue context")
	check(lab.home_introductions.discovered.size() == 3 and lab.classmate.lunch_at == 720 and lab.academics.present.size() == 2 and lab.academics.question_answers.size() == 1, "restart and manual load retain every completed introduction")
	await key(KEY_ESCAPE)
	await key(KEY_E)
	await click(lab.sleep_panel.skip_button)
	check(lab.time_manager.world_minutes == expected_wake and not lab._modal_open() and FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json")) == manual_bytes, "resume before-bed save and sleep without replacing manual")
	lab._choose_sleep(true)
	check(FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json")) == manual_bytes and lab.time_manager.world_minutes == expected_wake, "stale save callback after waking cannot rewrite manual or sleep twice")
	await key(KEY_C)
	await click(button_with_text(lab.debug_panel, tr("LOAD_AUTO")))
	check((not lab.debug_panel.visible and lab.time_manager.world_minutes == expected_wake and not lab.sleep_manager.pending) if enable_auto else (lab.debug_panel.visible and lab.time_manager.world_minutes == expected_wake), "independent auto load or absent slot has a safe outcome")
	if lab.debug_panel.visible:
		await key(KEY_ESCAPE)
	check(not lab._modal_open() and lab.player.controls_enabled and SaveManager.validate_state(lab.snapshot()), "continuous day ends with valid controllable state")
	return true


func deviations() -> void:
	print("DAY ONE: skipped content and failure recovery")
	await new_game(32, storage.path_join("deviations"))
	if not await walk_to(Vector2(320,400)) or not await use_node("Bed", Vector2(64,0)):
		return
	await key(KEY_2)
	check(lab.time_manager.world_minutes == 1800 and lab.home_introductions.discovered.is_empty() and lab.classmate.met_at == -1, "sleeping immediately skips optional content and still reaches next day")
	check(lab.academics.status(0,lab.academics.sessions[0]) == "absent" and lab.academics.status(0,lab.academics.sessions[1]) == "absent", "skipping first day records absences without softlock")
	check(not FileAccess.file_exists(lab.save_manager.storage_root.path_join("manual.json")) and not FileAccess.file_exists(lab.save_manager.storage_root.path_join("auto.json")), "sleep without manual or auto writes no slots")
	# Boundary fixtures below deliberately use debug/time setup; the two main routes do not.
	check(lab.debug_jump(1440+800), "later-day afternoon remains reachable after missed day")
	lab.change_area(&"classroom", &"door")
	await settle()
	if not await follow_main() or not await use_node("LessonPoint"):
		return
	await click(lab.academic_panel.attend_button)
	await finish_dialogue()
	await click(lab.question_panel.options[0])
	await key(KEY_ENTER)
	await key(KEY_ESCAPE)
	check(lab.time_manager.world_minutes == 1440+1020 and lab.academics.professor_intro_seen and lab.academics.question_answers.size() == 1 and lab.academics.present.size() == 1, "first lesson intro and wrong-answer question recover on later afternoon")
	check(lab.classmate.met_at == -1 and lab.home_introductions.discovered.is_empty(), "late recovery does not fabricate skipped social or hobby content")
	lab.change_area(&"room", &"door")
	await settle()
	if not await walk_to(Vector2(320,400)) or not await use_node("Bed", Vector2(64,0)):
		return
	await click(lab.sleep_panel.save_button)
	check(lab.time_manager.world_minutes == 2*1440+360 and not lab._modal_open(), "partial-progress day can save and finish normally")
	var manual_path: String = lab.save_manager.storage_root.path_join("manual.json")
	var manual_bytes := FileAccess.get_file_as_bytes(manual_path)
	lab.time_manager.set_process(false)
	lab.time_manager.restore_clock(2*1440+239,0.75)
	lab.change_area(&"street", &"door")
	lab.time_manager._process(300)
	await settle()
	check(lab.area_id == &"room" and lab.sleep_manager.forced and lab.sleep_manager.was_outside and lab.sleep_panel.visible and lab.time_manager.world_minutes == 2*1440+240, "long outside frame stops at exactly 04h and returns home")
	await key(KEY_ESCAPE)
	check(lab.sleep_manager.pending and lab.sleep_panel.visible and not lab.sleep_panel.cancel_button.visible, "forced sleep cannot be cancelled")
	var normal_root: String = lab.save_manager.storage_root
	var blocker_path := storage.path_join("blocked_parent")
	DirAccess.make_dir_recursive_absolute(storage)
	var blocker := FileAccess.open(blocker_path,FileAccess.WRITE)
	blocker.store_string("test file intentionally prevents directory creation")
	blocker.close()
	lab.save_manager.storage_root = blocker_path.path_join("saves")
	await click(lab.sleep_panel.save_button)
	check(lab.sleep_manager.pending and lab.time_manager.world_minutes == 2*1440+240 and lab.sleep_panel.status.text == tr("SAVE_FAILED"), "real write failure preserves pending sleep and offers recovery")
	check(FileAccess.get_file_as_bytes(manual_path) == manual_bytes, "failed save leaves valid manual file untouched")
	if "--capture" in OS.get_cmdline_user_args():
		await capture("day_one_save_recovery")
	await key(KEY_2)
	check(lab.time_manager.world_minutes == 2*1440+720 and not lab._modal_open() and lab.player.controls_enabled, "declining failed manual still wakes outside sleeper at noon same day")
	lab.save_manager.storage_root = normal_root
	lab.time_manager.restore_clock(3*1440+239)
	lab.change_area(&"room", &"door")
	lab.sleep_manager.alarm_minutes = 435
	lab.time_manager.running = true
	lab.time_manager._process(1)
	await settle()
	check(lab.sleep_manager.forced and not lab.sleep_manager.was_outside and lab.sleep_manager.wake_target() == 3*1440+435, "forced home sleep respects alarm")
	lab.save_manager.storage_root = blocker_path.path_join("saves")
	await click(lab.sleep_panel.save_button)
	check(lab.sleep_manager.pending and lab.time_manager.world_minutes == 3*1440+240, "failed home save leaves same sleep decision available for retry")
	lab.save_manager.storage_root = normal_root
	await click(lab.sleep_panel.save_button)
	check(lab.time_manager.world_minutes == 3*1440+435 and not lab._modal_open(), "valid retry path saves and wakes at home alarm")
	var before: Dictionary = lab.snapshot()
	SaveManager._write_json(normal_root.path_join("auto.json"),{"broken":true})
	await key(KEY_C)
	await click(button_with_text(lab.debug_panel,tr("LOAD_AUTO")))
	check(lab.snapshot() == before and lab.debug_panel.visible, "corrupt load preserves live day and keeps calendar dismissible")
	await key(KEY_ESCAPE)
	check(not lab._modal_open() and lab.player.controls_enabled and SaveManager.validate_state(lab.snapshot()), "failed load does not trap controls or corrupt state")
	root.size = Vector2i(960,540)
	if not await walk_to(Vector2(320,400)) or not await use_node("Bed",Vector2(64,0)):
		return
	await settle()
	check(root.get_visible_rect().encloses(lab.sleep_panel.save_button.get_global_rect()) and root.get_visible_rect().encloses(lab.sleep_panel.skip_button.get_global_rect()) and root.get_visible_rect().encloses(lab.sleep_panel.cancel_button.get_global_rect()), "all bedtime decisions remain reachable on notebook viewport")
	await capture("day_one_bed_notebook")
	lab.sleep_panel.hour.get_line_edit().grab_focus()
	lab.sleep_panel.hour.get_line_edit().select_all()
	await key(KEY_1)
	await key(KEY_ENTER)
	lab.sleep_panel.hour.get_line_edit().release_focus()
	check(lab.sleep_manager.pending and lab.sleep_panel.hour.value == 1, "typing alarm digit does not trigger unfocused sleep shortcut")
	await key(KEY_ESCAPE)
	check(not lab.sleep_manager.pending and lab.player.controls_enabled, "small-window voluntary sleep cancellation remains safe")


func run() -> void:
	Engine.max_fps = 120
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	storage = "user://test_runs/day_one_" + str(Time.get_ticks_usec())
	real_walk = "--walk" in OS.get_cmdline_user_args()
	Engine.time_scale = 1 if real_walk else 6
	if not await play_day(32,true):
		quit(1)
		return
	real_walk = false
	Engine.time_scale = 6
	if not await play_day(64,false):
		quit(1)
		return
	await deviations()
	Engine.time_scale = 1
	print("RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
