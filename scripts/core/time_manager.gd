class_name TimeManager
extends Node

signal minute_changed(absolute_minutes: int)
signal day_changed(absolute_day: int)

const MINUTES_PER_DAY: int = 1440
const DAYS_PER_SEASON: int = 30
const SEASONS_PER_YEAR: int = 4
const DAYS_PER_YEAR: int = DAYS_PER_SEASON * SEASONS_PER_YEAR
const SECONDS_PER_GAME_MINUTE: float = 1.0

# [PROPOSAL] Year 1, spring 1, 06:00; weekday origin remains configurable.
@export_range(0, 6) var weekday_offset: int = 0
var world_minutes: int:
	get:
		return _world_minutes
var running: bool = false
var _world_minutes: int = 6 * 60
var _fractional_seconds: float = 0.0


func _process(delta: float) -> void:
	if not running or delta <= 0.0:
		return
	_fractional_seconds += delta
	# Tolerance compensates floating-point sums such as sixty 1/60s frames.
	var elapsed_minutes := int(floor((_fractional_seconds + 1e-9) / SECONDS_PER_GAME_MINUTE))
	_fractional_seconds = maxf(0.0, _fractional_seconds - elapsed_minutes * SECONDS_PER_GAME_MINUTE)
	for minute in range(elapsed_minutes):
		_world_minutes += 1
		minute_changed.emit(_world_minutes)
		if _world_minutes % MINUTES_PER_DAY == 0:
			day_changed.emit(_world_minutes / MINUTES_PER_DAY)


func get_calendar() -> Dictionary:
	var absolute_day: int = _world_minutes / MINUTES_PER_DAY
	var minute_of_day: int = _world_minutes % MINUTES_PER_DAY
	return {
		"year": absolute_day / DAYS_PER_YEAR + 1,
		"season_index": (absolute_day % DAYS_PER_YEAR) / DAYS_PER_SEASON,
		"day": absolute_day % DAYS_PER_SEASON + 1,
		"weekday": (weekday_offset + absolute_day) % 7,
		"week": (weekday_offset + absolute_day) / 7 + 1,
		"hour": minute_of_day / 60,
		"minute": minute_of_day % 60,
	}
