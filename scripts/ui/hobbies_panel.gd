class_name HobbiesPanel
extends LabPanel

var introductions: HomeIntroductions
var discoveries: Label


func _ready() -> void:
	panel_size = Vector2(620, 380)
	super._ready()
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.09, 0.10, 0.12, 0.98)
	for child in get_children():
		if child is PanelContainer:
			child.add_theme_stylebox_override("panel", background)
	add_label("HOBBIES_TITLE")
	discoveries = add_label("")
	add_button("HOBBIES_CLOSE", close)
	introductions.changed.connect(refresh)


func open() -> void:
	refresh()
	super.open()


func refresh() -> void:
	if not is_instance_valid(discoveries):
		return
	discoveries.text = tr("HOBBIES_EMPTY") if introductions.discovered.is_empty() else ""
	for hobby in HomeIntroductions.data().hobbies:
		if introductions.discovered.has(hobby):
			var entry: Dictionary = HomeIntroductions.data().hobbies[hobby]
			discoveries.text += tr(entry.label) + "\n" + tr(entry.description) + "\n\n"
	if introductions.discovered.size() < HomeIntroductions.data().hobbies.size():
		discoveries.text += "\n" + tr("HOBBIES_MORE")
