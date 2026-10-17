extends Control
## Player status HUD built from the UI pack: portrait panel with health/mana/stamina bars,
## level & experience, gold & potions, action bar with the six skills (cooldowns), and a boss health bar.

const PANEL := "res://assets/ui/pack/character_panel.png"
const ACTION := "res://assets/ui/pack/Action_panel.png"
# bar rows inside the 84x30 portrait panel (from the full-bars variant at x=98)
const BARS := {"hp": [28, 8, 52], "mana": [30, 13, 43], "stamina": [29, 18, 38]}
const SLOT_PITCH := 16.0

var _clips := {}
var _gold: Label
var _potions: Label
var _level: Label
var _xp_fill: ColorRect
var _skill_icons: Array[TextureRect] = []
var _skill_cd: Array[ColorRect] = []
var _boss_root: Control
var _boss_fill: ColorRect
var _boss_name: Label
var _boss: Node = null
var _streak: Label
## The action bar (sword, potion, skills 1-6); touch controls tap its slots.
var action_bar: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_tex := load(PANEL) as Texture2D
	var base := TextureRect.new()
	base.texture = _atlas(panel_tex, Rect2(2, 2, 84, 30))
	base.position = Vector2(4, 4)
	add_child(base)
	for k in BARS:
		var b: Array = BARS[k]
		var clip := Control.new()
		clip.clip_contents = true
		clip.position = Vector2(b[0], b[1])
		clip.size = Vector2(b[2], 2)
		base.add_child(clip)
		var strip := TextureRect.new()
		strip.texture = _atlas(panel_tex, Rect2(98 + b[0], 2 + b[1], b[2], 2))
		clip.add_child(strip)
		_clips[k] = clip
	# experience: a thin bar under the portrait panel
	var xp_back := ColorRect.new()
	xp_back.color = Color(0.1, 0.07, 0.05, 0.85)
	xp_back.position = Vector2(31, 29)
	xp_back.size = Vector2(46, 2)
	add_child(xp_back)
	_xp_fill = ColorRect.new()
	_xp_fill.color = Color(0.95, 0.8, 0.35)
	_xp_fill.position = xp_back.position
	_xp_fill.size = Vector2(0, 2)
	add_child(_xp_fill)
	_level = _label(Vector2(6, 33), Color(0.95, 0.9, 0.75))
	_gold = _label(Vector2(31, 33), Color(1, 0.86, 0.4))
	_potions = _label(Vector2(66, 33), Color(1, 0.6, 0.6))
	_streak = _label(Vector2(6, 43), Color(1, 0.6, 0.25))
	_streak.add_theme_font_size_override("font_size", 8)
	# action bar: sword (J), potion (Q), skills 1-4
	var act := load(ACTION) as Texture2D
	var bar := TextureRect.new()
	bar.texture = _atlas(act, Rect2(12, 44, 168, 20))
	bar.size = Vector2(168, 20)
	add_child(bar)
	bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE)
	bar.position.y -= 4
	action_bar = bar
	var sword := TextureRect.new()
	sword.texture = _atlas(act, Rect2(129, 65, 14, 14))
	sword.position = Vector2(4, 3)
	bar.add_child(sword)
	var potion := TextureRect.new()
	potion.texture = _atlas(act, Rect2(179, 82, 9, 12))
	potion.position = Vector2(23, 4)
	bar.add_child(potion)
	for i in GameData.SKILLS.size():
		var t := TextureRect.new()
		t.texture = Game.icon_texture(GameData.SKILLS[i]["icon"])
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.size = Vector2(14, 14)
		t.position = Vector2(4 + SLOT_PITCH * (i + 2), 3)
		bar.add_child(t)
		_skill_icons.append(t)
		var cd := ColorRect.new()
		cd.color = Color(0.05, 0.03, 0.03, 0.65)
		cd.position = t.position
		cd.size = Vector2(14, 0)
		bar.add_child(cd)
		_skill_cd.append(cd)
	var keys := [[Vector2(11, 11), "J"], [Vector2(28, 11), "Q"]]
	for i in GameData.SKILLS.size():
		keys.append([Vector2(12 + SLOT_PITCH * (i + 2), 11), str(i + 1)])
	for pair in keys:
		var l := Label.new()
		l.text = pair[1]
		l.position = pair[0]
		l.add_theme_font_size_override("font_size", 6)
		l.add_theme_constant_override("outline_size", 3)
		bar.add_child(l)
	# boss bar
	_boss_root = Control.new()
	_boss_root.size = Vector2(200, 20)
	_boss_root.visible = false
	add_child(_boss_root)
	_boss_root.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE)
	_boss_root.position.y -= 54
	var back := ColorRect.new()
	back.color = Color(0.08, 0.05, 0.04, 0.85)
	back.size = Vector2(200, 7)
	back.position = Vector2(0, 12)
	_boss_root.add_child(back)
	_boss_fill = ColorRect.new()
	_boss_fill.color = Color(0.8, 0.18, 0.14)
	_boss_fill.position = Vector2(1, 13)
	_boss_fill.size = Vector2(198, 5)
	_boss_root.add_child(_boss_fill)
	_boss_name = Label.new()
	_boss_name.add_theme_font_size_override("font_size", 9)
	_boss_name.add_theme_constant_override("outline_size", 4)
	_boss_name.add_theme_color_override("font_color", Color(1, 0.85, 0.6))
	_boss_name.size = Vector2(200, 12)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_root.add_child(_boss_name)
	Game.stats_changed.connect(_refresh)
	Game.boss_engaged.connect(_on_boss)
	_refresh()


func _atlas(t: Texture2D, r: Rect2) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = t
	a.region = r
	return a


func _label(p: Vector2, c: Color) -> Label:
	var l := Label.new()
	l.position = p
	l.add_theme_font_size_override("font_size", 7)
	l.add_theme_color_override("font_color", c)
	l.add_theme_constant_override("outline_size", 3)
	add_child(l)
	return l


func _refresh() -> void:
	_set_bar("hp", float(Game.player_hp) / Game.max_hp)
	_set_bar("mana", Game.mana / Game.max_mana)
	_set_bar("stamina", Game.stamina / Game.max_stamina)
	_xp_fill.size.x = roundf(46.0 * float(Game.xp) / float(Game.xp_to_next()))
	_level.text = "Nv %d" % Game.level
	_gold.text = "%d oro" % Game.gold
	_potions.text = "x%d" % Game.potions


func _set_bar(k: String, frac: float) -> void:
	var b: Array = BARS[k]
	(_clips[k] as Control).size.x = roundf(b[2] * clampf(frac, 0.0, 1.0))


func _on_boss(m: Node) -> void:
	_boss = m
	_boss_root.visible = true
	_boss_name.text = "%s  ·  Nv %d" % [m.get("monster_name"), m.get("monster_level")]


func _process(_delta: float) -> void:
	var st := Game.streak()
	_streak.visible = st >= 2
	if st >= 2:
		_streak.text = "Racha x%d  (+%d %% renombre)" % [st, int(round((Game.streak_mult() - 1.0) * 100))]
	for i in GameData.SKILLS.size():
		var s: Dictionary = GameData.SKILLS[i]
		var known := Game.has_skill(s["id"])
		_skill_icons[i].modulate = Color(1, 1, 1, 1) if known and Game.mana >= float(s["mana"]) else Color(0.55, 0.55, 0.6, 0.55 if known else 0.22)
		var frac := Game.skill_cooldown_left(s["id"]) / Game.skill_cooldown(s["id"]) if known else 0.0
		_skill_cd[i].size.y = roundf(14.0 * frac)
		_skill_cd[i].position.y = 3.0 + 14.0 - _skill_cd[i].size.y
	if _boss == null:
		return
	if not is_instance_valid(_boss) or _boss.get("hp") <= 0 or _boss.get("state") == 6:
		_boss_root.visible = false
		_boss = null
		return
	var p := _boss.get_tree().get_first_node_in_group("player") as Node2D
	if p and p.global_position.distance_to((_boss as Node2D).global_position) > 260.0:
		_boss_root.visible = false
		_boss = null
		return
	_boss_fill.size.x = 198.0 * float(_boss.get("hp")) / float(_boss.get("max_hp"))
