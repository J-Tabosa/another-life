class_name SceneFade
extends CanvasLayer

signal covered
signal started
signal finished
var duration: float = 0.22
var active: bool = false
var shade: ColorRect


func _ready() -> void:
	layer = 100
	shade = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color.BLACK
	shade.hide()
	add_child(shade)


func play(swap: Callable) -> void:
	active = true
	started.emit()
	shade.color.a = 0
	shade.show()
	var tween := create_tween().set_ignore_time_scale(true)
	tween.tween_property(shade, "color:a", 1.0, duration)
	await tween.finished
	covered.emit()
	await get_tree().process_frame
	swap.call()
	await get_tree().process_frame
	tween = create_tween().set_ignore_time_scale(true)
	tween.tween_property(shade, "color:a", 0.0, duration)
	await tween.finished
	shade.hide()
	active = false
	finished.emit()
