extends SceneTree

var checks := 0
var failures := 0
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
	while lab.transitioning:
		await process_frame
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


func capture(file_name: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await settle()
	RenderingServer.force_draw(false)
	check(root.get_texture().get_image().save_png("res://docs/screenshots/" + file_name + ".png") == OK, "capture " + file_name)


func audit_calendar() -> void:
	# Independent day-by-day counters cover the entire 840-day weekday/year cycle
	# at every possible origin. This does not reuse the production date formulas.
	for offset in range(7):
		var weekday := offset
		var week := 1
		var absolute_day := 0
		for year in range(1, 8):
			var dates_ok := true
			var rules_ok := true
			var vacations := 0
			for season in range(4):
				for date in range(1, 31):
					var expected_key := ""
					if season == 1 and date in [1, 2, 3, 4, 5, 6, 7]:
						expected_key = "CALENDAR_SUMMER_BREAK"
					if season == 3 and date in [24, 25, 26, 27, 28, 29, 30]:
						expected_key = "CALENDAR_WINTER_BREAK"
					var info := TimeManager.day_info(absolute_day, offset)
					var teaching := weekday < 5 and expected_key.is_empty()
					dates_ok = dates_ok and info.year == year and info.season_index == season and info.day == date and info.weekday == weekday and info.week == week
					rules_ok = rules_ok and info.vacation_key == expected_key and info.is_weekend == (weekday >= 5) and info.is_teaching_day == teaching and AcademicSchedule.teaching_day(absolute_day, offset) == teaching
					if not expected_key.is_empty():
						vacations += 1
					weekday += 1
					if weekday == 7:
						weekday = 0
						week += 1
					absolute_day += 1
			check(dates_ok, "all 120 dates and continuous weeks: year %d origin %d" % [year, offset])
			check(rules_ok and vacations == 14, "exactly 14 vacation dates and correct teaching/weekends: year %d origin %d" % [year, offset])
		for boundary in [30, 36, 113, 119]:
			var next := TimeManager.next_teaching_day(boundary, offset)
			var earliest := AcademicSchedule.teaching_day(next, offset)
			for skipped in range(boundary, next):
				earliest = earliest and not AcademicSchedule.teaching_day(skipped, offset)
			check(earliest and next > boundary and next - boundary <= 9, "return from vacation includes adjacent weekends: day %d origin %d" % [boundary, offset])
	check(TimeManager.next_teaching_day(0, 0) == 0, "next teaching-day search is inclusive")
	var distant := TimeManager.day_info(9998 * 120 + 119, 6)
	check(distant.year == 9999 and distant.season_index == 3 and distant.day == 30 and distant.vacation_key == "CALENDAR_WINTER_BREAK", "last selectable year retains winter vacation")
	var clock := TimeManager.new()
	var events: Array[String] = []
	clock.minute_changed.connect(func(now: int) -> void: events.append("minute:%d" % now))
	clock.day_changed.connect(func(day: int) -> void: events.append("day:%d" % day))
	for destination in [30, 37, 60, 90, 113, 120, 240]:
		clock.restore_clock(destination * 1440 - 1, 0.5, 6)
		var before := clock.get_clock_state()
		TimeManager.day_info(destination, 6)
		TimeManager.next_teaching_day(destination, 6)
		check(clock.get_clock_state() == before, "calendar queries are pure at boundary %d" % destination)
		events.clear()
		check(clock.advance_minutes(1) and clock.world_minutes == destination * 1440, "midnight activity crosses boundary %d once" % destination)
		check(events == ["minute:%d" % (destination * 1440), "day:%d" % destination] and clock.get_calendar().weekday == (destination + 6) % 7, "ordered midnight signals and continuous weekday %d" % destination)
	clock.free()


func audit_game() -> void:
	lab = load("res://scenes/lab/scale_lab.tscn").instantiate()
	lab.test_storage_root = "user://test_runs/calendar_" + str(Time.get_ticks_usec())
	root.add_child(lab)
	lab.time_manager.set_process(false)
	var clock: TimeManager = lab.time_manager
	var schedule: AcademicSchedule = lab.academics
	var panel: CalendarDebugPanel = lab.debug_panel
	var morning: Dictionary = schedule.sessions[0]
	var afternoon: Dictionary = schedule.sessions[1]
	lab.change_area(&"classroom", &"door")
	# Last pre-vacation teaching day, then a real activity across midnight.
	clock.restore_clock(29 * 1440 + 1439, 0.75)
	check(clock.advance_minutes(1), "activity reaches summer 1 naturally")
	lab._open_academics()
	check("Férias de verão" in lab.academic_panel.details.text and "8 de Verão" in lab.academic_panel.details.text, "agenda explains summer vacation and return on the eighth")
	check(lab.academic_panel.attend_button.disabled and lab.academic_panel.wait_button.disabled, "no class or academic wait during vacation")
	lab.academic_panel.close()
	clock.restore_clock(clock.world_minutes, 0.75)
	var before: Dictionary = lab.snapshot()
	lab._open_debug()
	await settle()
	check(panel.visible and not clock.running and not lab.player.controls_enabled, "calendar is a modal paused consultation")
	check("Semana 5" in panel.summary.text and "Férias de verão" in panel.summary.text, "calendar explains continuous week and current vacation")
	check(panel.day_buttons.size() == 30 and panel.day_buttons[0].text.ends_with("F") and panel.day_buttons[6].text.ends_with("F") and not panel.day_buttons[7].text.ends_with("F"), "summer grid marks exactly the canonical vacation interval")
	check("Fim de semana" in panel.day_buttons[3].tooltip_text and "Férias de verão" in panel.day_buttons[3].tooltip_text, "overlapping weekend and vacation remain distinguishable")
	await capture("calendar_summer_vacation")
	for origin in range(7):
		clock.weekday_offset = origin
		for season in range(4):
			panel.year.set_value_no_signal(2)
			panel.season.select(season)
			panel._rebuild()
			check(panel.grid.get_children().find(panel.day_buttons[0]) == 7 + (120 + season * 30 + origin) % 7, "grid alignment year 2 season %d origin %d" % [season, origin])
	clock.weekday_offset = 0
	panel.year.set_value_no_signal(1)
	panel.season.select(0)
	panel._rebuild()
	check(panel.day_buttons.all(func(button: Button) -> bool: return button.disabled), "past season remains readable but cannot rewind")
	check("Ano 1" in panel.day_buttons[0].tooltip_text and "Segunda-feira" in panel.day_buttons[0].tooltip_text, "day tooltip has full date and weekday")
	panel.year.set_value_no_signal(9999)
	panel.season.select(3)
	panel._rebuild()
	check(panel.day_buttons[23].text.ends_with("F") and panel.day_buttons[29].text.ends_with("F"), "far-future calendar shows winter vacation without advancing time")
	check(lab.snapshot() == before and not FileAccess.file_exists(lab.save_manager.storage_root.path_join("manual.json")) and not FileAccess.file_exists(lab.save_manager.storage_root.path_join("auto.json")), "browsing preserves time fraction, attendance, knowledge and save slots")
	panel.year.set_value_no_signal(1)
	panel.season.select(1)
	panel.hour.set_value_no_signal(9)
	panel.minute.set_value_no_signal(0)
	panel._rebuild()
	await click(panel.day_buttons[6])
	check(clock.world_minutes == 36 * 1440 + 540 and not panel.visible, "real date click jumps forward to summer 7 at selected time")
	check(schedule.status(36, morning) == "no_class" and schedule.status(36, afternoon) == "no_class" and not schedule.attend() and schedule.wait_duration() == 0, "last summer vacation day never records absence or allows class")
	check(ClassmateEncounter.location_at(clock.world_minutes, 0).is_empty() and lab.classmate.met_at < 0, "classmate has no campus routine or invented encounter during vacation")
	check(lab.save_manager.save_slot("manual", lab.snapshot()), "existing schema saves vacation state")
	var bytes := FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json"))
	var invalid: Dictionary = lab.snapshot().duplicate(true)
	invalid.world.minutes = 36 * 1440 + 1020
	invalid.academics.evaluated_until = invalid.world.minutes
	invalid.academics.present["36:morning"] = 36 * 1440 + 540
	check(not SaveManager.validate_state(invalid), "save rejects fabricated presence on a vacation day")
	invalid = lab.snapshot().duplicate(true)
	invalid.classmate.met_at = clock.world_minutes
	check(not SaveManager.validate_state(invalid), "save rejects a fabricated campus encounter during vacation")
	check(lab.debug_jump(37 * 1440 + 540), "advance to first day after summer vacation")
	check(schedule.current_session().id == "morning" and schedule.status(36, morning) == "no_class", "summer 8 resumes lessons without retroactive vacation absences")
	check(not ClassmateEncounter.location_at(clock.world_minutes, 0).is_empty(), "campus routine resumes with classes")
	lab._open_academics()
	await click(lab.academic_panel.attend_button)
	check(lab.first_lesson_pending, "first professor introduction remains available after vacation")
	for _line in range(lab.PROFESSOR_INTRO.line_keys.size()):
		lab.dialogue_panel.advance()
	check(clock.world_minutes == 37 * 1440 + 720 and schedule.status(37, morning) == "present", "post-vacation class advances and records presence normally")
	lab.academic_panel.close()
	check(await lab.load_slot("manual"), "load vacation save with fade")
	check(clock.world_minutes == 36 * 1440 + 540 and not schedule.professor_intro_seen and schedule.present.is_empty() and not AcademicSchedule.teaching_day(36, clock.weekday_offset), "load restores vacation and academic progress without extra saved flags")
	check(FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json")) == bytes and SaveManager.validate_state(lab.snapshot()), "calendar query/load leaves schema and manual bytes intact")
	# Winter 23 is Monday and winter 24 Tuesday with this configured origin.
	clock.restore_clock(112 * 1440 + 600, 0.25, 0)
	check(not schedule.current_session().is_empty(), "winter 23 is still a teaching day")
	lab.debug_jump(113 * 1440 + 600)
	check(schedule.current_session().is_empty() and schedule.status(112, morning) == "absent" and schedule.status(113, morning) == "no_class", "winter boundary distinguishes missed lesson from vacation")
	lab._open_academics()
	check("Férias de inverno" in lab.academic_panel.details.text and "Ano 2" in lab.academic_panel.details.text and "Terça-feira" in lab.academic_panel.details.text, "winter agenda announces correct next-year return weekday")
	await capture("calendar_winter_agenda")
	lab.academic_panel.close()
	lab.debug_jump(119 * 1440 + 23 * 60)
	lab.change_area(&"room", &"door")
	check(lab.sleep_manager.request(), "request real sleep on winter 30")
	await click(lab.sleep_panel.skip_button)
	check(clock.get_calendar().year == 2 and clock.get_calendar().season_index == 0 and clock.get_calendar().day == 1 and clock.get_calendar().weekday == 1, "winter sleep reaches spring 1 next year without weekday reset")
	check(schedule.status(119, morning) == "no_class" and schedule.status(119, afternoon) == "no_class" and schedule.wait_duration() == 180, "new-year morning offers class wait and no winter absences")
	lab.debug_jump(149 * 1440 + 23 * 60)
	check(lab.save_manager.set_autosave(true), "enable optional autosave before entering vacation")
	check(lab.sleep_manager.request(), "request real sleep on spring 30 of the second year")
	await click(lab.sleep_panel.skip_button)
	check(clock.world_minutes == 150 * 1440 + 360 and schedule.status(150, morning) == "no_class" and schedule.wait_duration() == 0, "sleep into next summer starts vacation without class or waiting")
	var auto: Dictionary = lab.save_manager.load_slot("auto")
	check(not auto.is_empty() and auto.world.minutes == 150 * 1440 + 360 and not auto.sleep.pending, "autosave captures awakened vacation state")
	check(FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json")) == bytes, "vacation autosave preserves independent pre-existing manual file")
	lab.debug_jump(157 * 1440 + 600)
	check(await lab.load_slot("auto"), "load vacation autosave independently")
	check(clock.world_minutes == 150 * 1440 + 360 and clock.weekday_offset == 0 and schedule.current_session().is_empty(), "auto restores date and origin with vacation re-derived")
	check(lab.save_manager.set_autosave(false), "disable optional autosave again")
	# Offset 5 makes spring 1 of year 2 a Sunday; return must be Monday 2.
	clock.restore_clock(119 * 1440 + 600, 0.5, 5)
	lab._open_debug()
	check("2 de Primavera" in panel.summary.text and "Segunda-feira" in panel.summary.text, "winter return skips next-year weekend for configured origin")
	root.size = Vector2i(960, 540)
	await settle()
	check(panel.grid.get_global_rect().end.x < 960 and panel.summary.get_global_rect().position.x >= 0, "calendar content fits notebook width")
	await capture("calendar_winter_notebook")
	var scroll := panel.box.get_parent().get_parent() as ScrollContainer
	scroll.ensure_control_visible(panel.day_buttons[29])
	await settle()
	check(scroll.get_global_rect().encloses(panel.day_buttons[29].get_global_rect()), "last winter date remains reachable in notebook scroll")
	panel.close()
	lab.change_area(&"street", &"door")
	var start := clock.world_minutes
	clock._process(0.5)
	check(clock.world_minutes == start + 1, "calendar dismissal preserves fractional outdoor time")
	lab.queue_free()
	await process_frame


func run() -> void:
	Engine.max_fps = 120
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	audit_calendar()
	await audit_game()
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
