extends SceneTree

const LAB := preload("res://scenes/lab/scale_lab.tscn")
var checks: int = 0
var failures: int = 0
var storage: String


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
	for node in root.get_children():
		if node.has_method("change_area"):
			while node.transitioning:
				await process_frame


func press_key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.device = InputEvent.DEVICE_ID_KEYBOARD
	event.pressed = true
	Input.parse_input_event(event.duplicate())
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame


func new_lab() -> Node2D:
	var lab: Node2D = LAB.instantiate()
	lab.test_storage_root = storage
	root.add_child(lab)
	lab.time_manager.set_process(false)
	return lab


func click_button(button: Button) -> void:
	await settle()
	var center := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = center
	motion.device = InputEvent.DEVICE_ID_MOUSE
	root.push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.position = center
	event.button_index = MOUSE_BUTTON_LEFT
	event.device = InputEvent.DEVICE_ID_MOUSE
	event.pressed = true
	root.push_input(event.duplicate(), true)
	event.pressed = false
	root.push_input(event.duplicate(), true)
	await settle()


func run() -> void:
	Engine.max_fps = 60
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	storage = "user://test_runs/sleep_" + str(Time.get_ticks_usec())
	var lab := new_lab()
	var clock: TimeManager = lab.time_manager
	var sleeper: SleepManager = lab.sleep_manager
	var saves: SaveManager = lab.save_manager
	var events: Array[int] = []
	clock.minute_changed.connect(func(value: int) -> void: events.append(value))
	check(clock.enforce_sleep_limit and not saves.autosave_enabled, "game enforces 04h and autosave is opt-in")
	clock.restore_clock(1439)
	lab.change_area(&"street", &"door")
	clock._process(1.0)
	check(clock.world_minutes == 1440 and not sleeper.pending, "midnight changes date without forcing sleep")
	clock.restore_clock(1679, 0.75)
	lab.change_area(&"street", &"door")
	events.clear()
	clock._process(600.0)
	await settle()
	check(clock.world_minutes == 1680 and events == [1680], "large outdoor frame stops exactly at 04h without skipping sleep")
	check(sleeper.pending and sleeper.forced and sleeper.was_outside and lab.area_id == &"room", "04h outside returns to home and records compulsory sleep context")
	check(lab.sleep_panel.visible and not lab.sleep_panel.cancel_button.visible and not lab.player.controls_enabled, "compulsory sleep offers save and blocks cancellation/movement")
	await press_key(KEY_ESCAPE)
	check(sleeper.pending and lab.sleep_panel.visible and not sleeper.cancel(), "Escape and direct cancel cannot avoid compulsory sleep")
	clock._process(600)
	check(clock.world_minutes == 1680, "time stays frozen while compulsory save choice is pending")
	lab.sleep_panel.skip_button.pressed.emit()
	check(clock.world_minutes == 2160 and clock.get_calendar().day == 2 and clock.get_calendar().hour == 12, "outside sleep wakes at Tuesday 12h on the same calendar day")
	check(not sleeper.pending and lab.player.controls_enabled and not clock.running, "waking restores room controls and keeps natural clock frozen")
	check(not FileAccess.file_exists(saves.storage_root.path_join("manual.json")) and not FileAccess.file_exists(saves.storage_root.path_join("auto.json")), "declining manual save with autosave off writes neither slot")
	check(events == range(1680, 2161), "forced sleep emits all intermediate minutes chronologically")
	clock.restore_clock(2 * 1440 + 239)
	sleeper.alarm_minutes = 360
	lab.change_area(&"room", &"door")
	clock.running = true # Represent an advancing action in a home interior.
	clock._process(1)
	check(sleeper.forced and not sleeper.was_outside and sleeper.wake_target() == 2 * 1440 + 360, "04h at home respects the 06h alarm")
	lab.sleep_panel.skip_button.pressed.emit()
	check(clock.world_minutes == 2 * 1440 + 360, "home compulsory sleep wakes at 06h with two hours of sleep")
	# Actual bed interaction at both laboratory scales.
	for tile in [32, 64]:
		lab.tile_size = tile
		lab.change_area(&"room", &"door")
		var bed: Area2D = lab.area.get_node("Bed")
		lab.player.position = bed.position + Vector2(0, tile * 2 + 24)
		await settle()
		await press_key(KEY_E)
		check(sleeper.pending and not sleeper.forced, "E at bed opens voluntary sleep at tile %d" % tile)
		await press_key(KEY_ESCAPE)
		check(not sleeper.pending and not lab.sleep_panel.visible, "voluntary sleep may be cancelled at tile %d" % tile)
	clock.restore_clock(3 * 1440 + 23 * 60 + 30)
	sleeper.alarm_minutes = 7 * 60 + 15
	lab.protagonist_name = "João de teste"
	check(sleeper.request(), "voluntary sleep is requested without spending time")
	check(sleeper.wake_target() == 4 * 1440 + 7 * 60 + 15, "alarm minute precision resolves next morning across midnight")
	await click_button(lab.sleep_panel.save_button)
	var manual := saves.load_slot("manual")
	check(not manual.is_empty() and manual.world.minutes == 3 * 1440 + 23 * 60 + 30 and manual.sleep.pending, "manual save captures pre-sleep state and pending sleep")
	check(clock.world_minutes == 4 * 1440 + 7 * 60 + 15, "save-and-sleep wakes at the configured alarm")
	check((await lab.load_slot("manual")) and sleeper.pending and not sleeper.forced and lab.protagonist_name == "João de teste", "manual load restores name, alarm and pre-sleep choice")
	lab.sleep_panel.skip_button.pressed.emit()
	var manual_bytes := FileAccess.get_file_as_bytes(saves.storage_root.path_join("manual.json"))
	check(saves.set_autosave(true), "autosave preference persists separately")
	clock.restore_clock(5 * 1440 + 22 * 60)
	sleeper.request()
	lab.sleep_panel.skip_button.pressed.emit()
	var auto := saves.load_slot("auto")
	check(not auto.is_empty() and not auto.sleep.pending and auto.world.minutes == clock.world_minutes, "enabled autosave captures the awakened state")
	check(FileAccess.get_file_as_bytes(saves.storage_root.path_join("manual.json")) == manual_bytes, "autosave never overwrites manual file")
	clock.restore_clock(clock.world_minutes + 60, 0.1234567890123456, 6)
	lab.change_area(&"route", &"door")
	lab.player.position = Vector2(700, 800)
	check(saves.save_slot("auto", lab.snapshot()), "autosave can persist position and fractional outdoor time")
	var saved_minutes := clock.world_minutes
	saves.set_autosave(false)
	lab.change_area(&"room", &"door")
	check((await lab.load_slot("auto")) and lab.area_id == &"route" and lab.player.position == Vector2(700, 800) and clock.world_minutes == saved_minutes and clock.get_clock_state().fraction == 0.1234567890123456 and clock.weekday_offset == 6, "load restores map, exact position, full-precision fraction and weekday origin")
	saves.set_autosave(true)
	check(saves.save_slot("auto", auto), "existing auto file is replaced successfully through temporary write")
	check((await lab.load_slot("auto")) and clock.world_minutes == int(auto.world.minutes), "autosave loads independently from manual")
	var auto_bytes := FileAccess.get_file_as_bytes(saves.storage_root.path_join("auto.json"))
	var other := new_lab()
	check(other.save_manager.autosave_enabled and FileAccess.get_file_as_bytes(saves.storage_root.path_join("auto.json")) == auto_bytes, "new scene loads preference without overwriting existing auto on startup")
	other.queue_free()
	await settle()
	check(saves.set_autosave(false), "autosave can be disabled again")
	lab.change_area(&"street", &"door")
	check(FileAccess.get_file_as_bytes(saves.storage_root.path_join("auto.json")) == auto_bytes, "disabled autosave leaves existing file untouched")
	# Validate files before mutating a live scene.
	var before: Dictionary = lab.snapshot()
	var bad: Dictionary = before.duplicate(true)
	bad.schema_version = 99
	check(not saves.save_slot("manual", bad), "unsupported save version is rejected")
	bad = before.duplicate(true)
	bad.player.x = "not a position"
	check(not SaveManager.validate_state(bad), "invalid coordinates are rejected")
	bad = before.duplicate(true)
	bad.world.fraction = 2
	check(not SaveManager.validate_state(bad), "out-of-range fractional time is rejected")
	var file := FileAccess.open(saves.storage_root.path_join("auto.json"), FileAccess.WRITE)
	file.store_string("{broken json")
	file.close()
	check(not (await lab.load_slot("auto")) and lab.snapshot() == before, "corrupt load preserves the live game state")
	check(not saves.save_slot("../manual", before), "slot names cannot escape separate save paths")
	# Calendar grid, seasons, week continuity and forward-only debug jump.
	lab._open_debug()
	check(lab.debug_panel.visible and not clock.running and lab.debug_panel.day_buttons.size() == 30, "debug calendar shows 30 days and pauses natural time")
	lab.debug_panel.year.set_value_no_signal(2)
	lab.debug_panel.season.select(3)
	lab.debug_panel.hour.set_value_no_signal(3)
	lab.debug_panel.minute.set_value_no_signal(59)
	lab.debug_panel._rebuild()
	check(lab.debug_panel.grid.get_children().find(lab.debug_panel.day_buttons[0]) == 7 + (210 + clock.weekday_offset) % 7, "calendar aligns the first date with its actual weekday")
	await click_button(lab.debug_panel.day_buttons[29])
	check(clock.get_calendar().year == 2 and clock.get_calendar().season_index == 3 and clock.get_calendar().day == 30 and clock.get_calendar().hour == 3 and clock.get_calendar().minute == 59, "clicking date jumps to selected year/season/day/time")
	check(clock.get_calendar().weekday == (clock.weekday_offset + 239) % 7, "debug weekday continues across years using the configured origin")
	check(not lab.debug_jump(0), "debug calendar refuses backwards time travel")
	for season in range(4):
		lab.debug_jump((240 + season * 30) * 1440 + 360)
		check(lab.get_node("SeasonFilter/Tint").color == lab.SEASON_FILTERS[season], "season %d uses the requested visual filter" % season)
	# A debug jump to 04h still presents compulsory sleep at the destination.
	lab.debug_jump(400 * 1440 + 240)
	await settle()
	check(sleeper.pending and sleeper.was_outside and lab.area_id == &"room", "debug destination at 04h respects forced outside sleep")
	await click_button(lab.sleep_panel.save_button)
	check(clock.world_minutes == 400 * 1440 + 720, "debug sleep returns 12h on the selected day")
	check((await lab.load_slot("manual")) and sleeper.pending and sleeper.forced and sleeper.was_outside and lab.sleep_panel.visible, "loading compulsory pre-sleep save restores outside context and the save choice")
	await press_key(KEY_ESCAPE)
	check(sleeper.pending, "loaded compulsory sleep still cannot be cancelled")
	lab.sleep_panel.skip_button.pressed.emit()
	check(clock.world_minutes == 400 * 1440 + 720, "loaded outside sleep wakes at 12h without adding a calendar day")
	lab.queue_free()
	await settle()
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
