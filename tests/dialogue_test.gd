extends SceneTree

const LAB := preload("res://scenes/lab/scale_lab.tscn")
const CONVERSATION: DialogueData = preload("res://data/dialogues/lab_conversation.tres")
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
	# The signal fires before node _process; allow a full HUD update as well.
	for frame in range(2):
		await process_frame
	for node in root.get_children():
		if node.has_method("change_area"):
			while node.transitioning:
				await process_frame


func press_key(code: Key, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.device = InputEvent.DEVICE_ID_KEYBOARD
	event.pressed = true
	event.echo = echo
	# Use engine input dispatch to catch propagation into world interactions.
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	event.echo = false
	Input.parse_input_event(event.duplicate())
	await process_frame


func approach_npc(lab: Node2D) -> void:
	lab.player.position = lab.area.get_node("DialogueNPC").position + Vector2(40, 0)
	await settle()


func click_button(button: Button) -> void:
	var center := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = center
	motion.global_position = center
	motion.device = InputEvent.DEVICE_ID_MOUSE
	# Coordinates are local to the viewport, including in the headless display.
	root.push_input(motion, true)
	await process_frame
	var event := InputEventMouseButton.new()
	event.position = center
	event.global_position = center
	event.button_index = MOUSE_BUTTON_LEFT
	event.device = InputEvent.DEVICE_ID_MOUSE
	event.pressed = true
	root.push_input(event.duplicate(), true)
	await process_frame
	event.pressed = false
	root.push_input(event, true)
	await process_frame


func capture(file_name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://docs/screenshots/" + file_name) == OK, "rendered " + file_name)


func run() -> void:
	Engine.max_fps = 60
	# Fullscreen has no physical display under headless; establish a GUI viewport.
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var lab: Node2D = LAB.instantiate()
	lab.test_storage_root = "user://test_runs/regression_" + str(Time.get_ticks_usec())
	root.add_child(lab)
	var clock: TimeManager = lab.time_manager
	clock.set_process(false)
	var panel: DialoguePanel = lab.dialogue_panel
	var lifecycle: Array[String] = []
	panel.opened.connect(func() -> void: lifecycle.append("opened"))
	panel.closed.connect(func() -> void: lifecycle.append("closed"))
	var minutes: Array[int] = []
	clock.minute_changed.connect(func(value: int) -> void: minutes.append(value))
	check(not panel.active and not panel.visible, "dialogue starts closed")
	var invalid := DialogueData.new()
	check(not panel.start(null) and not panel.start(invalid), "missing or empty dialogue is refused")
	invalid.speaker_key = &"LAB_NPC"
	invalid.line_keys = PackedStringArray([""])
	check(not panel.start(invalid) and lifecycle.is_empty() and lab.player.controls_enabled, "invalid line does not lock controls or emit lifecycle events")
	await settle()
	await press_key(KEY_E)
	check(not panel.active and lab.area_id == &"room", "E at a distance does not open dialogue or use a door")
	await approach_npc(lab)
	check(lab._interaction_target() == lab.area.get_node("DialogueNPC") and "conversar" in lab.get_node("HUD/Info").text, "nearby NPC shares interaction targeting and translated hint")
	await press_key(KEY_E)
	check(panel.active and panel.visible and panel.get_node("Panel/Line").text == tr("LAB_DIALOGUE_01"), "E opens first line without immediately advancing it")
	check(panel.get_node("Panel/Speaker").text == "NPC provisório", "speaker uses a translated placeholder key")
	check(not panel.start(CONVERSATION) and lifecycle == ["opened"], "active conversation cannot be replaced or opened twice")
	var start_position: Vector2 = lab.player.position
	Input.action_press("move_right")
	await settle()
	Input.action_release("move_right")
	clock._process(60.0)
	check(lab.player.position == start_position and lab.player.velocity == Vector2.ZERO, "movement stops during dialogue even with input held")
	check(clock.world_minutes == 360 and minutes.is_empty(), "sixty simulated seconds of indoor dialogue consume no time")
	await press_key(KEY_R)
	lab.get_node("HUD/ActivityButton").pressed.emit()
	await press_key(KEY_T)
	var previous_frame: bool = lab.player.show_frame
	await press_key(KEY_F)
	lab.request_transition(&"street", &"door")
	await settle()
	check(clock.world_minutes == 360 and lab.tile_size == 32 and lab.player.show_frame == previous_frame and lab.area_id == &"room", "dialogue blocks activities, scale controls and door transition requests")
	check(lab.get_node("HUD/ActivityButton").disabled, "underlying activity button is disabled during dialogue")
	await press_key(KEY_E, true)
	check(panel.get_node("Panel/Line").text == tr("LAB_DIALOGUE_01"), "held interaction key does not skip lines")
	if "--capture" in OS.get_cmdline_user_args():
		await capture("dialogue_room.png")
	await press_key(KEY_ENTER)
	check(panel.active and panel.get_node("Panel/Line").text == tr("LAB_DIALOGUE_02"), "Enter advances to the second line")
	await press_key(KEY_E)
	check(not panel.active and lifecycle == ["opened", "closed"], "final E closes once without reopening the nearby NPC")
	check(lab.player.controls_enabled and not clock.running and not lab.get_node("HUD/ActivityButton").disabled, "closing indoors restores controls while natural time remains frozen")
	await press_key(KEY_E)
	await press_key(KEY_ESCAPE)
	check(not panel.active and clock.world_minutes == 360, "Escape cancels without spending time")
	# Outdoors, pausing must preserve the existing fractional minute.
	lab.change_area(&"street", &"door")
	clock._process(0.75)
	await approach_npc(lab)
	await press_key(KEY_E)
	check(panel.active and not clock.running and "Tempo natural parado" in lab.get_node("HUD/Clock").text, "outdoor dialogue pauses natural time and updates HUD")
	clock._process(60.0)
	check(clock.world_minutes == 360 and minutes.is_empty(), "sixty simulated seconds outdoors emit no minutes while talking")
	if "--capture" in OS.get_cmdline_user_args():
		await capture("dialogue_street.png")
	await click_button(panel.get_node("Panel/Next"))
	check(panel.get_node("Panel/Line").text == tr("LAB_DIALOGUE_02"), "mouse advance button uses the same conversation")
	await click_button(panel.get_node("Panel/Close"))
	check(not panel.active and clock.running and "Tempo externo" in lab.get_node("HUD/Clock").text, "mouse close restores outdoor time and HUD")
	clock._process(0.249)
	check(clock.world_minutes == 360, "dialogue does not consume fractional outdoor progress")
	clock._process(0.001)
	check(clock.world_minutes == 361 and minutes == [361], "outdoor remainder resumes with exactly one minute")
	await press_key(KEY_E)
	lab.change_area(&"room", &"door")
	check(not panel.active and lab.player.controls_enabled and not clock.running and lab.get_node("World").get_child_count() == 1, "programmatic map replacement safely closes dialogue and applies new area state")
	await press_key(KEY_R)
	check(clock.world_minutes == 421, "explicit activity works again after dialogue closes")
	for tile in [32, 64]:
		lab.tile_size = tile
		lab.change_area(&"street", &"door")
		await approach_npc(lab)
		await press_key(KEY_E)
		check(panel.active, "NPC interaction is accessible at tile %d" % tile)
		await press_key(KEY_ESCAPE)
	# Fresh scene and real elapsed time with automatic production callbacks.
	lab.queue_free()
	await settle()
	lab = LAB.instantiate()
	lab.test_storage_root = "user://test_runs/regression_" + str(Time.get_ticks_usec())
	root.add_child(lab)
	lab.change_area(&"street", &"door")
	await approach_npc(lab)
	await press_key(KEY_E)
	clock = lab.time_manager
	var start_minutes := clock.world_minutes
	start_position = lab.player.position
	var started_at := Time.get_ticks_usec()
	var duration := 60.0 if "--realtime" in OS.get_cmdline_user_args() else 2.0
	Input.action_press("move_right")
	while Time.get_ticks_usec() - started_at < int(duration * 1_000_000):
		await process_frame
	Input.action_release("move_right")
	check(lab.dialogue_panel.active and clock.world_minutes == start_minutes and lab.player.position == start_position, "actual outdoor conversation freezes time and movement")
	print("REALTIME: %.3fs talking outdoors, %d game minutes" % [(Time.get_ticks_usec() - started_at) / 1_000_000.0, clock.world_minutes - start_minutes])
	await press_key(KEY_ESCAPE)
	await create_timer(1.2).timeout
	check(clock.running and clock.world_minutes > start_minutes, "automatic ticking resumes after conversation")
	Input.action_press("move_right")
	await settle()
	Input.action_release("move_right")
	check(lab.player.position.x > start_position.x, "movement resumes after conversation")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
