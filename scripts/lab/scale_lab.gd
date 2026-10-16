extends Node2D

const AREAS := {
	&"room": preload("res://scenes/world/room.tscn"),
	&"street": preload("res://scenes/world/street.tscn"),
	&"route": preload("res://scenes/world/route.tscn"),
	&"campus": preload("res://scenes/world/campus.tscn"),
	&"university": preload("res://scenes/world/university.tscn"),
	&"classroom": preload("res://scenes/world/classroom.tscn"),
}
const SEASON_KEYS := ["SEASON_SPRING", "SEASON_SUMMER", "SEASON_AUTUMN", "SEASON_WINTER"]
const WEEKDAY_KEYS := ["WEEKDAY_MON", "WEEKDAY_TUE", "WEEKDAY_WED", "WEEKDAY_THU", "WEEKDAY_FRI", "WEEKDAY_SAT", "WEEKDAY_SUN"]
const TEST_ACTIVITY: TimedAction = preload("res://data/activities/lab_activity.tres")
const PROFESSOR_INTRO: DialogueData = preload("res://data/dialogues/professor_introduction.tres")
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
var journey := WalkingJourney.new()
var fade: SceneFade
var academics: AcademicSchedule
var academic_panel: AcademicPanel
var city_map: CityMapPanel
var first_lesson_pending: bool = false
var _first_lesson_minutes: int = -1
var classmate: ClassmateEncounter
var _classmate_pending: StringName = &""
var _classmate_minutes: int = -1
var question_panel: ClassQuestionPanel
var _question_minutes: int = -1
var _question_intro_completed: bool = false
var home_introductions: HomeIntroductions
var hobbies_panel: HobbiesPanel
var _home_pending: StringName = &""
var _home_event: StringName = &""
var _home_minutes: int = -1
@onready var player: CharacterBody2D = $Player
@onready var time_manager: TimeManager = $TimeManager
@onready var dialogue_panel: DialoguePanel = $HUD/DialoguePanel


func _ready() -> void:
	_setup_inputs()
	fade = SceneFade.new()
	add_child(fade)
	save_manager = SaveManager.new()
	if not test_storage_root.is_empty():
		save_manager.storage_root = test_storage_root.path_join("saves")
		save_manager.settings_path = test_storage_root.path_join("settings.json")
	add_child(save_manager)
	save_manager.load_settings()
	sleep_manager = SleepManager.new()
	sleep_manager.clock = time_manager
	add_child(sleep_manager)
	academics = AcademicSchedule.new()
	academics.clock = time_manager
	add_child(academics)
	classmate = ClassmateEncounter.new()
	classmate.clock = time_manager
	add_child(classmate)
	classmate.changed.connect(_refresh_classmate)
	home_introductions = HomeIntroductions.new()
	home_introductions.clock = time_manager
	add_child(home_introductions)
	home_introductions.changed.connect(_refresh_home)
	hobbies_panel = HobbiesPanel.new()
	hobbies_panel.introductions = home_introductions
	$HUD.add_child(hobbies_panel)
	hobbies_panel.visibility_updated.connect(_sync_controls)
	academic_panel = AcademicPanel.new()
	academic_panel.schedule = academics
	$HUD.add_child(academic_panel)
	academic_panel.visibility_updated.connect(_sync_controls)
	academic_panel.attendance_requested.connect(_attend_class)
	academic_panel.wait_requested.connect(_wait_for_class)
	question_panel = ClassQuestionPanel.new()
	$HUD.add_child(question_panel)
	question_panel.visibility_updated.connect(_sync_controls)
	question_panel.answer_requested.connect(_answer_class_question)
	question_panel.dismissed.connect(_on_question_closed)
	city_map = CityMapPanel.new()
	$HUD.add_child(city_map)
	city_map.visibility_updated.connect(_sync_controls)
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
	debug_panel.name_changed.connect(_set_protagonist_name)
	$HUD/DebugButton.text = tr("DEBUG_OPEN")
	$HUD/DebugButton.pressed.connect(_open_debug)
	$HUD/FullscreenButton.text = tr("FULLSCREEN_TOGGLE")
	$HUD/FullscreenButton.pressed.connect(_toggle_fullscreen)
	$HUD/HobbiesButton.text = tr("HOBBIES_OPEN")
	$HUD/HobbiesButton.pressed.connect(_open_hobbies)
	time_manager.enforce_sleep_limit = true
	time_manager.minute_changed.connect(_on_minute_changed)
	time_manager.clock_restored.connect(_update_clock)
	time_manager.sleep_limit_reached.connect(_on_sleep_limit)
	$HUD/ActivityButton.text = tr(TEST_ACTIVITY.label_key) % TEST_ACTIVITY.duration_minutes
	$HUD/ActivityButton.pressed.connect(_run_test_activity)
	dialogue_panel.opened.connect(_sync_controls)
	dialogue_panel.closed.connect(_sync_controls)
	dialogue_panel.finished.connect(_on_lesson_dialogue_finished)
	dialogue_panel.finished.connect(_on_classmate_dialogue_finished)
	dialogue_panel.finished.connect(_on_home_dialogue_finished)
	get_viewport().size_changed.connect(_layout_hud)
	_layout_hud()
	_set_protagonist_name(protagonist_name)
	change_area(&"room", &"start")


func _set_protagonist_name(value: String) -> void:
	protagonist_name = value
	dialogue_panel.text_context = {"player_name": value, "player_salutation": "" if value.strip_edges().is_empty() else ", " + value}


func _setup_inputs() -> void:
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E], "compare_scale": [KEY_T], "show_frame": [KEY_F],
		"test_activity": [KEY_R],
		"debug_calendar": [KEY_C], "toggle_fullscreen": [KEY_F11],
		"academic_schedule": [KEY_J], "city_map": [KEY_M], "hobbies": [KEY_H],
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
		journey.reset() # Tile comparison teleports, invalidating a walking trial.
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
	elif event.is_action_pressed("academic_schedule") and not event.is_echo():
		_open_academics()
	elif event.is_action_pressed("hobbies") and not event.is_echo():
		_open_hobbies()
	elif event.is_action_pressed("city_map") and not event.is_echo():
		city_map.region_id = area_id
		city_map.player_position = player.position
		city_map.open()


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
	if transitioning or _modal_open() or not _valid_destination(target, spawn):
		return
	transitioning = true
	_sync_controls()
	_transition_to.call_deferred(target, spawn)


func _valid_destination(target: StringName, spawn: StringName) -> bool:
	if not AREAS.has(target):
		return false
	return spawn in [&"start", &"door", &"bed"] if target == &"room" else WorldLayouts.region(String(target)).spawns.has(String(spawn))


func _transition_to(target: StringName, spawn: StringName) -> void:
	transitioning = true
	_sync_controls()
	await fade.play(func() -> void: change_area(target, spawn))
	transitioning = false
	_sync_controls()


func change_area(target: StringName, spawn: StringName) -> void:
	var had_area := is_instance_valid(area)
	var previous_area := area_id
	if not AREAS.has(target):
		push_error("Unknown laboratory area: " + String(target))
		transitioning = false
		return
	var next_area: Node2D = AREAS[target].instantiate()
	if next_area.has_method("prepare"):
		next_area.prepare()
	var marker := next_area.get_node_or_null("Spawns/" + String(spawn)) as Marker2D
	if marker == null:
		push_error("Unknown laboratory spawn: " + String(spawn))
		next_area.free()
		transitioning = false
		return
	first_lesson_pending = false
	_classmate_pending = &""
	_home_pending = &""
	_clear_question()
	dialogue_panel.close()
	if is_instance_valid(area):
		$World.remove_child(area)
		area.queue_free()
	area = next_area
	area_id = target
	area.tile_size = tile_size
	$World.add_child(area)
	_refresh_classmate()
	_refresh_home()
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
		if target_node.has_signal("lesson_requested"):
			target_node.lesson_requested.connect(_open_academics)
	for destination in get_tree().get_nodes_in_group("journey_destinations"):
		if area.is_ancestor_of(destination):
			destination.reached.connect(_on_journey_arrival)
	player.position = marker.position
	player.velocity = Vector2.ZERO
	player.facing = &"down" if target == &"street" else &"up"
	player.update_animation(Vector2.ZERO)
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_right = int(area.map_size.x)
	camera.limit_bottom = int(area.map_size.y)
	camera.zoom = Vector2.ONE
	camera.reset_smoothing()
	transitioning = fade.active
	if target == &"room":
		journey.reset()
	elif not loading_slot:
		if previous_area == &"room" and target == &"street":
			journey.begin(time_manager.world_minutes, &"home")
		elif target == &"route" and spawn == &"door" and not journey.active:
			journey.begin(time_manager.world_minutes, &"route")
	if had_area and not loading_slot and not sleep_manager.pending:
		_autosave()


func _open_dialogue(data: DialogueData) -> void:
	if not transitioning and not _modal_open():
		dialogue_panel.start(data)


func _refresh_classmate() -> void:
	if loading_slot or not is_instance_valid(area):
		return
	var actor := area.get_node_or_null("Classmate") as Area2D
	var location := classmate.location()
	if location.is_empty() or location.area != String(area_id):
		if actor != null:
			area.remove_child(actor)
			actor.queue_free()
		return
	if actor == null:
		actor = preload("res://scenes/world/dialogue_npc.tscn").instantiate()
		actor.set_script(preload("res://scripts/world/classmate_npc.gd"))
		actor.name = "Classmate"
		actor.meeting_requested.connect(_open_classmate_dialogue)
		area.add_child(actor)
	var profile := ClassmateEncounter.profile()
	actor.position = WorldLayouts.point(location.at)
	actor.marker_key = StringName(profile.marker)
	actor.hint_key = StringName(profile.hint)
	actor.marker_offset = WorldLayouts.point(profile.marker_offset)
	actor.marker_color = Color("e6b8c7")
	actor.dialogue = classmate.dialogue()
	actor.queue_redraw()


func _open_classmate_dialogue(actor: Area2D) -> void:
	if _modal_open() or not is_instance_valid(actor) or actor != area.get_node_or_null("Classmate") or not actor.can_interact(player):
		return
	_classmate_pending = classmate.conversation()
	_classmate_minutes = time_manager.world_minutes
	if not dialogue_panel.start(classmate.dialogue()):
		_classmate_pending = &""
		_sync_controls()


func _on_classmate_dialogue_finished(was_completed: bool) -> void:
	if _classmate_pending.is_empty():
		return
	var id := _classmate_pending
	_classmate_pending = &""
	var location := classmate.location()
	var valid: bool = not transitioning and not loading_slot and not sleep_manager.pending and time_manager.world_minutes == _classmate_minutes and not location.is_empty() and location.area == String(area_id)
	_classmate_minutes = -1
	if was_completed and valid and classmate.remember(id):
		_autosave()


func _sync_controls() -> void:
	var blocked := _modal_open()
	player.controls_enabled = not blocked
	player.velocity = Vector2.ZERO
	time_manager.running = is_instance_valid(area) and area.exterior and not blocked
	$HUD/ActivityButton.disabled = blocked
	$HUD/DebugButton.disabled = blocked
	$HUD/HobbiesButton.disabled = blocked
	_update_clock()


func _modal_open() -> bool:
	return transitioning or first_lesson_pending or not _classmate_pending.is_empty() or not _home_pending.is_empty() or dialogue_panel.active or sleep_manager.pending or (is_instance_valid(hobbies_panel) and hobbies_panel.visible) or (is_instance_valid(question_panel) and question_panel.visible) or (is_instance_valid(debug_panel) and debug_panel.visible) or (is_instance_valid(academic_panel) and academic_panel.visible) or (is_instance_valid(city_map) and city_map.visible)


func _open_hobbies() -> void:
	if not _modal_open():
		hobbies_panel.open()


func _refresh_home() -> void:
	if loading_slot or not is_instance_valid(area) or area_id != &"room":
		return
	for actor_id in HomeIntroductions.data().actors:
		var profile: Dictionary = HomeIntroductions.data().actors[actor_id]
		var actor := area.get_node_or_null(profile.node) as Area2D
		if not HomeIntroductions.available(actor_id, time_manager.world_minutes):
			if actor != null:
				area.remove_child(actor)
				actor.queue_free()
			continue
		if actor == null:
			actor = preload("res://scenes/world/dialogue_npc.tscn").instantiate()
			actor.set_script(preload("res://scripts/world/home_event_point.gd"))
			actor.name = profile.node
			actor.actor_id = StringName(actor_id)
			actor.home_event_requested.connect(_open_home_dialogue)
			area.add_child(actor)
		actor.position = WorldLayouts.point(profile.at)
		actor.marker_key = StringName(profile.marker)
		actor.hint_key = StringName(profile.hint)
		actor.marker_offset = WorldLayouts.point(profile.marker_offset)
		actor.marker_color = Color(profile.color)
		actor.dialogue = home_introductions.dialogue(StringName(actor_id))
		actor.queue_redraw()


func _open_home_dialogue(actor: Area2D) -> void:
	if _modal_open() or area_id != &"room" or not is_instance_valid(actor) or not area.is_ancestor_of(actor) or not actor.has_signal("home_event_requested") or not actor.can_interact(player):
		return
	var profile: Dictionary = HomeIntroductions.data().actors.get(String(actor.actor_id), {})
	if profile.is_empty() or actor != area.get_node_or_null(profile.node):
		return
	_home_pending = actor.actor_id
	_home_event = home_introductions.conversation(_home_pending)
	_home_minutes = time_manager.world_minutes
	if not dialogue_panel.start(home_introductions.dialogue(_home_pending)):
		_home_pending = &""
		_sync_controls()


func _on_home_dialogue_finished(was_completed: bool) -> void:
	if _home_pending.is_empty():
		return
	var actor_id := _home_pending
	var event_id := _home_event
	_home_pending = &""
	var valid := area_id == &"room" and not transitioning and not loading_slot and not sleep_manager.pending and time_manager.world_minutes == _home_minutes
	_home_minutes = -1
	_home_event = &""
	if was_completed and valid and home_introductions.remember(actor_id, event_id):
		if event_id == &"intro":
			var hobby: String = HomeIntroductions.data().actors[String(actor_id)].hobby
			$HUD/ActivityResult.text = tr("HOBBY_DISCOVERED") % tr(HomeIntroductions.data().hobbies[hobby].label)
		_autosave()


func _open_academics() -> void:
	if not _modal_open():
		academic_panel.in_classroom = area_id == &"classroom"
		academic_panel.open()


func _academic_action_allowed() -> bool:
	return area_id == &"classroom" and academic_panel.visible and not transitioning and not sleep_manager.pending and not dialogue_panel.active and not question_panel.visible and not hobbies_panel.visible and not debug_panel.visible and not city_map.visible


func _attend_class() -> void:
	if not _academic_action_allowed() or first_lesson_pending:
		return
	var session := academics.current_session()
	if session.is_empty() or academics.status(time_manager.world_minutes / 1440, session) == "present":
		return
	if not academics.professor_intro_seen:
		first_lesson_pending = true
		_first_lesson_minutes = time_manager.world_minutes
		academic_panel.close()
		if not dialogue_panel.start(PROFESSOR_INTRO):
			first_lesson_pending = false
			_open_academics()
		return
	_continue_lesson()


func _on_lesson_dialogue_finished(was_completed: bool) -> void:
	if not first_lesson_pending:
		return
	first_lesson_pending = false
	var can_finish := area_id == &"classroom" and not transitioning and not loading_slot and not sleep_manager.pending and time_manager.world_minutes == _first_lesson_minutes
	_first_lesson_minutes = -1
	if was_completed and can_finish:
		_continue_lesson(true)
	elif can_finish:
		_open_academics()
	else:
		_sync_controls()


func _continue_lesson(introduced: bool = false) -> void:
	if academics.needs_question():
		var question := ClassQuestionBank.first()
		if question.is_empty():
			_open_academics()
			return
		_question_minutes = time_manager.world_minutes
		_question_intro_completed = introduced
		academic_panel.close()
		question_panel.start(question)
	elif academics.attend():
		if introduced:
			academics.professor_intro_seen = true
		_autosave()
		if not academic_panel.visible:
			_open_academics()
		academic_panel.refresh()


func _answer_class_question(option_id: String) -> void:
	if not question_panel.visible or question_panel.answered or area_id != &"classroom" or transitioning or loading_slot or sleep_manager.pending or time_manager.world_minutes != _question_minutes:
		return
	if academics.attend(option_id):
		if _question_intro_completed:
			academics.professor_intro_seen = true
		question_panel.show_result(academics.question_answers[question_panel.question.id])
		_autosave()
		_sync_controls()


func _on_question_closed() -> void:
	_question_minutes = -1
	_question_intro_completed = false
	if area_id == &"classroom" and not transitioning and not loading_slot and not sleep_manager.pending:
		_open_academics()


func _clear_question() -> void:
	_question_minutes = -1
	_question_intro_completed = false
	if is_instance_valid(question_panel):
		question_panel.dismiss()


func _wait_for_class() -> void:
	if _academic_action_allowed() and academics.current_session().is_empty() and academics.wait_for_class():
		academic_panel.refresh()
		_autosave()


func _open_debug() -> void:
	if not _modal_open() and not transitioning:
		debug_panel.name_edit.text = protagonist_name
		debug_panel.open()


func debug_jump(minutes: int) -> bool:
	if first_lesson_pending or question_panel.visible or hobbies_panel.visible or not _home_pending.is_empty() or not _classmate_pending.is_empty() or sleep_manager.pending or minutes < time_manager.world_minutes:
		return false
	debug_panel.close()
	journey.reset()
	if not time_manager.restore_clock(minutes, 0.0, time_manager.weekday_offset):
		return false
	if minutes % 1440 == 240:
		_on_sleep_limit()
	else:
		_sync_controls()
	return true


func _on_sleep_limit() -> void:
	first_lesson_pending = false
	_classmate_pending = &""
	_home_pending = &""
	_clear_question()
	dialogue_panel.close()
	debug_panel.close()
	academic_panel.close()
	city_map.close()
	hobbies_panel.close()
	sleep_manager.request(true, area_id != &"room")


func _show_sleep() -> void:
	if sleep_manager.forced and sleep_manager.was_outside:
		await _transition_to(&"room", &"bed")
	sleep_panel.open()
	_sync_controls()


func _choose_sleep(manual_save: bool) -> void:
	if not sleep_manager.pending or transitioning:
		return
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
	return {"schema_version": SaveManager.SCHEMA_VERSION, "world": time_manager.get_clock_state(), "player": {"name": protagonist_name, "area": String(area_id), "x": player.position.x, "y": player.position.y}, "sleep": sleep_manager.get_state(), "lab": {"tile_size": tile_size}, "academics": academics.get_state(), "classmate": classmate.get_state(), "home_introductions": home_introductions.get_state()}


func load_slot(kind: String) -> bool:
	if sleep_manager.pending or transitioning:
		return false
	var state := save_manager.load_slot(kind)
	if state.is_empty():
		$HUD/ActivityResult.text = tr("LOAD_FAILED")
		return false
	transitioning = true
	_sync_controls()
	await fade.play(func() -> void: _restore_state(state))
	transitioning = false
	_sync_controls()
	$HUD/ActivityResult.text = tr("LOAD_MIGRATED" if state.get("migrated_from_legacy", false) else "LOAD_OK")
	return true


func _restore_state(state: Dictionary) -> void:
	loading_slot = true
	first_lesson_pending = false
	_classmate_pending = &""
	_home_pending = &""
	_clear_question()
	dialogue_panel.close()
	debug_panel.close()
	academic_panel.close()
	city_map.close()
	hobbies_panel.close()
	tile_size = int(state.lab.tile_size)
	_set_protagonist_name(state.player.name)
	academics.suspended = true
	classmate.suspended = true
	home_introductions.suspended = true
	time_manager.restore_clock(int(state.world.minutes), float(state.world.fraction), int(state.world.weekday_offset))
	academics.restore(state.academics)
	classmate.restore(state.get("classmate", {}))
	home_introductions.restore(state.get("home_introductions", {}))
	academics.suspended = false
	classmate.suspended = false
	home_introductions.suspended = false
	sleep_manager.alarm_minutes = int(state.sleep.alarm_minutes)
	sleep_manager.pending = state.sleep.pending
	sleep_manager.forced = state.sleep.forced
	sleep_manager.was_outside = state.sleep.was_outside
	time_manager.sleep_pending = sleep_manager.pending
	change_area(StringName(state.player.area), &"door")
	player.position = Vector2(state.player.x, state.player.y)
	journey.reset()
	loading_slot = false
	_refresh_classmate()
	_refresh_home()
	if sleep_manager.pending:
		sleep_panel.open()
	_sync_controls()


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
	$HUD/Info.add_theme_font_size_override("font_size", 16 if size.x < 1100 else 18)
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
	$HUD/HobbiesButton.position = Vector2(20, 108)


func _interaction_target() -> Area2D:
	var nearest: Area2D
	var nearest_distance := INF
	for candidate in get_tree().get_nodes_in_group("interactables"):
		if not area.is_ancestor_of(candidate) or not candidate.can_interact(player):
			continue
		var distance := player.global_position.distance_squared_to(candidate.global_position)
		# At an entrance, prefer entering over the nearby location description.
		if candidate.has_signal("transition_requested"):
			distance -= 10000
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest


func _on_minute_changed(_absolute_minutes: int) -> void:
	_update_clock()


func _on_journey_arrival(body: Node2D) -> void:
	if body == player:
		journey.finish(time_manager.world_minutes)


func _journey_text() -> String:
	if journey.active:
		return tr("JOURNEY_PROGRESS") % [tr("JOURNEY_HOME" if journey.origin == &"home" else "JOURNEY_PARTIAL"), journey.elapsed_seconds(), time_manager.world_minutes - journey.start_minutes]
	if not journey.result.is_empty():
		var result: Dictionary = journey.result
		var arrival: int = result.arrival_minutes
		var margin: int = result.margin_minutes
		var timing := tr("JOURNEY_EARLY") % margin if margin >= 0 else tr("JOURNEY_LATE") % -margin
		return tr("JOURNEY_RESULT") % [tr("JOURNEY_HOME" if result.origin == &"home" else "JOURNEY_PARTIAL"), arrival % 1440 / 60, arrival % 60, result.seconds, result.minutes, timing]
	return ""


func _update_clock() -> void:
	var calendar := time_manager.get_calendar()
	var status := tr("CLOCK_RUNNING") if time_manager.running else tr("CLOCK_STOPPED")
	$HUD/Clock.text = tr("CLOCK_DATE") % [calendar.year, tr(SEASON_KEYS[calendar.season_index]), calendar.day, tr(WEEKDAY_KEYS[calendar.weekday]), calendar.hour, calendar.minute] + " · " + status
	$SeasonFilter/Tint.color = SEASON_FILTERS[calendar.season_index]


func _process(_delta: float) -> void:
	var location := tr("LAB_ROOM") if area_id == &"room" else tr(WorldLayouts.region(String(area_id)).title)
	var target := _interaction_target() if not _modal_open() else null
	var hint := tr(target.hint_key) if target != null else ""
	$HUD/Info.text = tr("LAB_TITLE") + " | " + location + " | " + tr("LAB_SCALE") % tile_size + "\n" + tr("LAB_CONTROLS") + "\n" + hint
	var journey_text := _journey_text()
	if not journey_text.is_empty():
		$HUD/Info.text += (" · " if not hint.is_empty() else "") + journey_text
