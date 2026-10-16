class_name DialoguePanel
extends Control

signal opened
signal closed
signal finished(was_completed: bool)

var active: bool = false
var text_context: Dictionary = {"player_name": "", "player_salutation": ""}
var _line_keys: PackedStringArray
var _line_index: int = 0


func _ready() -> void:
	$Panel/Next.text = tr("DIALOGUE_NEXT")
	$Panel/Close.text = tr("DIALOGUE_CLOSE")
	$Panel/Next.pressed.connect(advance)
	$Panel/Close.pressed.connect(close)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var viewport_size := get_viewport_rect().size
	$Panel.position = Vector2(20, viewport_size.y - 208)
	$Panel.size = Vector2(viewport_size.x - 40, 168)
	$Panel/Speaker.size.x = viewport_size.x - 80
	$Panel/Line.size.x = viewport_size.x - 80
	var half := (viewport_size.x - 100) / 2
	$Panel/Next.size.x = half
	$Panel/Close.position.x = half + 40
	$Panel/Close.size.x = half


func start(data: DialogueData) -> bool:
	if active or data == null or data.speaker_key.is_empty() or data.line_keys.is_empty():
		return false
	for key in data.line_keys:
		if key.is_empty():
			return false
	_line_keys = data.line_keys.duplicate()
	_line_index = 0
	$Panel/Speaker.text = tr(data.speaker_key)
	active = true
	show()
	_show_line()
	opened.emit()
	return true


func advance() -> void:
	if not active:
		return
	_line_index += 1
	if _line_index == _line_keys.size():
		_finish(true)
	else:
		_show_line()


func close() -> void:
	_finish(false)


func _finish(was_completed: bool) -> void:
	if not active:
		return
	active = false
	hide()
	_line_keys.clear()
	$Panel/Speaker.text = ""
	$Panel/Line.text = ""
	finished.emit(was_completed)
	closed.emit()


func _show_line() -> void:
	$Panel/Line.text = tr(_line_keys[_line_index]).format(text_context)


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if not event.is_echo():
		if event.is_action_pressed("ui_cancel"):
			close()
		elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
			advance()
	get_viewport().set_input_as_handled()
