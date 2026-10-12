class_name DialoguePanel
extends Control

signal opened
signal closed

var active: bool = false
var _line_keys: PackedStringArray
var _line_index: int = 0


func _ready() -> void:
	$Panel/Next.text = tr("DIALOGUE_NEXT")
	$Panel/Close.text = tr("DIALOGUE_CLOSE")
	$Panel/Next.pressed.connect(advance)
	$Panel/Close.pressed.connect(close)


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
		close()
	else:
		_show_line()


func close() -> void:
	if not active:
		return
	active = false
	hide()
	_line_keys.clear()
	$Panel/Speaker.text = ""
	$Panel/Line.text = ""
	closed.emit()


func _show_line() -> void:
	$Panel/Line.text = tr(_line_keys[_line_index])


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if not event.is_echo():
		if event.is_action_pressed("ui_cancel"):
			close()
		elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
			advance()
	get_viewport().set_input_as_handled()
