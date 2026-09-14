extends Node

signal question_requested(question: String, answer: String, challenge_id: String)
signal question_closed

var current_question_id: String = ""
var current_answer: String = ""
var current_callback: Callable = Callable()

var ui_root: CanvasLayer
var panel: PanelContainer
var question_label: Label
var answer_input: LineEdit
var submit_button: Button
var close_button: Button


func _ready() -> void:
	_build_ui()
	_hide_ui()


func _build_ui() -> void:
	ui_root = CanvasLayer.new()
	ui_root.name = "ChallengeUI"
	add_child(ui_root)

	panel = PanelContainer.new()
	panel.name = "ChallengePanel"
	panel.custom_minimum_size = Vector2(420, 220)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -210
	panel.offset_top = -110
	panel.offset_right = 210
	panel.offset_bottom = 110
	ui_root.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.name = "Content"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "Desafio"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	question_label = Label.new()
	question_label.text = "Pergunta"
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.custom_minimum_size = Vector2(0, 90)
	vbox.add_child(question_label)

	answer_input = LineEdit.new()
	answer_input.placeholder_text = "Digite a resposta..."
	answer_input.max_length = 128
	vbox.add_child(answer_input)

	var buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 10)
	vbox.add_child(buttons)

	close_button = Button.new()
	close_button.text = "Fechar"
	buttons.add_child(close_button)

	submit_button = Button.new()
	submit_button.text = "Responder"
	buttons.add_child(submit_button)

	close_button.pressed.connect(_on_close_pressed)
	submit_button.pressed.connect(_on_submit_pressed)
	answer_input.text_submitted.connect(_on_answer_submitted)

	answer_input.grab_focus()
	_hide_ui()


func show_question(challenge_id: String, question: String, answer: String, callback: Callable) -> void:
	current_question_id = challenge_id
	current_answer = answer.strip_edges().to_lower()
	current_callback = callback
	question_label.text = question
	answer_input.text = ""
	answer_input.grab_focus()
	_show_ui()
	question_requested.emit(question, answer, challenge_id)


func _show_ui() -> void:
	if panel:
		panel.visible = true
	if answer_input:
		answer_input.grab_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _hide_ui() -> void:
	if panel:
		panel.visible = false
	if answer_input:
		answer_input.text = ""
	question_closed.emit()


func _on_submit_pressed() -> void:
	_submit_answer(answer_input.text)


func _on_answer_submitted(_text: String) -> void:
	_submit_answer(_text)


func _submit_answer(response: String) -> void:
	if current_callback.is_valid() and response.strip_edges().to_lower() == current_answer:
		var callback_copy = current_callback
		current_question_id = ""
		current_answer = ""
		current_callback = Callable()
		_hide_ui()
		callback_copy.call()
		return
	
	if current_answer.is_empty():
		_hide_ui()
		return
	
	question_label.text = "Resposta errada. Tente novamente."
	answer_input.text = ""
	answer_input.grab_focus()


func _on_close_pressed() -> void:
	current_question_id = ""
	current_answer = ""
	current_callback = Callable()
	_hide_ui()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
