"""Páramo del Ocaso: the land the Eclipse poisoned, east of Aurelia (post-game, levels 72-90).
The field's grass turned to violet ash, dead trees and ruins. The Twilight Post (safe haven) at the
entrance, the Ash Flats where the Black Sun cultists gather, the Withered Wood (the Corrupted Elder
Ent sleeps there), the Tar Lake, the Sunken Temple and, east, the Black Sun Crater with the way down
to the Pit of Dusk (wave dungeon)."""
import colorsys, glob, math, os, random
from PIL import Image
import w_snow_assets as SA   # noqa: F401  (registers the dusk monsters)
from w_field import *
import w_field as WF
import w_common as C
from w_coast import FWCG

OW, OH = 150, 110
GATE_W = (52, 58)      # to Aurelia (west edge)

# ---- ash versions of the field's tile sheets ---------------------------------------------
ASH_FG, ASH_GD, ASH_SHORE, ASH_WD = 21, 22, 23, 24
REMAP = {FG: ASH_FG, GD: ASH_GD, FWCG: ASH_SHORE, WD: ASH_WD}
GREEN = lambda h, s, v: 0.14 <= h <= 0.48 and s > 0.15
WARM = lambda h, s, v: h <= 0.13 and s > 0.2
ANY_BLUE = lambda h, s, v: 0.45 <= h <= 0.7
ASH_LO, ASH_HI = (58, 48, 70), (150, 136, 160)


def _make(src_rel, dst_rel, steps):
    im = Image.open(os.path.join(RAW, src_rel)).convert("RGBA")
    for st in steps:
        SA._ramp(im, *st)
    os.makedirs(os.path.dirname(os.path.join(RAW, dst_rel)), exist_ok=True)
    im.save(os.path.join(RAW, dst_rel))


_make(C.SOURCES[FG][0], "dusk_gen/ground_ash.png", [(GREEN, ASH_LO, ASH_HI),
      (WARM, (70, 40, 44), (150, 92, 86), 0.3, 0.5, (19 * 16, 16, 24 * 16, 4 * 16))])     # paths: scorched earth
_make(C.SOURCES[GD][0], "dusk_gen/details_ash.png", [(GREEN, (92, 70, 104), (176, 150, 190))])
_make(C.SOURCES[FWCG][0], "dusk_gen/shore_ash.png", [(GREEN, ASH_LO, ASH_HI)])
_make(C.SOURCES[WD][0], "dusk_gen/water_tar.png", [(ANY_BLUE, (30, 14, 44), (118, 66, 140), 0.3, 0.6)])
for sid, dst in ((ASH_FG, "ground_ash"), (ASH_GD, "details_ash"), (ASH_SHORE, "shore_ash"), (ASH_WD, "water_tar")):
    C.SOURCES[sid] = ("dusk_gen/%s.png" % dst, "assets/sprites/dusk/tiles/%s.png" % dst)
C.ANIM_ALIAS[ASH_SHORE] = C.WC
C.ANIM_ALIAS[ASH_WD] = WD
C.ANIM_ALIAS[ASH_FG] = FG
C.ANIM_ALIAS[ASH_GD] = GD


def remap_to_ash(w):
    for name, cells in w.layers.items():
        for c, (src, at, alt) in list(cells.items()):
            if src in REMAP:
                cells[c] = (REMAP[src], at, alt)
    for (src, at), kind in list(w.collide.items()):
        if src in REMAP:
            w.collide[(REMAP[src], at)] = kind


ZONES = [("Puesto del Crepúsculo", (2, 40, 26, 70)), ("Bosque Marchito", (14, 4, 96, 32)), ("Llanos de Ceniza", (26, 32, 96, 78)),
         ("Templo Hundido", (14, 78, 70, 106)), ("Lago de Brea", (84, 66, 138, 104)), ("Cráter del Sol Negro", (100, 8, 146, 62)),
         ("Páramo del Ocaso", (0, 0, OW, OH))]
DEAD = ["tr_dead", "tr_dead_m", "tr_dead", "gl_stump", "gl_stump2", "tr_stump"]
ROCKS = ["gl_rock", "gl_rock2", "gl_rock3", "gl_rock4", "gl_stone", "gl_stone2", "rock_big"]
RUINS = ["ruin_column", "ruin_column2", "ruin_pillar", "ruin_pillar2", "ruin_rubble"]


def build():
    WP.bake(ROOT + "/assets/sprites/city/baked_buildings.png")
    w = World(OW, OH, seed=8080)
    w.monsters = []
    w.field_path = set()
    w.field_points = []
    w.mrng = random.Random(4242)
    rng = w.rng
    for y in range(OH):
        for x in range(OW):
            w.put("ground", x, y, FG, GRASS_TILE)
    w.land = {(x, y) for x in range(OW) for y in range(OH)}

    # the tar lake and black pools
    lake(w, blob(112, 86, 16, 9, 0.22, 2.2))
    for (cx, cy, rx, ry, sd) in ((60, 56, 4, 3, 1.1), (36, 92, 4.5, 3, 0.4), (88, 24, 4, 3, 2.7)):
        lake(w, blob(cx, cy, rx, ry, 0.2, sd))
    hills = []
    for (cx, cy, rx, ry, sd) in ((46, 44, 5, 3.5, 0.9), (76, 66, 5, 3, 1.7), (138, 76, 5, 4, 0.3), (70, 96, 5, 3, 2.4)):
        hc = blob(cx, cy, rx, ry, 0.15, sd)
        hill(w, hc)
        hills.append(hc)
    w.hill_cells = set().union(*hills) | {(x, y + 1) for h in hills for (x, y) in h}

    P = [
        [(-1, 55), (8, 55), (18, 55), (30, 56)],                             # gate -> post -> flats
        [(30, 56), (44, 58), (60, 62), (78, 56), (96, 50)],                  # across the ash flats
        [(30, 56), (36, 40), (44, 26), (56, 18)],                            # -> withered wood
        [(96, 50), (110, 42), (122, 36)],                                    # -> black sun crater
        [(44, 58), (40, 74), (40, 86)],                                      # -> sunken temple
        [(78, 56), (92, 66), (100, 74)],                                     # -> tar lake shore
    ]
    for pts in P:
        path(w, pts, 3.2)
    autotile(w, "ground_overlay", w.field_path, FG, nine_at(19, 1), {"se": (22, 1), "sw": (23, 1), "ne": (22, 2), "nw": (23, 2)}, center_variants=[(20, 2)])
    w.blocked |= w.field_path

    # Twilight Post: the last camp before the ash (safe haven)
    for (k, x, y) in (("tent_purple", 9, 47.5), ("tent_ragged", 20, 47.5), ("camp_rug", 13.5, 51.2)):
        prop(w, k, x, y)
    actor(w, "campfire", 15 * T, 58 * T, SA.VILLAGE, (273, 88, 31, 38),
                    [(305 - 273, 0, 140), (337 - 273, 0, 140), (369 - 273, -3, 140)], collide=True)
    prop(w, "camp_log", 11.5, 60); prop(w, "camp_log", 18.5, 60); prop(w, "camp_trunk", 23, 52); prop(w, "camp_chest", 6, 52)
    w.blocked |= rect_cells(3, 43, 26, 63)
    camp_actor(w, "dusk_watch", "Char_sharpens_weapons.png", (0, 0, 48, 32), [(c * 48, r * 64) for r in range(2) for c in range(6)], 10.5 * 16, 58.5 * 16,
               talk=("Vigía Maren", ["Bienvenido al Puesto del Crepúsculo. Junto al fuego estás a salvo: tus pociones se rellenan aquí.",
                                    "Desde que cayó el Devorador, la tierra al este se volvió ceniza. Y los acólitos del Sol Negro no se fueron.",
                                    "Al este está el Cráter. Dicen que bajo él hay una fosa que no tiene fondo."]))
    # Sunken Temple: broken columns in rows
    for row in range(3):
        for col in range(6):
            if rng.random() < 0.75:
                prop(w, rng.choice(RUINS), 22 + col * 7 + rng.uniform(-0.8, 0.8), 84 + row * 7 + rng.uniform(-0.5, 0.5))
    w.blocked |= rect_cells(18, 80, 66, 104)
    # Black Sun Crater: a ring of ruins and crystals around the way down
    for i in range(14):
        a = i / 14 * math.tau
        prop(w, rng.choice(RUINS + ["camp_crystals"]), 124 + math.cos(a) * 13, 34 + math.sin(a) * 9)
    w.blocked |= rect_cells(114, 26, 134, 42)
    # Withered Wood clearing of the Elder
    for i in range(10):
        a = i / 10 * math.tau
        prop(w, "tr_dead" if i % 2 else "tr_dead_m", 60 + math.cos(a) * 10, 16 + math.sin(a) * 7)
    w.field_points += [(60, 16)]
    w.blocked |= rect_cells(53, 11, 67, 21)
    scatter(w, ["camp_crystals", "gl_crystalbush", "gl_crystalbush2"], (104, 10, 146, 60), 20, min_dist=3.0)

    # monsters
    monster(w, "dusk_elder", 60, 16)
    for (cx, cy) in ((40, 50), (52, 64), (66, 48), (84, 46), (90, 58), (58, 72)):
        pack_monsters(w, "dusk_cultist", cx, cy, 3, 3, own=True)
    for (cx, cy) in ((34, 66), (70, 38), (80, 74), (48, 34)):
        pack_monsters(w, "dusk_gnoll", cx, cy, 3, 3, own=True)
    for (cx, cy) in ((26, 20), (42, 12), (76, 12), (86, 30), (30, 30)):
        pack_monsters(w, "dusk_wolf", cx, cy, 3, 3.5, own=True)
    for (cx, cy) in ((50, 24), (70, 24), (36, 18)):
        pack_monsters(w, "dusk_ent", cx, cy, 2, 2.5, own=True)
    for (cx, cy) in ((110, 18), (138, 24), (140, 50), (108, 54)):
        pack_monsters(w, "eclipse_golem", cx, cy, 2, 2.5, own=True)
    for (cx, cy) in ((96, 78), (128, 70), (100, 96), (130, 98), (30, 96), (56, 98)):
        pack_monsters(w, "umbral_slime", cx, cy, 3, 3, own=True)

    w.chests = []
    for (x, y, tier) in ((60, 22, 4), (124, 46, 4), (40, 100, 3), (140, 92, 3), (88, 36, 2), (20, 26, 2), (72, 84, 2)):
        c = (x, y)
        for r in range(6):
            free = [(x + dx, y + dy) for dy in range(-r, r + 1) for dx in range(-r, r + 1)
                    if (x + dx, y + dy) not in w.solids and (x + dx, y + dy) not in w.hill_cells and (x + dx, y + dy) not in w.field_path]
            if free:
                c = free[0]
                break
        w.chests.append((c[0] + 0.5, c[1] + 0.9, tier))
        w.blocked |= rect_cells(c[0] - 1, c[1] - 2, c[0] + 1, c[1] + 1)

    # ---- dead woods and rocks at the edges and between the zones
    border = [(0, 0, 8, GATE_W[0] - 3), (0, GATE_W[1] + 3, 8, OH), (0, 0, OW, 7), (OW - 8, 0, OW, OH), (0, OH - 7, OW, OH)]
    for r in border:
        scatter(w, DEAD + ROCKS, r, int((r[2] - r[0]) * (r[3] - r[1]) / 12), min_dist=2.5, avoid_path=False)
    scatter(w, DEAD, (14, 4, 96, 32), 120, min_dist=3.0)
    scatter(w, DEAD + ROCKS, (8, 8, 142, 102), 90, min_dist=4.5)
    scatter(w, ["gl_rocks_s", "gl_grass", "gl_redplant", "tr_log"], (8, 8, 142, 102), 50, min_dist=5)
    tufts = [(x, 8) for x in range(0, 21)]
    for _ in range(900):
        x, y = rng.randrange(1, OW - 1), rng.randrange(1, OH - 1)
        if (x, y) not in w.blocked and (x, y) not in w.solids:
            w.put("detail", x, y, GD, rng.choice(tufts))
    remap_to_ash(w)
    w.graph = WL.Graph()
    return w


OCASO_CFG = dict(
    out="scenes/world/ocaso.tscn", tileset="res://resources/tilesets/ocaso_tileset.tres", stamina=True,
    minimap="res://resources/world/minimap_ocaso.png", title="Páramo del Ocaso", hunters=4,
    preview_layers=["water", "water_fx", "ground", "ground_overlay", "hill", "road", "detail", "coast", "dock", "dock_fx"],
    walkmask="res://resources/world/ocaso_walkmask.png", player=(5 * 16, 55 * 16),
    zones=ZONES,
    exits=[dict(name="WestExit", pos=(18, 55 * 16), size=(24, 6 * 16), scene="res://scenes/world/aurelia.tscn", spawn="east", dir="left")],
    spawns={"west": (5 * 16, 55 * 16), "respawn": (15 * 16, 55 * 16), "start": (5 * 16, 55 * 16)},
    left_gap=GATE_W,
)


if __name__ == "__main__":
    import w_export as WE
    w = build()
    WE.FRAMES_DIR = "ocaso"
    for f in glob.glob(os.path.join(ROOT, "resources/sprite_frames/ocaso/*.tres")):
        os.remove(f)
    for sheet in WP.SHEETS:
        if WP.SHEETS[sheet][0]:
            WE.res_for_raw(os.path.join(RAW, WP.SHEETS[sheet][0]))
    WE.LAYERS.insert(4, ("hill", True))
    WE.tileset(w, "resources/tilesets/ocaso_tileset.tres")
    WE.walk_mask(w, "resources/world/ocaso_walkmask.png")
    WE.scene(w, OCASO_CFG)
    print("ocaso: props", len(w.props), "actors", len(w.actors), "monsters", len(w.monsters), "chests", len(w.chests))
