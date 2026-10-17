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
