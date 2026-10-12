extends SceneTree

var failures: int = 0
var checks: int = 0


func _initialize() -> void:
	run.call_deferred()


func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)
	else:
		print("PASS: " + description)


func settle() -> void:
	# Area2D overlaps are synchronized by the physics server after tree signals.
	for tick in range(4):
		await physics_frame
	await process_frame


func run() -> void:
	var lab: Node2D = load("res://scenes/lab/scale_lab.tscn").instantiate()
	root.add_child(lab)
	await settle()
	var player: CharacterBody2D = lab.player
	check(lab.area_id == &"room", "initial area is room")
	check(player.position == Vector2(480, 400), "initial spawn")
	check(tr("LAB_ROOM") == "Quarto", "Portuguese translation loads")
	var frames: SpriteFrames = player.get_node("Sprite").sprite_frames
	for direction: StringName in [&"up", &"down", &"left", &"right"]:
		check(frames.get_frame_texture(StringName("walk_" + String(direction)), 0).get_size() == Vector2(128, 128), "128x128 frame: " + String(direction))
	for actions: Array in [["move_right"], ["move_left"], ["move_up"], ["move_down"], ["move_right", "move_up"], ["move_left", "move_up"], ["move_right", "move_down"], ["move_left", "move_down"]]:
		player.position = Vector2(480, 420)
		for action: String in actions:
			Input.action_press(action)
		await settle()
		check(is_equal_approx(player.velocity.length(), player.speed), "normalized speed: " + str(actions))
		for action: String in actions:
			Input.action_release(action)
		var facing: StringName = player.facing
		await settle()
		check(player.velocity.is_zero_approx() and player.get_node("Sprite").animation == StringName("idle_" + String(facing)), "idle retains direction: " + str(actions))
	player.position = Vector2(48, 420)
	Input.action_press("move_left")
	for tick in range(30):
		await physics_frame
	Input.action_release("move_left")
	await settle()
	check(player.position.x >= 43.0 and player.position.x <= 45.0, "wall collision blocks movement")
	for size: int in [32, 64]:
		lab.tile_size = size
		lab.change_area(&"room", &"door")
		player.position = Vector2(96 + size, 224 + size * 4 + 18)
		Input.action_press("move_up")
		for tick in range(30):
			await physics_frame
		Input.action_release("move_up")
		await settle()
		check(player.position.y >= 224 + size * 4 + 13, "bed collision at tile " + str(size))
		player.position = Vector2(640 + size, 224 + size * 2 + 18)
		Input.action_press("move_up")
		for tick in range(30):
			await physics_frame
		Input.action_release("move_up")
		await settle()
		check(player.position.y >= 224 + size * 2 + 13, "desk collision at tile " + str(size))
		lab.change_area(&"room", &"start")
		await settle()
		lab.area.get_node("Door").interact(player)
		await settle()
		check(lab.area_id == &"room", "door refuses remote interaction")
		lab.change_area(&"room", &"door")
		await settle()
		for cycle in range(3):
			# Approach the room door through its actual opening.
			Input.action_press("move_down")
			for tick in range(20):
				await physics_frame
			Input.action_release("move_down")
			await settle()
			check(lab.area.get_node("Door").can_interact(player), "room doorway is reachable")
			var interaction := InputEventAction.new()
			interaction.action = &"interact"
			interaction.pressed = true
			lab._unhandled_input(interaction)
			await settle()
			check(lab.area_id == &"street" and player.position == Vector2(480, 402), "room to street spawn")
			check(lab.get_node("World").get_child_count() == 1, "one active map")
			Input.action_press("move_up")
			for tick in range(25):
				await physics_frame
			Input.action_release("move_up")
			await settle()
			check(lab.area.get_node("Door").can_interact(player), "street doorway is reachable")
			lab._unhandled_input(interaction)
			await settle()
			check(lab.area_id == &"room" and player.position == Vector2(480, 524), "street to room spawn")
	if "--capture" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
		for size: int in [32, 64]:
			lab.tile_size = size
			for target: StringName in [&"room", &"street"]:
				lab.change_area(target, &"door")
				player.position = Vector2(480, 400)
				await settle()
				await RenderingServer.frame_post_draw
				var path := "res://docs/screenshots/%s_%d.png" % [target, size]
				check(root.get_texture().get_image().save_png(path) == OK, "capture " + path)
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
