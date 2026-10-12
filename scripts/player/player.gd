extends CharacterBody2D

@export var speed: float = 180.0
var facing: StringName = &"down"
var show_frame: bool = true
var controls_enabled: bool = true
@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	# Procedural placeholders: every texture is exactly 128 x 128 pixels.
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for direction: StringName in [&"up", &"down", &"left", &"right"]:
		for state: String in ["idle", "walk"]:
			var animation := StringName(state + "_" + String(direction))
			frames.add_animation(animation)
			frames.set_animation_speed(animation, 8.0)
			for step in range(2 if state == "walk" else 1):
				frames.add_frame(animation, _placeholder(direction, step))
	sprite.sprite_frames = frames
	update_animation(Vector2.ZERO)


func _physics_process(_delta: float) -> void:
	if not controls_enabled:
		velocity = Vector2.ZERO
		update_animation(Vector2.ZERO)
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	update_animation(direction)


func update_animation(direction: Vector2) -> void:
	if not direction.is_zero_approx():
		# Diagonal ties retain the horizontal facing; four animation directions.
		if absf(direction.x) >= absf(direction.y):
			facing = &"right" if direction.x > 0.0 else &"left"
		else:
			facing = &"down" if direction.y > 0.0 else &"up"
	var state := "idle" if direction.is_zero_approx() else "walk"
	sprite.play(StringName(state + "_" + String(facing)))


func _placeholder(direction: StringName, step: int) -> ImageTexture:
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	image.fill_rect(Rect2i(44, 32, 40, 56), Color("e9bb70"))
	image.fill_rect(Rect2i(44, 32, 40, 8), Color("946345"))
	image.fill_rect(Rect2i(46, 88 + step * 4, 12, 12), Color("263e51"))
	image.fill_rect(Rect2i(70, 92 - step * 4, 12, 12), Color("263e51"))
	var marker := Rect2i(58, 72, 12, 8)
	match direction:
		&"up": marker = Rect2i(58, 40, 12, 8)
		&"left": marker = Rect2i(44, 54, 8, 12)
		&"right": marker = Rect2i(76, 54, 8, 12)
	image.fill_rect(marker, Color("fff3cf"))
	return ImageTexture.create_from_image(image)


func _draw() -> void:
	if show_frame:
		draw_rect(Rect2(-64, -112, 128, 128), Color(1, 1, 1, 0.45), false)
		draw_rect(Rect2(-12, -14, 24, 14), Color("79e2c1"), false)
