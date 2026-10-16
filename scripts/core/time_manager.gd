class_name TimeManager
extends Node

signal minute_changed(absolute_minutes: int)
signal day_changed(absolute_day: int)
signal sleep_limit_reached
signal clock_restored

const MINUTES_PER_DAY: int = 1440
const DAYS_PER_SEASON: int = 30
const SEASONS_PER_YEAR: int = 4
const DAYS_PER_YEAR: int = DAYS_PER_SEASON * SEASONS_PER_YEAR
const DAYS_PER_WEEK: int = 7
const SEASON_KEYS := ["SEASON_SPRING", "SEASON_SUMMER", "SEASON_AUTUMN", "SEASON_WINTER"]
const WEEKDAY_KEYS := ["WEEKDAY_MON", "WEEKDAY_TUE", "WEEKDAY_WED", "WEEKDAY_THU", "WEEKDAY_FRI", "WEEKDAY_SAT", "WEEKDAY_SUN"]
const VACATIONS := [
	{"season": 1, "first": 1, "last": 7, "label": "CALENDAR_SUMMER_BREAK"},
	{"season": 3, "first": 24, "last": 30, "label": "CALENDAR_WINTER_BREAK"},
]
const SECONDS_PER_GAME_MINUTE: float = 1.0
const SLEEP_LIMIT_MINUTE: int = 4 * 60

# [PROPOSAL] Year 1, spring 1, 06:00; weekday origin remains configurable.
@export_range(0, 6) var weekday_offset: int = 0
var world_minutes: int:
	get:
		return _world_minutes
var running: bool = false
var enforce_sleep_limit: bool = false
var sleep_pending: bool = false
var _world_minutes: int = 6 * 60
var _fractional_seconds: float = 0.0
var _advancing: bool = false


func _process(delta: float) -> void:
	if not running or sleep_pending or _advancing or delta <= 0.0:
		return
	_fractional_seconds += delta
	# Tolerance compensates floating-point sums such as sixty 1/60s frames.
	var elapsed_minutes := int(floor((_fractional_seconds + 1e-9) / SECONDS_PER_GAME_MINUTE))
	_fractional_seconds = maxf(0.0, _fractional_seconds - elapsed_minutes * SECONDS_PER_GAME_MINUTE)
	_advance_clock(elapsed_minutes)


func can_advance_minutes(duration_minutes: int) -> bool:
	if _advancing or sleep_pending or duration_minutes <= 0:
		return false
	var minute_of_day := _world_minutes % MINUTES_PER_DAY
	if minute_of_day == SLEEP_LIMIT_MINUTE:
		return false
	var until_sleep := (SLEEP_LIMIT_MINUTE - minute_of_day + MINUTES_PER_DAY) % MINUTES_PER_DAY
	# [PROPOSAL] Reject actions ending at or beyond 04:00 before starting.
	# Keep the provisional preflight rejection for ordinary activities.
	return duration_minutes < until_sleep


func advance_minutes(duration_minutes: int) -> bool:
	if not can_advance_minutes(duration_minutes):
		return false
	# Explicit actions are independent of natural ticking and its remainder.
	_advance_clock(duration_minutes)
	return true


func advance_sleep_minutes(duration_minutes: int) -> bool:
	if not sleep_pending or _advancing or duration_minutes <= 0:
		return false
	_advance_clock(duration_minutes, true)
	_fractional_seconds = 0.0
	sleep_pending = false
	return true


func restore_clock(minutes: int, fraction: float = 0.0, offset: int = 0) -> bool:
	if _advancing or minutes < 0 or not is_finite(fraction) or fraction < 0.0 or fraction >= 1.0 or offset < 0 or offset > 6:
		return false
	_world_minutes = minutes
	_fractional_seconds = fraction
	weekday_offset = offset
	sleep_pending = false
	clock_restored.emit()
	return true


func get_clock_state() -> Dictionary:
	return {"minutes": _world_minutes, "fraction": _fractional_seconds, "weekday_offset": weekday_offset}


func _advance_clock(duration_minutes: int, sleeping: bool = false) -> void:
	_advancing = true
	for _minute in range(duration_minutes):
		_world_minutes += 1
		minute_changed.emit(_world_minutes)
		if _world_minutes % MINUTES_PER_DAY == 0:
			day_changed.emit(_world_minutes / MINUTES_PER_DAY)
		if enforce_sleep_limit and not sleeping and _world_minutes % MINUTES_PER_DAY == SLEEP_LIMIT_MINUTE:
			sleep_pending = true
			running = false
			_fractional_seconds = 0.0
			sleep_limit_reached.emit()
			break
	_advancing = false


func get_calendar() -> Dictionary:
	return calendar_at(_world_minutes, weekday_offset)


static func calendar_at(minutes: int, offset: int = 0) -> Dictionary:
	var absolute_day: int = minutes / MINUTES_PER_DAY
	var minute_of_day: int = minutes % MINUTES_PER_DAY
	return {
		"year": absolute_day / DAYS_PER_YEAR + 1,
		"season_index": (absolute_day % DAYS_PER_YEAR) / DAYS_PER_SEASON,
		"day": absolute_day % DAYS_PER_SEASON + 1,
		"weekday": (offset + absolute_day) % DAYS_PER_WEEK,
		"week": (offset + absolute_day) / DAYS_PER_WEEK + 1,
		"hour": minute_of_day / 60,
		"minute": minute_of_day % 60,
	}


# Derived data only: queries never tick the clock or create attendance records.
static func day_info(absolute_day: int, offset: int = 0) -> Dictionary:
	var date := calendar_at(absolute_day * MINUTES_PER_DAY, offset)
	date.absolute_day = absolute_day
	date.vacation_key = ""
	for vacation in VACATIONS:
		if date.season_index == vacation.season and date.day >= vacation.first and date.day <= vacation.last:
			date.vacation_key = vacation.label
	date.is_weekend = date.weekday >= 5
	date.is_teaching_day = not date.is_weekend and date.vacation_key.is_empty()
	# A vacation that overlaps a weekend still belongs to the vacation interval.
	date.reason_key = date.vacation_key if not date.vacation_key.is_empty() else ("CALENDAR_WEEKEND" if date.is_weekend else "CALENDAR_TEACHING_DAY")
	return date


# Inclusive search, including weekends immediately after the vacation ends.
static func next_teaching_day(from_day: int, offset: int = 0) -> int:
	var day := from_day
	while not day_info(day, offset).is_teaching_day:
		day += 1
	return day
