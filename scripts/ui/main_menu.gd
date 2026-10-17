extends Control
## Title screen with a slowly drifting view of the market.

const PAN_SPEED := 6.0

@onready var background: TextureRect = $Background
@onready var buttons: VBoxContainer = $Menu/Buttons
@onready var new_game_button: Button = $Menu/Buttons/NewGame
@onready var options: PanelContainer = $OptionsMenu
@onready var title_block: Control = $Menu

var _pan_dir := 1.0


func _ready() -> void:
	Game.input_locked = false
	options.hide()
	new_game_button.pressed.connect(Game.start_new_game)
	var cont := $Menu/Buttons/Continue as Button
	cont.disabled = not Game.has_save()
	cont.pressed.connect(func(): Game.load_game())
	if Game.has_save():
		var info := Game.save_info()
		cont.tooltip_text = "Nivel %d  ·  %s" % [int(info.get("level", 1)), String(info.get("saved_at", "")).replace("T", " ")]
	$Menu/Buttons/Options.pressed.connect(_open_options)
	$Menu/Buttons/Quit.pressed.connect(Game.quit_game)
	$Menu/Buttons/Dev.pressed.connect(_open_password)
	options.closed.connect(_on_options_closed)
	if Game.has_save():
		cont.grab_focus()
	else:
		new_game_button.grab_focus()
	# Intro: fade the menu in.
	title_block.modulate.a = 0.0
	create_tween().tween_property(title_block, "modulate:a", 1.0, 0.9).set_delay(0.2)


func _process(delta: float) -> void:
	# Ping-pong pan across the backdrop.
	var max_x := background.size.x - size.x
	background.position.x -= PAN_SPEED * delta * _pan_dir
	if background.position.x < -max_x:
		_pan_dir = -1.0
	elif background.position.x > 0.0:
		_pan_dir = 1.0


func _open_options() -> void:
	$Menu.hide()
	options.open()


func _on_options_closed() -> void:
	$Menu.show()
	$Menu/Buttons/Options.grab_focus()


# --- developer access -----------------------------------------------------------

var _pw_panel: PanelContainer
var _pw_edit: LineEdit
var _pw_msg: Label


func _open_password() -> void:
	if _pw_panel == null:
		_build_password_dialog()
	$Menu.hide()
	_pw_panel.show()
	_pw_edit.text = ""
	_pw_msg.text = "Ingresa la clave de desarrollador"
	_pw_msg.add_theme_color_override("font_color", Color(0.85, 0.78, 0.65))
	_pw_edit.grab_focus()


func _build_password_dialog() -> void:
	_pw_panel = PanelContainer.new()
	_pw_panel.size = Vector2(200, 100)
	add_child(_pw_panel)
	_pw_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_pw_panel.add_child(vb)
	var title := Label.new()
	title.text = "Modo desarrollador"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.7, 0.85, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	_pw_msg = Label.new()
	_pw_msg.add_theme_font_size_override("font_size", 8)
	_pw_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_pw_msg)
	_pw_edit = LineEdit.new()
	_pw_edit.secret = true
	_pw_edit.placeholder_text = "Clave"
	_pw_edit.add_theme_font_size_override("font_size", 10)
	_pw_edit.text_submitted.connect(func(_t): _try_password())
	vb.add_child(_pw_edit)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 6)
	vb.add_child(hb)
	var ok := Button.new(); ok.text = "Entrar"; ok.pressed.connect(_try_password)
	var cancel := Button.new(); cancel.text = "Cancelar"; cancel.pressed.connect(_close_password)
	hb.add_child(ok); hb.add_child(cancel)


func _try_password() -> void:
	if Game.check_dev_password(_pw_edit.text):
		_pw_msg.text = "Acceso concedido"
		_pw_msg.add_theme_color_override("font_color", Color(0.6, 1, 0.6))
		Game.start_editor()
	else:
		_pw_msg.text = "Clave incorrecta"
		_pw_msg.add_theme_color_override("font_color", Color(1, 0.45, 0.4))
		_pw_edit.text = ""
		var t := create_tween()
		var x := _pw_panel.position.x
		for i in 4:
			t.tween_property(_pw_panel, "position:x", x + (4 if i % 2 == 0 else -4), 0.04)
		t.tween_property(_pw_panel, "position:x", x, 0.04)


func _close_password() -> void:
	_pw_panel.hide()
	$Menu.show()
	$Menu/Buttons/Dev.grab_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	if _pw_panel and _pw_panel.visible and event.is_action_pressed("ui_cancel"):
		_close_password()
