class_name ClassQuestionPanel
extends LabPanel

signal answer_requested(option_id: String)
signal dismissed

var question: Dictionary = {}
var options: Array[Button] = []
var prompt: Label
var reaction: Label
var hint: Label
var close_button: Button
var answered: bool = false


func _ready() -> void:
	panel_size = Vector2(720, 480)
	super._ready()
	# Keep the question readable over world/HUD labels at smaller resolutions.
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.09, 0.10, 0.12, 0.98)
	for child in get_children():
		if child is PanelContainer:
			child.add_theme_stylebox_override("panel", background)
	add_label("PROFESSOR_SPEAKER")
	prompt = add_label("")
	prompt.add_theme_font_size_override("font_size", 20)
	for index in range(4):
		var button := add_button("", func() -> void: _choose(index))
		options.append(button)
	reaction = add_label("")
	hint = add_label("QUESTION_HINT")
	close_button = add_button("QUESTION_CANCEL", close)


func start(data: Dictionary) -> void:
	question = data.duplicate(true)
	answered = false
	prompt.text = tr(question.prompt_key)
	for index in range(4):
		options[index].text = "%d · %s" % [index + 1, tr(question.options[index].label_key)]
		options[index].disabled = false
	reaction.hide()
	hint.show()
	close_button.text = tr("QUESTION_CANCEL")
	open()


func show_result(record: Dictionary) -> void:
	answered = true
	for index in range(4):
		options[index].disabled = true
		if question.options[index].id == record.option_id:
			options[index].text = tr("QUESTION_SELECTED") % options[index].text
	reaction.text = tr(question.correct_reaction_key if record.correct else question.incorrect_reaction_key) + "\n" + tr(question.explanation_key) + "\n" + tr("QUESTION_RECORDED")
	reaction.show()
	hint.hide()
	close_button.text = tr("QUESTION_CONTINUE")


func _choose(index: int) -> void:
	if visible and not answered:
		answer_requested.emit(question.options[index].id)


func close() -> void:
	if visible:
		super.close()
		dismissed.emit()


func dismiss() -> void:
	# Area changes / loads must not run the normal return-to-agenda callback.
	super.close()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_4 and not answered:
			_choose(event.keycode - KEY_1)
		elif event.keycode == KEY_ENTER and answered:
			close()
	super._unhandled_input(event)
