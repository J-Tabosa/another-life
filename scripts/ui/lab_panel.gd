class_name LabPanel
extends Control

signal visibility_updated

var box: VBoxContainer
var panel_size := Vector2(620, 460)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.5)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -panel_size.x / 2
	panel.offset_right = panel_size.x / 2
	panel.offset_top = -panel_size.y / 2
	panel.offset_bottom = panel_size.y / 2
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	scroll.add_child(margin)
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	hide()


func add_label(key: String) -> Label:
	var label := Label.new()
	label.text = tr(key)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)
	return label


func add_button(key: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = tr(key)
	button.custom_minimum_size.y = 34
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	box.add_child(button)
	return button


func open() -> void:
	show()
	visibility_updated.emit()


func close() -> void:
	if visible:
		hide()
		visibility_updated.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		close()
	get_viewport().set_input_as_handled()
