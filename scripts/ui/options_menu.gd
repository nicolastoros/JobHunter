extends PanelContainer
## Options panel shared by the main menu and the pause menu.

signal closed

@onready var volume_slider: HSlider = $VBox/Volume/Slider
@onready var volume_value: Label = $VBox/Volume/Value
@onready var fullscreen_check: CheckButton = $VBox/Fullscreen
@onready var back_button: Button = $VBox/Back


func _ready() -> void:
	volume_slider.value = Game.settings["master_volume"] * 100.0
	fullscreen_check.button_pressed = Game.settings["fullscreen"]
	_update_volume_label(volume_slider.value)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_check.toggled.connect(func(on: bool): Game.set_setting("fullscreen", on))
	back_button.pressed.connect(close)
	_add_sfx_slider()


func _add_sfx_slider() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var l := Label.new()
	l.text = "Efectos"
	l.custom_minimum_size = Vector2(56, 0)
	$VBox/Volume/Label.custom_minimum_size = Vector2(56, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.step = 5.0
	s.value = float(Game.settings.get("sfx_volume", 0.8)) * 100.0
	row.add_child(s)
	var v := Label.new()
	v.custom_minimum_size = Vector2(28, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.text = "%d%%" % int(s.value)
	row.add_child(v)
	s.value_changed.connect(func(x: float):
		v.text = "%d%%" % int(x)
		Game.set_setting("sfx_volume", x / 100.0)
		Game.sfx("coin", -6.0, 0.0))
	$VBox.add_child(row)
	$VBox.move_child(row, $VBox/Volume.get_index() + 1)
	offset_top -= 12
	offset_bottom += 12


func open() -> void:
	show()
	volume_slider.grab_focus()


func close() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _on_volume_changed(value: float) -> void:
	_update_volume_label(value)
	Game.set_setting("master_volume", value / 100.0)


func _update_volume_label(value: float) -> void:
	volume_value.text = "%d%%" % int(value)
