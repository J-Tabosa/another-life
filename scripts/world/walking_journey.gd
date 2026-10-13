class_name WalkingJourney
extends RefCounted

# Diagnostic measurement only; no attendance, schedules or save state.
var active: bool = false
var origin: StringName
var start_minutes: int = 0
var start_usec: int = 0
var result: Dictionary = {}


func begin(minutes: int, from: StringName) -> void:
	active = true
	origin = from
	start_minutes = minutes
	start_usec = Time.get_ticks_usec()
	result = {}


func elapsed_seconds() -> float:
	return (Time.get_ticks_usec() - start_usec) / 1_000_000.0


func finish(minutes: int) -> void:
	if not active:
		return
	result = {"origin": origin, "seconds": elapsed_seconds(), "minutes": minutes - start_minutes, "arrival_minutes": minutes, "margin_minutes": start_minutes / 1440 * 1440 + 9 * 60 - minutes}
	active = false


func reset() -> void:
	active = false
	result = {}
