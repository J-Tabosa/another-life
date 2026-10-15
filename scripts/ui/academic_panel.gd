class_name AcademicPanel
extends LabPanel

signal attendance_requested
signal wait_requested
var schedule: AcademicSchedule
var in_classroom: bool = false
var details: Label
var history: Label
var attend_button: Button
var wait_button: Button


func _ready() -> void:
	panel_size = Vector2(660, 480)
	super._ready()
	add_label("ACADEMIC_TITLE")
	add_label("ACADEMIC_HOURS")
	details = add_label("")
	attend_button = add_button("ACADEMIC_ATTEND", func() -> void: attendance_requested.emit())
	wait_button = add_button("ACADEMIC_WAIT", func() -> void: wait_requested.emit())
	history = add_label("")
	add_button("DEBUG_CLOSE", close)
	schedule.changed.connect(refresh)


func open() -> void:
	refresh()
	super.open()


func refresh() -> void:
	if not is_instance_valid(details):
		return
	var day: int = schedule.clock.world_minutes / 1440
	details.text = tr("ACADEMIC_TODAY")
	for session in schedule.sessions:
		details.text += "\n" + tr(session.label) + ": " + tr("ACADEMIC_" + schedule.status(day, session).to_upper())
	if not in_classroom:
		details.text += "\n" + tr("ACADEMIC_GO_CLASSROOM")
	var current := schedule.current_session()
	attend_button.disabled = not in_classroom or current.is_empty() or (not current.is_empty() and schedule.status(day, current) == "present")
	wait_button.disabled = not in_classroom or schedule.wait_duration() <= 0 or not current.is_empty()
	history.text = tr("ACADEMIC_HISTORY")
	for previous in range(maxi(0, day - 6), day + 1):
		var date := "%d / %s · %d" % [previous % 30 + 1, tr(["SEASON_SPRING", "SEASON_SUMMER", "SEASON_AUTUMN", "SEASON_WINTER"][previous % 120 / 30]), previous / 120 + 1]
		for session in schedule.sessions:
			history.text += "\n" + date + " · " + tr(session.label) + ": " + tr("ACADEMIC_" + schedule.status(previous, session).to_upper())
	if not schedule.question_answers.is_empty():
		var question := ClassQuestionBank.first()
		var record: Dictionary = schedule.question_answers[question.id]
		var selected_key: String = ""
		for option in question.options:
			if option.id == record.option_id:
				selected_key = option.label_key
		var answered_day: int = int(record.answered_at) / 1440
		var date := "%d / %s · %d" % [answered_day % 30 + 1, tr(["SEASON_SPRING", "SEASON_SUMMER", "SEASON_AUTUMN", "SEASON_WINTER"][answered_day % 120 / 30]), answered_day / 120 + 1]
		history.text += "\n\n" + tr("QUESTION_HISTORY") + "\n" + date + " · " + tr("ACADEMIC_AFTERNOON") + "\n" + tr(question.prompt_key) + "\n" + tr("QUESTION_HISTORY_ANSWER") % [tr(selected_key), tr("QUESTION_RESULT_CORRECT" if record.correct else "QUESTION_RESULT_INCORRECT")]
