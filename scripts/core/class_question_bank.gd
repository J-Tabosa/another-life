class_name ClassQuestionBank
extends RefCounted

const PATH := "res://data/questions/history.json"
static var _first_question: Dictionary = {}


static func valid_bank(data: Variant) -> bool:
	if not data is Dictionary or not data.get("first_question_id") is String or not data.get("questions") is Array or data.questions.is_empty():
		return false
	var ids: Array[String] = []
	for question in data.questions:
		if not question is Dictionary:
			return false
		for field in ["id", "prompt_key", "correct_option_id", "correct_reaction_key", "incorrect_reaction_key", "explanation_key", "source_url"]:
			if not question.get(field) is String or question[field].is_empty():
				return false
		if question.id in ids or not question.get("options") is Array or question.options.size() != 4:
			return false
		ids.append(question.id)
		var options: Array[String] = []
		for option in question.options:
			if not option is Dictionary or not option.get("id") is String or not option.get("label_key") is String:
				return false
			if option.id.is_empty() or option.label_key.is_empty() or option.id in options:
				return false
			options.append(option.id)
		if question.correct_option_id not in options:
			return false
	return data.first_question_id in ids


static func first() -> Dictionary:
	if not _first_question.is_empty():
		return _first_question.duplicate(true)
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not valid_bank(data):
		return {}
	for question in data.questions:
		if question.id == data.first_question_id:
			_first_question = question.duplicate(true)
			return _first_question.duplicate(true)
	return {}


static func has_option(question: Dictionary, option_id: String) -> bool:
	for option in question.get("options", []):
		if option.id == option_id:
			return true
	return false
