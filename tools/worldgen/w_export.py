"""Export the generated world to Godot: assets, tileset, sprite frames and world.tscn."""
import os, shutil, struct, glob
from PIL import Image
import w_build
import w_common as C
import w_terrain as WT
import w_props as WP
import w_layout as WL

ROOT = C.ROOT
LAYERS = [("water", False), ("water_fx", False), ("ground", False), ("ground_overlay", False), ("road", False),
          ("detail", False), ("water_city", True), ("rim", True), ("coast", False), ("dock", False), ("dock_fx", False),
          ("fence", True), ("walls", True), ("towers", True), ("solids", True)]
POLY = {"full": "-8, -8, 8, -8, 8, 8, -8, 8", "bottom": "-8, 0, 8, 0, 8, 8, -8, 8",
        "left": "-8, -8, -4, -8, -4, 8, -8, 8", "right": "4, -8, 8, -8, 8, 8, 4, 8"}
SOLID = (C.MW, (14, 8))


def fmt(v):
    v = round(float(v), 3)
    return str(int(v)) if v == int(v) else str(v)


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def write(rel, text):
    p = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


# ---------------------------------------------------------------------------
_copied = {}


def res_for_raw(raw_abs):
    """Copy a raw asset image into the project (once) and return its res:// path."""
    raw_abs = os.path.normpath(raw_abs)
    if raw_abs in _copied:
        return _copied[raw_abs]
    rel = os.path.relpath(raw_abs, os.path.normpath(C.RAW)).replace("\\", "/")
    pack = rel.split("/")[0]
    proj = None
    for k, (r, p) in C.SOURCES.items():
        if os.path.normpath(os.path.join(C.RAW, r)) == raw_abs:
            proj = p
    for k, (r, p) in WP.SHEETS.items():
        if r and os.path.normpath(os.path.join(C.RAW, r)) == raw_abs:
            proj = p
    if proj is None:
        folder = {"market": "market/npc", "farm": "farm/actors", "fishing": "port/actors", "training": "training/actors",
                  "animals": "animals", "house": "nature", "guild": "guild/actors", "campfire_asset": "field/camp",
                  "grassland_01": "field", "trees_01": "field"}.get(pack) or ("monsters/" + pack.replace("mon_", ""))
        proj = "assets/sprites/%s/%s" % (folder, os.path.basename(raw_abs))
    dst = os.path.join(ROOT, proj)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    if not os.path.exists(dst) or os.path.getmtime(dst) < os.path.getmtime(raw_abs):
        shutil.copy2(raw_abs, dst)
    _copied[raw_abs] = "res://" + proj
    return _copied[raw_abs]


def res_for_image(path):
    path = os.path.normpath(path)
    if path.startswith(os.path.normpath(ROOT)):
        return "res://" + os.path.relpath(path, os.path.normpath(ROOT)).replace("\\", "/")
    return res_for_raw(path)


# ---------------------------------------------------------------------------
def tileset(w, out_path="resources/tilesets/world_tileset.tres"):
    anims = C.load_tile_anims()
    used = {}
    for name, _ in LAYERS:
        for (src, at, alt) in w.layers.get(name, {}).values():
            used.setdefault(src, set()).add(at)
    used.setdefault(SOLID[0], set()).add(SOLID[1])
    out = ['[gd_resource type="TileSet" format=3]', ""]
    for sid in sorted(used):
        out.append('[ext_resource type="Texture2D" path="%s" id="tex_%d"]' % (res_for_raw(os.path.join(C.RAW, C.SOURCES[sid][0])), sid))
    out.append("")
    for sid in sorted(used):
        out.append('[sub_resource type="TileSetAtlasSource" id="atlas_%d"]' % sid)
        out.append('texture = ExtResource("tex_%d")' % sid)
        cells = used[sid]
        reserved = set()
        lines = []
        for at in sorted(cells, key=lambda a: (a[1], a[0])):
            x, y = at
            an = anims.get(sid, {}).get(at)
            if an:
                step, n, dur = an
                frames = {(x, y + k * step) for k in range(1, n)}
                if frames & cells or frames & reserved:
                    an = None
                else:
                    reserved |= frames
            if an:
                lines.append("%d:%d/animation_columns = 1" % (x, y))
                lines.append("%d:%d/animation_separation = Vector2i(0, %d)" % (x, y, step - 1))
                for k in range(n):
                    lines.append("%d:%d/animation_frame_%d/duration = %s" % (x, y, k, fmt(dur)))
            lines.append("%d:%d/0 = 0" % (x, y))
            kind = w.collide.get((sid, at))
            if (sid, at) == SOLID:
                kind = "full"
            if kind:
                lines.append("%d:%d/0/physics_layer_0/polygon_0/points = PackedVector2Array(%s)" % (x, y, POLY[kind]))
        out += lines
        out.append("")
    out.append("[resource]")
    out.append("physics_layer_0/collision_layer = 1")
    out.append("physics_layer_0/collision_mask = 0")
    for sid in sorted(used):
        out.append('sources/%d = SubResource("atlas_%d")' % (sid, sid))
    write(out_path, "\n".join(out) + "\n")


def tile_data(cells):
    b = bytearray(struct.pack("<H", 0))
    for (x, y), (src, (ax, ay), alt) in sorted(cells.items(), key=lambda kv: (kv[0][1], kv[0][0])):
        b += struct.pack("<hhHHHH", x, y, src, ax, ay, alt)
    return "PackedByteArray(" + ", ".join(str(v) for v in b) + ")"


# ---------------------------------------------------------------------------
class Frames:
    def __init__(self):
        self.tex, self.subs, self.anims = [], [], []

    def anim(self, name, res_path, rects, fps, loop=True, durations=None):
        if res_path not in self.tex:
            self.tex.append(res_path)
        tid = "t%d" % self.tex.index(res_path)
        refs = []
        for i, r in enumerate(rects):
            sid = "a%d" % len(self.subs)
            self.subs.append('[sub_resource type="AtlasTexture" id="%s"]\natlas = ExtResource("%s")\nregion = Rect2(%d, %d, %d, %d)\n' % (sid, tid, *r))
            d = durations[i] if durations else 1.0
            refs.append('{\n"duration": %s,\n"texture": SubResource("%s")\n}' % (fmt(d), sid))
        self.anims.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %s\n}' % (", ".join(refs), "true" if loop else "false", name, fmt(fps)))

    def text(self):
        out = ['[gd_resource type="SpriteFrames" format=3]', ""]
        out += ['[ext_resource type="Texture2D" path="%s" id="t%d"]' % (p, i) for i, p in enumerate(self.tex)]
        out.append("")
        out += self.subs
        out.append("[resource]")
        out.append("animations = [%s]" % ", ".join(self.anims))
        return "\n".join(out) + "\n"


_frames_cache = {}
FRAMES_DIR = "world"


def actor_frames(a):
    img = res_for_image(a["image"])
    x, y, x1, y1 = a["rect"]
    fw, fh = x1 - x, y1 - y
    key = (img, x, y, fw, fh, tuple(tuple(f) for f in a["frames"]))
    if key in _frames_cache:
        return _frames_cache[key]
    base = min(f[2] for f in a["frames"]) or 150
    f = Frames()
    pil = Image.open(a["image"]).convert("RGBA")
    rects, durs = [], []
    for dx, dy, d in a["frames"]:
        r = (x + dx, y + dy, fw, fh)
        if r[0] + fw > pil.width or r[1] + fh > pil.height:
            continue
        rects.append(r)
        durs.append(d / base)
    if not rects:
        rects, durs = [(x, y, fw, fh)], [1.0]
    f.anim("default", img, rects, 1000.0 / base, durations=durs)
    import hashlib
    h = hashlib.md5(repr(key).encode()).hexdigest()[:10]
    path = "resources/sprite_frames/%s/actor_%s.tres" % (FRAMES_DIR, h)
    write(path, f.text())
    _frames_cache[key] = "res://" + path
    return _frames_cache[key]


def citizen_frames(n):
    if n <= 5:
        return "res://resources/sprite_frames/npc_citizen%d.tres" % n
    base = os.path.join(C.RAW, "guild/PNG/")
    names = {6: ("Citizen1_Idle.png", "Citizen1_Walk.png"), 7: ("Citizen2_Idle.png", "Citizen2_Walk.png"), 8: ("Fighter2_Idle.png", "Fighter2_Walk.png")}[n]
    f = Frames()
    for anim, fname in zip(("idle", "walk"), names):
        raw = base + fname
        pil = Image.open(raw).convert("RGBA")
        res = res_for_raw(raw)
        for r, dname in enumerate(["down", "left", "right", "up"]):
            rects = [(i * 32, r * 32, 32, 32) for i in range(pil.width // 32) if pil.crop((i * 32, r * 32, i * 32 + 32, r * 32 + 32)).getbbox()]
            f.anim("%s_%s" % (anim, dname), res, rects, 8)
    path = "resources/sprite_frames/npc_citizen%d.tres" % n
    write(path, f.text())
    return "res://" + path


def animal_frames(kind):
    folder = "Black_grouse" if kind == "Black_grouse" else kind
    base = os.path.join(C.RAW, "animals/PNG/With_Shadow/%s/" % folder)
    f = Frames()
    for anim, fname in (("idle", "%s_Idle_with_shadow.png" % kind), ("walk", ("Fox_walk" if kind == "Fox" else kind + "_Walk") + "_with_shadow.png")):
        raw = base + fname
        pil = Image.open(raw).convert("RGBA")
        res = res_for_raw(raw)
        n = pil.width // 32
        for r, d in enumerate(["down", "up", "left", "right"]):
            rects = [(i * 32, r * 32, 32, 32) for i in range(n) if pil.crop((i * 32, r * 32, i * 32 + 32, r * 32 + 32)).getbbox()]
            f.anim("%s_%s" % (anim, d), res, rects, 6 if anim == "idle" else 9)
    path = "resources/sprite_frames/world/animal_%s.tres" % kind.lower()
    write(path, f.text())
    return "res://" + path


# ---------------------------------------------------------------------------
def walk_mask(w, out_path="resources/world/walkmask.png"):
    """8px walkability grid (R=blocked) + road preference (G) as a PNG the game loads into AStarGrid2D."""
    S = 8
    gw, gh = w.W * 2, w.H * 2
    img = Image.new("RGB", (gw, gh), (0, 0, 0))
    px = img.load()
    def block(x0, y0, x1, y1):
        for gy in range(max(0, int(y0 // S)), min(gh, int((y1 - 0.01) // S) + 1)):
            for gx in range(max(0, int(x0 // S)), min(gw, int((x1 - 0.01) // S) + 1)):
                r, g, b = px[gx, gy]
                px[gx, gy] = (255, g, b)
    for name in ("walls", "towers", "rim", "fence", "water_city"):
        for (x, y), (src, at, alt) in w.layers.get(name, {}).items():
            kind = w.collide.get((src, at))
            if not kind:
                continue
            X, Y = x * 16, y * 16
            r = {"full": (0, 0, 16, 16), "bottom": (0, 8, 16, 16), "left": (0, 0, 5, 16), "right": (11, 0, 16, 16)}[kind]
            block(X + r[0], Y + r[1], X + r[2], Y + r[3])
    for (x, y) in w.solids:
        block(x * 16, y * 16, x * 16 + 16, y * 16 + 16)
    for p in w.props:
        X, Y = p["pos"]
        for (a, b, c, d) in p.get("feet", []):
            block(X + a - 2, Y + b - 2, X + c + 2, Y + d + 1)
    for a in w.actors:
        if a.get("collide", True) and a.get("talk"):
            X, Y = a["pos"]
            block(X - 8, Y - 8, X + 8, Y + 2)
    roads = set(w.layers.get("road", {}).keys()) | {c for c, v in w.layers.get("ground", {}).items() if v[0] == C.MW}
    for (x, y) in roads:
        for gy in (y * 2, y * 2 + 1):
            for gx in (x * 2, x * 2 + 1):
                if 0 <= gx < gw and 0 <= gy < gh:
                    r, g, b = px[gx, gy]
                    px[gx, gy] = (r, 255, b)
    for gy in range(gh):
        for gx in (0, gw - 1):
            px[gx, gy] = (255, 0, 0)
    for gx in range(gw):
        px[gx, 0] = (255, 0, 0)
    os.makedirs(os.path.join(ROOT, "resources/world"), exist_ok=True)
    img.save(os.path.join(ROOT, out_path))


WORLD_CFG = dict(
    out="scenes/world/world.tscn", tileset="res://resources/tilesets/world_tileset.tres",
    walkmask="res://resources/world/walkmask.png", player=(89.5 * 16, 66 * 16),
    minimap="res://resources/world/minimap_world.png", title="Valdoria",
    preview_layers=["water", "water_fx", "ground", "ground_overlay", "road", "detail", "water_city", "rim", "coast", "dock", "dock_fx", "fence", "walls", "towers"],
    zones=[("Cuartel de la Guardia", (8, 34, 47, 74)), ("Granjas del Este", (132, 14, 180, 96)),
           ("Puerto de Valdoria", (30, 92, 156, 140)), ("Ciudadela de Valdoria", (52, 24, 128, 89)),
           ("Pradera del Norte", (0, 0, 180, 24)), ("Costa del Oeste", (0, 88, 30, 140)), ("Costa del Este", (156, 88, 180, 140)),
           ("Alrededores de Valdoria", (0, 0, 180, 140))],
    exits=[dict(name="NorthExit", pos=(89.5 * 16, 18), size=(6 * 16, 24), scene="res://scenes/world/field.tscn", spawn="south", dir="up")],
    spawns={"north_gate": (89.5 * 16, 3 * 16)},
    top_gap=(86, 93),
)


def _map_extras(w, cfg):
    """Root properties for the minimap picture, map title and treasure chests."""
    out = ""
    if cfg.get("minimap"):
        render_minimap(w, cfg)
        out += 'minimap_path = "%s"\n' % cfg["minimap"]
    if cfg.get("hunters"):
        out += "hunter_count = %d\n" % cfg["hunters"]
    if cfg.get("title"):
        out += 'map_title = "%s"\n' % esc(cfg["title"])
    chests = cfg.get("chests") or getattr(w, "chests", [])
    if chests:
        out += "chest_points = PackedVector2Array(%s)\n" % ", ".join("%s, %s" % (fmt(x * 16), fmt(y * 16)) for x, y, _t in chests)
        out += "chest_tiers = PackedInt32Array(%s)\n" % ", ".join(str(t) for _x, _y, t in chests)
    return out


def render_minimap(w, cfg):
    """Renders the whole map and shrinks it to 2 px per tile for the in-game minimap."""
    import w_preview as PV
    order = cfg.get("preview_layers")
    if order:
        PV.LAYER_ORDER[:] = order
    tmp = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "_minimap_full.png")
    PV.render(w, tmp, 1)
    img = Image.open(tmp).convert("RGB").resize((w.W * 2, w.H * 2), Image.LANCZOS)
    dst = os.path.join(ROOT, cfg["minimap"].replace("res://", ""))
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    img.save(dst)


def scene(w, cfg=None):
    cfg = cfg or WORLD_CFG
    ext, subs, nodes = [], [], []

    def eid(typ, path):
        for t, p, i in ext:
            if p == path:
                return i
        i = "%d_%s" % (len(ext) + 1, os.path.splitext(os.path.basename(path))[0].lower()[:10])
        ext.append((typ, path, i))
        return i

    shapes = {}

    def rect_shape(a, b):
        k = (round(a, 2), round(b, 2))
        if k not in shapes:
            shapes[k] = "Rect_%d" % len(shapes)
            subs.append('[sub_resource type="RectangleShape2D" id="%s"]\nsize = Vector2(%s, %s)\n' % (shapes[k], fmt(a), fmt(b)))
        return shapes[k]

    ts = eid("TileSet", cfg["tileset"])
    script = eid("Script", "res://scripts/world/world.gd")
    g = w.graph
    zones = cfg["zones"]
    zt = ", ".join('"%s": Rect2(%d, %d, %d, %d)' % (n, x0 * 16, y0 * 16, (x1 - x0) * 16, (y1 - y0) * 16) for n, (x0, y0, x1, y1) in zones)
    homes = [(d["pos"][0], d["pos"][1] + 5) for d in w.house_doors]
    shops = list(w.shop_points)
    for a in w.actors:
        if a.get("seller"):
            shops.append((a["pos"][0], a["pos"][1] + 22))
    vec = lambda pts: ", ".join("%s, %s" % (fmt(x), fmt(y)) for x, y in pts)
    nodes.append('[node name="World" type="Node2D"]\nscript = ExtResource("%s")\nmap_size = Vector2i(%d, %d)\nwalk_nodes = PackedVector2Array(%s)\nwalk_edges = PackedInt32Array(%s)\nhome_points = PackedVector2Array(%s)\nshop_points = PackedVector2Array(%s)\nzones = {%s}\nwalkmask_path = "%s"\n%s' % (
        script, w.W, w.H, vec(g.nodes), ", ".join("%d, %d" % e for e in sorted(g.edges)), vec(homes), vec(shops), zt, cfg["walkmask"],
        ("run_uses_stamina = true\n" if cfg.get("stamina") else "") + _map_extras(w, cfg)))
    # solids layer
    w.layers["solids"] = {c: (SOLID[0], SOLID[1], 0) for c in w.solids}
    for name, col in LAYERS:
        cells = w.layers.get(name)
        if not cells:
            continue
        extra = "" if col else "collision_enabled = false\n"
        if name == "solids":
            extra += "visible = false\n"
        nodes.append('[node name="%s" type="TileMapLayer" parent="."]\ntile_map_data = %s\ntile_set = ExtResource("%s")\n%s' % (
            "".join(s.capitalize() for s in name.split("_")), tile_data(cells), ts, extra))

    nodes.append('[node name="FloorDecor" type="Node2D" parent="."]\n')
    nodes.append('[node name="Entities" type="Node2D" parent="."]\ny_sort_enabled = true\n')
    for grp in ("Props", "Actors", "Citizens", "Animals"):
        nodes.append('[node name="%s" type="Node2D" parent="Entities"]\ny_sort_enabled = true\n' % grp)

    counts = {}
    used = set()

    def uname(base):
        while True:
            counts[base] = counts.get(base, 0) + 1
            name = base + ("" if counts[base] == 1 else "_%d" % counts[base])
            if name not in used:
                used.add(name)
                return name

    for p in w.props:
        name = uname("".join(s.capitalize() for s in p["key"].split("_")))
        tex = eid("Texture2D", res_for_image(p["image"]))
        x0, y0, x1, y1 = p["rect"]
        ox, oy = p["origin"]
        px, py = p["pos"]
        flip = "flip_h = true\n" if p.get("flip") else ""
        spr = 'texture = ExtResource("%s")\ncentered = false\noffset = Vector2(%s, %s)\n%sregion_enabled = true\nregion_rect = Rect2(%d, %d, %d, %d)\n' % (
            tex, fmt(-ox), fmt(-oy), flip, x0, y0, x1 - x0, y1 - y0)
        if p.get("floor"):
            nodes.append('[node name="%s" type="Sprite2D" parent="FloorDecor"]\nposition = Vector2(%s, %s)\n%s' % (name, fmt(px), fmt(py), spr))
        elif not p["feet"]:
            nodes.append('[node name="%s" type="Sprite2D" parent="Entities/Props"]\nposition = Vector2(%s, %s)\n%s' % (name, fmt(px), fmt(py), spr))
        else:
            nodes.append('[node name="%s" type="StaticBody2D" parent="Entities/Props"]\nposition = Vector2(%s, %s)\ncollision_mask = 0\n' % (name, fmt(px), fmt(py)))
            nodes.append('[node name="Sprite2D" type="Sprite2D" parent="Entities/Props/%s"]\n%s' % (name, spr))
            for i, (a, b, c, d) in enumerate(p["feet"]):
                nodes.append('[node name="Shape%d" type="CollisionShape2D" parent="Entities/Props/%s"]\nposition = Vector2(%s, %s)\nshape = SubResource("%s")\n' % (
                    i, name, fmt((a + c) / 2), fmt((b + d) / 2), rect_shape(c - a, d - b)))

    actor_scene = eid("PackedScene", "res://scenes/npc/actor.tscn")
    for a in w.actors:
        fr = eid("SpriteFrames", actor_frames(a))
        fw, fh = a["size"]
        off_y = fh / 2 - a["origin"][1]
        name = uname("".join(s.capitalize() for s in a["kind"].split("_")))
        lines = ""
        if a.get("talk"):
            nm, ls = a["talk"]
            lines = 'npc_name = "%s"\nlines = PackedStringArray(%s)\n' % (esc(nm), ", ".join('"%s"' % esc(l) for l in ls))
        shouts = ""
        if a.get("bubble"):
            shouts = "shouts = PackedStringArray(%s)\n" % ", ".join('"%s"' % esc(l) for l in a["bubble"])
        nodes.append('[node name="%s" parent="Entities/Actors" instance=ExtResource("%s")]\nposition = Vector2(%s, %s)\nframes = ExtResource("%s")\nsprite_offset = Vector2(0, %s)\n%s%s%s%s%s' % (
            name, actor_scene, fmt(a["pos"][0]), fmt(a["pos"][1]), fr, fmt(off_y), "flip = true\n" if a.get("flip") else "",
            "" if a.get("collide", True) else "collide = false\n", lines, shouts,
            ("seller = true\n" if a.get("seller") else "") + ('opens = "%s"\n' % a["opens"] if a.get("opens") else "")))

    walker_scene = eid("PackedScene", "res://scenes/npc/walker.tscn")
    import math
    for i, c in enumerate(w.walkers):
        fr = eid("SpriteFrames", citizen_frames(c["n"]))
        px, py = c["pos"]
        best = min(range(len(g.nodes)), key=lambda k: (g.nodes[k][0] - px) ** 2 + (g.nodes[k][1] - py) ** 2)
        t = 0.88 + w.rng.random() * 0.12
        tint = "Color(%s, %s, %s, 1)" % (fmt(t), fmt(0.88 + w.rng.random() * 0.12), fmt(0.88 + w.rng.random() * 0.12))
        nodes.append('[node name="Citizen%d" parent="Entities/Citizens" instance=ExtResource("%s")]\nposition = Vector2(%s, %s)\nframes = ExtResource("%s")\nsprite_offset_y = %s\nnpc_name = "%s"\nlines = PackedStringArray(%s)\nstart_node = %d\ntint = %s\n' % (
            i + 1, walker_scene, fmt(px), fmt(py), fr, fmt(16 - c["origin"][1]), ("Guardia" if c.get("guard") else {"city": "Vecino", "port": "Marinero", "farm": "Granjero", "training": "Recluta"}.get(c["zone"], "Vecino")),
            ", ".join('"%s"' % esc(l) for l in c["lines"]), best, tint) + ("brain = true\n" if c.get("brain") else "") + ("guard = true\n" if c.get("guard") else "")
            + ('mode = "%s"\n' % c.get("mode", "stroller")))

    animal_scene = eid("PackedScene", "res://scenes/npc/wild_animal.tscn")
    for i, a in enumerate(w.animals):
        fr = eid("SpriteFrames", animal_frames(a["kind"]))
        x, y, wd, ht = a["wander"]
        nodes.append('[node name="%s%d" parent="Entities/Animals" instance=ExtResource("%s")]\nposition = Vector2(%s, %s)\nframes = ExtResource("%s")\nwander_rect = Rect2(%s, %s, %s, %s)\n' % (
            a["kind"].replace("_", ""), i + 1, animal_scene, fmt(a["pos"][0]), fmt(a["pos"][1]), fr, x, y, wd, ht))

    player = eid("PackedScene", "res://scenes/characters/player.tscn")
    monster_scene = None
    for i, m in enumerate(getattr(w, "monsters", [])):
        if monster_scene is None:
            monster_scene = eid("PackedScene", "res://scenes/monsters/monster.tscn")
            nodes.append('[node name="Monsters" type="Node2D" parent="Entities"]\ny_sort_enabled = true\n')
        fr = eid("SpriteFrames", m["frames"])
        props_txt = "".join('%s = %s\n' % (k, v) for k, v in m["props"].items())
        nodes.append('[node name="%s" parent="Entities/Monsters" instance=ExtResource("%s")]\nposition = Vector2(%s, %s)\nframes = ExtResource("%s")\n%s' % (
            uname(m["name"]), monster_scene, fmt(m["pos"][0]), fmt(m["pos"][1]), fr, props_txt))
    nodes.append('[node name="Player" parent="Entities" instance=ExtResource("%s")]\nposition = Vector2(%d, %d)\n' % (player, int(cfg["player"][0]), int(cfg["player"][1])))

    # world bounds (a gap in the top edge when the map has a northern exit)
    W, H = w.W * 16, w.H * 16
    nodes.append('[node name="Bounds" type="StaticBody2D" parent="."]\ncollision_mask = 0\n')
    gap = cfg.get("top_gap")
    edges = {"Left": (-8, H / 2, 16, H), "Right": (W + 8, H / 2, 16, H), "Bottom": (W / 2, H + 8, W, 16)}
    if gap:
        edges["TopLeft"] = (gap[0] * 8, -8, gap[0] * 16, 16)
        edges["TopRight"] = ((gap[1] + w.W) * 8, -8, (w.W - gap[1]) * 16, 16)
        edges["TopGate"] = ((gap[0] + gap[1]) * 8, -24, (gap[1] - gap[0]) * 16, 16)
    else:
        edges["Top"] = (W / 2, -8, W, 16)
    bgap = cfg.get("bottom_gap")
    if bgap:
        del edges["Bottom"]
        edges["BottomLeft"] = (bgap[0] * 8, H + 8, bgap[0] * 16, 16)
        edges["BottomRight"] = ((bgap[1] + w.W) * 8, H + 8, (w.W - bgap[1]) * 16, 16)
        edges["BottomGate"] = ((bgap[0] + bgap[1]) * 8, H + 24, (bgap[1] - bgap[0]) * 16, 16)
    for nm, (cx, cy, sw, sh) in edges.items():
        nodes.append('[node name="%s" type="CollisionShape2D" parent="Bounds"]\nposition = Vector2(%s, %s)\nshape = SubResource("%s")\n' % (nm, fmt(cx), fmt(cy), rect_shape(sw, sh)))
    exit_scr = eid("Script", "res://scripts/world/zone_exit.gd")
    for e in cfg.get("exits", []):
        nodes.append('[node name="%s" type="Area2D" parent="."]\nposition = Vector2(%s, %s)\ncollision_layer = 0\ncollision_mask = 2\nmonitorable = false\nscript = ExtResource("%s")\ntarget_scene = "%s"\ntarget_spawn = "%s"\n' % (
            e["name"], fmt(e["pos"][0]), fmt(e["pos"][1]), exit_scr, e["scene"], e["spawn"]))
        nodes.append('[node name="CollisionShape2D" type="CollisionShape2D" parent="%s"]\nshape = SubResource("%s")\n' % (e["name"], rect_shape(*e["size"])))

    nodes.append('[node name="Spawns" type="Node2D" parent="."]\n')
    for nm, (x, y) in cfg.get("spawns", {}).items():
        nodes.append('[node name="%s" type="Marker2D" parent="Spawns"]\nposition = Vector2(%s, %s)\n' % (nm, fmt(x), fmt(y)))
    for d in w.doors:
        x, y = d["pos"]
        nodes.append('[node name="%s" type="Marker2D" parent="Spawns"]\nposition = Vector2(%s, %s)\n' % (d["name"], fmt(x), fmt(y + 12)))
    door_scr = eid("Script", "res://scripts/world/door.gd")
    for d in w.doors:
        x, y = d["pos"]
        nodes.append('[node name="Door_%s" type="Area2D" parent="."]\nposition = Vector2(%s, %s)\nscript = ExtResource("%s")\ntarget_scene = "res://scenes/interiors/%s.tscn"\ntarget_spawn = "door"\nreturn_marker = "%s"\ndirection = "up"\nlabel = "%s"\n' % (
            d["name"], fmt(x), fmt(y + 2), door_scr, d["interior"], d["name"], esc(d["label"])))
        nodes.append('[node name="Shape" type="CollisionShape2D" parent="Door_%s"]\nshape = SubResource("%s")\n' % (d["name"], rect_shape(18, 10)))
    nodes.append('[node name="HUD" parent="." instance=ExtResource("%s")]\n' % eid("PackedScene", "res://scenes/ui/hud.tscn"))
    nodes.append('[node name="PauseMenu" parent="." instance=ExtResource("%s")]\n' % eid("PackedScene", "res://scenes/ui/pause_menu.tscn"))

    out = ['[gd_scene format=3]', ""]
    out += ['[ext_resource type="%s" path="%s" id="%s"]' % (t, p, i) for t, p, i in ext]
    out.append("")
    out += subs
    out += nodes
    write(cfg["out"], "\n".join(out))


if __name__ == "__main__":
    for f in glob.glob(os.path.join(ROOT, "resources/sprite_frames/world/*.tres")):
        os.remove(f)
    stale = os.path.join(ROOT, "resources/world/walkmask.res")
    if os.path.exists(stale):
        os.remove(stale)   # the editor's runtime mask; the generator's PNG replaces it
    w = w_build.build()
    for sheet in WP.SHEETS:
        if WP.SHEETS[sheet][0]:
            res_for_raw(os.path.join(C.RAW, WP.SHEETS[sheet][0]))
    tileset(w)
    walk_mask(w)
    scene(w)
    import w_catalog
    print("catalog", w_catalog.build(w))
    print("props", len(w.props), "actors", len(w.actors), "walkers", len(w.walkers), "animals", len(w.animals),
          "nodes", len(w.graph.nodes), "frames", len(_frames_cache))
