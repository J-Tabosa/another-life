extends Node2D

@export var exterior: bool = false
var map_size := Vector2(960, 640)
var tile_size: int = 32
var solids: Array[Rect2] = []
var furniture: Array[Rect2] = []
var collision_root: Node2D


func _ready() -> void:
	rebuild()


func rebuild() -> void:
	if is_instance_valid(collision_root):
		remove_child(collision_root)
		collision_root.queue_free()
	collision_root = Node2D.new()
	add_child(collision_root)
	solids = [Rect2(0, 0, 960, 32), Rect2(0, 0, 32, 640), Rect2(928, 0, 32, 640)]
	var doorway_width := float(tile_size * 2)
	if exterior:
		solids.append(Rect2(0, 608, 960, 32))
		# Facade split around the doorway; this is a separate map.
		solids.append(Rect2(224, 192, 256 - doorway_width / 2, 128))
		solids.append(Rect2(480 + doorway_width / 2, 192, 256 - doorway_width / 2, 128))
		furniture = []
	else:
		solids.append(Rect2(32, 608, 448 - doorway_width / 2, 32))
		solids.append(Rect2(480 + doorway_width / 2, 608, 448 - doorway_width / 2, 32))
		furniture = [Rect2(96, 224, tile_size * 2, tile_size * 4), Rect2(640, 224, tile_size * 3, tile_size * 2)]
		solids.append_array(furniture)
	for rect in solids:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = rect.size
		shape.shape = rectangle
		body.position = rect.get_center()
		body.add_child(shape)
		collision_root.add_child(body)
	# Door width follows the same tile comparison as its drawing.
	var door_shape: CollisionShape2D = $Door/CollisionShape2D
	var portal_shape := RectangleShape2D.new()
	portal_shape.size = Vector2(doorway_width, 64)
	door_shape.shape = portal_shape
	if not exterior:
		$Bed.position = furniture[0].get_center()
		var bed_shape := RectangleShape2D.new()
		bed_shape.size = furniture[0].size + Vector2(80, 80)
		$Bed/CollisionShape2D.shape = bed_shape
	queue_redraw()


func _draw() -> void:
	var floor_color := Color("49665b") if exterior else Color("776752")
	draw_rect(Rect2(0, 0, 960, 640), floor_color)
	for x in range(0, 961, tile_size):
		draw_line(Vector2(x, 32), Vector2(x, 608), Color(1, 1, 1, 0.12))
	for y in range(32, 609, tile_size):
		draw_line(Vector2(32, y), Vector2(928, y), Color(1, 1, 1, 0.12))
	if exterior:
		draw_rect(Rect2(32, 352, 896, 160), Color("6b777d"))
	for rect in solids:
		draw_rect(rect, Color("344451"))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, minf(24, rect.size.y))), Color("506372"))
	if not exterior and furniture.size() == 2:
		draw_rect(furniture[0], Color("678fa4"))
		draw_rect(Rect2(furniture[0].position + Vector2(8, 8), Vector2(furniture[0].size.x - 16, 24)), Color("e5d9bb"))
		draw_rect(furniture[1], Color("bc956a"))
		draw_string(ThemeDB.fallback_font, furniture[0].position + Vector2(0, -12), tr("LAB_BED"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
		draw_string(ThemeDB.fallback_font, furniture[1].position + Vector2(0, -12), tr("LAB_DESK"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	var door_position: Vector2 = $Door.position
	draw_rect(Rect2(door_position - Vector2(tile_size, 16), Vector2(tile_size * 2, 32)), Color("d5bc7e"))
	draw_string(ThemeDB.fallback_font, door_position + Vector2(-tile_size, -24), tr("LAB_DOOR"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
