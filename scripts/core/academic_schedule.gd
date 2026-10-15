class_name AcademicSchedule
extends Node

signal changed
signal session_finished(day: int, session_id: String, status: String)

const CONFIG := "res://data/schedules/academic.json"
var clock: TimeManager
var sessions: Array = []
var started_at: int
var evaluated_until: int
var present: Dictionary = {}
var suspended: bool = false
var _acting: bool = false


func _ready() -> void:
	sessions = JSON.parse_string(FileAccess.get_file_as_string(CONFIG)).sessions
	started_at = clock.world_minutes
	evaluated_until = started_at
	clock.minute_changed.connect(_on_minute)
	clock.clock_restored.connect(reconcile)


static func teaching_day(day: int, offset: int) -> bool:
	var season: int = day % 120 / 30
	var date := day % 30 + 1
	return (day + offset) % 7 < 5 and not (season == 1 and date <= 7) and not (season == 3 and date >= 24)


func key(day: int, session: Dictionary) -> String:
	return str(day) + ":" + session.id


func status(day: int, session: Dictionary) -> String:
	if not teaching_day(day, clock.weekday_offset):
		return "no_class"
	if present.has(key(day, session)):
		return "present"
	var finish: int = day * 1440 + int(session.end)
	if finish <= started_at:
		return "untracked"
	if finish <= evaluated_until:
		return "absent"
	return "ongoing" if clock.world_minutes >= day * 1440 + int(session.start) else "future"


func current_session() -> Dictionary:
	var now := clock.world_minutes
	var day: int = now / 1440
	if teaching_day(day, clock.weekday_offset):
		for session in sessions:
			if now % 1440 >= session.start and now % 1440 < session.end:
				return session
	return {}


func wait_duration() -> int:
	var now := clock.world_minutes
	if teaching_day(now / 1440, clock.weekday_offset):
		for session in sessions:
			if now % 1440 < session.start:
				return int(session.start) - now % 1440
	return 0


func wait_for_class() -> bool:
	var duration := wait_duration()
	return not _acting and current_session().is_empty() and duration > 0 and clock.advance_minutes(duration)


func attend() -> bool:
	var session := current_session()
	if _acting or session.is_empty():
		return false
	var now := clock.world_minutes
	var id := key(now / 1440, session)
	var duration := int(session.end) - now % 1440
	if present.has(id) or not clock.can_advance_minutes(duration):
		return false
	_acting = true
	# Reserve presence before minute events reach the end of this class.
	# Arrival after the start is recorded; grading/penalties belong to P2-04+.
	present[id] = now
	var completed := clock.advance_minutes(duration)
	if not completed:
		present.erase(id)
	_acting = false
	changed.emit()
	return completed


func _on_minute(now: int) -> void:
	if suspended:
		return
	evaluated_until = maxi(evaluated_until, now)
	var day: int = now / 1440
	for session in sessions:
		if now % 1440 == int(session.end) and teaching_day(day, clock.weekday_offset):
			session_finished.emit(day, session.id, status(day, session))
	changed.emit()


func reconcile() -> void:
	if not suspended:
		# Sparse ledger: skipped classes are determined from this cursor, without
		# iterating through thousands of years when using the debug calendar.
		evaluated_until = maxi(evaluated_until, clock.world_minutes)
		changed.emit()


func get_state() -> Dictionary:
	return {"started_at": started_at, "evaluated_until": evaluated_until, "present": present.duplicate()}


func restore(state: Dictionary) -> void:
	started_at = int(state.started_at)
	evaluated_until = int(state.evaluated_until)
	present = state.present.duplicate()
	changed.emit()


static func valid_state(state: Dictionary, minutes: int, offset: int) -> bool:
	if not SaveManager._whole(state.get("started_at"), 0, minutes) or not SaveManager._whole(state.get("evaluated_until"), int(state.started_at), minutes) or not state.get("present") is Dictionary:
		return false
	for id in state.present:
		if not id is String:
			return false
		var parts: PackedStringArray = id.split(":")
		if parts.size() != 2 or not parts[0].is_valid_int() or parts[1] not in ["morning", "afternoon"]:
			return false
		var day := parts[0].to_int()
		var start := 540 if parts[1] == "morning" else 780
		var finish := 720 if parts[1] == "morning" else 1020
		var joined: Variant = state.present[id]
		if day < 0 or str(day) != parts[0] or not teaching_day(day, offset) or not SaveManager._whole(joined, maxi(day * 1440 + start, int(state.started_at)), day * 1440 + finish - 1) or day * 1440 + finish > int(state.evaluated_until):
			return false
	return true
