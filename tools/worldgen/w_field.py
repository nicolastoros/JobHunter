"""Llanura de Valdoria: the great field north of the city (Hyrule Field spirit).
Winding paths between landmarks, hills with cliffs, a lake with an island and a bridge,
ancient ruins guarded by a golem, a goblin camp, a haunted grove, a traveler's camp and monsters."""
import math, glob, os
from PIL import Image
from w_common import *
import w_props as WP
import w_layout as WL
from w_layout import prop, actor
from w_coast import road_mask, GRASS_ISLAND, GRASS_INNER, FWCG

import w_terrain as WT

W, H = 170, 130
ENTRY_X = (82, 89)
NORTH_GAP = (27, 33)   # trail to the Deep Forest
EAST_GAP = (76, 82)    # caravan trail to the Desert of Amber

# ---- extra sheets for the field ---------------------------------------------------
WP.SHEETS["gl"] = ("grassland_01/Tiled_files/Trees_rocks.png", "assets/sprites/field/Trees_rocks.png")
WP.SHEETS["tr01"] = ("trees_01/PNG/Trees_texture_shadow_source.png", "assets/sprites/field/Trees_source.png")
WP.SHEETS["camp"] = ("campfire_asset/PNG/Tents_n_objects.png", "assets/sprites/field/Tents_n_objects.png")
add = WP.add
for k, r in {"gl_tree_big": (1, 0, 62, 80), "gl_tree": (67, 6, 120, 75), "gl_apple": (129, 2, 190, 77), "gl_apple2": (199, 7, 250, 73),
             "gl_tree_round": (117, 80, 156, 128), "gl_apple3": (49, 164, 79, 206)}.items():
    add(k, "gl", r, "tree")
for k, r in {"gl_mound": (2, 83, 60, 125), "gl_mound2": (64, 86, 112, 123), "gl_redbush": (162, 86, 205, 127), "gl_bluebush": (209, 87, 256, 125),
             "gl_mound3": (1, 128, 44, 159), "gl_bluebush2": (51, 129, 93, 160), "gl_bush": (102, 128, 137, 160), "gl_mound4": (145, 129, 190, 159),
             "gl_yellowbush": (4, 162, 44, 197), "gl_bluebush3": (80, 166, 110, 191), "gl_yellowbush2": (147, 163, 175, 191),
             "gl_crystalbush": (128, 199, 176, 237), "gl_reeds": (179, 201, 219, 235), "gl_crystalbush2": (225, 227, 254, 256)}.items():
    add(k, "gl", r, "bush")
for k, r in {"gl_stump": (195, 129, 221, 159), "gl_stump2": (226, 131, 254, 158), "gl_flower": (182, 168, 202, 186), "gl_flower2": (211, 169, 233, 189),
             "gl_sprout": (240, 160, 256, 176), "gl_pinkflower": (225, 197, 253, 220), "gl_redplant": (2, 212, 31, 239), "gl_grass": (35, 213, 60, 237)}.items():
    add(k, "gl", r, None)
for k, r in {"gl_rock": (3, 244, 61, 301), "gl_rock2": (129, 244, 190, 303), "gl_rock3": (73, 256, 120, 301), "gl_rock4": (198, 256, 251, 303),
             "gl_rocks_s": (96, 400, 160, 432), "gl_stone": (163, 499, 189, 526), "gl_stone2": (193, 499, 223, 526)}.items():
    add(k, "gl", r, [(int((r[2] - r[0]) * 0.1), int((r[3] - r[1]) * 0.45), int((r[2] - r[0]) * 0.9), r[3] - r[1] - 2)])
add("ruin_tower", "gl", (2, 309, 102, 414), [(10, 62, 90, 100)])
add("ruin_tower2", "gl", (144, 389, 247, 496), [(10, 64, 93, 102)])
add("ruin_arch", "gl", (119, 309, 180, 380), [(4, 40, 58, 68)])
add("ruin_arch2", "gl", (3, 421, 71, 494), [(4, 42, 64, 70)])
add("ruin_column", "gl", (193, 325, 253, 380), [(8, 34, 54, 52)])
add("ruin_column2", "gl", (80, 437, 144, 494), [(6, 36, 58, 54)])
add("ruin_pillar", "gl", (1, 501, 43, 544), [(6, 28, 36, 41)])
add("ruin_pillar2", "gl", (48, 501, 94, 544), [(6, 28, 40, 41)])
add("ruin_rubble", "gl", (96, 496, 160, 528), [(6, 14, 58, 30)])
TR = {"pine": (1, 2, 64, 80), "leafy": (65, 1, 127, 80), "autumn": (277, 1, 347, 80), "dead": (357, 8, 413, 76), "willow": (417, 2, 478, 78),
      "fruit": (481, 5, 542, 80), "blossom": (547, 2, 605, 79), "fan": (609, 4, 671, 78), "palm": (673, 5, 736, 77), "fruit2": (743, 7, 792, 74),
      "pine_m": (0, 82, 48, 140), "leafy_m": (51, 80, 104, 144), "autumn_m": (242, 80, 302, 144), "dead_m": (311, 80, 360, 142),
      "willow_m": (368, 82, 416, 142), "blossom_m": (417, 81, 464, 144), "fan_m": (470, 82, 520, 143)}
for k, r in TR.items():
    add("tr_" + k, "tr01", r, "tree")
add("tr_log", "tr01", (592, 84, 672, 124), [(6, 20, 74, 38)])
add("tr_stump", "tr01", (676, 91, 714, 121), [(6, 14, 32, 28)])
for k, r in {"tent_white": (1, 13, 109, 116), "tent_orange": (0, 138, 66, 228), "tent_purple": (14, 252, 117, 340),
             "tent_ragged": (9, 359, 98, 445), "tent_stripes": (3, 458, 93, 545), "tent_green": (11, 560, 90, 649)}.items():
    x0, y0, x1, y1 = r
    add(k, "camp", r, [(6, int((y1 - y0) * 0.55), x1 - x0 - 6, y1 - y0 - 4)])
add("camp_chest", "camp", (369, 77, 414, 115))
add("camp_rug", "camp", (263, 496, 341, 548), "floor")
add("camp_log", "camp", (354, 531, 402, 541), [(0, 2, 48, 10)])
add("camp_bedroll", "camp", (8, 666, 58, 706), None)
add("camp_bones", "camp", (378, 662, 405, 692), None)
add("camp_crystals", "camp", (164, 728, 189, 762))
add("camp_trunk", "camp", (81, 725, 128, 765))

HILL_NINE = nine_at(1, 7)
FOREST = ["tr_pine", "tr_leafy", "tr_willow", "tr_pine_m", "tr_leafy_m", "gl_tree_big", "gl_tree", "tree_big", "pine_big", "pine_mid",
          "tree_bushy", "tree_oak", "tree_light", "tr_fan"]
GROVE = ["tr_autumn", "tr_dead", "tr_willow", "tr_autumn_m", "tr_dead_m", "tr_willow_m", "tr_pine"]
LONE = ["gl_tree_big", "gl_tree", "gl_apple", "tr_leafy", "tr_blossom", "tr_fruit", "tr_fruit2", "gl_tree_round", "tree_light2"]
BUSHES = ["gl_mound", "gl_mound2", "gl_redbush", "gl_bluebush", "gl_bush", "gl_yellowbush", "gl_bluebush2", "gl_yellowbush2",
          "gl_mound3", "gl_mound4", "gl_bluebush3", "shrub2", "shrub5", "bush_a"]
SMALL = ["gl_flower", "gl_flower2", "gl_sprout", "gl_pinkflower", "gl_redplant", "gl_grass", "flower0", "flower2", "flower3", "weed0", "weed2"]
ROCKS = ["gl_rock", "gl_rock2", "gl_rock3", "gl_rock4", "gl_stone", "gl_stone2", "rock_big", "rock_tall", "rock_s1"]

# ---- monsters --------------------------------------------------------------------
MON = {
    "slime":   dict(pack="mon_slimes_01", kinds=["Slime1", "Slime2", "Slime3"], name="Limo", props=dict(max_hp=3, damage=1, speed=14, chase_speed=26, aggro_radius=64, attack_range=14, gold=2, territory=70)),
    "slime_x": dict(pack="mon_special_slimes_mobs01", kinds=["Slime1", "Slime2", "Slime3"], name="Limo extraño", props=dict(max_hp=5, damage=1, speed=16, chase_speed=30, aggro_radius=72, attack_range=15, gold=3, territory=80)),
    "goblin":  dict(pack="mon_goblin_mobs01", kinds=["Goblin1", "Goblin2", "Goblin3"], name="Goblin", props=dict(max_hp=5, damage=1, speed=22, chase_speed=44, aggro_radius=96, attack_range=18, gold=4, territory=90)),
    "gnoll":   dict(pack="mon_gnolls_mobs01", kinds=["Gnoll1", "Gnoll2", "Gnoll3"], name="Gnoll", props=dict(max_hp=8, damage=2, speed=24, chase_speed=52, aggro_radius=110, attack_range=20, gold=6, territory=110)),
    "golem":   dict(pack="mon_golem_bosses01", kinds=["Golem1"], name="Gólem de las Ruinas", props=dict(max_hp=40, damage=3, speed=12, chase_speed=22, aggro_radius=120, attack_range=30, gold=60, territory=90, boss="true", respawn_time=180, body_size="Vector2(30, 10)")),
    "ent":     dict(pack="mon_ent_bosses_01", kinds=["Ent1"], name="Ent Ancestral", props=dict(max_hp=50, damage=3, speed=10, chase_speed=20, aggro_radius=120, attack_range=32, gold=80, territory=80, boss="true", respawn_time=180, body_size="Vector2(30, 10)")),
    # forest dwellers: smaller versions of the bosses' kin
    "sapling": dict(pack="mon_ent_bosses_01", kinds=["Ent2"], name="Retoño del bosque", props=dict(max_hp=9, damage=2, speed=12, chase_speed=30, aggro_radius=84, attack_range=18, gold=5, territory=80, sprite_scale=0.55, body_size="Vector2(14, 6)")),
    "treant": dict(pack="mon_ent_bosses_01", kinds=["Ent3"], name="Ent frondoso", props=dict(max_hp=16, damage=3, speed=11, chase_speed=26, aggro_radius=96, attack_range=22, gold=9, territory=80, sprite_scale=0.72, body_size="Vector2(18, 7)")),
    "mossy": dict(pack="mon_slimes02", kinds=["Slime_boss2"], name="Limo musgoso", props=dict(max_hp=7, damage=1, speed=15, chase_speed=30, aggro_radius=76, attack_range=16, gold=4, territory=80, sprite_scale=0.5, body_size="Vector2(14, 6)")),
    "mist": dict(pack="mon_slimes02", kinds=["Slime_boss3"], name="Limo de bruma", props=dict(max_hp=8, damage=2, speed=16, chase_speed=32, aggro_radius=80, attack_range=16, gold=5, territory=80, sprite_scale=0.5, body_size="Vector2(14, 6)")),
    "crystal": dict(pack="mon_golem_bosses01", kinds=["Golem2"], name="Gólem de cristal", props=dict(max_hp=14, damage=3, speed=12, chase_speed=24, aggro_radius=90, attack_range=20, gold=8, territory=70, sprite_scale=0.55, body_size="Vector2(16, 7)")),
    "slimeking": dict(pack="mon_slimes02", kinds=["Slime_boss1"], name="Rey Limo", props=dict(max_hp=35, damage=2, speed=14, chase_speed=26, aggro_radius=110, attack_range=30, gold=50, territory=80, boss="true", respawn_time=180, body_size="Vector2(32, 12)")),
}
_mon_frames = {}


def monster_frames(pack, kind):
    """SpriteFrames .tres for a monster: idle/walk/run/attack/hurt/death x down/up/left/right."""
    import w_export as WE
    key = (pack, kind)
    if key in _mon_frames:
        return _mon_frames[key]
    folder = os.path.join(RAW, pack, "PNG", kind, "With_shadow")
    files = glob.glob(os.path.join(folder, "*.png"))

    def find(word, avoid=()):
        for f in files:
            b = os.path.basename(f).lower()
            if word in b and not any(a in b for a in avoid):
                return f
        return None
    anims = {"idle": find("idle"), "walk": find("walk", ("attack",)), "run": find("run", ("attack",)),
             "attack": find("attack", ("run", "walk", "attack2")), "hurt": find("hurt"), "death": find("death")}
    fr = WE.Frames()
    foot = None
    fs = None
    for name, f in anims.items():
        if not f:
            continue
        pil = Image.open(f).convert("RGBA")
        fs = pil.height // 4
        n = pil.width // fs
        res = WE.res_for_raw(f)
        for r, d in enumerate(["down", "up", "left", "right"]):
            rects = [(i * fs, r * fs, fs, fs) for i in range(n) if pil.crop((i * fs, r * fs, i * fs + fs, r * fs + fs)).getbbox()]
            if rects:
                fps = {"idle": 7, "walk": 9, "run": 12, "attack": 12, "hurt": 12, "death": 10}[name]
                fr.anim("%s_%s" % (name, d), res, rects, fps, loop=name in ("idle", "walk", "run"))
        if name == "idle":
            bb = pil.crop((0, 0, fs, fs)).getbbox()
            foot = bb[3] - 3 if bb else fs * 0.75
    path = "resources/sprite_frames/monsters/%s_%s.tres" % (pack.replace("mon_", ""), kind.lower())
    WE.write(path, fr.text())
    _mon_frames[key] = ("res://" + path, fs / 2 - foot)
    return _mon_frames[key]


def monster(w, mtype, tx, ty, variant=0, name_override=None):
    m = MON[mtype]
    kind = m["kinds"][variant % len(m["kinds"])]
    path, off = monster_frames(m["pack"], kind)
    props = dict(m["props"])
    props["sprite_offset_y"] = round(off, 1)
    props["monster_name"] = '"%s"' % (name_override or m["name"])
    w.monsters.append(dict(name=mtype.capitalize() + "_" + kind, frames=path, pos=(tx * 16, ty * 16), props=props))


def pack_monsters(w, mtype, cx, cy, n, spread=3.5, own=False):
    """`own`: roll the monsters' own dice (newer packs), so adding them never reshuffles trees and flowers."""
    if not own:
        for i in range(n):
            a = w.rng.random() * math.tau
            r = w.rng.uniform(0.5, spread)
            monster(w, mtype, cx + math.cos(a) * r, cy + math.sin(a) * r, variant=w.rng.randrange(3))
        return
    if not hasattr(w, "mrng"):
        import random
        w.mrng = random.Random(4242)
    rng = w.mrng
    for i in range(n):
        for _try in range(12):
            a = rng.random() * math.tau
            r = rng.uniform(0.5, spread)
            x, y = cx + math.cos(a) * r, cy + math.sin(a) * r
            c = (int(x), int(y))
            if c not in w.solids and c not in getattr(w, "hill_cells", set()):
                break
        monster(w, mtype, x, y, variant=rng.randrange(3))


# ---- terrain helpers ---------------------------------------------------------------
def hill(w, cells):
    """Raised grassy mesa with a cliff face (farm 'Hill' tiles); solid scenery."""
    for (x, y) in cells:
        n = (x, y - 1) in cells; s = (x, y + 1) in cells; we = (x - 1, y) in cells; e = (x + 1, y) in cells
        k = "c"
        if not n and not we: k = "tl"
        elif not n and not e: k = "tr"
        elif not s and not we: k = "bl"
        elif not s and not e: k = "br"
        elif not n: k = "t"
        elif not s: k = "b"
        elif not we: k = "l"
        elif not e: k = "r"
        at = HILL_NINE[k]
        if k == "b":
            at = w.rng.choice([(2, 9), (2, 9), (6, 7), (10, 7)])
        w.put("hill", x, y, FG, at, "full")
        if k in ("b", "bl", "br"):
            base = {"bl": (1, 10), "br": (3, 10), "b": {(2, 9): (2, 10), (6, 7): (6, 8), (10, 7): (10, 8)}.get(at, (2, 10))}[k]
            w.put("hill", x, y + 1, FG, base, "full")
    w.blocked |= cells | {(x, y + 1) for (x, y) in cells}


def blob(cx, cy, rx, ry, wobble=0.25, seed=0):
    cells = set()
    for y in range(int(cy - ry - 3), int(cy + ry + 4)):
        for x in range(int(cx - rx - 3), int(cx + rx + 4)):
            a = math.atan2(y - cy, x - cx)
            r = 1 + wobble * math.sin(a * 3 + seed) + wobble * 0.6 * math.sin(a * 5 + seed * 2)
            if ((x - cx) / (rx * r)) ** 2 + ((y - cy) / (ry * r)) ** 2 <= 1:
                cells.add((x, y))
    # remove 1-wide spurs so the autotile always has a valid piece
    changed = True
    while changed:
        changed = False
        for (x, y) in list(cells):
            if ((x - 1, y) not in cells and (x + 1, y) not in cells) or ((x, y - 1) not in cells and (x, y + 1) not in cells):
                cells.discard((x, y)); changed = True
    return cells


def lake(w, cells, island=None):
    for (x, y) in cells:
        w.put("water", x, y, WD, (36, 0))
        w.erase("ground", x, y)
        w.solids.add((x, y))
    land = {(x, y) for x in range(W) for y in range(H)} - cells
    if island:
        land |= island
        for c in island:
            w.solids.discard(c)
    border = set()
    for (x, y) in land:
        if any((x + dx, y + dy) in cells and (x + dx, y + dy) not in (island or set()) for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
            border.add((x, y))
    for (x, y) in border:
        n = (x, y - 1) in land; s = (x, y + 1) in land; we = (x - 1, y) in land; e = (x + 1, y) in land
        if not s and not we: k = "bl"
        elif not s and not e: k = "br"
        elif not n and not we: k = "tl"
        elif not n and not e: k = "tr"
        elif not s: k = "b"
        elif not n: k = "t"
        elif not we: k = "l"
        elif not e: k = "r"
        elif (x + 1, y + 1) not in land: k = "se"
        elif (x - 1, y + 1) not in land: k = "sw"
        elif (x + 1, y - 1) not in land: k = "ne"
        else: k = "nw"
        at = GRASS_INNER[k] if k in GRASS_INNER else GRASS_ISLAND[k]
        w.erase("ground", x, y)
        w.put("water", x, y, WD, (36, 0))
        w.put("coast", x, y, FWCG, at)
        w.solids.add((x, y))
    w.blocked |= cells | border


def path(w, pts, width=3.6):
    cells = {c for c in road_mask(pts, width) if 0 < c[0] < W - 1 and 0 < c[1] < H}
    cells = {c for c in cells if c not in w.solids}
    w.field_path |= cells


def scatter(w, keys, rect, n, min_dist=2.0, avoid_path=True):
    rng = w.rng
    x0, y0, x1, y1 = rect
    placed = []
    tries = 0
    while len(placed) < n and tries < n * 40:
        tries += 1
        x, y = rng.uniform(x0, x1), rng.uniform(y0, y1)
        c = (int(x), int(y))
        if c in w.blocked or c in w.solids or (avoid_path and any((c[0] + dx, c[1] + dy) in w.field_path for dx in (-1, 0, 1) for dy in (-1, 0, 1))):
            continue
        if any((x - a) ** 2 + (y - b) ** 2 < min_dist ** 2 for a, b in placed + w.field_points):
            continue
        placed.append((x, y))
        prop(w, rng.choice(keys), x, y, flip=rng.random() < 0.5)
    w.field_points += [p for p in placed if True]
    return placed


def camp_actor(w, name, file, region, offsets, px, py, talk=None, bubble=None, ms=150):
    """Each sheet packs 2-3 variants of a character side by side; `region` is one variant's box in the
    first frame and `offsets` the frame steps from the pack's Tiled animations (Tiled_files/Characters.tmx)."""
    img = os.path.join(RAW, "campfire_asset/PNG", file)
    frames = [(ox, oy, ms) for (ox, oy) in offsets]
    return actor(w, name, px, py, img, region, frames, talk=talk, bubble=bubble)


# ---- the field -----------------------------------------------------------------------
def build():
    WP.bake(ROOT + "/assets/sprites/city/baked_buildings.png")
    w = World(W, H, seed=77)
    w.monsters = []
    w.field_path = set()
    w.field_points = []
    rng = w.rng
    for y in range(H):
        for x in range(W):
            w.put("ground", x, y, FG, GRASS_TILE)
    w.land = {(x, y) for x in range(W) for y in range(H)}

    # water: the Mirror Lake (east) with an island, a marsh pond (north-east), a pond (west)
    lake_cells = blob(132, 72, 20, 14, 0.22, 1.3)
    island = blob(136, 70, 4.5, 3.5, 0.15, 0.4)
    lake(w, lake_cells - island, island)
    for (cx, cy, rx, ry, sd) in ((140, 26, 7, 4.5, 2.1), (150, 34, 4.5, 3, 0.7), (128, 30, 4, 3, 3.3), (34, 66, 5, 3.5, 1.1)):
        lake(w, blob(cx, cy, rx, ry, 0.2, sd))

    # hills (mesas) give the field relief
    hills = []
    for (cx, cy, rx, ry, sd) in ((52, 104, 9, 5, 0.3), (118, 108, 8, 4.5, 1.7), (56, 48, 7, 4, 2.4), (110, 44, 6, 4, 0.9),
                                  (24, 106, 6, 4, 1.3), (150, 106, 7, 5, 2.8), (70, 20, 5, 3, 0.2), (40, 72, 4, 3, 1.1)):
        hc = blob(cx, cy, rx, ry, 0.15, sd)
        hill(w, hc)
        hills.append(hc)
    w.hill_cells = set().union(*hills) | {(x, y + 1) for h in hills for (x, y) in h}

    # winding paths between landmarks
    P = [
        [(85.5, 131), (85, 120), (82, 110), (78, 100), (80, 90), (82, 80), (83, 72)],          # entrance -> ruins
        [(79, 99), (68, 96), (56, 91), (44, 86), (32, 82), (22, 80)],                            # -> goblin camp (west)
        [(81, 97), (94, 96), (104, 92), (108, 86), (109, 78)],                                   # -> lake shore & bridge
        [(83, 56), (84, 48), (88, 40), (92, 34), (94, 32)],                                      # ruins -> traveler camp
        [(86, 44), (74, 40), (60, 34), (46, 30), (34, 28)],                                      # -> haunted grove (north-west)
        [(94, 32), (106, 32), (118, 30), (126, 34)],                                             # camp -> marsh
        [(154, 72), (160, 78), (160, 92), (154, 100), (146, 112)],                               # far shore -> east hills
    ]
    for pts in P:
        path(w, pts, 3.6)
    # wooden bridge over the lake to the island and the far shore: each span starts and ends square,
    # one tile onto dry land, so the path meets it cleanly
    rows = (70, 71, 72)
    wet = [x for x in range(108, 160) if any((x, y) in w.solids or (x, y) in lake_cells for y in rows)]
    spans = []
    for x in wet:
        if spans and x == spans[-1][1] + 1:
            spans[-1][1] = x
        else:
            spans.append([x, x])
    deck = set()
    for (x0, x1) in spans:
        for x in range(x0 - 1, x1 + 2):
            for r, y in enumerate(rows):
                w.put("dock", x, y, EX, (x % 7, (0, 1, 3)[r]))
                w.solids.discard((x, y))
                deck.add((x, y))
            if (x, 73) in lake_cells and x % 4 == 0:
                w.put("dock_fx", x, 73, PL, (0, 0)); w.put("dock_fx", x, 74, PL, (0, 1))
    w.field_path -= deck
    w.blocked |= {(x, y) for (x, _y) in deck for y in range(67, 75)}
    west, east = spans[0][0] - 1, spans[-1][1] + 1
    for pts in ([(109, 76), (109, 72.5), (west - 1, 71.5)], [(east + 1, 71.5), (156, 74), (158, 76)]):
        before = set(w.field_path)
        path(w, pts, 3.4)
        w.field_path -= (w.field_path - before) & deck
    # keep both bridgeheads clear of trees and rocks
    w.blocked |= rect_cells(102, 64, 119, 80) | rect_cells(149, 64, 162, 80)
    autotile(w, "ground_overlay", w.field_path, FG, nine_at(19, 1), {"se": (22, 1), "sw": (23, 1), "ne": (22, 2), "nw": (23, 2)}, center_variants=[(20, 2)])
    w.blocked |= w.field_path

    # ---- landmarks --------------------------------------------------------------------
    # Ancient ruins at the heart of the field: broken paving + a ring of ruined walls
    paving = set()
    for (cx, cy, rx, ry, sd) in ((83, 64, 11, 7, 0.4), (73, 60, 4, 3, 1.2), (94, 60, 4, 3, 2.2), (83, 54, 4, 2.5, 0.8)):
        paving |= blob(cx, cy, rx, ry, 0.3, sd)
    paving = {c for c in paving if c not in w.solids}
    import w_terrain as _WT
    autotile(w, "road", paving, RD, _WT.ROAD_NINE, _WT.ROAD_INNER, center_variants=[(2, 2), (2, 2), (2, 2)])
    w.blocked |= paving
    for (k, x, y) in (("ruin_tower2", 83, 60), ("ruin_arch", 72.5, 63), ("ruin_arch2", 94, 64), ("ruin_column", 70, 57.5), ("ruin_column2", 97, 58),
                      ("ruin_pillar", 77.5, 55), ("ruin_pillar2", 89, 55), ("ruin_pillar", 75, 70, ), ("ruin_pillar2", 92, 70.5),
                      ("ruin_rubble", 79, 71.5), ("ruin_rubble", 88, 72), ("ruin_tower", 64.5, 68), ("gl_rocks_s", 100, 66), ("gl_stone", 68, 66)):
        prop(w, k, x, y)
    w.blocked |= rect_cells(64, 50, 100, 74)
    w.field_points += [(83, 63), (74, 66), (92, 67)]
    monster(w, "golem", 83, 69)
    # Traveler's camp (safe haven)
    # tents at the back, the fire in the middle with a log on each side, the road passing in front
    for (k, x, y) in (("tent_white", 88, 21.5), ("tent_green", 102, 21.5), ("camp_rug", 88.5, 24.2)):
        prop(w, k, x, y)
    prop(w, "camp_log", 91.5, 28.6); prop(w, "camp_log", 98.5, 28.6); prop(w, "camp_chest", 105.5, 24.5); prop(w, "camp_trunk", 84.5, 24.5)
    prop(w, "camp_bedroll", 100.5, 24.6, flip=True)
    w.blocked |= rect_cells(82, 17, 108, 34)   # the camp stays clear of random rocks and trees
    camp_actor(w, "cook", "Bonfire_boiler_lizardman.png", (0, 0, 62, 58), [(c * 112, r * 112) for c in range(3) for r in range(4)], 95 * 16, 27.4 * 16,
               talk=("Varka, cocinera", ["Siéntate junto al fuego. La llanura es más peligrosa de lo que parece.",
                                         "Los limos son lentos, pero no dejes que te rodeen."]), bubble=["El guiso ya casi está.", "Huele bien, ¿verdad?"])
    camp_actor(w, "drinker", "Drinker1.png", (0, 0, 32, 48), [(0, r * 48) for r in (0, 0, 0, 1, 2, 3, 4, 4, 4, 5, 6, 7)], 91.5 * 16, 28.45 * 16,
               talk=("Viajero", ["Vengo del este. En las colinas vi gnolls cazando en grupo."]))
    camp_actor(w, "lute", "Lute_player.png", (0, 0, 44, 48), [(0, r * 48) for r in range(6)], 98.5 * 16, 28.45 * 16,
               talk=("Juglar", ["Dicen que en las ruinas duerme un guardián de piedra. Yo no iría solo."]), bubble=["♪ ♪"])
    camp_actor(w, "sharpener", "Char_sharpens_weapons.png", (0, 0, 48, 32), [(c * 48, r * 64) for r in range(2) for c in range(6)], 85.5 * 16, 28.5 * 16,
               talk=("Mercenaria", ["Una hoja bien afilada vale más que una armadura pesada."]))
    camp_actor(w, "orc", "Orc.png", (0, 0, 32, 42), [(c * 32, 0) for c in (0, 0, 0, 0, 1, 2, 3, 3, 3, 4, 5, 6)], 104.5 * 16, 28.5 * 16,
               talk=("Grosh", ["No todos los orcos son enemigos. Yo solo quiero vender mis pieles en Valdoria."]))
    # Goblin camp (west)
    for (k, x, y) in (("tent_ragged", 20, 76), ("tent_purple", 30, 72), ("camp_bones", 24, 82), ("camp_crystals", 34, 79), ("crates_c", 16, 82)):
        prop(w, k, x, y)
    pack_monsters(w, "goblin", 25, 80, 6, 5)
    # Haunted grove (north-west) with the Ent
    scatter(w, GROVE, (8, 8, 52, 40), 46, min_dist=3.6)
    monster(w, "ent", 30, 24)
    # Marsh (north-east) with the Slime King
    scatter(w, ["gl_reeds", "gl_crystalbush", "gl_crystalbush2", "gl_bluebush", "tr_willow_m"], (120, 16, 162, 42), 24, min_dist=2.6)
    monster(w, "slimeking", 136, 34)
    pack_monsters(w, "slime_x", 146, 40, 4, 4)
    # Gnoll hills (south-east)
    pack_monsters(w, "gnoll", 140, 108, 5, 6)
    pack_monsters(w, "gnoll", 158, 92, 3, 4)
    # Slimes along the first stretch of road (easy encounters)
    for (cx, cy) in ((76, 112), (92, 108), (68, 98), (96, 90), (58, 82), (108, 62)):
        pack_monsters(w, "slime", cx, cy, 3, 3)
    pack_monsters(w, "goblin", 46, 60, 3, 3)
    pack_monsters(w, "slime_x", 120, 54, 3, 3)
    # more life on the meadow
    for (cx, cy) in ((112, 100), (64, 46), (148, 50), (100, 76), (58, 116), (124, 118)):
        pack_monsters(w, "slime", cx, cy, 3, 3, own=True)
    for (cx, cy) in ((72, 30), (116, 20), (40, 96)):
        pack_monsters(w, "slime_x", cx, cy, 3, 3, own=True)
    for (cx, cy, n) in ((52, 92, 4), (104, 84, 3), (66, 78, 3), (116, 40, 3)):
        pack_monsters(w, "goblin", cx, cy, n, 3.5, own=True)
    for (cx, cy, n) in ((148, 96, 3), (160, 64, 3), (128, 106, 4)):
        pack_monsters(w, "gnoll", cx, cy, n, 4, own=True)
    # the forests: saplings, treants and mossy slimes under the trees
    pack_monsters(w, "sapling", 18, 16, 3, 3, own=True); pack_monsters(w, "sapling", 42, 14, 3, 3, own=True)
    pack_monsters(w, "treant", 16, 34, 2, 3, own=True); pack_monsters(w, "treant", 44, 34, 2, 3, own=True)
    pack_monsters(w, "mossy", 26, 12, 3, 3, own=True); pack_monsters(w, "mossy", 36, 36, 3, 3, own=True)
    pack_monsters(w, "sapling", 22, 48, 3, 4, own=True); pack_monsters(w, "mossy", 30, 58, 3, 3, own=True); pack_monsters(w, "treant", 14, 56, 2, 3, own=True)
    pack_monsters(w, "sapling", 20, 94, 3, 3, own=True); pack_monsters(w, "mossy", 48, 112, 3, 3, own=True); pack_monsters(w, "treant", 64, 118, 2, 3, own=True)
    pack_monsters(w, "sapling", 108, 116, 3, 3, own=True); pack_monsters(w, "treant", 140, 118, 2, 3, own=True); pack_monsters(w, "mossy", 156, 116, 3, 3, own=True)
    # crystal golems around the ruins, mist slimes in the marsh
    for (cx, cy) in ((70, 48), (98, 50), (62, 76), (104, 70)):
        pack_monsters(w, "crystal", cx, cy, 2, 2.5, own=True)
    for (cx, cy) in ((126, 22), (156, 24), (142, 44)):
        pack_monsters(w, "mist", cx, cy, 3, 3, own=True)

    # ---- vegetation: dense forest walls, groves, lone trees, flowers --------------------
    border_rects = [(0, 0, 8, H), (W - 8, 0, W, H), (0, 0, W, 8), (0, H - 8, ENTRY_X[0] - 3, H), (ENTRY_X[1] + 3, H - 8, W, H)]
    for r in border_rects:
        scatter(w, FOREST, r, int((r[2] - r[0]) * (r[3] - r[1]) / 14), min_dist=2.8, avoid_path=False)
    for r in ((10, 40, 40, 64), (130, 96, 166, 124), (40, 108, 70, 124), (100, 112, 130, 124), (8, 86, 30, 100)):
        scatter(w, FOREST, r, 14, min_dist=3.6)
    # ---- treasure chests: rewards at the landmarks (tier 0-4: better chest, better loot)
    def free_spot(x, y):
        best = None
        for r in range(0, 6):
            for dy in range(-r, r + 1):
                for dx in range(-r, r + 1):
                    c = (x + dx, y + dy)
                    if any((c[0] + i, c[1] + j) in w.solids for i in (-1, 0, 1) for j in (-1, 0)):
                        continue
                    if c in w.hill_cells:
                        continue
                    if any(abs(pp["pos"][0] / 16 - (c[0] + 0.5)) < 1.6 and abs(pp["pos"][1] / 16 - (c[1] + 0.9)) < 1.3 for pp in w.props if not pp["floor"]):
                        continue
                    return c
        return (x, y)
    w.chests = []
    for (x, y, tier) in ((86, 57, 3), (136, 67, 3), (28, 22, 3), (134, 37, 3), (25, 77, 2), (161, 118, 1),
                         (70, 113, 0), (40, 61, 1), (64, 24, 1), (118, 96, 2), (100, 40, 1), (12, 116, 2)):
        c = free_spot(x, y)
        w.chests.append((c[0] + 0.5, c[1] + 0.9, tier))
        w.blocked |= rect_cells(c[0] - 1, c[1] - 2, c[0] + 1, c[1] + 1)
    scatter(w, LONE, (10, 10, 160, 120), 44, min_dist=9)
    scatter(w, ROCKS, (10, 10, 160, 120), 40, min_dist=7)
    scatter(w, BUSHES, (10, 10, 160, 122), 120, min_dist=3.2)
    scatter(w, SMALL, (8, 8, 162, 124), 320, min_dist=1.1)
    for hc in hills:
        top = [c for c in hc if (c[0], c[1] + 1) in hc and (c[0], c[1] + 2) in hc and (c[0] - 1, c[1]) in hc and (c[0] + 1, c[1]) in hc]
        for c in rng.sample(top, min(len(top), 4)):
            prop(w, rng.choice(LONE + ROCKS + ["gl_mound", "gl_bush"]), c[0] + 0.5, c[1] + 0.9)
    for _ in range(22):
        cx, cy = rng.uniform(14, 156), rng.uniform(14, 120)
        for _k in range(rng.randint(10, 18)):
            x, y = cx + rng.gauss(0, 2.2), cy + rng.gauss(0, 1.6)
            c = (int(x), int(y))
            if c in w.blocked or c in w.solids or c in w.field_path:
                continue
            prop(w, rng.choice(["gl_flower", "gl_flower2", "gl_pinkflower", "gl_grass", "gl_sprout", "flower0", "flower1", "flower3", "weed1", "gl_redplant"]), x, y)
    tufts = [(x, 8) for x in range(0, 21)]
    for _ in range(1600):
        x, y = rng.randrange(1, W - 1), rng.randrange(1, H - 1)
        if (x, y) not in w.blocked and (x, y) not in w.solids:
            w.put("detail", x, y, GD, rng.choice(tufts))
    # animals grazing far from the monsters
    import w_outside as WO
    # (only a few: the wild animals live on the farms and the meadow by the city)
    for kind, n in (("Deer", 1), ("Hare", 2)):
        for _ in range(n):
            x, y = rng.uniform(56, 114), rng.uniform(78, 118)
            WO.animal(w, kind, x * 16, y * 16, (52 * 16, 76 * 16, 66 * 16, 44 * 16))
    # trail from the Whispering Woods up to the Deep Forest (north gap). Carved last, so the rest of the
    # field keeps its layout: clear the trees on the way and repaint the dirt paths.
    trail = {c for c in road_mask([(34, 28), (31, 20), (30, 10), (30, -1)], 3.4) if 0 <= c[0] < W and 0 <= c[1] < H}
    trail = {c for c in trail if c not in w.solids}
    near = {(x + dx, y + dy) for (x, y) in trail for dx in (-2, -1, 0, 1, 2) for dy in (-1, 0, 1, 2)}
    near |= set(rect_cells(NORTH_GAP[0] - 1, 0, NORTH_GAP[1] + 1, 9))
    w.props = [pp for pp in w.props if pp["floor"] or (int(pp["pos"][0] // 16), int((pp["pos"][1] - 1) // 16)) not in near]
    w.field_path |= trail
    autotile(w, "ground_overlay", w.field_path, FG, nine_at(19, 1), {"se": (22, 1), "sw": (23, 1), "ne": (22, 2), "nw": (23, 2)}, center_variants=[(20, 2)])
    for c in trail:
        w.layers.get("detail", {}).pop(c, None)
    # caravan trail east to the Desert of Amber (gap in the east forest wall)
    east = {c for c in road_mask([(160, 78), (165, 79), (171, 79)], 3.4) if 0 <= c[0] < W and 0 <= c[1] < H}
    east = {c for c in east if c not in w.solids}
    near = {(x + dx, y + dy) for (x, y) in east for dx in (-1, 0, 1) for dy in (-2, -1, 0, 1, 2)}
    near |= set(rect_cells(W - 9, EAST_GAP[0] - 1, W, EAST_GAP[1] + 1))
    w.props = [pp for pp in w.props if pp["floor"] or (int(pp["pos"][0] // 16), int((pp["pos"][1] - 1) // 16)) not in near]
    w.field_path |= east
    autotile(w, "ground_overlay", w.field_path, FG, nine_at(19, 1), {"se": (22, 1), "sw": (23, 1), "ne": (22, 2), "nw": (23, 2)}, center_variants=[(20, 2)])
    for c in east:
        w.layers.get("detail", {}).pop(c, None)
    w.graph = WL.Graph()
    return w


GRASS_TILE = (17, 8)

FIELD_CFG = dict(
    out="scenes/world/field.tscn", tileset="res://resources/tilesets/field_tileset.tres", stamina=True,
    minimap="res://resources/world/minimap_field.png", title="Llanura de Valdoria", hunters=10,
    preview_layers=["water", "water_fx", "ground", "ground_overlay", "hill", "road", "detail", "coast", "dock", "dock_fx"],
    walkmask="res://resources/world/field_walkmask.png", player=(85.5 * 16, 124 * 16),
    zones=[("Ruinas Antiguas", (62, 48, 104, 76)), ("Campamento del Viajero", (80, 16, 110, 34)),
           ("Bosque de los Susurros", (6, 6, 54, 42)), ("Lago Espejo", (108, 54, 160, 90)),
           ("Pantano del Norte", (118, 14, 166, 44)), ("Campamento goblin", (10, 66, 40, 88)),
           ("Colinas del Este", (128, 94, 170, 130)), ("Llanura de Valdoria", (0, 0, 170, 130))],
    exits=[dict(name="SouthExit", pos=(85.5 * 16, 130 * 16 - 18), size=(8 * 16, 24), scene="res://scenes/world/world.tscn", spawn="north_gate", dir="down"),
           dict(name="NorthExit", pos=(30 * 16, 18), size=(6 * 16, 24), scene="res://scenes/world/forest.tscn", spawn="south", dir="up"),
           dict(name="EastExit", pos=(W * 16 - 18, 79 * 16), size=(24, 6 * 16), scene="res://scenes/world/desert.tscn", spawn="west", dir="right")],
    spawns={"south": (85.5 * 16, 124 * 16), "respawn": (85.5 * 16, 124 * 16), "start": (85.5 * 16, 124 * 16), "north": (30 * 16, 5 * 16), "east": (165 * 16, 79 * 16)},
    bottom_gap=ENTRY_X, top_gap=NORTH_GAP, right_gap=EAST_GAP,
)


if __name__ == "__main__":
    import w_export as WE, w_preview as PV, sys
    w = build()
    if "--preview" in sys.argv:
        PV.LAYER_ORDER[:] = ["water", "water_fx", "ground", "ground_overlay", "hill", "road", "detail", "coast", "dock", "dock_fx"]
        w.actors += []
        PV.render(w, "../field.png", 1)
    else:
        WE.FRAMES_DIR = "field"
        for f in glob.glob(os.path.join(ROOT, "resources/sprite_frames/field/*.tres")):
            os.remove(f)
        for sheet in WP.SHEETS:
            if WP.SHEETS[sheet][0]:
                WE.res_for_raw(os.path.join(RAW, WP.SHEETS[sheet][0]))
        WE.LAYERS.insert(4, ("hill", True))
        WE.tileset(w, "resources/tilesets/field_tileset.tres")
        WE.walk_mask(w, "resources/world/field_walkmask.png")
        WE.scene(w, FIELD_CFG)
        print("field: props", len(w.props), "actors", len(w.actors), "monsters", len(w.monsters), "animals", len(w.animals))
