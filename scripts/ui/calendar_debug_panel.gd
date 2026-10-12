class_name CalendarDebugPanel
extends LabPanel

signal jump_requested(minutes: int)
signal load_requested(kind: String)
signal autosave_changed(enabled: bool)
signal name_changed(value: String)

const SEASONS := ["SEASON_SPRING", "SEASON_SUMMER", "SEASON_AUTUMN", "SEASON_WINTER"]
const WEEKDAYS := ["WEEKDAY_MON", "WEEKDAY_TUE", "WEEKDAY_WED", "WEEKDAY_THU", "WEEKDAY_FRI", "WEEKDAY_SAT", "WEEKDAY_SUN"]
var clock: TimeManager
var year: SpinBox
var season: OptionButton
var hour: SpinBox
var minute: SpinBox
var grid: GridContainer
var autosave: CheckBox
var name_edit: LineEdit
var day_buttons: Array[Button] = []


func _ready() -> void:
	panel_size = Vector2(680, 520)
	super._ready()
	add_label("DEBUG_CALENDAR").add_theme_font_size_override("font_size", 22)
	add_label("DEBUG_JUMP_HINT")
	var row := HBoxContainer.new()
	box.add_child(row)
	year = SpinBox.new()
	year.min_value = 1
	year.max_value = 9999
	year.prefix = tr("DEBUG_YEAR") + " "
	year.custom_minimum_size.x = 150
	row.add_child(year)
	season = OptionButton.new()
	for key in SEASONS:
		season.add_item(tr(key))
	row.add_child(season)
	hour = SpinBox.new()
	hour.max_value = 23
	hour.custom_minimum_size.x = 100
	row.add_child(hour)
	minute = SpinBox.new()
	minute.max_value = 59
	minute.custom_minimum_size.x = 100
	row.add_child(minute)
	for spinner in [year, hour, minute]:
		spinner.value_changed.connect(func(_value: float) -> void: _rebuild())
	season.item_selected.connect(func(_index: int) -> void: _rebuild())
	grid = GridContainer.new()
	grid.columns = 7
	box.add_child(grid)
	name_edit = LineEdit.new()
	name_edit.placeholder_text = tr("DEBUG_NAME")
	name_edit.max_length = 80
	name_edit.text_changed.connect(func(value: String) -> void: name_changed.emit(value))
	box.add_child(name_edit)
	autosave = CheckBox.new()
	autosave.text = tr("DEBUG_AUTOSAVE")
	autosave.toggled.connect(func(enabled: bool) -> void: autosave_changed.emit(enabled))
	box.add_child(autosave)
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	for kind in ["manual", "auto"]:
		var button := Button.new()
		button.text = tr("LOAD_MANUAL" if kind == "manual" else "LOAD_AUTO")
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func() -> void: load_requested.emit(kind))
		buttons.add_child(button)
	add_button("DEBUG_CLOSE", close)


func open() -> void:
	var date := clock.get_calendar()
	year.set_value_no_signal(date.year)
	season.select(date.season_index)
	hour.set_value_no_signal(date.hour)
	minute.set_value_no_signal(date.minute)
	_rebuild()
	super.open()


func _rebuild() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	day_buttons.clear()
	for key in WEEKDAYS:
		var label := Label.new()
		label.text = tr(key).left(3)
		label.custom_minimum_size.x = 84
		grid.add_child(label)
	var first_day := (int(year.value) - 1) * 120 + season.selected * 30
	for blank in range((first_day + clock.weekday_offset) % 7):
		grid.add_child(Control.new())
	for day in range(30):
		var target := (first_day + day) * 1440 + int(hour.value) * 60 + int(minute.value)
		var button := Button.new()
		button.text = str(day + 1)
		button.custom_minimum_size = Vector2(84, 30)
		button.focus_mode = Control.FOCUS_NONE
		button.disabled = target < clock.world_minutes
		if (first_day + day) == clock.world_minutes / 1440:
			button.modulate = Color("99d9ec")
		button.pressed.connect(func() -> void: jump_requested.emit(target))
		grid.add_child(button)
		day_buttons.append(button)
