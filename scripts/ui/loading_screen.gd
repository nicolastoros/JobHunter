extends Control
## First screen: loads the maps, characters and sprites once (with a progress bar) and keeps them in
## memory, so moving between maps later is quick. Then opens the main menu.

const NEXT := "res://scenes/ui/main_menu.tscn"
const DIRS := ["res://resources/sprite_frames/monsters", "res://resources/sprite_frames/companions",
	"res://resources/sprite_frames", "res://scenes/interiors"]
const FIRST := ["res://scenes/ui/main_menu.tscn", "res://scenes/ui/hud.tscn", "res://scenes/ui/pause_menu.tscn",
	"res://scenes/characters/player.tscn", "res://scenes/monsters/monster.tscn", "res://scenes/npc/hunter.tscn",
	"res://scenes/objects/chest.tscn"]
const MAPS := ["res://scenes/world/world.tscn", "res://scenes/world/field.tscn", "res://scenes/world/forest.tscn"]
const TIPS := ["Las pociones se rellenan en la ciudad y en los refugios del mapa.",
	"Tab fija una presa; la rueda del ratón cambia de presa.",
	"Kara, la herrera, mejora tu equipo y compra lo que no necesites.",
	"Cada día salen a cazar cazadores distintos. Algunos descansan en la ciudad.",
	"Al norte del Bosque de los Susurros empieza el Bosque Profundo.",
	"Las rachas de caza dan más renombre en el Gremio.",
	"En el establo de las granjas hay compañeros que te ayudan a cazar."]

var _queue: Array[String] = []
var _done := 0
var _bar: ColorRect
var _bar_bg: ColorRect
var _label: Label
var _tip: Label
var _tip_left := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.05, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(300, 0)
	box.position = -Vector2(150, 50)
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var title := Label.new()
	title.text = "Crónicas del Cazador"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.86, 0.5))
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color(0.18, 0.1, 0.05))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(300, 10)
	box.add_child(holder)
	_bar_bg = ColorRect.new()
	_bar_bg.color = Color(0.25, 0.17, 0.12)
	_bar_bg.size = Vector2(300, 10)
	holder.add_child(_bar_bg)
	_bar = ColorRect.new()
	_bar.color = Color(0.9, 0.65, 0.2)
	_bar.position = Vector2(2, 2)
	_bar.size = Vector2(0, 6)
	holder.add_child(_bar)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", Color(0.85, 0.78, 0.65))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_label)
	_tip = Label.new()
	_tip.add_theme_font_size_override("font_size", 8)
	_tip.add_theme_color_override("font_color", Color(0.65, 0.6, 0.5))
	_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip.custom_minimum_size = Vector2(300, 0)
	box.add_child(_tip)
	_next_tip()
	_queue.append_array(FIRST)
	for d in DIRS:
		_queue.append_array(_list(d))
	_queue.append_array(MAPS)
	_load_all.call_deferred()


func _process(delta: float) -> void:
	_tip_left -= delta
	if _tip_left <= 0.0:
		_next_tip()


func _next_tip() -> void:
	_tip_left = 3.5
	_tip.text = "Consejo: " + TIPS.pick_random()


static func _list(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f in ResourceLoader.list_directory(dir):   # also works in exported builds
		if f.ends_with(".tres") or f.ends_with(".tscn"):
			out.append(dir.path_join(f))
	return out


func _load_all() -> void:
	var total := _queue.size()
	for path in _queue:
		_label.text = "Cargando %s…  %d %%" % [_what(path), int(100.0 * _done / maxf(1, total))]
		await get_tree().process_frame
		if ResourceLoader.exists(path):
			var res := load(path)
			if res:
				Game.preloaded.append(res)
		_done += 1
		_bar.size.x = 296.0 * _done / maxf(1, total)
	_label.text = "¡Listo!"
	await get_tree().create_timer(0.2).timeout
	Game.change_scene(NEXT)


static func _what(path: String) -> String:
	if path.contains("/world/"):
		return {"world.tscn": "Valdoria", "field.tscn": "la Llanura", "forest.tscn": "el Bosque Profundo"}.get(path.get_file(), "el mundo")
	if path.contains("monsters"):
		return "monstruos"
	if path.contains("interiors"):
		return "interiores"
	if path.contains("sprite_frames"):
		return "personajes"
	return "el juego"
