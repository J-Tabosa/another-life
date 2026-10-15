class_name HomeIntroductions
extends Node

signal changed
signal remembered(actor_id: StringName, event_id: StringName, minutes: int)

const CONFIG := "res://data/events/home_introductions.json"
static var _data: Dictionary = {}
var clock: TimeManager
var greetings: Dictionary = {}
var discovered: Dictionary = {}
var suspended: bool = false
var _available: Array[String] = []


static func data() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return _data


static func available(actor_id: String, minutes: int) -> bool:
	if not data().actors.has(actor_id) or minutes % 1440 == 240:
		return false
	for window in data().actors[actor_id].home_windows:
		if minutes % 1440 >= window[0] and minutes % 1440 < window[1]:
			return true
	return false


func _ready() -> void:
	clock.minute_changed.connect(func(_minutes: int) -> void: refresh())
	clock.clock_restored.connect(refresh)
	refresh()


func refresh() -> void:
	if suspended:
		return
	var next: Array[String] = []
	for actor_id in data().actors:
		if available(actor_id, clock.world_minutes):
			next.append(actor_id)
	if next != _available:
		_available = next
		changed.emit()


func conversation(actor_id: StringName) -> StringName:
	if not available(String(actor_id), clock.world_minutes):
		return &""
	if actor_id != &"music" and clock.world_minutes % 1440 < 1020:
		return &"greeting" if not greetings.has(String(actor_id)) else &"waiting"
	return &"intro" if not discovered.has(data().actors[String(actor_id)].hobby) else &"repeat"


func dialogue(actor_id: StringName) -> DialogueData:
	var event_id := conversation(actor_id)
	if event_id.is_empty():
		return null
	return load("res://data/dialogues/" + data().actors[String(actor_id)].dialogues[String(event_id)] + ".tres")


func remember(actor_id: StringName, event_id: StringName) -> bool:
	if event_id.is_empty() or event_id != conversation(actor_id) or event_id not in [&"greeting", &"intro"]:
		return false
	var now := clock.world_minutes
	if event_id == &"greeting":
		greetings[String(actor_id)] = now
	else:
		discovered[data().actors[String(actor_id)].hobby] = now
	changed.emit()
	remembered.emit(actor_id, event_id, now)
	return true


func get_state() -> Dictionary:
	return {"greetings": greetings.duplicate(), "discovered": discovered.duplicate()}


func restore(state: Dictionary) -> void:
	# JSON numbers arrive as floats; event timestamps are whole game minutes.
	greetings.clear()
	discovered.clear()
	for actor_id in state.get("greetings", {}):
		greetings[actor_id] = int(state.greetings[actor_id])
	for hobby in state.get("discovered", {}):
		discovered[hobby] = int(state.discovered[hobby])
	_available.clear()
	refresh()
	changed.emit()


static func valid_state(state: Dictionary, minutes: int) -> bool:
	if not state.get("greetings") is Dictionary or not state.get("discovered") is Dictionary:
		return false
	for actor_id in state.greetings:
		if actor_id not in ["father", "sister"] or not SaveManager._whole(state.greetings[actor_id], 0, minutes):
			return false
		var at := int(state.greetings[actor_id])
		if not available(actor_id, at) or at % 1440 >= 1020:
			return false
	for hobby in state.discovered:
		if not data().hobbies.has(hobby) or not SaveManager._whole(state.discovered[hobby], 0, minutes):
			return false
		var actor_id: String = data().hobbies[hobby].actor
		var at := int(state.discovered[hobby])
		if not available(actor_id, at) or (actor_id != "music" and at % 1440 < 1020):
			return false
	return true
