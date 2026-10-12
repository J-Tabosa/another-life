class_name SleepPanel
extends LabPanel

signal sleep_chosen(manual_save: bool)
signal cancel_requested
signal alarm_changed(minutes: int)

var manager: SleepManager
var title: Label
var target: Label
var hour: SpinBox
var minute: SpinBox
var cancel_button: Button
var save_button: Button
var skip_button: Button
var status: Label


func _ready() -> void:
	panel_size = Vector2(580, 400)
	super._ready()
	title = add_label("SLEEP_TITLE")
	title.add_theme_font_size_override("font_size", 22)
	target = add_label("")
	add_label("SLEEP_ALARM")
	var row := HBoxContainer.new()
	box.add_child(row)
	hour = SpinBox.new()
	hour.max_value = 23
	hour.custom_minimum_size.x = 100
	row.add_child(hour)
	minute = SpinBox.new()
	minute.max_value = 59
	minute.custom_minimum_size.x = 100
	row.add_child(minute)
	hour.value_changed.connect(_alarm_updated)
	minute.value_changed.connect(_alarm_updated)
	save_button = add_button("SLEEP_SAVE", func() -> void: sleep_chosen.emit(true))
	skip_button = add_button("SLEEP_SKIP", func() -> void: sleep_chosen.emit(false))
	cancel_button = add_button("SLEEP_CANCEL", close)
	status = add_label("")


func open() -> void:
	hour.set_value_no_signal(manager.alarm_minutes / 60)
	minute.set_value_no_signal(manager.alarm_minutes % 60)
	var outside := manager.forced and manager.was_outside
	hour.editable = not outside
	minute.editable = not outside
	title.text = tr("SLEEP_FORCED") if manager.forced else tr("SLEEP_TITLE")
	cancel_button.visible = not manager.forced
	status.text = ""
	_refresh_target()
	super.open()


func _alarm_updated(_value: float) -> void:
	alarm_changed.emit(int(hour.value) * 60 + int(minute.value))
	_refresh_target()


func _refresh_target() -> void:
	var wake := manager.wake_target()
	target.text = tr("SLEEP_WAKE") % [wake % 1440 / 60, wake % 60, (wake - manager.clock.world_minutes) / 60.0]


func close() -> void:
	if manager.forced:
		return
	cancel_requested.emit()


func dismiss() -> void:
	super.close()
