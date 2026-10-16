class_name CalendarDebugPanel
extends LabPanel

signal jump_requested(minutes: int)
signal load_requested(kind: String)
signal autosave_changed(enabled: bool)
signal name_changed(value: String)

const SEASONS := TimeManager.SEASON_KEYS
const WEEKDAYS := TimeManager.WEEKDAY_KEYS
var clock: TimeManager
var year: SpinBox
var season: OptionButton
var hour: SpinBox
var minute: SpinBox
var grid: GridContainer
var autosave: CheckBox
var name_edit: LineEdit
var day_buttons: Array[Button] = []
var summary: Label


func _ready() -> void:
	panel_size = Vector2(680, 520)
	super._ready()
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.09, 0.10, 0.12, 0.98)
	for child in get_children():
		if child is PanelContainer:
			child.add_theme_stylebox_override("panel", background)
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
	hour.suffix = "h"
	hour.custom_minimum_size.x = 100
	row.add_child(hour)
	minute = SpinBox.new()
	minute.max_value = 59
	minute.suffix = "min"
	minute.custom_minimum_size.x = 100
	row.add_child(minute)
	for spinner in [year, hour, minute]:
		spinner.value_changed.connect(func(_value: float) -> void: _rebuild())
	season.item_selected.connect(func(_index: int) -> void: _rebuild())
	summary = add_label("")
	add_label("CALENDAR_LEGEND")
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
	(box.get_parent().get_parent() as ScrollContainer).scroll_vertical = 0
	super.open()


func _rebuild() -> void:
	var today := TimeManager.day_info(clock.world_minutes / TimeManager.MINUTES_PER_DAY, clock.weekday_offset)
	summary.text = tr("CALENDAR_TODAY") % [date_text(today), today.week, tr(today.reason_key)]
	if not today.is_teaching_day:
		var next := TimeManager.day_info(TimeManager.next_teaching_day(today.absolute_day + 1, clock.weekday_offset), clock.weekday_offset)
		summary.text += "\n" + tr("CALENDAR_RETURN") % date_text(next)
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	day_buttons.clear()
	for key in WEEKDAYS:
		var label := Label.new()
		label.text = tr(key).left(3)
		label.custom_minimum_size.x = 84
		grid.add_child(label)
	var first_day := (int(year.value) - 1) * TimeManager.DAYS_PER_YEAR + season.selected * TimeManager.DAYS_PER_SEASON
	for blank in range((first_day + clock.weekday_offset) % TimeManager.DAYS_PER_WEEK):
		grid.add_child(Control.new())
	for day in range(TimeManager.DAYS_PER_SEASON):
		var date := TimeManager.day_info(first_day + day, clock.weekday_offset)
		var target := (first_day + day) * TimeManager.MINUTES_PER_DAY + int(hour.value) * 60 + int(minute.value)
		var button := Button.new()
		var marker := "CALENDAR_MARK_CLASS" if date.is_teaching_day else ("CALENDAR_MARK_VACATION" if not date.vacation_key.is_empty() else "CALENDAR_MARK_WEEKEND")
		button.text = "%d · %s" % [day + 1, tr(marker)]
		button.tooltip_text = date_text(date) + "\n" + tr(date.reason_key)
		if date.is_weekend and not date.vacation_key.is_empty():
			button.tooltip_text += " · " + tr("CALENDAR_WEEKEND")
		button.custom_minimum_size = Vector2(84, 30)
		button.focus_mode = Control.FOCUS_NONE
		button.disabled = target < clock.world_minutes
		if (first_day + day) == clock.world_minutes / 1440:
			button.modulate = Color("99d9ec")
		button.pressed.connect(func() -> void: jump_requested.emit(target))
		grid.add_child(button)
		day_buttons.append(button)


func date_text(date: Dictionary) -> String:
	return tr("CALENDAR_DATE") % [date.day, tr(SEASONS[date.season_index]), date.year, tr(WEEKDAYS[date.weekday])]
