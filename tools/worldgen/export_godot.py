"""Exports the market layout to Godot 4 resources/scenes."""
import os
import struct
from PIL import Image
import market_layout as L
import npc_defs as N

ROOT = r"C:/Users/nicol/OneDrive/Documentos/JobHunter"
RES_TILES = "res://assets/sprites/market/tiles/"
RES_PROPS = "res://assets/sprites/market/props/"
RES_NPC = "res://assets/sprites/market/npc/"
RES_NATURE = "res://assets/sprites/nature/"
RES_SWORD = "res://assets/sprites/characters/swordsman/"

ATLASES = {L.WS: "Walls_street.png", L.DC: "Decorative_cracks.png"}
PROP_TEX = {L.OBJ: RES_PROPS + "Objects.png", L.SGL: RES_PROPS + "Objects_single.png", L.EXT: RES_NATURE + "exterior.png"}

POLY = {
    "full": "-8, -8, 8, -8, 8, 8, -8, 8",
    "bottom": "-8, 0, 8, 0, 8, 8, -8, 8",
    "left": "-8, -8, -4, -8, -4, 8, -8, 8",
    "right": "4, -8, 8, -8, 8, 8, 4, 8",
}


def w(path, text):
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def fmt(v):
    v = round(float(v), 3)
    return str(int(v)) if v == int(v) else str(v)


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


# ---------------------------------------------------------------------------
def tileset(m):
    out = ['[gd_resource type="TileSet" format=3]', ""]
    for sid, name in ATLASES.items():
        out.append('[ext_resource type="Texture2D" path="%s%s" id="tex_%d"]' % (RES_TILES, name, sid))
    out.append("")
    for sid, name in ATLASES.items():
        img = Image.open(os.path.join(ROOT, "assets/sprites/market/tiles", name)).convert("RGBA")
        out.append('[sub_resource type="TileSetAtlasSource" id="atlas_%d"]' % sid)
        out.append('texture = ExtResource("tex_%d")' % sid)
        for ty in range(img.height // 16):
            for tx in range(img.width // 16):
                if img.crop((tx * 16, ty * 16, tx * 16 + 16, ty * 16 + 16)).getbbox() is None:
                    continue
                out.append("%d:%d/0 = 0" % (tx, ty))
                kind = m.collide.get((sid, (tx, ty)))
                if kind:
                    out.append("%d:%d/0/physics_layer_0/polygon_0/points = PackedVector2Array(%s)" % (tx, ty, POLY[kind]))
        out.append("")
    out.append("[resource]")
    out.append("physics_layer_0/collision_layer = 1")
    out.append("physics_layer_0/collision_mask = 0")
    for sid in ATLASES:
        out.append('sources/%d = SubResource("atlas_%d")' % (sid, sid))
    w("resources/tilesets/market_tileset.tres", "\n".join(out) + "\n")


def tile_data(cells):
    b = bytearray(struct.pack("<H", 0))
    for (x, y), (src, (ax, ay)) in sorted(cells.items(), key=lambda kv: (kv[0][1], kv[0][0])):
        b += struct.pack("<hhHHHH", x, y, src, ax, ay, 0)
    return "PackedByteArray(" + ", ".join(str(v) for v in b) + ")"


# ---------------------------------------------------------------------------
class Frames:
    """Builds a SpriteFrames .tres from sheet regions."""

    def __init__(self):
        self.tex = []
        self.subs = []
        self.anims = []

    def tex_id(self, path):
        if path not in self.tex:
            self.tex.append(path)
        return "t%d" % self.tex.index(path)

    def anim(self, name, path, rects, fps, loop=True):
        # Drop empty cells (some sheet rows are shorter than others).
        img = Image.open(path.replace("res://", ROOT + "/")).convert("RGBA")
        rects = [r for r in rects if img.crop((r[0], r[1], r[0] + r[2], r[1] + r[3])).getbbox()]
        tid = self.tex_id(path)
        refs = []
        for r in rects:
            sid = "a%d" % len(self.subs)
            self.subs.append('[sub_resource type="AtlasTexture" id="%s"]\natlas = ExtResource("%s")\nregion = Rect2(%d, %d, %d, %d)\n' % (sid, tid, *r))
            refs.append('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % sid)
        self.anims.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %s\n}' % (
            ", ".join(refs), "true" if loop else "false", name, fmt(fps)))

    def text(self):
        out = ['[gd_resource type="SpriteFrames" format=3]', ""]
        for i, p in enumerate(self.tex):
            out.append('[ext_resource type="Texture2D" path="%s" id="t%d"]' % (p, i))
        out.append("")
        out += self.subs
        out.append("[resource]")
        out.append("animations = [%s]" % ", ".join(self.anims))
        return "\n".join(out) + "\n"


DIRS = ["down", "left", "right", "up"]


def swordsman_frames(level):
    f = Frames()
    base = RES_SWORD + "lvl%d/Swordsman_lvl%d_" % (level, level)
    sheets = [("idle", "Idle", 12, 8, True), ("walk", "Walk", 6, 10, True), ("run", "Run", 8, 12, True),
              ("attack", "attack", 8, 16, False), ("walk_attack", "Walk_Attack", 6, 14, False),
              ("run_attack", "Run_Attack", 8, 16, False), ("hurt", "Hurt", 5, 12, False), ("death", "Death", 7, 10, False)]
    for name, file, n, fps, loop in sheets:
        img = Image.open(os.path.join(ROOT, "assets/sprites/characters/swordsman/lvl%d/Swordsman_lvl%d_%s_with_shadow.png" % (level, level, file)))
        assert img.width == n * 64, (file, img.size)
        for r, d in enumerate(DIRS):
            f.anim("%s_%s" % (name, d), base + file + "_with_shadow.png", [(i * 64, r * 64, 64, 64) for i in range(n)], fps, loop)
    w("resources/sprite_frames/swordsman_lvl%d.tres" % level, f.text())


def npc_frames():
    offsets = {}
    for kind in N.TRADERS:
        d = N.trader(kind)
        f = Frames()
        f.anim("default", RES_NPC + os.path.basename(d["path"]), [(x, y, d["fw"], d["fh"]) for x, y in d["frames"]], d["fps"])
        w("resources/sprite_frames/npc_%s.tres" % kind, f.text())
        offsets[kind] = d["fh"] / 2 - d["foot"]
    for n in range(1, 6):
        d = N.citizen(n)
        f = Frames()
        for r, dname in enumerate(DIRS):
            f.anim("idle_" + dname, RES_NPC + os.path.basename(d["idle"]), [(i * 32, r * 32, 32, 32) for i in range(12)], 8)
            f.anim("walk_" + dname, RES_NPC + os.path.basename(d["walk"]), [(i * 32, r * 32, 32, 32) for i in range(6)], 8)
        w("resources/sprite_frames/npc_citizen%d.tres" % n, f.text())
        offsets["citizen%d" % n] = 16 - d["foot"]
    return offsets


# ---------------------------------------------------------------------------
NPC_FLAVOR = {
    "lute": ("Bardo Anselmo", ["♪ Oh, cazador de ojos fieros, que al bosque vas sin compañeros... ♪",
                               "¿Una moneda para el bardo? ¿No? Bueno, la música es gratis... por hoy."]),
    "flutist": ("Nell la flautista", ["Tocamos aquí cada día de mercado. La gente compra más contenta, ¿sabes?"]),
    "eater": ("Viajero hambriento", ["Mmm... El estofado de Rosa es lo mejor de todo Valdoria. *ñam*"]),
}
CITIZEN_LINES = [
    ["Dicen que algo grande ronda el bosque del norte. Yo no saldría de las murallas."],
    ["¡Qué día de mercado! Hace semanas que no veía tanta gente."],
    ["Si vas a cazar, pasa primero por la armería de Kara. Y por las pociones de Ezra."],
    ["Mi hermano se fue de cacería y volvió sin botas. No preguntes."],
    ["La vidente Morga nunca se equivoca... o eso dice ella."],
]


def scene(m, offsets):
    ext = []   # (type, path, id)
    subs = []  # text blocks
    nodes = []

    def ext_id(typ, path):
        for t, p, i in ext:
            if p == path:
                return i
        i = "%d_%s" % (len(ext) + 1, os.path.splitext(os.path.basename(path))[0].lower()[:12])
        ext.append((typ, path, i))
        return i

    shapes = {}

    def rect_shape(wd, ht):
        key = (round(wd, 2), round(ht, 2))
        if key not in shapes:
            sid = "Rect_%d" % len(shapes)
            shapes[key] = sid
            subs.append('[sub_resource type="RectangleShape2D" id="%s"]\nsize = Vector2(%s, %s)\n' % (sid, fmt(wd), fmt(ht)))
        return shapes[key]

    ts = ext_id("TileSet", "res://resources/tilesets/market_tileset.tres")
    script = ext_id("Script", "res://scripts/world/market.gd")
    player = ext_id("PackedScene", "res://scenes/characters/player.tscn")
    trader = ext_id("PackedScene", "res://scenes/npc/trader.tscn")
    citizen = ext_id("PackedScene", "res://scenes/npc/citizen.tscn")
    hud = ext_id("PackedScene", "res://scenes/ui/hud.tscn")
    pause = ext_id("PackedScene", "res://scenes/ui/pause_menu.tscn")
    exit_scr = ext_id("Script", "res://scripts/world/zone_exit.gd")

    nodes.append('[node name="Market" type="Node2D"]\nscript = ExtResource("%s")\nmap_size = Vector2i(%d, %d)\nlocation_name = "Mercado de Valdoria"\n' % (script, L.W, L.H))
    for name, cells, col in (("Ground", m.ground, False), ("GroundDetails", m.detail, False), ("Walls", m.walls, True)):
        nodes.append('[node name="%s" type="TileMapLayer" parent="."]\ntile_map_data = %s\ntile_set = ExtResource("%s")\n%s' % (
            name, tile_data(cells), ts, "" if col else "collision_enabled = false\n"))

    nodes.append('[node name="FloorDecor" type="Node2D" parent="."]\n')
    nodes.append('[node name="Entities" type="Node2D" parent="."]\ny_sort_enabled = true\n')
    nodes.append('[node name="Props" type="Node2D" parent="Entities"]\ny_sort_enabled = true\n')

    counts = {}
    for p in m.props:
        key = p["key"]
        counts[key] = counts.get(key, 0) + 1
        name = "".join(s.capitalize() for s in key.split("_")) + ("" if counts[key] == 1 else str(counts[key]))
        tex = ext_id("Texture2D", PROP_TEX[p["sheet"]])
        x0, y0, wd, ht = p["region"]
        ox, oy = p["origin"]
        px, py = p["pos"]
        sprite = 'texture = ExtResource("%s")\ncentered = false\noffset = Vector2(%s, %s)\nregion_enabled = true\nregion_rect = Rect2(%d, %d, %d, %d)\n' % (
            tex, fmt(-ox), fmt(-oy), x0, y0, wd, ht)
        if p["floor"]:
            nodes.append('[node name="%s" type="Sprite2D" parent="FloorDecor"]\nposition = Vector2(%s, %s)\n%s' % (name, fmt(px), fmt(py), sprite))
            continue
        if not p["feet"]:
            nodes.append('[node name="%s" type="Sprite2D" parent="Entities/Props"]\nposition = Vector2(%s, %s)\n%s' % (name, fmt(px), fmt(py), sprite))
            continue
        nodes.append('[node name="%s" type="StaticBody2D" parent="Entities/Props"]\nposition = Vector2(%s, %s)\ncollision_mask = 0\n' % (name, fmt(px), fmt(py)))
        nodes.append('[node name="Sprite2D" type="Sprite2D" parent="Entities/Props/%s"]\n%s' % (name, sprite))
        for i, (a, b, c, d) in enumerate(p["feet"]):
            sid = rect_shape(c - a, d - b)
            nodes.append('[node name="Shape%d" type="CollisionShape2D" parent="Entities/Props/%s"]\nposition = Vector2(%s, %s)\nshape = SubResource("%s")\n' % (
                i, name, fmt((a + c) / 2), fmt((b + d) / 2), sid))

    nodes.append('[node name="NPCs" type="Node2D" parent="Entities"]\ny_sort_enabled = true\n')
    used = {}
    for i, n in enumerate(m.npcs):
        k = n["kind"]
        frames = ext_id("SpriteFrames", "res://resources/sprite_frames/npc_%s.tres" % k)
        px, py = n["pos"]
        if k.startswith("citizen"):
            wx0, wy0, wx1, wy1 = n["wander"]
            nm = "Citizen%d" % (i + 1)
            lines = CITIZEN_LINES[i % len(CITIZEN_LINES)]
            nodes.append('[node name="%s" parent="Entities/NPCs" instance=ExtResource("%s")]\nposition = Vector2(%s, %s)\nframes = ExtResource("%s")\nsprite_offset_y = %s\nwander_rect = Rect2(%s, %s, %s, %s)\nnpc_name = "Ciudadano"\nlines = PackedStringArray(%s)\n' % (
                nm, citizen, fmt(px), fmt(py), frames, fmt(offsets[k]), fmt(wx0), fmt(wy0), fmt(wx1 - wx0), fmt(wy1 - wy0),
                ", ".join('"%s"' % esc(s) for s in lines)))
        else:
            if "name" in n:
                npc_name, lines = n["name"], [n["line"]]
            else:
                npc_name, lines = NPC_FLAVOR[k]
            base = "".join(s.capitalize() for s in k.split("_"))
            used[base] = used.get(base, 0) + 1
            nm = base + ("" if used[base] == 1 else str(used[base]))
            nodes.append('[node name="%s" parent="Entities/NPCs" instance=ExtResource("%s")]\nposition = Vector2(%s, %s)\nframes = ExtResource("%s")\nsprite_offset_y = %s\nnpc_name = "%s"\nlines = PackedStringArray(%s)\n' % (
                nm, trader, fmt(px), fmt(py), frames, fmt(offsets[k]), esc(npc_name), ", ".join('"%s"' % esc(s) for s in lines)))

    sx, sy = 24 * L.T, 31 * L.T
    nodes.append('[node name="Player" parent="Entities" instance=ExtResource("%s")]\nposition = Vector2(%d, %d)\n' % (player, sx, sy))

    # Gate exits + invisible blockers beyond the map edge
    gx0, gx1 = L.GATE_X0 * L.T, (L.GATE_X1 + 1) * L.T
    gw = gx1 - gx0
    blk = rect_shape(gw, 16)
    trig = rect_shape(gw, 12)
    nodes.append('[node name="Bounds" type="StaticBody2D" parent="."]\ncollision_mask = 0\n')
    nodes.append('[node name="NorthGate" type="CollisionShape2D" parent="Bounds"]\nposition = Vector2(%s, -8)\nshape = SubResource("%s")\n' % (fmt(gx0 + gw / 2), blk))
    nodes.append('[node name="SouthGate" type="CollisionShape2D" parent="Bounds"]\nposition = Vector2(%s, %d)\nshape = SubResource("%s")\n' % (fmt(gx0 + gw / 2), L.H * L.T + 8, blk))
    for nm, y, msg in (("NorthExit", 8, "Bosque Sombrío — Las cacerías llegarán pronto."),
                       ("SouthExit", L.H * L.T - 8, "Camino Real — Aún no puedes abandonar Valdoria.")):
        nodes.append('[node name="%s" type="Area2D" parent="."]\nposition = Vector2(%s, %d)\ncollision_layer = 0\ncollision_mask = 2\nmonitorable = false\nscript = ExtResource("%s")\nmessage = "%s"\n' % (
            nm, fmt(gx0 + gw / 2), y, exit_scr, esc(msg)))
        nodes.append('[node name="CollisionShape2D" type="CollisionShape2D" parent="%s"]\nshape = SubResource("%s")\n' % (nm, trig))

    nodes.append('[node name="HUD" parent="." instance=ExtResource("%s")]\n' % hud)
    nodes.append('[node name="PauseMenu" parent="." instance=ExtResource("%s")]\n' % pause)

    out = ['[gd_scene format=3]', ""]
    for t, p, i in ext:
        out.append('[ext_resource type="%s" path="%s" id="%s"]' % (t, p, i))
    out.append("")
    out += subs
    out += nodes
    w("scenes/world/market.tscn", "\n".join(out))


def menu_background():
    import preview
    path = os.path.join(ROOT, "assets/ui/menu_bg.png")
    preview.main(path, show_col=False, scale=1, player=None)


if __name__ == "__main__":
    m = L.build()
    tileset(m)
    for lv in (1, 2, 3):
        swordsman_frames(lv)
    offs = npc_frames()
    scene(m, offs)
    menu_background()
    print("ok", len(m.props), "props", len(m.npcs), "npcs")
