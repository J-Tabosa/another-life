class_name CityMapPanel
extends LabPanel

var region_id: StringName
var player_position: Vector2
var position_label: Label
var map_view: Control


func _ready() -> void:
	panel_size = Vector2(820, 490)
	super._ready()
	add_label("CITY_MAP_TITLE")
	map_view = Control.new()
	map_view.set_script(preload("res://scripts/ui/city_map_view.gd"))
	map_view.custom_minimum_size = Vector2(760, 300)
	box.add_child(map_view)
	position_label = add_label("")
	add_label("CITY_MAP_HELP")
	add_button("DEBUG_CLOSE", close)


func open() -> void:
	var layout := WorldLayouts.region(String(region_id))
	position_label.text = tr("CITY_MAP_INTERIOR")
	map_view.source_position = Vector2(-1, -1)
	if layout.has("reference_crop"):
		var source := ReferenceCity.source_point(player_position, WorldLayouts.rectangle(layout.reference_crop))
		position_label.text = tr("CITY_MAP_POSITION") % [source.x, source.y]
		map_view.source_position = source
	map_view.queue_redraw()
	super.open()
