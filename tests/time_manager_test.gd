extends SceneTree

const CLOCK := preload("res://scripts/core/time_manager.gd")
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


func new_clock() -> TimeManager:
	var clock: TimeManager = CLOCK.new()
	clock.running = true
	return clock


func run() -> void:
	var clock := new_clock()
	check(clock.get_calendar() == {"year": 1, "season_index": 0, "day": 1, "weekday": 0, "week": 1, "hour": 6, "minute": 0}, "initial calendar is spring 1, year 1, 06:00")
	var minute_events: Array[int] = []
	clock.minute_changed.connect(func(value: int) -> void: minute_events.append(value))
	clock._process(0.4)
	check(clock.world_minutes == 360 and minute_events.is_empty(), "sub-second time does not advance a minute")
	clock._process(0.6)
	check(clock.world_minutes == 361 and minute_events == [361], "one real second advances exactly one game minute")
	clock._process(59.0)
	check(clock.world_minutes == 420 and minute_events.size() == 60, "60 real seconds advance exactly 60 game minutes")
	check(minute_events == range(361, 421), "large deltas emit every intermediate minute in order")
	clock.free()
	clock = new_clock()
	for frame in range(3600):
		clock._process(1.0 / 60.0)
	check(clock.world_minutes == 420, "3600 frames at 60 FPS advance one game hour without drift")
	clock._process(0.25)
	clock._process(0.25)
	clock._process(0.5)
	check(clock.world_minutes == 421, "fractional frame remainder is preserved")
	clock._process(0.0)
	clock._process(-1.0)
	check(clock.world_minutes == 421, "zero and negative deltas do not rewind time")
	clock.free()
	clock = new_clock()
	clock._process(17 * 60 + 59)
	check(clock.get_calendar().hour == 23 and clock.get_calendar().minute == 59 and clock.get_calendar().day == 1, "23:59 remains on the first day")
	var ordered_events: Array[String] = []
	clock.minute_changed.connect(func(value: int) -> void: ordered_events.append("minute:%d" % value))
	clock.day_changed.connect(func(value: int) -> void: ordered_events.append("day:%d" % value))
	clock._process(2.0)
	check(clock.get_calendar() == {"year": 1, "season_index": 0, "day": 2, "weekday": 1, "week": 1, "hour": 0, "minute": 1}, "midnight changes the date and weekday")
	check(ordered_events == ["minute:1440", "day:1", "minute:1441"], "midnight emits events chronologically once")
	clock.free()
	for season in range(1, 4):
		clock = new_clock()
		clock._process(season * 30 * 1440 - 360 - 1)
		check(clock.get_calendar().season_index == season - 1 and clock.get_calendar().day == 30, "last minute of season %d" % (season - 1))
		clock._process(1.0)
		check(clock.get_calendar().season_index == season and clock.get_calendar().day == 1 and clock.get_calendar().hour == 0, "season %d begins on day 1 at midnight" % season)
		check(clock.get_calendar().weekday == (season * 30) % 7, "weekday continues across season %d" % season)
		clock.free()
	clock = new_clock()
	clock._process(120 * 1440 - 360 - 1)
	check(clock.get_calendar().year == 1 and clock.get_calendar().season_index == 3 and clock.get_calendar().day == 30, "last minute of winter 30, year 1")
	clock._process(1.0)
	check(clock.get_calendar() == {"year": 2, "season_index": 0, "day": 1, "weekday": 1, "week": 18, "hour": 0, "minute": 0}, "year 2 starts in spring and retains weekday/week continuity")
	clock.free()
	clock = new_clock()
	clock.weekday_offset = 6
	check(clock.get_calendar().weekday == 6, "weekday origin can be configured to Sunday")
	for day in range(1, 15):
		clock._process(1440.0)
		check(clock.get_calendar().weekday == (6 + day) % 7 and clock.get_calendar().week == (6 + day) / 7 + 1, "weekday and week across absolute day %d" % day)
	clock.free()
	# Production scene wiring: clock survives area replacement and controls HUD.
	var lab: Node2D = load("res://scenes/lab/scale_lab.tscn").instantiate()
	root.add_child(lab)
	var active_clock: TimeManager = lab.time_manager
	active_clock.set_process(false)
	check(not active_clock.running, "natural clock is not activated in the room")
	lab.change_area(&"street", &"door")
	check(active_clock.running, "street activates natural time")
	active_clock._process(60.0)
	check(active_clock.world_minutes == 420 and "07:00" in lab.get_node("HUD/Clock").text, "street time and translated HUD advance together")
	lab.change_area(&"room", &"door")
	lab.change_area(&"street", &"door")
	check(lab.time_manager == active_clock and active_clock.world_minutes == 420, "area transitions retain clock instance and date/time")
	if "--realtime" in OS.get_cmdline_user_args():
		Engine.max_fps = 60
		# Flush the earlier test work while the production clock is disabled.
		await process_frame
		await process_frame
		active_clock.set_process(true)
		var started_at := Time.get_ticks_usec()
		var starting_minutes := active_clock.world_minutes
		print("REALTIME: measuring 60 seconds in the street")
		while Time.get_ticks_usec() - started_at < 60_000_000:
			await process_frame
		await process_frame
		active_clock.set_process(false)
		var real_seconds := (Time.get_ticks_usec() - started_at) / 1_000_000.0
		var game_minutes := active_clock.world_minutes - starting_minutes
		print("REALTIME: %.3fs, %d game minutes" % [real_seconds, game_minutes])
		check(game_minutes == 60, "60 seconds of actual engine execution advance 60 game minutes")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://docs/screenshots/time_clock.png") == OK, "rendered clock capture")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
