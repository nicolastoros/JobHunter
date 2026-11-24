"""Villa Escarcha: a snowed-in village east of the Bosque Nevado. A safe haven: cabins of the winter
pack and snowy houses around the Plaza del Fuego (bonfire, torches, the well), Bjorn's forge,
the alchemist, the inn, a frozen pond, villagers and guards; a fence with the west gate."""
import glob, os, random
import w_snow_assets as SA
from w_field import *
import w_field as WF
from w_layout import trader, citizen, tmx_actor

VW, VH = 110, 80
GATE_W = (38, 44)
PEN = nine_at(20, 15)
LINES = ["En invierno el camino al sur se cierra con la nieve.", "Bjorn forja con hierro que nunca se oxida.", "¿Has visto al Ent Invernal? Mi abuelo sí.",
         "El fuego de la plaza no se apaga desde hace cien años.", "Las pieles de lobo blanco se pagan bien.", "Qué frío hace hoy...",
         "Los yetis bajan cuando nieva fuerte.", "Hilda sirve la mejor sopa de todo el norte.", "Dicen que bajo el lago hay un limo enorme."]


def torch(w, x, y):
    frames = [(292 - 260, -9, 110), (308 - 260, -7, 110), (324 - 260, -10, 110)]
    return actor(w, "torch", x * T, y * T, SA.VILLAGE, (260, 138, 8, 29), frames, collide=False)


def bonfire(w, x, y):
    frames = [(305 - 273, 0, 140), (337 - 273, 0, 140), (369 - 273, 0, 140)]
    return actor(w, "bonfire", x * T, y * T, SA.VILLAGE, (273, 88, 31, 38), frames, collide=True)


def fence_ring(w, x0, y0, x1, y1, gap):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            edge = x in (x0, x1) or y in (y0, y1)
            if not edge or (x == x0 and gap[0] <= y <= gap[1]):
                continue
            k = ("t" if y == y0 else "b" if y == y1 else "") + ("l" if x == x0 else "r" if x == x1 else "")
            k = {"t": "t", "b": "b", "l": "l", "r": "r"}.get(k, k)
            w.put("fence", x, y, FG, PEN[k], "full")
    w.blocked |= {(x, y) for x in range(x0, x1 + 1) for y in (y0, y1)} | {(x, y) for y in range(y0, y1 + 1) for x in (x0, x1)}


def build():
    WP.bake(ROOT + "/assets/sprites/city/baked_buildings.png")
    SA.bake_snow()
    w = World(VW, VH, seed=808)
    w.monsters = []
    w.field_path = set()
    w.field_points = []
    rng = w.rng
    for name in ("ground", "ground_overlay", "road", "detail", "water", "coast", "fence"):
        w.layer(name)
    for y in range(VH):
        for x in range(VW):
            w.put("ground", x, y, FG, GRASS_TILE)
    w.land = {(x, y) for x in range(VW) for y in range(VH)}
    g = WL.Graph()

    lake(w, blob(88, 60, 6, 4, 0.2, 0.9))     # frozen pond
    # streets of packed snow
    P = [[(-1, 41), (20, 41), (40, 41), (55, 41), (70, 41), (95, 41)],
         [(55, 12), (55, 30), (55, 41), (55, 52), (55, 70)],
         [(22, 24), (88, 24)], [(22, 58), (80, 58)], [(22, 24), (22, 58)], [(88, 24), (88, 50)]]
    for pts in P:
        path(w, pts, 3.4)
    autotile(w, "ground_overlay", w.field_path, FG, nine_at(19, 1), {"se": (22, 1), "sw": (23, 1), "ne": (22, 2), "nw": (23, 2)}, center_variants=[(20, 2)])
    w.blocked |= w.field_path
    fence_ring(w, 6, 6, VW - 7, VH - 7, GATE_W)

    # Plaza del Fuego
    bonfire(w, 55, 42.5)
    for (x, y) in ((49, 37), (61, 37), (49, 47.5), (61, 47.5)):
        torch(w, x, y)
    prop(w, "sv_well2", 62.5, 44)
    # the village elder (story)
    tmx_actor(w, "elder", "Old_man_idle", (0, 0, 32, 32), 62 * T, 47.5 * T,
              talk=("Anciana Freya", ["El fuego de esta plaza lleva cien años encendido. Yo lo vi encender.",
                                      "Las canciones antiguas hablan de tres Sellos... pero ya nadie las canta."]),
              bubble=["Acércate al fuego.", "Las canciones antiguas..."])
    for (x, y) in ((50.5, 44.5), (59.5, 40.5)):
        prop(w, "t_bench", x, y)
    trader(w, "lute", 52 * T, 45 * T, talk=("Bardo Olaf", ["Canto al fuego que nunca se apaga. Siéntate, viajero."]), bubble=["♪ ♪"])
    w.blocked |= rect_cells(46, 34, 64, 50)

    # houses around the streets: winter cabins and snowy houses
    pool = ["sv_cabin", "sv_cabin_lit", "sv_cabin", "s_house_red", "s_farmhouse", "s_fish_house", "s_fish_house2", "s_shed", "s_barn"]
    widths = {"sv_cabin": 6.2, "sv_cabin_lit": 6.2, "s_house_red": 8.3, "s_farmhouse": 7.8, "s_fish_house": 6.4, "s_fish_house2": 6.4,
              "s_shed": 5.0, "s_barn": 5.7, "s_longshed": 4.4}

    def row(xa, xb, base):
        x = xa
        last = None
        while True:
            fits = [k for k in pool if x + widths[k] <= xb]
            if not fits:
                break
            k = rng.choice([f for f in fits if f != last] or fits)
            last = k
            prop(w, k, x + widths[k] / 2, base, flip=rng.random() < 0.5 and not k.startswith("sv_"))
            x += widths[k] + rng.uniform(0.8, 2.2)

    row(10, 52, 22); row(58, 100, 22)
    row(26, 52, 38.8); row(66, 86, 38.8)
    row(10, 52, 56.5); row(58, 80, 56.5)
    row(10, 50, 72); row(58, 96, 72)
    # Bjorn's forge, the alchemist, the inn
    prop(w, "weapon_stall", 76, 50.6)
    smith = trader(w, "weapon", 75.2 * T, 52 * T, talk=("Bjorn, el herrero del norte", ["El frío templa el acero mejor que cualquier fragua. Te mejoro el equipo o te compro lo que te sobre."]),
                   bubble=["Acero del norte.", "¿Traes pieles?"])
    smith["opens"] = "forge"
    prop(w, "potion_cart", 36, 50.5)
    trader(w, "drinks", 34 * T, 50.6 * T, talk=("Ingrid la alquimista", ["Tónicos calientes. En el norte, el frío mata más que las bestias."]))
    prop(w, "bread_stall", 70, 30.5)
    trader(w, "bread", 73 * T, 30 * T, talk=("Hilda la posadera", ["Sopa de setas y pan de centeno. Come algo antes de volver al bosque."]))
    for _ in range(14):
        x, y = rng.uniform(12, 98), rng.choice([26.5, 43.5, 60.5]) + rng.uniform(-0.3, 0.3)
        if 44 <= x <= 66 and 33 <= y <= 51:     # the square stays clear
            continue
        prop(w, rng.choice(["barrel", "crate", "sack", "sv_vase", "crates_a", "barrels_a", "sn_snowman"]), x, y)
    for (x, y) in ((44, 40.2), (44, 43.6)):
        prop(w, "sv_sign", x, y)
    # snow everywhere: trees inside and a pinewood outside the fence
    for r in ((0, 0, VW, 5), (0, VH - 5, VW, VH), (0, 0, 5, GATE_W[0] - 2), (0, GATE_W[1] + 2, 5, VH), (VW - 5, 0, VW, VH)):
        scatter(w, SA.SNOW_TREES, r, int((r[2] - r[0]) * (r[3] - r[1]) / 10), min_dist=2.4, avoid_path=False)
    scatter(w, ["sn_tree_round", "sn_tree_big", "sn_pine_green", "sn_pine"], (9, 9, VW - 9, VH - 9), 26, min_dist=5)
    scatter(w, SA.SNOW_SMALL + ["sn_rock", "sn_rock2"], (8, 8, VW - 8, VH - 8), 90, min_dist=2.2)
    tufts = [(x, 8) for x in range(0, 21)]
    for _ in range(400):
        x, y = rng.randrange(1, VW - 1), rng.randrange(1, VH - 1)
        if (x, y) not in w.blocked and (x, y) not in w.solids:
            w.put("detail", x, y, GD, rng.choice(tufts))

    # people
    for name, x, y in (("a", 20, 41), ("b", 40, 41), ("c", 55, 41), ("d", 70, 41), ("e", 88, 41), ("f", 55, 24), ("g", 55, 58), ("h", 22, 24),
                       ("i", 88, 24), ("j", 22, 58), ("k", 80, 58)):
        g.node(name, x, y)
    g.link("a", "b", "c", "d", "e"); g.link("f", "c", "g"); g.link("h", "f", "i"); g.link("j", "g", "k"); g.link("h", "a", "j"); g.link("i", "e")
    for i in range(24):
        x, y = rng.choice([(rng.uniform(14, 96), 41), (55, rng.uniform(14, 68)), (rng.uniform(22, 88), 24), (rng.uniform(22, 80), 58)])
        citizen(w, rng.randint(1, 7), x * T, y * T, "city", LINES)
    for (x, y) in ((9, 39.5), (9, 42.8), (55, 9), (100, 41)):
        citizen(w, 8, x * T, y * T, "city", ["Bienvenido a Villa Escarcha.", "Abrígate, viajero.", "Ojo con los lobos blancos."], guard=True)
    for i, c in enumerate(w.walkers):
        c["mode"] = "guard" if c.get("guard") else ("loiterer" if i % 3 == 1 else "stroller")
        if not c.get("guard") and i % 5 in (0, 2, 3):
            c["brain"] = True
    SA.remap_to_snow(w)
    w.graph = g
    return w


ZONES = [("Plaza del Fuego", (44, 30, 68, 52)), ("Villa Escarcha", (0, 0, VW, VH))]
SNOWVILLAGE_CFG = dict(
    out="scenes/world/snowvillage.tscn", tileset="res://resources/tilesets/snowvillage_tileset.tres",
    walkmask="res://resources/world/snowvillage_walkmask.png", player=(4 * 16, 41 * 16),
    minimap="res://resources/world/minimap_snowvillage.png", title="Villa Escarcha", hunters=5,
    preview_layers=["water", "water_fx", "ground", "ground_overlay", "road", "detail", "coast", "fence"],
    zones=ZONES,
    exits=[dict(name="WestExit", pos=(18, 41 * 16), size=(24, 6 * 16), scene="res://scenes/world/snowforest.tscn", spawn="east", dir="left")],
    spawns={"west": (4 * 16, 41 * 16), "respawn": (55 * 16, 46 * 16), "start": (4 * 16, 41 * 16)},
    left_gap=GATE_W,
)

if __name__ == "__main__":
    import w_export as WE
    w = build()
    WE.FRAMES_DIR = "snowvillage"
    for f in glob.glob(os.path.join(ROOT, "resources/sprite_frames/snowvillage/*.tres")):
        os.remove(f)
    for sheet in WP.SHEETS:
        if WP.SHEETS[sheet][0]:
            WE.res_for_raw(os.path.join(RAW, WP.SHEETS[sheet][0]))
    WE.tileset(w, "resources/tilesets/snowvillage_tileset.tres")
    WE.walk_mask(w, "resources/world/snowvillage_walkmask.png")
    WE.scene(w, SNOWVILLAGE_CFG)
    print("snowvillage: props", len(w.props), "actors", len(w.actors), "walkers", len(w.walkers))
