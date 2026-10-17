extends CanvasLayer
## In-game HUD: location banner, toasts, control hints and the dialogue box.

const CHARS_PER_SECOND := 45.0

@onready var location_banner: Control = $LocationBanner
@onready var location_label: Label = $LocationBanner/VBox/Title
@onready var toast_panel: PanelContainer = $Toast
@onready var toast_label: Label = $Toast/Label
@onready var controls_hint: Label = $ControlsHint
@onready var dialogue_box: PanelContainer = $DialogueBox
@onready var speaker_label: Label = $DialogueBox/VBox/Speaker
@onready var text_label: Label = $DialogueBox/VBox/Text
@onready var continue_label: Label = $DialogueBox/Continue

var _lines: PackedStringArray = []
var _index := 0
var _typing_tween: Tween
var _toast_tween: Tween


func _ready() -> void:
	location_banner.modulate.a = 0.0
	toast_panel.visible = false
	dialogue_box.visible = false
	Game.location_entered.connect(_on_location_entered)
	Game.toast_requested.connect(_on_toast)
	Game.dialogue_requested.connect(_on_dialogue_requested)
	var t := create_tween()
	t.tween_interval(9.0)
	t.tween_property(controls_hint, "modulate:a", 0.0, 1.5)


func _process(_delta: float) -> void:
	if dialogue_box.visible:
		continue_label.visible = _is_line_complete() and fmod(Time.get_ticks_msec() / 400.0, 2.0) < 1.4


func _input(event: InputEvent) -> void:
	if not dialogue_box.visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		if _is_line_complete():
			_next_line()
		else:
			_typing_tween.kill()
			text_label.visible_ratio = 1.0


# --- Location banner ----------------------------------------------------------

func _on_location_entered(location_name: String) -> void:
	location_label.text = location_name
	var t := create_tween()
	t.tween_interval(0.4)
	t.tween_property(location_banner, "modulate:a", 1.0, 0.8)
	t.tween_interval(2.5)
	t.tween_property(location_banner, "modulate:a", 0.0, 1.0)


# --- Toasts -------------------------------------------------------------------

func _on_toast(text: String) -> void:
	toast_label.text = text
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.25)
	_toast_tween.tween_interval(2.5)
	_toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.5)
	_toast_tween.tween_callback(toast_panel.hide)


# --- Dialogue -----------------------------------------------------------------

func _on_dialogue_requested(speaker: String, lines: PackedStringArray) -> void:
	_lines = lines
	_index = -1
	speaker_label.text = speaker
	dialogue_box.visible = true
	Game.input_locked = true
	_next_line()


func _next_line() -> void:
	_index += 1
	if _index >= _lines.size():
		_close_dialogue()
		return
	text_label.text = _lines[_index]
	text_label.visible_ratio = 0.0
	if _typing_tween:
		_typing_tween.kill()
	_typing_tween = create_tween()
	_typing_tween.tween_property(text_label, "visible_ratio", 1.0, text_label.text.length() / CHARS_PER_SECOND)


func _is_line_complete() -> bool:
	return text_label.visible_ratio >= 1.0


func _close_dialogue() -> void:
	dialogue_box.visible = false
	# Release input on the next frame so the closing key press doesn't re-open the chat.
	await get_tree().process_frame
	Game.input_locked = false
	Game.dialogue_finished.emit()
