extends SceneTree

var checks := 0
var failures := 0
var lab: Node2D
var initial: Dictionary
var memories: Array[String] = []


func _initialize() -> void:
	run.call_deferred()


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error(description)


func settle() -> void:
	for tick in range(4):
		await physics_frame
	while lab.transitioning:
		await process_frame
	await process_frame


func key(code: Key, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	event.echo = echo
	event.device = InputEvent.DEVICE_ID_KEYBOARD
	Input.parse_input_event(event.duplicate())
	await process_frame
	event.pressed = false
	event.echo = false
	Input.parse_input_event(event)
	await settle()


func click(button: Button) -> void:
	await settle()
	var motion := InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = motion.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await settle()


func finish_dialogue(mouse: bool = false) -> void:
	var lines: int = lab.dialogue_panel._line_keys.size() - lab.dialogue_panel._line_index
	for line in range(lines):
		if mouse:
			await click(lab.dialogue_panel.get_node("Panel/Next"))
		else:
			await key(KEY_E if line == lines - 1 else KEY_ENTER)


func walk_to(target: Vector2) -> bool:
	var deadline := Time.get_ticks_usec() + 5_000_000
	while lab.player.position.distance_to(target) > 10:
		var direction: Vector2 = target - lab.player.position
		for action in ["move_left", "move_right", "move_up", "move_down"]:
			Input.action_release(action)
		if absf(direction.x) > 5:
			Input.action_press("move_right" if direction.x > 0 else "move_left")
		if absf(direction.y) > 5:
			Input.action_press("move_down" if direction.y > 0 else "move_up")
		await physics_frame
		if Time.get_ticks_usec() > deadline:
			break
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
	await settle()
	return lab.player.position.distance_to(target) <= 12


func approach(actor_id: String) -> void:
	lab.player.position = lab.area.get_node(HomeIntroductions.data().actors[actor_id].node).position + Vector2(45,0)
	await settle()
	await key(KEY_E)


func prepare(minutes: int, tile: int = 32) -> void:
	lab._restore_state(initial.duplicate(true))
	lab.time_manager.restore_clock(minutes, 0.375)
	lab.tile_size = tile
	lab.change_area(&"room", &"door")
	await settle()
	memories.clear()


func capture(name: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await settle()
	RenderingServer.force_draw(false)
	check(root.get_texture().get_image().save_png("res://docs/screenshots/" + name + ".png") == OK, "render " + name)


func run() -> void:
	Engine.max_fps = 120
	Engine.time_scale = 3 # Test-only acceleration; production movement speed stays 180.
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	lab = load("res://scenes/lab/scale_lab.tscn").instantiate()
	lab.test_storage_root = "user://test_runs/home_" + str(Time.get_ticks_usec())
	root.add_child(lab)
	lab.time_manager.set_process(false)
	lab.fade.duration = 0.03
	initial = lab.snapshot()
	var home: HomeIntroductions = lab.home_introductions
	var clock: TimeManager = lab.time_manager
	var dialogue: DialoguePanel = lab.dialogue_panel
	var panel: HobbiesPanel = lab.hobbies_panel
	home.remembered.connect(func(actor_id: StringName, event_id: StringName, _at: int) -> void: memories.append(String(actor_id) + ":" + String(event_id)))
	check(HomeIntroductions.data().hobbies.keys() == ["skate", "videogames", "music"], "exactly three canonical hobbies in reusable data")
	for actor_id in HomeIntroductions.data().actors:
		for event_id in HomeIntroductions.data().actors[actor_id].dialogues:
			var path: String = "res://data/dialogues/" + HomeIntroductions.data().actors[actor_id].dialogues[event_id] + ".tres"
			var data: DialogueData = load(path)
			var translated: bool = data != null and tr(data.speaker_key) != String(data.speaker_key)
			for line in data.line_keys:
				translated = translated and tr(line) != line
			check(translated, "resource and text keys available: " + actor_id + "/" + event_id)
	check(home.greetings.is_empty() and home.discovered.is_empty(), "new game knows no completed home event or hobby")
	await key(KEY_H)
	check(panel.visible and not lab.player.controls_enabled and not clock.running, "H opens interests and pauses controls/time")
	check(not panel.discoveries.text.contains(tr("HOBBY_SKATE")) and not panel.discoveries.text.contains(tr("HOBBY_MUSIC")), "unknown hobby names are not leaked in interests")
	check(not lab.debug_jump(1020), "debug cannot change time beneath interests panel")
	await key(KEY_ESCAPE)
	check(not panel.visible and lab.player.controls_enabled, "Escape closes interests and restores movement")
	lab._open_home_dialogue(null)
	lab._open_home_dialogue(lab.area.get_node("Bed"))
	lab._open_home_dialogue(lab.area.get_node("Father"))
	check(not dialogue.active and home.greetings.is_empty(), "remote or missing home actor cannot start conversation")
	check(await walk_to(lab.area.get_node("Father").position), "father physically reachable from initial spawn")
	await key(KEY_E)
	check(dialogue.active and dialogue.get_node("Panel/Line").text == tr("FATHER_GREETING_01").format({"player_salutation": ""}), "nearby E opens father morning greeting")
	var start: Vector2 = lab.player.position
	clock._process(300)
	await key(KEY_R)
	await key(KEY_T)
	await key(KEY_H)
	await key(KEY_M)
	lab.request_transition(&"street", &"door")
	check(clock.world_minutes == 360 and lab.player.position == start and lab.area_id == &"room" and not panel.visible and not lab.city_map.visible, "home dialogue blocks activities movement maps interests and doors")
	check(not lab.debug_jump(1020), "calendar cannot skip a pending home event")
	await key(KEY_E, true)
	check(dialogue.get_node("Panel/Line").text == tr("FATHER_GREETING_01").format({"player_salutation": ""}), "held E does not skip home dialogue")
	await key(KEY_ESCAPE)
	check(home.greetings.is_empty() and home.discovered.is_empty() and not dialogue.active, "cancelled greeting records nothing")
	await key(KEY_E)
	await finish_dialogue()
	check(home.greetings.get("father") == 360 and home.discovered.is_empty() and memories == ["father:greeting"], "morning father greeting remembered without discovering skate early")
	await key(KEY_E)
	await finish_dialogue()
	check(memories.size() == 1 and home.discovered.is_empty(), "morning repeat does not replay introduction or invent hobby")
	check(await walk_to(lab.area.get_node("Sister").position), "sister physically reachable across room")
	await key(KEY_E)
	check(dialogue.get_node("Panel/Line").text == tr("SISTER_GREETING_01"), "sister has distinct morning greeting")
	await finish_dialogue(true)
	check(home.greetings.size() == 2 and home.discovered.is_empty(), "both greetings complete before university without early hobby unlocks")
	check(clock.world_minutes == 360 and clock.get_clock_state().fraction == 0.0 and lab.academics.present.is_empty(), "family introductions consume no time or academic presence")
	check(not FileAccess.file_exists(lab.save_manager.storage_root.path_join("auto.json")), "autosave off creates no implicit home save")
	check(await walk_to(Vector2(480,430)) and await walk_to(lab.area.get_node("MusicCorner").position + Vector2(45,0)), "music point reachable around furniture with physics movement")
	await key(KEY_E)
	check(dialogue.active and dialogue.get_node("Panel/Speaker").text == tr("MUSIC_SPEAKER"), "music corner starts its own discovery")
	await key(KEY_ENTER)
	await key(KEY_ENTER)
	await click(dialogue.get_node("Panel/Close"))
	check(home.discovered.is_empty(), "mouse cancel on last music line still records nothing")
	await key(KEY_E)
	await capture("home_music_discovery")
	await finish_dialogue()
	check(home.discovered == {"music":360} and memories[-1] == "music:intro", "completed music discovery records only music")
	await key(KEY_H)
	check(panel.discoveries.text.contains(tr("HOBBY_MUSIC")) and not panel.discoveries.text.contains(tr("HOBBY_SKATE")), "interests shows discovered music without revealing skate")
	await key(KEY_ESCAPE)
	check(lab.save_manager.save_slot("manual", lab.snapshot()), "manual can preserve greetings and early music discovery")
	var manual_bytes := FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json"))
	check(lab.debug_jump(1020), "debug can advance to optional evening opportunity")
	lab.change_area(&"street", &"door")
	lab.player.position = lab.area.get_node("Door").position
	await settle()
	await key(KEY_E)
	check(lab.area_id == &"room" and lab.player.position == Vector2(480,524) and lab.area.has_node("Father") and lab.area.has_node("Sister"), "real faded return home makes evening family available")
	check(home.discovered == {"music":360}, "returning or calendar advancement grants no offscreen hobbies")
	check(lab.save_manager.set_autosave(true), "enable isolated auto for completed introductions")
	await approach("father")
	check(dialogue.get_node("Panel/Line").text == tr("FATHER_SKATE_01"), "evening father introduces skate with distinct scene")
	await capture("home_father_skate")
	await key(KEY_ESCAPE)
	check(not home.discovered.has("skate") and not FileAccess.file_exists(lab.save_manager.storage_root.path_join("auto.json")), "cancelled skate conversation neither discovers nor autosaves")
	await key(KEY_E)
	await finish_dialogue()
	check(home.discovered.get("skate") == 1020 and home.discovered.size() == 2, "father completion discovers skate once")
	check(lab.save_manager.load_slot("auto").home_introductions.discovered.skate == 1020, "completed skate discovery is autosaved")
	check(FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json")) == manual_bytes, "home auto preserves earlier manual bytes")
	var auto_after := FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("auto.json"))
	await key(KEY_E)
	await finish_dialogue()
	check(FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("auto.json")) == auto_after and memories.count("father:intro") == 1, "repeat father scene cannot duplicate discovery or rewrite auto")
	check(await walk_to(lab.area.get_node("Sister").position + Vector2(45,0)), "sister reachable after father evening event")
	await key(KEY_E)
	check(dialogue.get_node("Panel/Line").text == tr("SISTER_GAMES_01"), "sister introduces games independently of father")
	await capture("home_sister_games")
	await finish_dialogue(true)
	check(home.discovered.size() == 3 and home.discovered.get("videogames") == 1020, "sister completes third canonical hobby discovery")
	check(clock.world_minutes == 1020 and lab.academics.present.is_empty() and SaveManager.validate_state(lab.snapshot()), "evening events preserve time and academic state with valid save")
	await click(lab.get_node("HUD/HobbiesButton"))
	check(panel.visible and panel.discoveries.text.contains(tr("HOBBY_SKATE")) and panel.discoveries.text.contains(tr("HOBBY_VIDEOGAMES")) and panel.discoveries.text.contains(tr("HOBBY_MUSIC")) and not panel.discoveries.text.contains(tr("HOBBIES_MORE")), "interests button shows exactly the three completed discoveries")
	await capture("home_hobbies")
	await key(KEY_ESCAPE)
	var all_known: Dictionary = lab.snapshot()
	await approach("sister")
	check(await lab.load_slot("manual"), "manual load may interrupt an active home dialogue")
	check(not dialogue.active and lab._home_pending.is_empty() and home.discovered == {"music":360} and home.greetings.size() == 2 and clock.world_minutes == 360, "rollback restores known events time and no pending continuation")
	check(await lab.load_slot("auto") and home.discovered.size() == 3 and clock.world_minutes == 1020, "auto restores all three discoveries independently of manual")
	lab.sleep_manager.request()
	check(lab.sleep_panel.visible and lab.sleep_manager.pending, "family events leave ordinary bedtime available")
	lab._choose_sleep(true)
	check(not lab.sleep_manager.pending and home.discovered.size() == 3 and clock.world_minutes == 1440 + 360, "sleep advances normally while keeping discoveries")
	check(await lab.load_slot("manual"), "manual made at bedtime reloads")
	check(lab.sleep_manager.pending and home.discovered.size() == 3 and home.greetings.size() == 2, "before-bed manual restores all introductions and pending sleep choice")
	lab._cancel_sleep()
	lab.save_manager.set_autosave(false)
	for mutation in ["block_type", "greetings_type", "discoveries_type", "unknown_actor", "unknown_hobby", "future", "fractional", "boolean", "early_skate", "late_greeting", "absent_father", "04h_music"]:
		var bad := all_known.duplicate(true)
		match mutation:
			"block_type": bad.home_introductions = []
			"greetings_type": bad.home_introductions.greetings = []
			"discoveries_type": bad.home_introductions.discovered = false
			"unknown_actor": bad.home_introductions.greetings.mother = 360
			"unknown_hobby": bad.home_introductions.discovered.fishing = 1020
			"future": bad.home_introductions.discovered.music = 1021
			"fractional": bad.home_introductions.discovered.music = 360.5
			"boolean": bad.home_introductions.discovered.music = true
			"early_skate": bad.home_introductions.discovered.skate = 360
			"late_greeting": bad.home_introductions.greetings.father = 1020
			"absent_father": bad.home_introductions.discovered.skate = 900
			"04h_music": bad.home_introductions.discovered.music = 240
		check(not SaveManager.validate_state(bad), "save refuses invalid home knowledge " + mutation)
	var before_invalid: Dictionary = lab.snapshot()
	var invalid_home := all_known.duplicate(true)
	invalid_home.home_introductions.discovered.skate = -1
	SaveManager._write_json(lab.save_manager.storage_root.path_join("auto.json"), invalid_home)
	check(not await lab.load_slot("auto") and lab.snapshot() == before_invalid, "corrupt load leaves current home state untouched")
	var old := all_known.duplicate(true)
	old.erase("home_introductions")
	check(lab.save_manager.save_slot("manual", old), "pre-P2-07 schema-three save remains valid")
	var old_bytes := FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json"))
	check(await lab.load_slot("manual"), "schema three without home discoveries loads")
	check(home.greetings.is_empty() and home.discovered.is_empty() and clock.world_minutes == 1020 and lab.player.position == Vector2(old.player.x,old.player.y), "old save defaults undiscovered without changing clock or position")
	check(FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json")) == old_bytes, "old save original is not rewritten")
	await approach("father")
	check(dialogue.active and dialogue.get_node("Panel/Line").text == tr("FATHER_SKATE_01"), "old save can discover skate without requiring morning greeting")
	lab.change_area(&"street", &"door")
	check(not dialogue.active and home.discovered.is_empty() and lab._home_pending.is_empty(), "area replacement cancels pending home introduction without recording")
	for minute in [359,360,479,480,1019,1020,1379,1380,1440,1440+360]:
		clock.restore_clock(minute)
		lab.change_area(&"room", &"door")
		var expected: bool = minute % 1440 >= 360 and minute % 1440 < 480 or minute % 1440 >= 1020 and minute % 1440 < 1380
		check(lab.area.has_node("Father") == expected and lab.area.has_node("Sister") == expected and lab.area.has_node("MusicCorner"), "home availability exact boundary %d" % minute)
	check(home.discovered.is_empty(), "availability never fabricates player discoveries")
	await prepare(1020)
	await approach("father")
	clock.restore_clock(1021)
	await finish_dialogue()
	check(home.discovered.is_empty() and lab._home_pending.is_empty(), "changed clock invalidates pending home completion without awarding discovery")
	await prepare(5 * 1440 + 1020)
	await approach("sister")
	await finish_dialogue()
	await approach("father")
	await finish_dialogue()
	check(home.greetings.is_empty() and home.discovered.size() == 2 and home.discovered.videogames == 5*1440+1020, "missed first day recovers on later weekend with reverse sibling/father order")
	await prepare(239)
	await approach("music")
	check(dialogue.active, "music discovery remains available at 03h59")
	await finish_dialogue()
	check(home.discovered.music == 239 and clock.world_minutes == 239 and clock.get_clock_state().fraction == 0.375, "late music discovery preserves time fraction and avoids crossing sleep limit")
	check(lab.debug_jump(240) and lab.sleep_manager.pending and not dialogue.active and not panel.visible, "04h mandatory sleep still works after music discovery")
	lab._choose_sleep(false)
	check(clock.world_minutes == 360 and home.discovered.music == 239, "home alarm wakes at 06h retaining discovery")
	for tile in [32,64]:
		await prepare(1020, tile)
		check(await walk_to(lab.area.get_node("Father").position), "father physical access at tile %d" % tile)
		await key(KEY_E)
		check(dialogue.active, "father E interaction at tile %d" % tile)
		await finish_dialogue()
		check(await walk_to(lab.area.get_node("Sister").position), "sister physical access at tile %d" % tile)
		await key(KEY_E)
		await finish_dialogue()
		check(await walk_to(Vector2(480,430)) and await walk_to(lab.area.get_node("MusicCorner").position), "music physical access around desk at tile %d" % tile)
		await key(KEY_E)
		await finish_dialogue()
		check(home.discovered.size() == 3 and lab.player.get_node("Camera2D").zoom == Vector2.ONE and lab.player.scale == Vector2.ONE, "all discoveries preserve scale at tile %d" % tile)
	root.size = Vector2i(960,540)
	await approach("music")
	await settle()
	check(root.get_visible_rect().encloses(dialogue.get_node("Panel/Next").get_global_rect()) and dialogue.get_node("Panel/Line").get_line_count() <= 2, "home text and controls fit notebook viewport")
	await key(KEY_ESCAPE)
	await key(KEY_H)
	check(root.get_visible_rect().encloses(panel.discoveries.get_global_rect()), "three hobby descriptions fit notebook viewport")
	await capture("home_hobbies_notebook")
	await key(KEY_ESCAPE)
	lab.change_area(&"street", &"door")
	clock.restore_clock(1020, 0.75)
	await key(KEY_H)
	clock._process(100)
	check(panel.visible and not clock.running and clock.world_minutes == 1020 and clock.get_clock_state().fraction == 0.75, "interests also freezes outdoor time without consuming fractional progress")
	await key(KEY_ESCAPE)
	clock._process(0.25)
	check(clock.running and clock.world_minutes == 1021 and clock.get_clock_state().fraction == 0.0, "closing outdoor interests resumes exact remaining fraction")
	check(SaveManager.validate_state(lab.snapshot()), "final state remains valid")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
