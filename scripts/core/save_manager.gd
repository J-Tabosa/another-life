class_name SaveManager
extends Node

const SCHEMA_VERSION := 3
const LEGACY_MAP_SIZES := {"room": Vector2(960, 640), "street": Vector2(960, 640), "route": Vector2(12800, 1600), "campus": Vector2(2400, 1600)}
const V2_MAP_SIZES := {"room": Vector2(960, 640), "street": Vector2(3200, 2400), "route": Vector2(6000, 3600), "campus": Vector2(3200, 2600), "university": Vector2(1600, 1100), "classroom": Vector2(1400, 1000)}
var storage_root: String = "user://saves/slot_01"
var settings_path: String = "user://settings.json"
var autosave_enabled: bool = false


func save_slot(kind: String, state: Dictionary) -> bool:
	if kind not in ["manual", "auto"] or not validate_state(state):
		return false
	if kind == "auto" and not autosave_enabled:
		return false
	return _write_json(storage_root.path_join(kind + ".json"), state)


func load_slot(kind: String) -> Dictionary:
	if kind not in ["manual", "auto"]:
		return {}
	var state := _read_json(storage_root.path_join(kind + ".json"))
	if (state.get("schema_version") == 1 or state.get("schema_version") == 2) and validate_state(state, true):
		# Old outside geometry no longer exists. Keep all gameplay values and
		# place the player at this region's safe entrance, without writing back.
		state.schema_version = SCHEMA_VERSION
		if state.player.area in ["street", "route", "campus"]:
			var safe: Vector2 = WorldLayouts.point(WorldLayouts.region(state.player.area).spawns.door)
			state.player.x = safe.x
			state.player.y = safe.y
		state.academics = {"started_at": int(state.world.minutes), "evaluated_until": int(state.world.minutes), "present": {}}
		state.migrated_from_legacy = true
	return state if validate_state(state) else {}


func set_autosave(enabled: bool) -> bool:
	if not _write_json(settings_path, {"autosave_enabled": enabled}):
		return false
	autosave_enabled = enabled
	return true


func load_settings() -> void:
	var state := _read_json(settings_path)
	if state.get("autosave_enabled") is bool:
		autosave_enabled = state.autosave_enabled


static func _whole(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= minimum and value <= maximum


static func validate_state(state: Dictionary, legacy: bool = false) -> bool:
	if (legacy and state.get("schema_version") != 1 and state.get("schema_version") != 2) or (not legacy and state.get("schema_version") != SCHEMA_VERSION):
		return false
	for key in ["world", "player", "sleep", "lab"]:
		if not state.get(key) is Dictionary:
			return false
	var world: Dictionary = state.world
	var player: Dictionary = state.player
	var sleep: Dictionary = state.sleep
	if not _whole(world.get("minutes"), 0, 1440 * 120 * 9999) or not _whole(world.get("weekday_offset"), 0, 6):
		return false
	var fraction: Variant = world.get("fraction")
	if not (fraction is float or fraction is int) or not is_finite(float(fraction)) or fraction < 0 or fraction >= 1:
		return false
	if not player.get("name") is String or player.name.length() > 80 or not player.get("area") is String:
		return false
	var bounds: Vector2 = WorldLayouts.bounds(player.area)
	if legacy:
		bounds = (LEGACY_MAP_SIZES if state.schema_version == 1 else V2_MAP_SIZES).get(player.area, Vector2.ZERO)
	if bounds == Vector2.ZERO:
		return false
	for axis in ["x", "y"]:
		var coordinate: Variant = player.get(axis)
		if not (coordinate is float or coordinate is int) or not is_finite(float(coordinate)):
			return false
	if player.x < 32 or player.y < 32 or player.x > bounds.x - 32 or player.y > bounds.y - 32:
		return false
	if not _whole(sleep.get("alarm_minutes"), 0, 1439) or not _whole(state.lab.get("tile_size"), 32, 64):
		return false
	if int(state.lab.tile_size) not in [32, 64]:
		return false
	for key in ["pending", "forced", "was_outside"]:
		if not sleep.get(key) is bool:
			return false
	if (sleep.forced or sleep.was_outside) and not sleep.pending:
		return false
	if sleep.was_outside and not sleep.forced:
		return false
	if sleep.pending and player.area != "room":
		return false
	if sleep.forced and int(world.minutes) % 1440 != 240:
		return false
	if not legacy and (not state.get("academics") is Dictionary or not AcademicSchedule.valid_state(state.academics, int(world.minutes), int(world.weekday_offset))):
		return false
	return true


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 1024 * 1024:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		return {}
	return json.data


static func _write_json(path: String, state: Dictionary) -> bool:
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK:
		return false
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(state, "\t", true, true))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return false
	return DirAccess.rename_absolute(temporary, path) == OK
