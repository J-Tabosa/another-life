extends Node2D

@export var map_size := Vector2(12800, 1600)
@export var title_key: StringName = &"LAB_ROUTE"
@export var campus: bool = false
var exterior: bool = true
var tile_size: int = 32
var collision_root: Node2D
var sign_root: Node2D


func _ready() -> void:
	sign_root = Node2D.new()
	sign_root.name = "RouteSigns"
	add_child(sign_root)
	if not campus:
		for x in range(640, int(map_size.x - 160), 640):
			var sign_node: Node2D = preload("res://scenes/world/wayfinding_sign.tscn").instantiate()
			sign_node.position = Vector2(x, 980)
			sign_root.add_child(sign_node)
	rebuild()


func rebuild() -> void:
	if is_instance_valid(collision_root):
		remove_child(collision_root)
		collision_root.queue_free()
	collision_root = Node2D.new()
	add_child(collision_root)
	var solids: Array[Rect2] = [Rect2(0, 0, map_size.x, 32), Rect2(0, map_size.y - 32, map_size.x, 32), Rect2(0, 0, 32, map_size.y), Rect2(map_size.x - 32, 0, 32, map_size.y)]
	if campus:
		solids.append(Rect2(1088, 224, 960, 384))
	for rect in solids:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = rect.size
		shape.shape = rectangle
		body.position = rect.get_center()
		body.add_child(shape)
		collision_root.add_child(body)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, map_size), Color("49665b"))
	for x in range(32, int(map_size.x), tile_size):
		draw_line(Vector2(x, 32), Vector2(x, map_size.y - 32), Color(1, 1, 1, 0.05))
	draw_rect(Rect2(32, 640, map_size.x - 64, 320), Color("6b777d"))
	if campus:
		draw_rect(Rect2(1088, 224, 960, 384), Color("344451"))
		draw_string(ThemeDB.fallback_font, Vector2(1120, 280), tr("LAB_CAMPUS"), HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
		draw_rect(Rect2(1408, 576, 192, 32), Color("d5bc7e"))
