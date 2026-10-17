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
	$Menu/Buttons/Options.pressed.connect(_open_options)
	$Menu/Buttons/Quit.pressed.connect(Game.quit_game)
	options.closed.connect(_on_options_closed)
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
