extends Node
## Global game state: scene transitions, settings and UI event bus.

signal dialogue_requested(speaker: String, lines: PackedStringArray)
signal dialogue_finished
signal toast_requested(text: String)
signal location_entered(location_name: String)

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const FIRST_LEVEL := "res://scenes/world/market.tscn"
const SETTINGS_PATH := "user://settings.cfg"

## True while a dialogue or menu should block player input.
var input_locked := false

var settings := {
	"master_volume": 0.8,
	"fullscreen": false,
}

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_fade()
	load_settings()


func _build_fade() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.05, 0.03, 0.04, 1.0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.modulate.a = 0.0
	_fade_layer.add_child(_fade_rect)


func change_scene(path: String, duration := 0.35) -> void:
	if _busy:
		return
	_busy = true
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, duration)
	await tween.finished
	get_tree().paused = false
	input_locked = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 0.0, duration)
	await tween.finished
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func start_new_game() -> void:
	change_scene(FIRST_LEVEL)


func go_to_main_menu() -> void:
	change_scene(MAIN_MENU)


func quit_game() -> void:
	get_tree().quit()


# --- UI bus -------------------------------------------------------------------

func show_dialogue(speaker: String, lines: PackedStringArray) -> void:
	dialogue_requested.emit(speaker, lines)


func toast(text: String) -> void:
	toast_requested.emit(text)


# --- Settings -----------------------------------------------------------------

func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	apply_settings()
	save_settings()


func apply_settings() -> void:
	var bus := AudioServer.get_bus_index("Master")
	var vol: float = settings["master_volume"]
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(vol, 0.0001)))
	AudioServer.set_bus_mute(bus, vol <= 0.0)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if settings["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		for key in settings.keys():
			settings[key] = cfg.get_value("settings", key, settings[key])
	apply_settings()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key in settings.keys():
		cfg.set_value("settings", key, settings[key])
	cfg.save(SETTINGS_PATH)
