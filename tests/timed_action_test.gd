extends SceneTree

const CLOCK := preload("res://scripts/core/time_manager.gd")
const ACTIVITY: TimedAction = preload("res://data/activities/lab_activity.tres")
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


func at_time(minutes_since_start: int) -> TimeManager:
	var clock: TimeManager = CLOCK.new()
	clock.running = true
	clock._process(float(minutes_since_start))
	clock.running = false
	return clock


func run() -> void:
	check(ACTIVITY.duration_minutes == 60 and ACTIVITY.label_key == &"LAB_ACTIVITY", "activity duration and translated label come from reusable data")
	var clock := at_time(0)
	var minutes: Array[int] = []
	clock.minute_changed.connect(func(value: int) -> void: minutes.append(value))
	check(clock.advance_minutes(ACTIVITY.duration_minutes), "60-minute action is accepted indoors")
	check(clock.world_minutes == 420 and clock.get_calendar().hour == 7, "indoor action advances exactly 60 minutes")
	check(minutes == range(361, 421), "action emits all sixty intermediate minutes in order")
	check(not clock.running, "action does not enable natural ticking indoors")
	clock._process(60.0)
	check(clock.world_minutes == 420, "natural time stays frozen after the action")
	check(not clock.advance_minutes(0) and not clock.advance_minutes(-1), "non-positive durations are rejected")
	check(clock.world_minutes == 420 and minutes.size() == 60, "rejected durations have no effects")
	clock.free()
	clock = at_time(0)
	clock.running = true
	clock._process(0.75)
	check(clock.advance_minutes(60) and clock.world_minutes == 420, "outdoor action advances exactly sixty minutes with a pending fraction")
	check(clock.running, "outdoor action preserves natural ticking")
	clock._process(0.249)
	check(clock.world_minutes == 420, "explicit action does not consume fractional outdoor progress")
	clock._process(0.001)
	check(clock.world_minutes == 421, "remaining fraction completes a natural minute after the action")
	clock.free()
	clock = at_time(17 * 60 + 30)
	var ordered: Array[String] = []
	clock.minute_changed.connect(func(value: int) -> void: ordered.append("minute:%d" % value))
	clock.day_changed.connect(func(value: int) -> void: ordered.append("day:%d" % value))
	var observed: Array[int] = []
	clock.minute_changed.connect(func(value: int) -> void:
		if value in [1435, 1445]:
			observed.append(clock.world_minutes)
	)
	check(clock.advance_minutes(60), "action may cross midnight without ending the day")
	check(clock.get_calendar().day == 2 and clock.get_calendar().hour == 0 and clock.get_calendar().minute == 30, "23:30 plus sixty minutes is next day 00:30")
	var expected: Array[String] = []
	for value in range(1411, 1471):
		expected.append("minute:%d" % value)
		if value == 1440:
			expected.append("day:1")
	check(ordered == expected, "minute and midnight callbacks run chronologically")
	check(observed == [1435, 1445], "listeners observe intermediate times rather than the final state")
	clock.free()
	clock = at_time(120 * 1440 - 360 - 30)
	check(clock.advance_minutes(60), "action may cross winter/year boundary before the sleep limit")
	check(clock.get_calendar().year == 2 and clock.get_calendar().season_index == 0 and clock.get_calendar().day == 1 and clock.get_calendar().hour == 0 and clock.get_calendar().minute == 30, "action updates year/season/date correctly")
	clock.free()
	clock = at_time(21 * 60 + 30)
	var rejected_events: Array[int] = []
	clock.minute_changed.connect(func(value: int) -> void: rejected_events.append(value))
	check(not clock.can_advance_minutes(60) and not clock.advance_minutes(60), "03:30 action crossing 04:00 is refused before starting")
	check(clock.get_calendar().hour == 3 and clock.get_calendar().minute == 30 and rejected_events.is_empty(), "sleep-limit rejection is atomic")
	check(clock.advance_minutes(29), "action may finish at 03:59")
	check(not clock.advance_minutes(1) and clock.get_calendar().minute == 59, "action ending exactly at 04:00 is refused provisionally")
	clock.running = true
	clock._process(1.0)
	check(not clock.advance_minutes(1), "actions are refused at 04:00 pending the sleep system")
	clock.free()
	clock = at_time(0)
	check(not clock.advance_minutes(1440), "multi-day action cannot skip the next 04:00")
	check(clock.advance_minutes(22 * 60 - 1) and clock.get_calendar().hour == 3 and clock.get_calendar().minute == 59, "long action can end before the next sleep boundary")
	clock.free()
	clock = at_time(0)
	var nested_results: Array[bool] = []
	clock.minute_changed.connect(func(_value: int) -> void:
		nested_results.append(clock.advance_minutes(1))
		clock.running = true
		clock._process(1.0)
	)
	check(clock.advance_minutes(1) and clock.world_minutes == 361 and nested_results == [false], "callbacks cannot recursively advance time during an action")
	check(clock.advance_minutes(1) and clock.world_minutes == 362, "advancement guard is released after the action")
	clock._process(1.0)
	check(clock.world_minutes == 363 and nested_results == [false, false, false], "natural ticks also protect chronological callbacks")
	clock.free()
	# Exercise the real laboratory input and button, including repeat rejection.
	var lab: Node2D = load("res://scenes/lab/scale_lab.tscn").instantiate()
	lab.test_storage_root = "user://test_runs/regression_" + str(Time.get_ticks_usec())
	root.add_child(lab)
	clock = lab.time_manager
	clock.set_process(false)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_R
	event.pressed = true
	check(event.is_action_pressed("test_activity"), "R is mapped to the test activity")
	lab._unhandled_input(event)
	check(clock.world_minutes == 420 and "07:00" in lab.get_node("HUD/Clock").text, "R performs an indoor activity and updates the HUD")
	check("+60 min" in lab.get_node("HUD/ActivityResult").text, "activity feedback is translated")
	event.echo = true
	lab._unhandled_input(event)
	check(clock.world_minutes == 420, "held R does not repeat the activity")
	lab.get_node("HUD/ActivityButton").pressed.emit()
	check(clock.world_minutes == 480, "activity button executes the same duration")
	clock.running = true
	clock._process(19 * 60 + 30)
	clock.running = false
	lab.get_node("HUD/ActivityButton").pressed.emit()
	check(clock.world_minutes == 1650 and "04h" in lab.get_node("HUD/ActivityResult").text, "laboratory reports a blocked action without advancing at 03:30")
	if "--capture" in OS.get_cmdline_user_args():
		# Fresh scene for a readable 06:00 -> 07:00 example.
		lab.queue_free()
		await process_frame
		lab = load("res://scenes/lab/scale_lab.tscn").instantiate()
		lab.test_storage_root = "user://test_runs/regression_" + str(Time.get_ticks_usec())
		root.add_child(lab)
		lab.get_node("HUD/ActivityButton").pressed.emit()
		for frame in range(4):
			await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://docs/screenshots/timed_action.png") == OK, "rendered activity capture")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
