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
var professor_intro_seen: bool = false
var question_answers: Dictionary = {}
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


func needs_question() -> bool:
	var session := current_session()
	return not session.is_empty() and session.id == "afternoon" and question_answers.is_empty()


func attend(option_id: String = "") -> bool:
	var session := current_session()
	if _acting or session.is_empty():
		return false
	var now := clock.world_minutes
	var id := key(now / 1440, session)
	var duration := int(session.end) - now % 1440
	if present.has(id) or not clock.can_advance_minutes(duration):
		return false
	var question := ClassQuestionBank.first() if needs_question() else {}
	if needs_question():
		if question.is_empty() or not ClassQuestionBank.has_option(question, option_id):
			return false
	elif not option_id.is_empty():
		return false
	_acting = true
	# Reserve presence before minute events reach the end of this class.
	# Arrival after the start is recorded; grading and penalties remain undecided.
	present[id] = now
	if not question.is_empty():
		question_answers[question.id] = {"option_id": option_id, "correct": option_id == question.correct_option_id, "answered_at": now, "session_key": id}
	var completed := clock.advance_minutes(duration)
	if not completed:
		present.erase(id)
		if not question.is_empty():
			question_answers.erase(question.id)
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
	return {"started_at": started_at, "evaluated_until": evaluated_until, "present": present.duplicate(), "professor_intro_seen": professor_intro_seen, "question_answers": question_answers.duplicate(true)}


func restore(state: Dictionary) -> void:
	started_at = int(state.started_at)
	evaluated_until = int(state.evaluated_until)
	present = state.present.duplicate()
	professor_intro_seen = state.get("professor_intro_seen", false)
	question_answers = state.get("question_answers", {}).duplicate(true)
	changed.emit()


static func valid_state(state: Dictionary, minutes: int, offset: int) -> bool:
	# Optional in schema 3: saves from P2-03 predate this introduction.
	if not state.get("professor_intro_seen", false) is bool:
		return false
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
	# Optional in schema 3: P2-03/04/05 saves have no question history yet.
	var answers: Variant = state.get("question_answers", {})
	if not answers is Dictionary or answers.size() > 1:
		return false
	var question := ClassQuestionBank.first()
	for id in answers:
		if question.is_empty() or id != question.id or not answers[id] is Dictionary:
			return false
		var answer: Dictionary = answers[id]
		if not answer.get("option_id") is String or not ClassQuestionBank.has_option(question, answer.option_id) or not answer.get("correct") is bool:
			return false
		if answer.correct != (answer.option_id == question.correct_option_id) or not SaveManager._whole(answer.get("answered_at"), int(state.started_at), minutes):
			return false
		var answered_at := int(answer.answered_at)
		var session_key := str(answered_at / 1440) + ":afternoon"
		if not answer.get("session_key") is String or answer.session_key != session_key or not state.present.has(session_key) or state.present[session_key] != answered_at:
			return false
	return true
