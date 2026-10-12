extends Node2D

const AREAS := {
	&"room": preload("res://scenes/world/room.tscn"),
	&"street": preload("res://scenes/world/street.tscn"),
	&"route": preload("res://scenes/world/route.tscn"),
	&"campus": preload("res://scenes/world/campus.tscn"),
}
const SEASON_KEYS := ["SEASON_SPRING", "SEASON_SUMMER", "SEASON_AUTUMN", "SEASON_WINTER"]
const WEEKDAY_KEYS := ["WEEKDAY_MON", "WEEKDAY_TUE", "WEEKDAY_WED", "WEEKDAY_THU", "WEEKDAY_FRI", "WEEKDAY_SAT", "WEEKDAY_SUN"]
const TEST_ACTIVITY: TimedAction = preload("res://data/activities/lab_activity.tres")
const SEASON_FILTERS := [Color(1.0, 0.55, 0.72, 0.09), Color(0.3, 0.65, 1.0, 0.09), Color(1.0, 0.55, 0.2, 0.12), Color(1.0, 1.0, 1.0, 0.12)]
@export var test_storage_root: String = ""
var area: Node2D
var area_id: StringName = &"room"
var tile_size: int = 32
var transitioning: bool = false
var protagonist_name: String = ""
var loading_slot: bool = false
var sleep_manager: SleepManager
var save_manager: SaveManager
var sleep_panel: SleepPanel
var debug_panel: CalendarDebugPanel
var travel_start_minutes: int = -1
var travel_start_usec: int = 0
var travel_result: String = ""
@onready var player: CharacterBody2D = $Player
@onready var time_manager: TimeManager = $TimeManager
@onready var dialogue_panel: DialoguePanel = $HUD/DialoguePanel


func _ready() -> void:
	_setup_inputs()
	save_manager = SaveManager.new()
	if not test_storage_root.is_empty():
		save_manager.storage_root = test_storage_root.path_join("saves")
		save_manager.settings_path = test_storage_root.path_join("settings.json")
	add_child(save_manager)
	save_manager.load_settings()
	sleep_manager = SleepManager.new()
	sleep_manager.clock = time_manager
	add_child(sleep_manager)
	sleep_panel = SleepPanel.new()
	sleep_panel.name = "SleepPanel"
	sleep_panel.manager = sleep_manager
	$HUD.add_child(sleep_panel)
	debug_panel = CalendarDebugPanel.new()
	debug_panel.name = "DebugPanel"
	debug_panel.clock = time_manager
	$HUD.add_child(debug_panel)
	debug_panel.autosave.set_pressed_no_signal(save_manager.autosave_enabled)
	debug_panel.visibility_updated.connect(_sync_controls)
	sleep_panel.visibility_updated.connect(_sync_controls)
	sleep_panel.sleep_chosen.connect(_choose_sleep)
	sleep_panel.cancel_requested.connect(_cancel_sleep)
	sleep_panel.alarm_changed.connect(func(minutes: int) -> void: sleep_manager.alarm_minutes = minutes)
	sleep_manager.requested.connect(_show_sleep)
	sleep_manager.woke.connect(_on_woke)
	debug_panel.jump_requested.connect(debug_jump)
	debug_panel.load_requested.connect(load_slot)
	debug_panel.autosave_changed.connect(_set_autosave)
	debug_panel.name_changed.connect(func(value: String) -> void: protagonist_name = value)
	$HUD/DebugButton.text = tr("DEBUG_OPEN")
	$HUD/DebugButton.pressed.connect(_open_debug)
	$HUD/FullscreenButton.text = tr("FULLSCREEN_TOGGLE")
	$HUD/FullscreenButton.pressed.connect(_toggle_fullscreen)
	time_manager.enforce_sleep_limit = true
	time_manager.minute_changed.connect(_on_minute_changed)
	time_manager.clock_restored.connect(_update_clock)
	time_manager.sleep_limit_reached.connect(_on_sleep_limit)
	$HUD/ActivityButton.text = tr(TEST_ACTIVITY.label_key) % TEST_ACTIVITY.duration_minutes
	$HUD/ActivityButton.pressed.connect(_run_test_activity)
	dialogue_panel.opened.connect(_sync_controls)
	dialogue_panel.closed.connect(_sync_controls)
	get_viewport().size_changed.connect(_layout_hud)
	_layout_hud()
	change_area(&"room", &"start")


func _setup_inputs() -> void:
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E], "compare_scale": [KEY_T], "show_frame": [KEY_F],
		"test_activity": [KEY_R],
		"debug_calendar": [KEY_C], "toggle_fullscreen": [KEY_F11],
	}
	for action: String in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)


func _unhandled_input(event: InputEvent) -> void:
	if transitioning or _modal_open():
		return
	if event.is_action_pressed("interact") and not event.is_echo():
		var target := _interaction_target()
		if target != null:
			target.interact(player)
	elif event.is_action_pressed("compare_scale") and not event.is_echo():
		tile_size = 64 if tile_size == 32 else 32
		area.tile_size = tile_size
		area.rebuild()
		# Reset to a safe marker: enlarged furniture may cover the old position.
		player.position = area.get_node("Spawns/door").position
		player.velocity = Vector2.ZERO
	elif event.is_action_pressed("show_frame") and not event.is_echo():
		player.show_frame = not player.show_frame
		player.queue_redraw()
	elif event.is_action_pressed("test_activity") and not event.is_echo():
		_run_test_activity()
	elif event.is_action_pressed("debug_calendar") and not event.is_echo():
		_open_debug()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen") and not event.is_echo():
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()


func _run_test_activity() -> void:
	if transitioning or _modal_open():
		return
	if time_manager.advance_minutes(TEST_ACTIVITY.duration_minutes):
		$HUD/ActivityResult.text = tr("ACTIVITY_COMPLETED") % TEST_ACTIVITY.duration_minutes
	else:
		$HUD/ActivityResult.text = tr("ACTIVITY_SLEEP_LIMIT")


func request_transition(target: StringName, spawn: StringName) -> void:
	if transitioning or _modal_open():
		return
	transitioning = true
	change_area.call_deferred(target, spawn)


func change_area(target: StringName, spawn: StringName) -> void:
	var had_area := is_instance_valid(area)
	if not AREAS.has(target):
		push_error("Unknown laboratory area: " + String(target))
		transitioning = false
		return
	var next_area: Node2D = AREAS[target].instantiate()
	var marker := next_area.get_node_or_null("Spawns/" + String(spawn)) as Marker2D
	if marker == null:
		push_error("Unknown laboratory spawn: " + String(spawn))
		next_area.free()
		transitioning = false
		return
	dialogue_panel.close()
	if is_instance_valid(area):
		$World.remove_child(area)
		area.queue_free()
	area = next_area
	area_id = target
	area.tile_size = tile_size
	$World.add_child(area)
	# Natural time is enabled only in the outdoor laboratory.
	_sync_controls()
	for target_node in get_tree().get_nodes_in_group("interactables"):
		if not area.is_ancestor_of(target_node):
			continue
		if target_node.has_signal("transition_requested"):
			target_node.transition_requested.connect(request_transition)
		if target_node.has_signal("dialogue_requested"):
			target_node.dialogue_requested.connect(_open_dialogue)
		if target_node.has_signal("sleep_requested"):
			target_node.sleep_requested.connect(func() -> void: sleep_manager.request())
	player.position = marker.position
	player.velocity = Vector2.ZERO
	player.facing = &"down" if target == &"street" else &"up"
	player.update_animation(Vector2.ZERO)
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_right = int(area.map_size.x)
	camera.limit_bottom = int(area.map_size.y)
	camera.zoom = Vector2.ONE
	camera.reset_smoothing()
	transitioning = false
	if target == &"route" and spawn == &"door":
		travel_start_minutes = time_manager.world_minutes
		travel_start_usec = Time.get_ticks_usec()
		travel_result = ""
	elif target == &"campus" and travel_start_minutes >= 0:
		travel_result = tr("TRAVEL_RESULT") % [(Time.get_ticks_usec() - travel_start_usec) / 1_000_000.0, time_manager.world_minutes - travel_start_minutes]
		travel_start_minutes = -1
	if had_area and not loading_slot and not sleep_manager.pending:
		_autosave()


func _open_dialogue(data: DialogueData) -> void:
	if not transitioning and not _modal_open():
		dialogue_panel.start(data)


func _sync_controls() -> void:
	var blocked := _modal_open()
	player.controls_enabled = not blocked
	player.velocity = Vector2.ZERO
	time_manager.running = is_instance_valid(area) and area.exterior and not blocked
	$HUD/ActivityButton.disabled = blocked
	$HUD/DebugButton.disabled = blocked
	_update_clock()


func _modal_open() -> bool:
	return dialogue_panel.active or sleep_manager.pending or debug_panel.visible


func _open_debug() -> void:
	if not _modal_open() and not transitioning:
		debug_panel.name_edit.text = protagonist_name
		debug_panel.open()


func debug_jump(minutes: int) -> bool:
	if sleep_manager.pending or minutes < time_manager.world_minutes:
		return false
	debug_panel.close()
	travel_start_minutes = -1
	travel_result = ""
	if not time_manager.restore_clock(minutes, 0.0, time_manager.weekday_offset):
		return false
	if minutes % 1440 == 240:
		_on_sleep_limit()
	else:
		_sync_controls()
	return true


func _on_sleep_limit() -> void:
	dialogue_panel.close()
	debug_panel.close()
	sleep_manager.request(true, area_id != &"room")


func _show_sleep() -> void:
	if sleep_manager.forced and sleep_manager.was_outside:
		change_area(&"room", &"bed")
	sleep_panel.open()
	_sync_controls()


func _choose_sleep(manual_save: bool) -> void:
	if manual_save and not save_manager.save_slot("manual", snapshot()):
		sleep_panel.status.text = tr("SAVE_FAILED")
		return
	sleep_manager.complete()


func _cancel_sleep() -> void:
	if sleep_manager.cancel():
		sleep_panel.dismiss()
		_sync_controls()


func _on_woke(duration_minutes: int) -> void:
	player.position = area.get_node("Spawns/bed").position
	sleep_panel.dismiss()
	_sync_controls()
	$HUD/ActivityResult.text = tr("SLEEP_RESULT") % duration_minutes
	_autosave()


func snapshot() -> Dictionary:
	return {"schema_version": SaveManager.SCHEMA_VERSION, "world": time_manager.get_clock_state(), "player": {"name": protagonist_name, "area": String(area_id), "x": player.position.x, "y": player.position.y}, "sleep": sleep_manager.get_state(), "lab": {"tile_size": tile_size}}


func load_slot(kind: String) -> bool:
	if sleep_manager.pending:
		return false
	var state := save_manager.load_slot(kind)
	if state.is_empty():
		$HUD/ActivityResult.text = tr("LOAD_FAILED")
		return false
	loading_slot = true
	dialogue_panel.close()
	debug_panel.close()
	tile_size = int(state.lab.tile_size)
	protagonist_name = state.player.name
	time_manager.restore_clock(int(state.world.minutes), float(state.world.fraction), int(state.world.weekday_offset))
	sleep_manager.alarm_minutes = int(state.sleep.alarm_minutes)
	sleep_manager.pending = state.sleep.pending
	sleep_manager.forced = state.sleep.forced
	sleep_manager.was_outside = state.sleep.was_outside
	time_manager.sleep_pending = sleep_manager.pending
	change_area(StringName(state.player.area), &"door")
	player.position = Vector2(state.player.x, state.player.y)
	travel_start_minutes = -1
	travel_result = ""
	loading_slot = false
	if sleep_manager.pending:
		sleep_panel.open()
	_sync_controls()
	$HUD/ActivityResult.text = tr("LOAD_OK")
	return true


func _autosave() -> void:
	if save_manager.autosave_enabled and not save_manager.save_slot("auto", snapshot()):
		$HUD/ActivityResult.text = tr("SAVE_FAILED")


func _set_autosave(enabled: bool) -> void:
	if not save_manager.set_autosave(enabled):
		debug_panel.autosave.set_pressed_no_signal(save_manager.autosave_enabled)
		$HUD/ActivityResult.text = tr("SAVE_FAILED")


func _toggle_fullscreen() -> void:
	var window := get_window()
	window.mode = Window.MODE_WINDOWED if window.mode != Window.MODE_WINDOWED else Window.MODE_FULLSCREEN


func _layout_hud() -> void:
	var size := get_viewport_rect().size
	$HUD/Panel.size.x = size.x
	$HUD/Info.size.x = size.x - 40
	$HUD/ClockPanel.position = Vector2(0, size.y - 32)
	$HUD/ClockPanel.size = Vector2(size.x, 32)
	$HUD/Clock.position = Vector2(20, size.y - 28)
	$HUD/Clock.size.x = size.x - 40
	$HUD/ActivityButton.position = Vector2(size.x - 340, size.y - 76)
	$HUD/ActivityResult.position = Vector2(20, size.y - 70)
	$HUD/ActivityResult.size.x = size.x - 380
	$HUD/DebugButton.position = Vector2(size.x - 350, 108)
	$HUD/FullscreenButton.position = Vector2(size.x - 170, 108)


func _interaction_target() -> Area2D:
	var nearest: Area2D
	var nearest_distance := INF
	for candidate in get_tree().get_nodes_in_group("interactables"):
		if not area.is_ancestor_of(candidate) or not candidate.can_interact(player):
			continue
		var distance := player.global_position.distance_squared_to(candidate.global_position)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest


func _on_minute_changed(_absolute_minutes: int) -> void:
	_update_clock()


func _update_clock() -> void:
	var calendar := time_manager.get_calendar()
	var status := tr("CLOCK_RUNNING") if time_manager.running else tr("CLOCK_STOPPED")
	$HUD/Clock.text = tr("CLOCK_DATE") % [calendar.year, tr(SEASON_KEYS[calendar.season_index]), calendar.day, tr(WEEKDAY_KEYS[calendar.weekday]), calendar.hour, calendar.minute] + " · " + status
	$SeasonFilter/Tint.color = SEASON_FILTERS[calendar.season_index]


func _process(_delta: float) -> void:
	var location := tr({&"room": "LAB_ROOM", &"street": "LAB_STREET", &"route": "LAB_ROUTE", &"campus": "LAB_CAMPUS"}[area_id])
	var target := _interaction_target() if not _modal_open() else null
	var hint := tr(target.hint_key) if target != null else ""
	$HUD/Info.text = tr("LAB_TITLE") + " | " + location + " | " + tr("LAB_SCALE") % tile_size + "\n" + tr("LAB_CONTROLS") + "\n" + hint
	if travel_start_minutes >= 0:
		$HUD/Info.text += tr("TRAVEL_PROGRESS") % [player.position.x / 1000.0, (Time.get_ticks_usec() - travel_start_usec) / 1_000_000.0, time_manager.world_minutes - travel_start_minutes]
	elif not travel_result.is_empty():
		$HUD/Info.text += travel_result
