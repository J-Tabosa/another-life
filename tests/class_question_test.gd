extends SceneTree

var checks := 0
var failures := 0
var lab: Node2D
var initial: Dictionary
var events: Array[int] = []
var completed: Array[String] = []


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
	event.physical_keycode = code
	event.keycode = code
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
	var center := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = center
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = center
		event.pressed = pressed
		event.button_index = MOUSE_BUTTON_LEFT
		root.push_input(event, true)
		await process_frame
	await settle()


func prepare(minutes: int = 780, introduced: bool = true) -> void:
	lab._restore_state(initial.duplicate(true))
	lab.time_manager.restore_clock(minutes, 0.375)
	lab.academics.professor_intro_seen = introduced
	lab.change_area(&"classroom", &"door")
	lab.player.position = lab.area.get_node("LessonPoint").position
	await settle()
	lab._open_academics()
	events.clear()
	completed.clear()


func capture(name: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await settle()
	# An unchanged / hidden test window may skip a render-loop frame.
	RenderingServer.force_draw(false)
	check(root.get_texture().get_image().save_png("res://docs/screenshots/" + name + ".png") == OK, "render " + name)


func run() -> void:
	Engine.max_fps = 120
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	lab = load("res://scenes/lab/scale_lab.tscn").instantiate()
	lab.test_storage_root = "user://test_runs/questions_" + str(Time.get_ticks_usec())
	root.add_child(lab)
	lab.time_manager.set_process(false)
	lab.fade.duration = 0.03
	initial = lab.snapshot()
	var clock: TimeManager = lab.time_manager
	var schedule: AcademicSchedule = lab.academics
	var panel: ClassQuestionPanel = lab.question_panel
	var bank: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ClassQuestionBank.PATH))
	var question := ClassQuestionBank.first()
	clock.minute_changed.connect(func(value: int) -> void: events.append(value))
	schedule.session_finished.connect(func(day: int, session: String, status: String) -> void: completed.append("%d:%s:%s" % [day, session, status]))
	check(ClassQuestionBank.valid_bank(bank) and question.options.size() == 4, "data bank has exactly four stable alternatives")
	check(question.correct_option_id == "year_1822" and question.source_url.begins_with("https://bndigital.bn.gov.br/"), "unambiguous historical answer has authoritative source")
	for field in ["prompt_key", "correct_reaction_key", "incorrect_reaction_key", "explanation_key"]:
		check(tr(question[field]) != question[field], "localized question field " + field)
	for option in question.options:
		check(tr(option.label_key) != option.label_key, "localized option " + option.id)
	for mutation in ["count", "duplicate", "missing_correct", "empty_text", "duplicate_question", "missing_first"]:
		var bad := bank.duplicate(true)
		match mutation:
			"count": bad.questions[0].options.pop_back()
			"duplicate": bad.questions[0].options[0].id = bad.questions[0].options[1].id
			"missing_correct": bad.questions[0].correct_option_id = "unknown"
			"empty_text": bad.questions[0].prompt_key = ""
			"duplicate_question": bad.questions.append(bad.questions[0].duplicate(true))
			"missing_first": bad.first_question_id = "unknown"
		check(not ClassQuestionBank.valid_bank(bad), "bank rejects " + mutation)
	await prepare(540)
	await click(lab.academic_panel.attend_button)
	check(clock.world_minutes == 720 and not panel.visible and schedule.question_answers.is_empty(), "morning attendance has no afternoon question")
	await click(lab.academic_panel.wait_button)
	check(clock.world_minutes == 780 and schedule.needs_question(), "first afternoon offers question")
	check(not schedule.attend() and not schedule.attend("unknown") and clock.world_minutes == 780, "model rejects missing or invalid alternatives before any time or presence")
	await click(lab.academic_panel.attend_button)
	check(panel.visible and not lab.academic_panel.visible and not lab.dialogue_panel.active, "participation click opens separate four-choice screen")
	check(not panel.answered and not panel.reaction.visible and panel.options.all(func(button: Button) -> bool: return not button.disabled), "fresh question shows four enabled choices without revealing answer")
	check(clock.world_minutes == 780 and schedule.present.size() == 1 and events.size() == 240, "opening question spends no extra time and grants no afternoon presence")
	check(not lab.player.controls_enabled and not clock.running, "question freezes movement and natural time")
	await capture("class_question")
	var before: Vector2 = lab.player.position
	clock._process(200)
	await key(KEY_R)
	await key(KEY_T)
	await key(KEY_M)
	await key(KEY_J)
	lab.request_transition(&"room", &"door")
	check(clock.world_minutes == 780 and lab.player.position == before and lab.area_id == &"classroom" and not lab.city_map.visible, "pending question blocks activities scene transitions map and scale")
	check(not lab.debug_jump(800), "debug cannot change date under question")
	await key(KEY_ENTER)
	await key(KEY_2, true)
	check(not panel.answered and schedule.question_answers.is_empty(), "Enter and held choice key cannot silently choose")
	await key(KEY_ESCAPE)
	check(not panel.visible and lab.academic_panel.visible and clock.world_minutes == 780 and schedule.question_answers.is_empty(), "Escape before answer cancels without recording or advancing")
	check(not FileAccess.file_exists(lab.save_manager.storage_root.path_join("auto.json")), "autosave off creates no file on opening or cancelling question")
	await click(lab.academic_panel.attend_button)
	await click(panel.close_button)
	check(not panel.visible and schedule.question_answers.is_empty(), "mouse cancel also leaves question available")
	var pre_answer: Dictionary = lab.snapshot()
	check(lab.save_manager.save_slot("manual", pre_answer), "pre-answer manual save valid")
	var manual_bytes := FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json"))
	check(lab.save_manager.set_autosave(true), "enable isolated autosave")
	await click(lab.academic_panel.attend_button)
	events.clear()
	await click(panel.options[1])
	check(panel.visible and panel.answered and panel.reaction.visible and panel.reaction.text.contains(tr(question.correct_reaction_key)), "correct mouse choice shows professor encouragement")
	check(panel.options.all(func(button: Button) -> bool: return button.disabled), "all choices lock once answered")
	check(clock.world_minutes == 1020 and events.size() == 240 and events[0] == 781 and events[-1] == 1020, "answer advances remaining afternoon chronologically to 17h")
	check(completed == ["0:morning:present", "0:afternoon:present"], "answer yields one afternoon presence event")
	var answer: Dictionary = schedule.question_answers[question.id]
	check(answer.option_id == "year_1822" and answer.correct and answer.answered_at == 780 and answer.session_key == "0:afternoon", "record keeps stable question option correctness time and class")
	check(clock.get_clock_state().fraction == 0.375 and SaveManager.validate_state(lab.snapshot()), "answer keeps clock fraction and creates valid snapshot")
	var auto: Dictionary = lab.save_manager.load_slot("auto")
	check(auto.academics.question_answers[question.id].correct and auto.academics.present.has("0:afternoon"), "autosave stores answer and presence together before reaction closes")
	check(FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json")) == manual_bytes, "answer autosave preserves manual file byte for byte")
	await capture("class_question_correct")
	lab._answer_class_question("year_1500")
	await key(KEY_1)
	await click(panel.options[0])
	check(schedule.question_answers[question.id].option_id == "year_1822" and schedule.present.size() == 2 and events.size() == 240, "repeated click key or callback cannot reroll or award twice")
	await key(KEY_ESCAPE)
	check(lab.academic_panel.visible and schedule.question_answers.size() == 1 and lab.academic_panel.history.text.contains(tr("QUESTION_HISTORY")), "Escape after reaction keeps answer and exposes history in agenda")
	check(lab.academic_panel.history.text.contains("1822") and lab.academic_panel.history.text.contains(tr("QUESTION_RESULT_CORRECT")), "agenda exposes selected answer and recorded success")
	check(await lab.load_slot("manual"), "manual rollback before question works")
	check(clock.world_minutes == 780 and schedule.question_answers.is_empty() and not panel.visible and schedule.present.size() == 1, "rollback restores question eligibility with original presence")
	lab._open_academics()
	await click(lab.academic_panel.attend_button)
	check(await lab.load_slot("auto"), "load can interrupt an unanswered question")
	check(clock.world_minutes == 1020 and not panel.visible and schedule.question_answers[question.id].correct, "load dismisses pending UI without leaking callbacks")
	lab.debug_jump(1440 + 780)
	lab._open_academics()
	await click(lab.academic_panel.attend_button)
	check(clock.world_minutes == 1440 + 1020 and not panel.visible and schedule.question_answers.size() == 1, "later afternoon does not repeat first question or duplicate acerto")
	check(not schedule.attend("year_1822"), "completed session rejects additional answer at model level")
	lab.save_manager.set_autosave(false)
	for index in range(4):
		await prepare(800)
		await click(lab.academic_panel.attend_button)
		await key(KEY_1 + index)
		var record: Dictionary = schedule.question_answers[question.id]
		check(record.option_id == question.options[index].id and record.correct == (index == 1), "keyboard alternative %d records exact selection and correctness" % (index + 1))
		check(clock.world_minutes == 1020 and events.size() == 220 and schedule.present["0:afternoon"] == 800 and completed == ["0:afternoon:present"], "alternative %d advances only remaining minutes and gives normal presence" % (index + 1))
		check(SaveManager.validate_state(lab.snapshot()) and panel.reaction.text.contains(tr(question.correct_reaction_key if index == 1 else question.incorrect_reaction_key)), "alternative %d has appropriate reaction and valid save" % (index + 1))
		if index == 0:
			await capture("class_question_incorrect")
		await key(KEY_ENTER)
		check(not panel.visible and lab.academic_panel.visible, "Enter closes reaction %d without starting another action" % (index + 1))
	var answered: Dictionary = lab.snapshot()
	for mutation in ["not_dictionary", "unknown_question", "unknown_option", "wrong_correctness", "non_boolean", "future_time", "fractional_time", "wrong_session", "missing_presence", "different_join", "unknown_record"]:
		var bad := answered.duplicate(true)
		var record: Dictionary = bad.academics.question_answers[question.id]
		match mutation:
			"not_dictionary": bad.academics.question_answers = []
			"unknown_question": bad.academics.question_answers = {"unknown": record}
			"unknown_option": record.option_id = "unknown"
			"wrong_correctness": record.correct = not record.correct
			"non_boolean": record.correct = 0
			"future_time": record.answered_at = 1021
			"fractional_time": record.answered_at = 800.5
			"wrong_session": record.session_key = "0:morning"
			"missing_presence": bad.academics.present.clear()
			"different_join": record.answered_at = 801
			"unknown_record": bad.academics.question_answers[question.id] = []
		check(not SaveManager.validate_state(bad), "save rejects malformed answer " + mutation)
		if mutation == "wrong_correctness":
			check(not lab.save_manager.save_slot("manual", bad) and FileAccess.get_file_as_bytes(lab.save_manager.storage_root.path_join("manual.json")) == manual_bytes, "invalid record cannot overwrite valid manual slot")
	lab.change_area(&"room", &"door")
	lab.sleep_manager.request()
	check(lab.sleep_manager.pending and lab.sleep_panel.visible, "answered class can use real before-bed manual save flow")
	lab._choose_sleep(true)
	check(not lab.sleep_manager.pending and clock.world_minutes > 1020, "before-bed save completes and sleep advances normally")
	check(await lab.load_slot("manual"), "manual made at bedtime reloads answered class")
	check(lab.sleep_manager.pending and lab.sleep_panel.visible and schedule.question_answers[question.id].option_id == "year_1930" and not schedule.question_answers[question.id].correct, "bedtime load restores incorrect choice exactly and offers pending sleep")
	lab._cancel_sleep()
	check(not lab.sleep_manager.pending and not lab.sleep_panel.visible, "cancelling optional sleep keeps answer")
	lab.debug_jump(1440 + 780)
	lab.change_area(&"classroom", &"door")
	lab._open_academics()
	await click(lab.academic_panel.attend_button)
	check(not panel.visible and clock.world_minutes == 1440 + 1020 and not schedule.question_answers[question.id].correct, "incorrect answer also remains final on subsequent afternoons")
	var old := answered.duplicate(true)
	old.academics.erase("question_answers")
	check(lab.save_manager.save_slot("manual", old) and await lab.load_slot("manual"), "older schema-three saves without question field load successfully")
	check(schedule.question_answers.is_empty() and clock.world_minutes == 1020 and schedule.present.size() == 1, "old save defaults unanswered without changing existing attendance")
	lab.debug_jump(1440 + 780)
	lab._open_academics()
	await click(lab.academic_panel.attend_button)
	check(panel.visible, "upgraded save gets question next eligible afternoon")
	lab.change_area(&"university", &"door")
	check(not panel.visible and schedule.question_answers.is_empty(), "internal area replacement cancels pending question safely")
	for minutes in [800, 1440 + 1019]:
		await prepare(minutes, false)
		await click(lab.academic_panel.attend_button)
		for line in range(lab.PROFESSOR_INTRO.line_keys.size()):
			lab.dialogue_panel.advance()
		check(panel.visible and not schedule.professor_intro_seen and clock.world_minutes == minutes, "first attended afternoon completes introduction then awaits answer at %d" % minutes)
		await key(KEY_ESCAPE)
		check(schedule.present.is_empty() and not schedule.professor_intro_seen, "cancelling fallback question awards no introduction or attendance")
		await click(lab.academic_panel.attend_button)
		for line in range(lab.PROFESSOR_INTRO.line_keys.size()):
			lab.dialogue_panel.advance()
		await key(KEY_2)
		check(schedule.professor_intro_seen and schedule.question_answers[question.id].answered_at == minutes and clock.world_minutes == minutes / 1440 * 1440 + 1020, "fallback answer commits introduction presence and response atomically")
		check(schedule.status(0, schedule.sessions[0]) == "absent", "fallback preserves missed morning")
	for minutes in [5 * 1440 + 780, 30 * 1440 + 780, 1020]:
		await prepare(minutes)
		lab._attend_class()
		check(not panel.visible and schedule.question_answers.is_empty(), "no question outside teaching afternoon %d" % minutes)
	await prepare()
	await click(lab.academic_panel.attend_button)
	root.size = Vector2i(960, 540)
	await settle()
	check(panel.get_global_rect().size == Vector2(960, 540) and panel.options.all(func(button: Button) -> bool: return root.get_visible_rect().encloses(button.get_global_rect())), "four alternatives remain on-screen at notebook resolution")
	await key(KEY_2)
	check(root.get_visible_rect().encloses(panel.close_button.get_global_rect()) and root.get_visible_rect().encloses(panel.reaction.get_global_rect()), "reaction and continue button fit notebook viewport")
	await capture("class_question_notebook")
	await key(KEY_ENTER)
	check(not panel.visible and SaveManager.validate_state(lab.snapshot()), "small-window keyboard completion remains functional")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
