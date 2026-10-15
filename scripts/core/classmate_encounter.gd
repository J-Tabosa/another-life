class_name ClassmateEncounter
extends Node

signal changed
signal remembered(event_id: StringName, minutes: int)

const CONFIG := "res://data/npcs/classmate.json"
static var _profile: Dictionary = {}
var clock: TimeManager
var met_at: int = -1
var lunch_at: int = -1
var suspended: bool = false
var _location: Dictionary = {}


static func profile() -> Dictionary:
	if _profile.is_empty():
		_profile = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return _profile


static func location_at(minutes: int, offset: int) -> Dictionary:
	if not AcademicSchedule.teaching_day(minutes / 1440, offset):
		return {}
	for location in profile().locations:
		if minutes % 1440 >= location.from and minutes % 1440 < location.until:
			return location
	return {}


func _ready() -> void:
	clock.minute_changed.connect(func(_minutes: int) -> void: refresh())
	clock.clock_restored.connect(refresh)
	refresh()


func refresh() -> void:
	if suspended:
		return
	var next := location_at(clock.world_minutes, clock.weekday_offset)
	if next != _location:
		_location = next
		changed.emit()


func location() -> Dictionary:
	return location_at(clock.world_minutes, clock.weekday_offset)


func conversation() -> StringName:
	if location().is_empty():
		return &""
	if met_at < 0:
		return &"intro"
	if lunch_at < 0:
		return &"lunch" if location().area == "university" else &"waiting"
	return &"repeat"


func dialogue() -> DialogueData:
	var id := conversation()
	return load(profile().dialogues[String(id)]) if not id.is_empty() else null


func remember(id: StringName) -> bool:
	if id != conversation() or id not in [&"intro", &"lunch"]:
		return false
	var now := clock.world_minutes
	if id == &"intro":
		met_at = now
	else:
		lunch_at = now
	changed.emit()
	remembered.emit(id, now)
	return true


func get_state() -> Dictionary:
	return {"met_at": met_at, "lunch_at": lunch_at}


func restore(state: Dictionary) -> void:
	met_at = int(state.get("met_at", -1))
	lunch_at = int(state.get("lunch_at", -1))
	_location = location()
	changed.emit()


static func valid_state(state: Dictionary, minutes: int, offset: int) -> bool:
	for key in ["met_at", "lunch_at"]:
		if not SaveManager._whole(state.get(key), -1, minutes):
			return false
	if state.met_at == -1:
		return state.lunch_at == -1
	if location_at(int(state.met_at), offset).is_empty():
		return false
	if state.lunch_at != -1:
		var where := location_at(int(state.lunch_at), offset)
		if state.lunch_at < state.met_at or where.is_empty() or where.area != "university":
			return false
	return true
