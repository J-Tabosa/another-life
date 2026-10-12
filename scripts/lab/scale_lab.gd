extends Node2D

const AREAS := {
	&"room": preload("res://scenes/world/room.tscn"),
	&"street": preload("res://scenes/world/street.tscn"),
}
const SEASON_KEYS := ["SEASON_SPRING", "SEASON_SUMMER", "SEASON_AUTUMN", "SEASON_WINTER"]
const WEEKDAY_KEYS := ["WEEKDAY_MON", "WEEKDAY_TUE", "WEEKDAY_WED", "WEEKDAY_THU", "WEEKDAY_FRI", "WEEKDAY_SAT", "WEEKDAY_SUN"]
const TEST_ACTIVITY: TimedAction = preload("res://data/activities/lab_activity.tres")
var area: Node2D
var area_id: StringName = &"room"
var tile_size: int = 32
var transitioning: bool = false
@onready var player: CharacterBody2D = $Player
@onready var time_manager: TimeManager = $TimeManager


func _ready() -> void:
	_setup_inputs()
	time_manager.minute_changed.connect(_on_minute_changed)
	$HUD/ActivityButton.text = tr(TEST_ACTIVITY.label_key) % TEST_ACTIVITY.duration_minutes
	$HUD/ActivityButton.pressed.connect(_run_test_activity)
	change_area(&"room", &"start")


func _setup_inputs() -> void:
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E], "compare_scale": [KEY_T], "show_frame": [KEY_F],
		"test_activity": [KEY_R],
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
	if transitioning:
		return
	if event.is_action_pressed("interact") and not event.is_echo():
		area.get_node("Door").interact(player)
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


func _run_test_activity() -> void:
	if time_manager.advance_minutes(TEST_ACTIVITY.duration_minutes):
		$HUD/ActivityResult.text = tr("ACTIVITY_COMPLETED") % TEST_ACTIVITY.duration_minutes
	else:
		$HUD/ActivityResult.text = tr("ACTIVITY_SLEEP_LIMIT")


func request_transition(target: StringName, spawn: StringName) -> void:
	if transitioning:
		return
	transitioning = true
	change_area.call_deferred(target, spawn)


func change_area(target: StringName, spawn: StringName) -> void:
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
	if is_instance_valid(area):
		$World.remove_child(area)
		area.queue_free()
	area = next_area
	area_id = target
	area.tile_size = tile_size
	$World.add_child(area)
	# Natural time is enabled only in the outdoor laboratory.
	time_manager.running = area.exterior
	_update_clock()
	area.get_node("Door").transition_requested.connect(request_transition)
	player.position = marker.position
	player.velocity = Vector2.ZERO
	player.facing = &"down" if target == &"street" else &"up"
	player.update_animation(Vector2.ZERO)
	player.get_node("Camera2D").reset_smoothing()
	transitioning = false


func _on_minute_changed(_absolute_minutes: int) -> void:
	_update_clock()


func _update_clock() -> void:
	var calendar := time_manager.get_calendar()
	var status := tr("CLOCK_RUNNING") if time_manager.running else tr("CLOCK_STOPPED")
	$HUD/Clock.text = tr("CLOCK_DATE") % [calendar.year, tr(SEASON_KEYS[calendar.season_index]), calendar.day, tr(WEEKDAY_KEYS[calendar.weekday]), calendar.hour, calendar.minute] + " · " + status


func _process(_delta: float) -> void:
	var location := tr("LAB_STREET") if area_id == &"street" else tr("LAB_ROOM")
	var hint := tr("LAB_INTERACT") if is_instance_valid(area) and area.get_node("Door").can_interact(player) else ""
	$HUD/Info.text = tr("LAB_TITLE") + " | " + location + " | " + tr("LAB_SCALE") % tile_size + "\n" + tr("LAB_CONTROLS") + "\n" + hint
