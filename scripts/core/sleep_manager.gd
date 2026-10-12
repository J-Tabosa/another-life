class_name SleepManager
extends Node

signal requested
signal woke(duration_minutes: int)

var clock: TimeManager
var alarm_minutes: int = 6 * 60
var pending: bool = false
var forced: bool = false
var was_outside: bool = false


func request(is_forced: bool = false, outside: bool = false) -> bool:
	if pending:
		return false
	pending = true
	forced = is_forced
	was_outside = outside
	clock.sleep_pending = true
	clock.running = false
	requested.emit()
	return true


func wake_target() -> int:
	if forced and was_outside:
		return clock.world_minutes / 1440 * 1440 + 12 * 60
	var duration := (alarm_minutes - clock.world_minutes % 1440 + 1440) % 1440
	return clock.world_minutes + (1440 if duration == 0 else duration)


func complete() -> bool:
	if not pending:
		return false
	var duration := wake_target() - clock.world_minutes
	if not clock.advance_sleep_minutes(duration):
		return false
	pending = false
	forced = false
	was_outside = false
	woke.emit(duration)
	return true


func cancel() -> bool:
	if not pending or forced:
		return false
	pending = false
	clock.sleep_pending = false
	return true


func get_state() -> Dictionary:
	return {"alarm_minutes": alarm_minutes, "pending": pending, "forced": forced, "was_outside": was_outside}
