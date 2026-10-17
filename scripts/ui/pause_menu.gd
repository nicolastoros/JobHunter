extends CanvasLayer
## Pause overlay: resume, options, back to title, quit.

@onready var root: Control = $Root
@onready var panel: PanelContainer = $Root/Panel
@onready var options: PanelContainer = $Root/OptionsMenu
@onready var resume_button: Button = $Root/Panel/VBox/Resume


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.hide()
	options.hide()
	resume_button.pressed.connect(resume)
	$Root/Panel/VBox/Options.pressed.connect(_open_options)
	$Root/Panel/VBox/MainMenu.pressed.connect(Game.go_to_main_menu)
	$Root/Panel/VBox/Quit.pressed.connect(Game.quit_game)
	options.closed.connect(_on_options_closed)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	get_viewport().set_input_as_handled()
	if not root.visible:
		if not Game.input_locked:
			_pause()
	elif options.visible:
		options.close()
	else:
		resume()


func _pause() -> void:
	get_tree().paused = true
	root.show()
	panel.show()
	resume_button.grab_focus()


func resume() -> void:
	root.hide()
	options.hide()
	get_tree().paused = false


func _open_options() -> void:
	panel.hide()
	options.open()


func _on_options_closed() -> void:
	panel.show()
	$Root/Panel/VBox/Options.grab_focus()
