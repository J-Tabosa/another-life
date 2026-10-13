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
	await process_frame
	for node in root.get_children():
		if node.has_method("change_area"):
			while node.transitioning:
				await process_frame


func use_door(lab: Node2D) -> void:
	lab.player.position = lab.area.get_node("Door").position
	await settle()
	check(lab.area.get_node("Door").can_interact(lab.player), "player can interact with the active door")
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	lab._unhandled_input(event)
	await settle()


func run() -> void:
	var lab: Node2D = LAB.instantiate()
	lab.test_storage_root = "user://test_runs/regression_" + str(Time.get_ticks_usec())
	root.add_child(lab)
	var clock: TimeManager = lab.time_manager
	# Disable automatic ticks only for exact, deterministic frame sequences.
	clock.set_process(false)
	var minutes: Array[int] = []
	var days: Array[int] = []
	clock.minute_changed.connect(func(value: int) -> void: minutes.append(value))
	clock.day_changed.connect(func(value: int) -> void: days.append(value))
	var initial_date := clock.get_calendar()
	clock._process(60.0)
	check(clock.world_minutes == 360 and clock.get_calendar() == initial_date, "60 seconds indoors preserve date and time")
	check(minutes.is_empty() and days.is_empty(), "no time events are emitted indoors")
	check("Tempo natural parado" in lab.get_node("HUD/Clock").text, "HUD reports frozen natural time indoors")
	var player: CharacterBody2D = lab.player
	var initial_position := player.position
	Input.action_press("move_right")
	for tick in range(20):
		await physics_frame
	Input.action_release("move_right")
	await settle()
	check(player.position.x > initial_position.x + 40, "player can move while natural time is frozen")
	check(not paused and clock.world_minutes == 360, "interior freeze does not pause the scene tree")
	await use_door(lab)
	check(lab.area_id == &"street" and clock.running, "door exit resumes the outdoor clock")
	clock._process(0.75)
	await use_door(lab)
	check(lab.area_id == &"room" and not clock.running, "door entry freezes natural time immediately")
	var before_interior := clock.get_calendar()
	clock._process(60.0)
	check(clock.get_calendar() == before_interior and minutes.is_empty(), "indoor wait does not consume the outdoor fractional second")
	await use_door(lab)
	clock._process(0.249)
	check(clock.world_minutes == 360, "resume waits for the remaining outdoor fraction")
	clock._process(0.001)
	check(clock.world_minutes == 361 and minutes == [361], "0.75s before entry plus 0.25s after exit advances exactly one minute")
	for cycle in range(20):
		clock._process(0.1)
		var before_entry := clock.world_minutes
		lab.change_area(&"room", &"door")
		clock._process(60.0)
		check(clock.world_minutes == before_entry, "indoor minute stays frozen in cycle %d" % (cycle + 1))
		lab.change_area(&"street", &"door")
	check(clock.world_minutes == 363 and minutes == [361, 362, 363], "twenty transitions preserve fractional progress without duplicate minutes")
	check(lab.time_manager == clock and lab.get_node("World").get_child_count() == 1, "clock persists with one active map")
	check("06:03" in lab.get_node("HUD/Clock").text and "Tempo externo" in lab.get_node("HUD/Clock").text, "HUD resumes with the preserved time")
	# A frozen clock must not roll the date over or fire midnight events.
	clock._process(17 * 60 + 56)
	clock._process(0.75)
	lab.change_area(&"room", &"door")
	clock._process(600.0)
	check(clock.get_calendar().hour == 23 and clock.get_calendar().minute == 59 and clock.get_calendar().day == 1 and days.is_empty(), "23:59 remains frozen indoors without a midnight event")
	lab.change_area(&"street", &"door")
	clock._process(0.25)
	check(clock.world_minutes == 1440 and clock.get_calendar().day == 2 and days == [1], "midnight fires once when outdoor time actually reaches it")
	check(minutes[-2] == 1439 and minutes[-1] == 1440, "minute events remain ordered after an interior wait")
	# Fresh production scene, automatic ticks, and monotonic real-time measurement.
	lab.queue_free()
	await settle()
	lab = LAB.instantiate()
	lab.test_storage_root = "user://test_runs/regression_" + str(Time.get_ticks_usec())
	root.add_child(lab)
	clock = lab.time_manager
	Engine.max_fps = 60
	var duration := 60.0 if "--realtime" in OS.get_cmdline_user_args() else 2.0
	var started_at := Time.get_ticks_usec()
	var start_position: Vector2 = lab.player.position
	var start_minutes := clock.world_minutes
	Input.action_press("move_right")
	print("REALTIME: measuring %.0fs inside the room with automatic ticks" % duration)
	# Measure wall time directly: engine delta may include earlier test work.
	while Time.get_ticks_usec() - started_at < int(duration * 1_000_000):
		await process_frame
	Input.action_release("move_right")
	await settle()
	var measured_seconds := (Time.get_ticks_usec() - started_at) / 1_000_000.0
	check(clock.world_minutes == start_minutes and lab.player.position.x > start_position.x, "actual indoor execution freezes time while movement continues")
	print("REALTIME: %.3fs indoors, %d game minutes" % [measured_seconds, clock.world_minutes - start_minutes])
	await use_door(lab)
	start_minutes = clock.world_minutes
	await create_timer(1.2).timeout
	check(clock.world_minutes > start_minutes and lab.area_id == &"street", "automatic outdoor ticking resumes after the real door exit")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
