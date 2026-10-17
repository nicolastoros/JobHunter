"""Builds every interior scene (guild floors, houses) from the authors' Tiled maps."""
import os, sys
import w_interior as WI
import w_export as WE

T = 16
WORLD = "res://scenes/world/world.tscn"

# Cells are in converted-map tile coordinates (see debug images).
INTERIORS = {
    "guild_1f": dict(map="guild/Tiled_files/Interior_1st_floor.tmx", title="Gremio de Cazadores",
                     exits=[dict(cells=[(9, 12), (10, 12), (9, 13), (10, 13), (9, 14), (10, 14)], dir="down", scene=WORLD, spawn="")],
                     stairs=[dict(cells=[(5, 11), (6, 11)], dir="left", scene="res://scenes/interiors/guild_2f.tscn", spawn="stairs")],
                     decals=[(4, 10, 8, 13)],
                     spawns={"door": (10, 11.4), "stairs": (8, 11.6)},
                     boards=[(3.5, 9.7), (19.5, 9.7)],
                     talk={"Guildmaster": ("Maestra del Gremio Ysolde", ["Bienvenido al Gremio de Cazadores de Valdoria.",
                                                                          "Los pedidos están en los tablones a ambos lados del salón. Elige uno según tu rango.",
                                                                          "El dragón lo cazó mi abuelo. Por favor, no lo toques."]),
                           "Various_characters": ("Cazador", ["¿Viste el pedido urgente? Nadie quiere ir al norte.",
                                                              "Dicen que la bestia del norte mide tres metros.",
                                                              "Arriba entrenan los magos. Ten cuidado al subir."])}),
    "guild_2f": dict(map="guild/Tiled_files/Interior_2nd_floor.tmx", title="Gremio — Sala de entrenamiento",
                     exits=[], stairs=[dict(cells=[(5, 11), (6, 11)], dir="left", scene="res://scenes/interiors/guild_1f.tscn", spawn="stairs")],
                     decals=[(4, 10, 8, 13)], spawns={"stairs": (8, 11.6)}, boards=[],
                     talk={"Mage": ("Maga aprendiz", ["Cuidado, este hechizo todavía no me sale bien.", "El círculo arcano canaliza el fuego."]),
                           "Reader": ("Erudito", ["Este bestiario describe más de cien criaturas. Las del norte son las peores.",
                                                  "Estoy leyendo."]),
                           "Fighter": ("Espadachín veterano", ["Golpea, retrocede, golpea. Así de simple."])}),
    "house_red": dict(map="house/Tiled_files/Interior1.tmx", title="Casa de piedra",
                      exits=[dict(cells=[(19, 15), (20, 15), (19, 16), (19, 17), (20, 16), (20, 17)], dir="down", scene=WORLD, spawn="")],
                      stairs=[], decals=[], spawns={"door": (19.7, 14.6)}, boards=[], talk={}),
    "farmhouse": dict(map="farm/Tiled_files/House_interior.tmx", title="Casa de campo",
                      exits=[dict(cells=[(13, 13), (14, 13), (13, 14), (14, 14), (13, 15), (14, 15)], dir="down", scene=WORLD, spawn="")],
                      stairs=[], decals=[], spawns={"door": (14, 12.5)}, boards=[], talk={}),
    "port_house": dict(map="fishing/Tiled_foles/Interior.tmx", title="Pescadería de la abuela Nilda",
                       exits=[dict(cells=[(13, 12), (14, 12), (13, 13), (13, 14), (14, 13), (14, 14)], dir="down", scene=WORLD, spawn="")],
                       stairs=[], decals=[], spawns={"door": (13.6, 11.5)}, boards=[],
                       talk={"Seller_gramma": ("Abuela Nilda", ["Pescado fresco. Lo trajo mi nieto esta mañana.",
                                                                "Si algún día eres un cazador famoso, vuelve a visitarme."])}),
}


def fmt(v):
    return WE.fmt(v)


def build(name, cfg, debug_dir=None):
    exits = cfg["exits"] + cfg["stairs"]
    info = WI.convert(name, cfg["map"], exits, cfg["title"])
    # decal regions: props whose centre lies inside become floor art (no collision)
    keep = []
    from PIL import Image
    base = os.path.join(WE.ROOT, "assets/interiors", name)
    floor = Image.open(os.path.join(base, "floor.png")).convert("RGBA")
    objs = Image.open(os.path.join(base, "objects.png")).convert("RGBA")
    for p in info["props"]:
        x0, y0, x1, y1 = p["rect"]
        cx, cy = (x0 + x1) / 2 / T, (y0 + y1) / 2 / T
        if any(a <= cx <= c and b <= cy <= d for (a, b, c, d) in cfg["decals"]):
            floor.alpha_composite(objs.crop(p["rect"]), (x0, y0))
        else:
            keep.append(p)
    floor.save(os.path.join(base, "floor.png"))
    info["props"] = keep
    if debug_dir:
        im = WI.ascii_mask(info)
        from PIL import ImageDraw
        d = ImageDraw.Draw(im)
        for e in exits:
            for (x, y) in e["cells"]:
                d.rectangle((x * 32, y * 32, x * 32 + 31, y * 32 + 31), outline=(0, 255, 0), width=2)
        for k, (x, y) in cfg["spawns"].items():
            d.ellipse((x * 32 - 4, y * 32 - 4, x * 32 + 4, y * 32 + 4), fill=(0, 0, 255))
        for (x, y) in cfg["boards"]:
            d.ellipse((x * 32 - 4, y * 32 - 4, x * 32 + 4, y * 32 + 4), fill=(255, 255, 0))
        im.save(os.path.join(debug_dir, "int_%s.png" % name))
    write_scene(name, cfg, info)


def solid_rects(solid, B=4):
    """Merge solid 4px blocks into rectangles (row runs merged vertically)."""
    runs = {}
    rows = {}
    for (bx, by) in solid:
        rows.setdefault(by, []).append(bx)
    row_runs = {}
    for by, xs in rows.items():
        xs.sort()
        rr = []
        start = prev = xs[0]
        for x in xs[1:]:
            if x == prev + 1:
                prev = x
                continue
            rr.append((start, prev)); start = prev = x
        rr.append((start, prev))
        row_runs[by] = rr
    rects = []
    open_ = {}
    for by in sorted(row_runs):
        cur = {}
        for run in row_runs[by]:
            if run in open_:
                cur[run] = open_.pop(run)
            else:
                cur[run] = by
        for run, y0 in open_.items():
            rects.append((run[0], y0, run[1], by - 1))
        open_ = cur
    for run, y0 in open_.items():
        rects.append((run[0], y0, run[1], max(row_runs) if row_runs else y0))
    return [(a * B, b * B, (c + 1) * B, (d + 1) * B) for a, b, c, d in rects]


def write_scene(name, cfg, info):
    ext, subs, nodes = [], [], []

    def eid(typ, path):
        for t, p, i in ext:
            if p == path:
                return i
        i = "%d_%s" % (len(ext) + 1, os.path.splitext(os.path.basename(path))[0].lower()[:10])
        ext.append((typ, path, i))
        return i

    shapes = {}

    def rshape(w, h):
        k = (w, h)
        if k not in shapes:
            shapes[k] = "R%d" % len(shapes)
            subs.append('[sub_resource type="RectangleShape2D" id="%s"]\nsize = Vector2(%s, %s)\n' % (shapes[k], fmt(w), fmt(h)))
        return shapes[k]

    base = "res://assets/interiors/%s/" % name
    W, H = info["size"]
    nodes.append('[node name="%s" type="Node2D"]\nscript = ExtResource("%s")\ntitle = "%s"\nroom_size = Vector2i(%d, %d)\n' % (
        "".join(s.capitalize() for s in name.split("_")), eid("Script", "res://scripts/world/interior.gd"), WE.esc(cfg["title"]), W, H))
    nodes.append('[node name="Floor" type="Sprite2D" parent="."]\ntexture = ExtResource("%s")\ncentered = false\n' % eid("Texture2D", base + "floor.png"))
    nodes.append('[node name="Entities" type="Node2D" parent="."]\ny_sort_enabled = true\n')
    objtex = eid("Texture2D", base + "objects.png")
    for i, p in enumerate(info["props"]):
        x0, y0, x1, y1 = p["rect"]
        fx0, fy0, fx1, fy1 = p["feet"]
        nodes.append('[node name="Prop%d" type="StaticBody2D" parent="Entities"]\nposition = Vector2(%s, %s)\ncollision_mask = 0\n' % (i, fmt((x0 + x1) / 2), fmt(y1)))
        nodes.append('[node name="Sprite2D" type="Sprite2D" parent="Entities/Prop%d"]\ntexture = ExtResource("%s")\ncentered = false\noffset = Vector2(%s, %s)\nregion_enabled = true\nregion_rect = Rect2(%d, %d, %d, %d)\n' % (
            i, objtex, fmt(-(x1 - x0) / 2), fmt(-(y1 - y0)), x0, y0, x1 - x0, y1 - y0))
        nodes.append('[node name="Shape" type="CollisionShape2D" parent="Entities/Prop%d"]\nposition = Vector2(%s, %s)\nshape = SubResource("%s")\n' % (
            i, fmt((fx0 + fx1) / 2 - (x0 + x1) / 2), fmt((fy0 + fy1) / 2 - y1), rshape(fx1 - fx0, fy1 - fy0)))
    actor_scene = eid("PackedScene", "res://scenes/npc/actor.tscn")
    for i, a in enumerate(info["actors"]):
        fr = eid("SpriteFrames", WE.actor_frames(dict(image=a["image"], rect=a["rect"], frames=a["frames"])))
        fw, fh = a["size"]
        layer = a["layer"].split("/")[-1]
        talk = None
        for k, v in cfg["talk"].items():
            if layer.startswith(k):
                talk = v
        lines = ""
        if talk:
            lines = 'npc_name = "%s"\nlines = PackedStringArray(%s)\n' % (WE.esc(talk[0]), ", ".join('"%s"' % WE.esc(l) for l in talk[1]))
        collide = "" if talk else "collide = false\n"
        nodes.append('[node name="Actor%d" parent="Entities" instance=ExtResource("%s")]\nposition = Vector2(%s, %s)\nframes = ExtResource("%s")\nsprite_offset = Vector2(0, %s)\n%s%s' % (
            i, actor_scene, fmt(a["pos"][0]), fmt(a["pos"][1]), fr, fmt(fh / 2 - a["foot"]), collide, lines))
    board_scene = eid("PackedScene", "res://scenes/world/interactable.tscn")
    for i, (x, y) in enumerate(cfg["boards"]):
        nodes.append('[node name="QuestBoard%d" parent="Entities" instance=ExtResource("%s")]\nposition = Vector2(%s, %s)\n' % (i, board_scene, fmt(x * T), fmt(y * T)))
    sx, sy = list(cfg["spawns"].values())[0]
    nodes.append('[node name="Player" parent="Entities" instance=ExtResource("%s")]\nposition = Vector2(%s, %s)\n' % (eid("PackedScene", "res://scenes/characters/player.tscn"), fmt(sx * T), fmt(sy * T)))
    nodes.append('[node name="Top" type="Sprite2D" parent="."]\nz_index = 20\ntexture = ExtResource("%s")\ncentered = false\n' % eid("Texture2D", base + "top.png"))
    nodes.append('[node name="Solids" type="StaticBody2D" parent="."]\ncollision_mask = 0\n')
    for i, (x0, y0, x1, y1) in enumerate(solid_rects(info["solid"])):
        nodes.append('[node name="S%d" type="CollisionShape2D" parent="Solids"]\nposition = Vector2(%s, %s)\nshape = SubResource("%s")\n' % (i, fmt((x0 + x1) / 2), fmt((y0 + y1) / 2), rshape(x1 - x0, y1 - y0)))
    nodes.append('[node name="Spawns" type="Node2D" parent="."]\n')
    for k, (x, y) in cfg["spawns"].items():
        nodes.append('[node name="%s" type="Marker2D" parent="Spawns"]\nposition = Vector2(%s, %s)\n' % (k, fmt(x * T), fmt(y * T)))
    door = eid("Script", "res://scripts/world/door.gd")
    for i, e in enumerate(cfg["exits"] + cfg["stairs"]):
        xs = [c[0] for c in e["cells"]]; ys = [c[1] for c in e["cells"]]
        x0, x1, y0, y1 = min(xs) * T, (max(xs) + 1) * T, min(ys) * T, (max(ys) + 1) * T
        nodes.append('[node name="Door%d" type="Area2D" parent="."]\nposition = Vector2(%s, %s)\nscript = ExtResource("%s")\ntarget_scene = "%s"\ntarget_spawn = "%s"\ndirection = "%s"\n' % (
            i, fmt((x0 + x1) / 2), fmt((y0 + y1) / 2), door, e["scene"], e["spawn"], e["dir"]))
        nodes.append('[node name="Shape" type="CollisionShape2D" parent="Door%d"]\nshape = SubResource("%s")\n' % (i, rshape(x1 - x0, y1 - y0)))
    nodes.append('[node name="HUD" parent="." instance=ExtResource("%s")]\n' % eid("PackedScene", "res://scenes/ui/hud.tscn"))
    nodes.append('[node name="PauseMenu" parent="." instance=ExtResource("%s")]\n' % eid("PackedScene", "res://scenes/ui/pause_menu.tscn"))
    out = ["[gd_scene format=3]", ""]
    out += ['[ext_resource type="%s" path="%s" id="%s"]' % (t, p, i) for t, p, i in ext]
    out.append("")
    out += subs
    out += nodes
    WE.write("scenes/interiors/%s.tscn" % name, "\n".join(out))


if __name__ == "__main__":
    import glob
    WE.FRAMES_DIR = "interiors"
    for f in glob.glob(os.path.join(WE.ROOT, "resources/sprite_frames/interiors/*.tres")):
        os.remove(f)
    dbg = sys.argv[1] if len(sys.argv) > 1 else None
    for name, cfg in INTERIORS.items():
        build(name, cfg, dbg)
        print("built", name)
