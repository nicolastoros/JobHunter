"""Bosque Profundo: a big forest north of the Whispering Woods (Llanura de Valdoria).
Dense tree walls with clearings joined by trails: the ranger's outpost (safe haven) at the entrance,
the Moss Glade, the Hollow of Saplings, the Crystal Grove, the Misty Marsh and, at its heart,
the Obsidian Golem."""
import glob, os, random
from w_field import *          # catalog, terrain helpers, monsters (the forest shares the field's art)
import w_field as WF

FW, FH = 160, 120
GATE_X = (77, 84)              # trail out to the plain (bottom edge)

WF.MON["obsidian"] = dict(pack="mon_golem_bosses01", kinds=["Golem3"], name="Gólem de Obsidiana",
                          props=dict(max_hp=60, damage=4, speed=12, chase_speed=24, aggro_radius=130, attack_range=30, gold=90, territory=90,
                                     boss="true", respawn_time=200, body_size="Vector2(30, 10)"))

ZONES = [("Puesto del Guardabosques", (66, 98, 96, 120)), ("Claro del Musgo", (14, 60, 58, 96)),
         ("Hondonada de los Retoños", (98, 62, 148, 96)), ("Arboleda de Cristal", (12, 12, 56, 50)),
         ("Pantano Brumoso", (102, 12, 150, 50)), ("Corazón del Bosque", (60, 14, 100, 52)),
         ("Bosque Profundo", (0, 0, FW, FH))]


def build():
    WP.bake(ROOT + "/assets/sprites/city/baked_buildings.png")
    w = World(FW, FH, seed=1907)
    w.monsters = []
    w.field_path = set()
    w.field_points = []
    w.mrng = random.Random(77)
    rng = w.rng
    for y in range(FH):
        for x in range(FW):
            w.put("ground", x, y, FG, GRASS_TILE)
    w.land = {(x, y) for x in range(FW) for y in range(FH)}

    # water: the misty marsh ponds and a pool in the moss glade
    for (cx, cy, rx, ry, sd) in ((124, 28, 8, 5, 0.4), (138, 38, 5, 3.5, 1.8), (112, 40, 4, 3, 2.6), (30, 80, 5, 3.5, 1.1)):
        lake(w, blob(cx, cy, rx, ry, 0.22, sd))
    # a few mesas for relief
    hills = []
    for (cx, cy, rx, ry, sd) in ((60, 70, 5, 3.5, 0.7), (100, 104, 5, 3, 1.4), (24, 104, 6, 4, 2.2), (142, 104, 6, 4, 0.3)):
        hc = blob(cx, cy, rx, ry, 0.15, sd)
        hill(w, hc)
        hills.append(hc)
    w.hill_cells = set().union(*hills) | {(x, y + 1) for h in hills for (x, y) in h}

    # trails
    P = [
        [(80.5, 121), (80, 110), (80, 100), (79, 90), (78, 80)],                 # gate -> hub
        [(78, 82), (66, 80), (54, 78), (42, 76)],                                # -> moss glade
        [(79, 82), (92, 80), (106, 78), (120, 78)],                              # -> hollow of saplings
        [(78, 80), (79, 68), (80, 56), (80, 44)],                                # -> heart of the forest
        [(79, 50), (66, 44), (52, 38), (38, 32)],                                # -> crystal grove
        [(81, 50), (94, 44), (106, 46), (116, 50)],                              # -> misty marsh
        [(42, 76), (36, 64), (34, 52), (36, 40)],                                # glade -> grove (west loop)
        [(120, 78), (128, 66), (128, 56)],                                       # hollow -> marsh (east loop)
    ]
    for pts in P:
        path(w, pts, 3.4)
    autotile(w, "ground_overlay", w.field_path, FG, nine_at(19, 1), {"se": (22, 1), "sw": (23, 1), "ne": (22, 2), "nw": (23, 2)}, center_variants=[(20, 2)])
    w.blocked |= w.field_path

    # ranger's outpost (safe haven) by the entrance
    for (k, x, y) in (("tent_green", 72, 104.5), ("tent_orange", 88.5, 104.5), ("camp_rug", 72.5, 107.2)):
        prop(w, k, x, y)
    prop(w, "camp_log", 77, 110.6); prop(w, "camp_log", 84, 110.6); prop(w, "camp_trunk", 91, 107.5); prop(w, "camp_chest", 68, 107.5)
    w.blocked |= rect_cells(66, 100, 95, 114)
    camp_actor(w, "ranger", "Char_sharpens_weapons.png", (0, 0, 48, 32), [(c * 48, r * 64) for r in range(2) for c in range(6)], 74.5 * 16, 110.5 * 16,
               talk=("Hilde, guardabosques", ["Bienvenido al Bosque Profundo. Aquí los árboles tienen memoria... y mal genio.",
                                              "Junto al fuego estás a salvo; tus pociones se rellenan aquí.",
                                              "En el corazón del bosque duerme un gólem de obsidiana. No vayas sin estar preparado."]))
    camp_actor(w, "cook2", "Bonfire_boiler_lizardman.png", (0, 0, 62, 58), [(c * 112, r * 112) for c in range(3) for r in range(4)], 80.5 * 16, 109.4 * 16,
               talk=("Varko, cocinero", ["Mi hermana cocina en el campamento de la llanura. Yo prefiero la sombra de los árboles."]),
               bubble=["Sopa de setas, ¿quieres?"])

    # landmarks
    # crystal grove: crystal bushes and shards
    scatter(w, ["gl_crystalbush", "gl_crystalbush2", "camp_crystals", "gl_bluebush", "gl_bluebush2"], (14, 14, 56, 48), 26, min_dist=3.0)
    # misty marsh: reeds and willows
    scatter(w, ["gl_reeds", "gl_reeds", "tr_willow_m", "gl_bluebush3", "tr_dead_m"], (102, 14, 150, 50), 28, min_dist=2.6)
    # heart of the forest: a ring of old dead trees around the golem
    for i in range(12):
        import math
        a = i / 12 * math.tau
        prop(w, "tr_dead" if i % 2 else "tr_dead_m", 80 + math.cos(a) * 11, 30 + math.sin(a) * 8)
    w.field_points += [(80, 30)]
    w.blocked |= rect_cells(72, 24, 88, 36)

    # monsters
    monster(w, "obsidian", 80, 30)
    for (cx, cy) in ((72, 40), (90, 40), (68, 22), (92, 22)):
        pack_monsters(w, "treant", cx, cy, 2, 2.5, own=True)
    for (cx, cy) in ((24, 70), (40, 88), (50, 66), (20, 90)):
        pack_monsters(w, "mossy", cx, cy, 3, 3, own=True)
    for (cx, cy) in ((32, 76), (46, 92)):
        pack_monsters(w, "sapling", cx, cy, 3, 3, own=True)
    for (cx, cy) in ((106, 70), (122, 72), (138, 82), (112, 90), (132, 92), (144, 70)):
        pack_monsters(w, "sapling", cx, cy, 3, 3, own=True)
    for (cx, cy) in ((116, 84), (140, 92)):
        pack_monsters(w, "treant", cx, cy, 2, 3, own=True)
    for (cx, cy) in ((24, 24), (40, 20), (30, 40), (48, 34), (16, 44)):
        pack_monsters(w, "crystal", cx, cy, 2, 2.5, own=True)
    for (cx, cy) in ((110, 24), (132, 20), (146, 30), (118, 44), (144, 46)):
        pack_monsters(w, "mist", cx, cy, 3, 3, own=True)
    # stragglers along the trails
    for (cx, cy, k) in ((80, 92, "mossy"), (64, 80, "sapling"), (96, 80, "mossy"), (80, 62, "sapling"), (60, 44, "crystal"), (100, 46, "mist")):
        pack_monsters(w, k, cx, cy, 2, 2.5, own=True)

    # treasure chests
    w.chests = []
    for (x, y, tier) in ((80, 38, 4), (20, 18, 3), (146, 16, 3), (150, 88, 2), (14, 88, 2), (56, 58, 1), (104, 58, 1), (126, 104, 2)):
        c = (x, y)
        for r in range(6):
            free = [(x + dx, y + dy) for dy in range(-r, r + 1) for dx in range(-r, r + 1)
                    if (x + dx, y + dy) not in w.solids and (x + dx, y + dy) not in w.hill_cells and (x + dx, y + dy) not in w.field_path]
            if free:
                c = free[0]
                break
        w.chests.append((c[0] + 0.5, c[1] + 0.9, tier))
        w.blocked |= rect_cells(c[0] - 1, c[1] - 2, c[0] + 1, c[1] + 1)

    # ---- the forest itself: thick walls at the edges and between the clearings ----------
    border = [(0, 0, 9, FH), (FW - 9, 0, FW, FH), (0, 0, FW, 9), (0, FH - 9, GATE_X[0] - 3, FH), (GATE_X[1] + 3, FH - 9, FW, FH)]
    for r in border:
        scatter(w, FOREST, r, int((r[2] - r[0]) * (r[3] - r[1]) / 11), min_dist=2.5, avoid_path=False)
    for r in ((56, 54, 74, 74), (88, 54, 104, 72), (8, 50, 30, 62), (130, 52, 152, 62), (36, 96, 64, 112), (100, 96, 136, 112),
              (56, 8, 66, 30), (94, 8, 104, 30), (8, 96, 34, 112), (138, 96, 152, 112)):
        scatter(w, FOREST + GROVE, r, int((r[2] - r[0]) * (r[3] - r[1]) / 9), min_dist=2.6)
    # trees inside the clearings too (lighter)
    scatter(w, FOREST + GROVE, (10, 10, 150, 110), 140, min_dist=4.2)
    scatter(w, BUSHES, (10, 10, 150, 112), 110, min_dist=3.0)
    scatter(w, ["tr_log", "tr_stump", "gl_stump", "gl_stump2", "gl_mound"], (10, 10, 150, 112), 30, min_dist=6)
    scatter(w, ROCKS, (10, 10, 150, 112), 24, min_dist=8)
    scatter(w, SMALL, (8, 8, 152, 114), 360, min_dist=1.1)
    tufts = [(x, 8) for x in range(0, 21)]
    for _ in range(1500):
        x, y = rng.randrange(1, FW - 1), rng.randrange(1, FH - 1)
        if (x, y) not in w.blocked and (x, y) not in w.solids:
            w.put("detail", x, y, GD, rng.choice(tufts))
    w.graph = WL.Graph()
    return w


FOREST_CFG = dict(
    out="scenes/world/forest.tscn", tileset="res://resources/tilesets/forest_tileset.tres", stamina=True,
    minimap="res://resources/world/minimap_forest.png", title="Bosque Profundo", hunters=6,
    preview_layers=["water", "water_fx", "ground", "ground_overlay", "hill", "road", "detail", "coast", "dock", "dock_fx"],
    walkmask="res://resources/world/forest_walkmask.png", player=(80.5 * 16, 115 * 16),
    zones=ZONES,
    exits=[dict(name="SouthExit", pos=(80.5 * 16, FH * 16 - 18), size=(8 * 16, 24), scene="res://scenes/world/field.tscn", spawn="north", dir="down")],
    spawns={"south": (80.5 * 16, 115 * 16), "respawn": (80.5 * 16, 115 * 16), "start": (80.5 * 16, 115 * 16)},
    bottom_gap=GATE_X,
)


if __name__ == "__main__":
    import w_export as WE
    w = build()
    WE.FRAMES_DIR = "forest"
    for f in glob.glob(os.path.join(ROOT, "resources/sprite_frames/forest/*.tres")):
        os.remove(f)
    for sheet in WP.SHEETS:
        if WP.SHEETS[sheet][0]:
            WE.res_for_raw(os.path.join(RAW, WP.SHEETS[sheet][0]))
    WE.LAYERS.insert(4, ("hill", True))
    WE.tileset(w, "resources/tilesets/forest_tileset.tres")
    WE.walk_mask(w, "resources/world/forest_walkmask.png")
    WE.scene(w, FOREST_CFG)
    print("forest: props", len(w.props), "actors", len(w.actors), "monsters", len(w.monsters), "chests", len(w.chests))
