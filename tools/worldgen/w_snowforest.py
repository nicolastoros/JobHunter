"""Bosque Nevado: a snowbound forest north of the Bosque Profundo (levels 50-70).
The Frozen Edge with a hunters' camp (safe haven) at the entrance, the White Pinewood, the Forgotten
Graveyard, the Frozen Lake (the Frost Slime King sleeps on its ice), the Crystal Grotto and, up north,
the Glade of the Winter Ent. East, the road to Villa Escarcha."""
import glob, math, os, random
import w_snow_assets as SA
from w_field import *
import w_field as WF

SW, SH = 160, 120
GATE_S = (77, 84)      # to the Bosque Profundo
GATE_E = (58, 64)      # to Villa Escarcha

ZONES = [("Linde Helada", (62, 98, 100, 120)), ("Pinar Blanco", (8, 56, 60, 98)), ("Cementerio Olvidado", (8, 8, 54, 50)),
         ("Lago Congelado", (92, 52, 152, 88)), ("Gruta de Cristal", (108, 8, 154, 46)), ("Claro del Ent Invernal", (58, 10, 102, 46)),
         ("Bosque Nevado", (0, 0, SW, SH))]


def camp_fire(w, x, y):
    """The village pack's campfire, animated (3 lit frames)."""
    frames = [(305 - 273, 0, 140), (337 - 273, 0, 140), (369 - 273, -3, 140)]
    return actor(w, "campfire", x * T, y * T, SA.VILLAGE, (273, 88, 31, 38), frames, collide=True)


def build():
    WP.bake(ROOT + "/assets/sprites/city/baked_buildings.png")
    w = World(SW, SH, seed=5150)
    w.monsters = []
    w.field_path = set()
    w.field_points = []
    w.mrng = random.Random(909)
    rng = w.rng
    for y in range(SH):
        for x in range(SW):
            w.put("ground", x, y, FG, GRASS_TILE)
    w.land = {(x, y) for x in range(SW) for y in range(SH)}

    # the frozen lake and icy ponds
    lake(w, blob(122, 70, 15, 9, 0.22, 1.1))
    for (cx, cy, rx, ry, sd) in ((30, 76, 5, 3.5, 2.0), (44, 22, 4, 3, 0.7), (140, 26, 4.5, 3, 1.6)):
        lake(w, blob(cx, cy, rx, ry, 0.2, sd))
    hills = []
    for (cx, cy, rx, ry, sd) in ((60, 70, 5, 3.5, 1.3), (98, 100, 5, 3, 0.4), (22, 104, 6, 4, 2.0), (140, 104, 6, 4, 0.8), (90, 58, 4, 3, 2.6)):
        hc = blob(cx, cy, rx, ry, 0.15, sd)
        hill(w, hc)
        hills.append(hc)
    w.hill_cells = set().union(*hills) | {(x, y + 1) for h in hills for (x, y) in h}

    P = [
        [(80.5, 121), (80, 110), (80, 98), (79, 88), (78, 78)],             # gate -> hub
        [(78, 80), (64, 78), (50, 80), (36, 84)],                            # -> white pinewood
        [(78, 78), (79, 64), (80, 50), (80, 40)],                            # -> winter ent glade
        [(36, 84), (30, 66), (28, 50), (30, 34)],                            # pinewood -> graveyard
        [(79, 78), (94, 80), (104, 84), (118, 84)],                          # -> frozen lake shore
        [(81, 50), (98, 44), (114, 40), (128, 34)],                          # -> crystal grotto
        [(118, 84), (140, 74), (150, 62), (161, 61)],                        # road east -> Villa Escarcha
    ]
    for pts in P:
        path(w, pts, 3.2)
    autotile(w, "ground_overlay", w.field_path, FG, nine_at(19, 1), {"se": (22, 1), "sw": (23, 1), "ne": (22, 2), "nw": (23, 2)}, center_variants=[(20, 2)])
    w.blocked |= w.field_path

    # Frozen Edge: the hunters' camp (safe haven)
    for (k, x, y) in (("tent_white", 72, 105.5), ("tent_green", 89, 105.5), ("camp_rug", 72.5, 108.2)):
        prop(w, k, x, y)
    camp_fire(w, 80.5, 110)
    prop(w, "camp_log", 77, 111.6); prop(w, "camp_log", 84, 111.6); prop(w, "camp_trunk", 92, 108.5); prop(w, "camp_chest", 68, 108.5)
    prop(w, "sn_snowman", 94, 111)
    w.blocked |= rect_cells(66, 101, 96, 115)
    camp_actor(w, "frost_ranger", "Char_sharpens_weapons.png", (0, 0, 48, 32), [(c * 48, r * 64) for r in range(2) for c in range(6)], 74.5 * 16, 111.5 * 16,
               talk=("Sigrid, cazadora del norte", ["Pocos llegan tan lejos. Junto al fuego estás a salvo: tus pociones se rellenan aquí.",
                                                   "Al este, siguiendo el camino, está Villa Escarcha. Al norte, el Ent Invernal.",
                                                   "Y no pises el hielo del lago: algo enorme duerme debajo."]))
    # Forgotten Graveyard: tombstones in rows
    for row in range(4):
        for col in range(6):
            if rng.random() < 0.8:
                prop(w, rng.choice(["sn_tomb", "sn_tomb2", "sn_tomb3"]), 14 + col * 5 + rng.uniform(-0.8, 0.8), 16 + row * 7 + rng.uniform(-0.5, 0.5))
    w.blocked |= rect_cells(10, 10, 46, 44)
    # Glade of the Winter Ent: a ring of dead trees
    for i in range(12):
        a = i / 12 * math.tau
        prop(w, "sn_dead" if i % 2 else "sn_dead2", 80 + math.cos(a) * 11, 26 + math.sin(a) * 8)
    w.field_points += [(80, 26)]
    w.blocked |= rect_cells(72, 20, 88, 32)
    # Crystal Grotto
    scatter(w, ["sn_crystal", "sn_crystal", "camp_crystals", "gl_crystalbush", "gl_crystalbush2"], (110, 10, 152, 44), 30, min_dist=2.6)

    # monsters
    monster(w, "winter_ent", 80, 26)
    monster(w, "frost_king", 103, 71)   # on the west shore of the frozen lake
    for (cx, cy) in ((24, 66), (44, 90), (52, 62), (16, 88), (36, 58)):
        pack_monsters(w, "frost_wolf", cx, cy, 3, 4, own=True)
    for (cx, cy) in ((20, 30), (36, 22), (30, 44), (48, 36)):
        pack_monsters(w, "frost_goblin", cx, cy, 3, 3, own=True)
    for (cx, cy) in ((70, 36), (92, 36), (66, 18), (94, 16)):
        pack_monsters(w, "ice_ent", cx, cy, 2, 2.5, own=True)
    for (cx, cy) in ((116, 20), (132, 16), (146, 32), (122, 38), (138, 42)):
        pack_monsters(w, "ice_golem", cx, cy, 2, 2.5, own=True)
    for (cx, cy) in ((100, 60), (104, 82), (140, 84), (148, 56), (110, 90)):
        pack_monsters(w, "frost_slime", cx, cy, 3, 3, own=True)
    for (cx, cy) in ((64, 88), (96, 92), (130, 96), (52, 104), (112, 102)):
        pack_monsters(w, "yeti", cx, cy, 2, 3.5, own=True)
    for (cx, cy, k) in ((80, 92, "frost_slime"), (66, 78, "frost_wolf"), (80, 62, "yeti"), (100, 46, "ice_ent"), (140, 64, "frost_wolf")):
        pack_monsters(w, k, cx, cy, 2, 2.5, own=True)

    w.chests = []
    for (x, y, tier) in ((80, 34, 4), (28, 14, 3), (146, 12, 3), (150, 90, 2), (14, 96, 2), (56, 50, 1), (104, 54, 2), (126, 104, 2)):
        c = (x, y)
        for r in range(6):
            free = [(x + dx, y + dy) for dy in range(-r, r + 1) for dx in range(-r, r + 1)
                    if (x + dx, y + dy) not in w.solids and (x + dx, y + dy) not in w.hill_cells and (x + dx, y + dy) not in w.field_path]
            if free:
                c = free[0]
                break
        w.chests.append((c[0] + 0.5, c[1] + 0.9, tier))
        w.blocked |= rect_cells(c[0] - 1, c[1] - 2, c[0] + 1, c[1] + 1)

    # ---- the forest: thick snowy pines at the edges and between the clearings
    border = [(0, 0, 9, SH), (0, 0, SW, 9), (SW - 9, 0, SW, GATE_E[0] - 3), (SW - 9, GATE_E[1] + 3, SW, SH),
              (0, SH - 9, GATE_S[0] - 3, SH), (GATE_S[1] + 3, SH - 9, SW, SH)]
    for r in border:
        scatter(w, SA.SNOW_TREES, r, int((r[2] - r[0]) * (r[3] - r[1]) / 11), min_dist=2.5, avoid_path=False)
    for r in ((8, 56, 60, 98), (56, 50, 74, 74), (100, 96, 140, 112), (8, 96, 34, 112), (102, 46, 112, 60)):
        scatter(w, SA.SNOW_TREES, r, int((r[2] - r[0]) * (r[3] - r[1]) / 16), min_dist=3.0)
    scatter(w, SA.SNOW_TREES, (10, 10, 150, 110), 110, min_dist=4.5)
    scatter(w, SA.SNOW_ROCKS, (10, 10, 150, 112), 40, min_dist=6)
    scatter(w, ["sn_snowman", "sn_stump", "tr_log"], (10, 10, 150, 112), 10, min_dist=14)
    scatter(w, SA.SNOW_SMALL, (8, 8, 152, 114), 300, min_dist=1.3)
    tufts = [(x, 8) for x in range(0, 21)]
    for _ in range(1200):
        x, y = rng.randrange(1, SW - 1), rng.randrange(1, SH - 1)
        if (x, y) not in w.blocked and (x, y) not in w.solids:
            w.put("detail", x, y, GD, rng.choice(tufts))
    SA.remap_to_snow(w)
    w.graph = WL.Graph()
    return w


SNOWFOREST_CFG = dict(
    out="scenes/world/snowforest.tscn", tileset="res://resources/tilesets/snowforest_tileset.tres", stamina=True,
    minimap="res://resources/world/minimap_snowforest.png", title="Bosque Nevado", hunters=5,
    preview_layers=["water", "water_fx", "ground", "ground_overlay", "hill", "road", "detail", "coast", "dock", "dock_fx"],
    walkmask="res://resources/world/snowforest_walkmask.png", player=(80.5 * 16, 116 * 16),
    zones=ZONES,
    exits=[dict(name="SouthExit", pos=(80.5 * 16, SH * 16 - 18), size=(8 * 16, 24), scene="res://scenes/world/forest.tscn", spawn="north", dir="down"),
           dict(name="EastExit", pos=(SW * 16 - 18, 61 * 16), size=(24, 6 * 16), scene="res://scenes/world/snowvillage.tscn", spawn="west", dir="right")],
    spawns={"south": (80.5 * 16, 116 * 16), "respawn": (80.5 * 16, 113 * 16), "start": (80.5 * 16, 116 * 16), "east": (SW * 16 - 6 * 16, 61 * 16)},
    bottom_gap=GATE_S, right_gap=GATE_E,
)


if __name__ == "__main__":
    import w_export as WE
    w = build()
    WE.FRAMES_DIR = "snowforest"
    for f in glob.glob(os.path.join(ROOT, "resources/sprite_frames/snowforest/*.tres")):
        os.remove(f)
    for sheet in WP.SHEETS:
        if WP.SHEETS[sheet][0]:
            WE.res_for_raw(os.path.join(RAW, WP.SHEETS[sheet][0]))
    WE.LAYERS.insert(4, ("hill", True))
    WE.tileset(w, "resources/tilesets/snowforest_tileset.tres")
    WE.walk_mask(w, "resources/world/snowforest_walkmask.png")
    WE.scene(w, SNOWFOREST_CFG)
    print("snowforest: props", len(w.props), "actors", len(w.actors), "monsters", len(w.monsters), "chests", len(w.chests))
