class_name TimedAction
extends Resource

@export var label_key: StringName
@export_range(1, 1440, 1, "or_greater") var duration_minutes: int = 60
