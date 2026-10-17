extends Node
## Global game state: scene transitions, settings and UI event bus.

signal dialogue_requested(speaker: String, lines: PackedStringArray)
signal dialogue_finished
signal toast_requested(text: String)
signal location_entered(location_name: String)
signal quest_board_requested
signal quests_changed
signal stats_changed
signal boss_engaged(monster: Node)
signal monster_killed(monster: Node)

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const FIRST_LEVEL := "res://scenes/world/world.tscn"
const SETTINGS_PATH := "user://settings.cfg"

## True while a dialogue or menu should block player input.
var input_locked := false

## Developer map editor ------------------------------------------------------
const DEV_PASSWORD_SHA256 := "c384eb6226bf1f9ebc7ce8897ce70bcbfa9834327b2cf02e3414b0d1b84cd63a"
const EDITOR_SCENE := "res://scenes/editor/map_editor.tscn"
## True while the map editor is open: NPCs and animals freeze.
var editing := false

## Spawn marker the next loaded scene should place the player at.
var pending_spawn := ""
## Exterior door to return to when leaving an interior.
var return_spawn := ""

var gold := 120
var max_hp := 10
var player_hp := 10
var max_stamina := 100.0
var stamina := 100.0
var potions := 3
var kills := {}
var quests: Array[Dictionary] = [
	{"id": "slimes", "rank": "E", "title": "Limos en el camino", "giver": "Guardia de la puerta norte", "zone": "Llanura de Valdoria",
	 "desc": "Varios limos bloquean el camino al norte de la ciudad. Elimina 5 para que los viajeros puedan pasar.", "reward": 40, "state": "open"},
	{"id": "hares", "rank": "E", "title": "Liebres en los cultivos", "giver": "Tomás el frutero", "zone": "Granjas del Este",
	 "desc": "Las liebres se están comiendo los repollos de las granjas. Ahuyéntalas antes de que arruinen la cosecha.", "reward": 50, "state": "open"},
	{"id": "goblins", "rank": "D", "title": "El campamento goblin", "giver": "Capitana Brenna", "zone": "Llanura de Valdoria",
	 "desc": "Un grupo de goblins acampa al oeste de la llanura y asalta a los viajeros. Dispérsalos.", "reward": 120, "state": "open"},
	{"id": "gnolls", "rank": "D", "title": "Gnolls en las colinas", "giver": "Gremio de Cazadores", "zone": "Llanura de Valdoria",
	 "desc": "Se han visto gnolls cerca de las colinas del este. Son rápidos y atacan en grupo.", "reward": 150, "state": "open"},
	{"id": "pier", "rank": "C", "title": "Algo bajo el muelle", "giver": "Pescador Ulrik", "zone": "Puerto de Valdoria",
	 "desc": "Las redes aparecen rotas cada mañana y nadie sabe por qué. Investiga qué ocurre bajo el muelle.", "reward": 300, "state": "open"},
	{"id": "golem", "rank": "B", "title": "El guardián de las ruinas", "giver": "Maestra del Gremio Ysolde", "zone": "Llanura de Valdoria",
	 "desc": "Un gólem de piedra despertó en las ruinas del centro de la llanura. Nadie que se haya acercado ha vuelto ileso.", "reward": 600, "state": "open"},
	{"id": "ent", "rank": "B", "title": "El árbol que camina", "giver": "Morga la vidente", "zone": "Llanura de Valdoria",
	 "desc": "En el bosque del noroeste hay un árbol antiguo que se mueve de noche. Las cartas dicen que protege algo.", "reward": 800, "state": "open"},
]

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
	pending_spawn = ""
	return_spawn = ""
	change_scene(FIRST_LEVEL)


## Moves to another scene and places the player at the named spawn marker.
func travel(scene_path: String, spawn: String, remember_return := "") -> void:
	if remember_return != "":
		return_spawn = remember_return
	pending_spawn = spawn
	change_scene(scene_path, 0.25)


# --- Player stats ---------------------------------------------------------------

func damage_player(amount: int) -> void:
	player_hp = maxi(player_hp - amount, 0)
	stats_changed.emit()


func heal_player(amount: int) -> void:
	player_hp = mini(player_hp + amount, max_hp)
	stats_changed.emit()


func set_stamina(v: float) -> void:
	var nv := clampf(v, 0.0, max_stamina)
	if absf(nv - stamina) > 0.01:
		stamina = nv
		stats_changed.emit()


func add_gold(n: int) -> void:
	gold += n
	stats_changed.emit()


func use_potion() -> void:
	if potions <= 0:
		toast("No te quedan pociones.")
		return
	if player_hp >= max_hp:
		toast("Ya tienes la vida completa.")
		return
	potions -= 1
	heal_player(4)
	toast("Usaste una poción. (+4 de vida)")


## The player fell: fade out and wake up at the map's safe spot with full health.
func player_died() -> void:
	toast("Despiertas en un lugar seguro...")
	player_hp = max_hp
	stamina = max_stamina
	var scene := get_tree().current_scene
	pending_spawn = "respawn"
	change_scene(scene.scene_file_path, 0.6)


## Small floating text in the world (damage numbers, gold...).
func spawn_popup(pos: Vector2, text: String, color: Color) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var p := Node2D.new()
	p.set_script(load("res://scripts/ui/popup_text.gd"))
	p.set("text", text)
	p.set("color", color)
	p.position = pos
	p.z_index = 70
	scene.add_child(p)


func check_dev_password(text: String) -> bool:
	return text.strip_edges().sha256_text() == DEV_PASSWORD_SHA256


## Opens the overworld in edit mode with the map editor on top.
func start_editor(scene_path := FIRST_LEVEL) -> void:
	if _busy:
		return
	editing = true
	pending_spawn = ""
	change_scene(scene_path)
	await get_tree().create_timer(0.8).timeout
	var ed: Node = load(EDITOR_SCENE).instantiate()
	get_tree().root.add_child(ed)


func stop_editing() -> void:
	editing = false
	input_locked = false


func accept_quest(id: String) -> void:
	for q in quests:
		if q["id"] == id and q["state"] == "open":
			q["state"] = "accepted"
			quests_changed.emit()
			toast("Pedido aceptado: %s" % q["title"])
			return


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
