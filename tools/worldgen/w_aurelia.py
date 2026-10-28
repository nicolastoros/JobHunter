"""Aurelia, la Ciudad Dorada: a great walled city east of the Desert of Amber.
Two canals cross it from north to south; avenues meet at the Gran Plaza and its fountain; the palace
gardens to the north, the Mercado Mayor to the south, house blocks, the caravan quarter by the west
gate, an arms academy and the eastern gardens."""
import glob, os, random
import w_field  # noqa: F401  (registers the field / camp / trees sheets in the catalog)
from w_layout import *
import w_terrain as WT

AW, AH = 200, 150
CX0, CX1, CY0, CY1 = 14, 185, 14, 140
GATE_W = (80, 85)        # west gate (to the desert) and the east one
GATE_N = (97, 102)       # north / south gates
AVE_Y = (80, 85)
AVE_X = (97, 102)
CANALS = (54, 143)       # x of each canal (3 wide)
BRIDGES = ((44, 48), (79, 86), (112, 116))

LINES = ['Aurelia nunca duerme.', 'Las caravanas del desierto llegan cada mañana.', '¿Has visto el palacio? Dicen que tiene cien salas.',
         'Los canales vienen de un río subterráneo.', 'En el Mercado Mayor encuentras de todo.', 'Mi primo es cazador en Valdoria.',
         'El oro de las Ruinas del Sol hizo rica a esta ciudad.', 'Cuidado con los carteristas en la plaza.', 'Hoy hay música en la plaza.',
         'La academia busca reclutas.', 'Dicen que el Guardián del Sol despierta de noche.', 'Qué calor hace hoy.',
         'Las especias del sur valen más que el oro.', 'Me perdí otra vez en el barrio antiguo.']

HOUSES = {"house_red": 8.3, "fish_house": 6.4, "fish_house2": 6.4, "farmhouse": 7.8, "barn": 5.7, "shed": 5.0, "longshed": 4.4}
BIG = ["house_red", "fish_house", "fish_house2", "farmhouse"]


def build():
    WP.bake(ROOT + "/assets/sprites/city/baked_buildings.png")
    w = World(AW, AH, seed=1312)
    rng = w.rng
    for name in ("ground", "ground_overlay", "road", "detail", "water", "water_fx", "coast", "dock", "walls"):
        w.layer(name)
    for y in range(AH):
        for x in range(AW):
            w.put("ground", x, y, FG, WT.GRASS)
    # ---- walls & paving: the castle-town helpers, pointed at this city's rectangle
    WT.CX0, WT.CX1, WT.CY0, WT.CY1 = CX0, CX1, CY0, CY1
    WT.GATE_N, WT.GATE_W = GATE_N, GATE_W
    WT.city_paving(w)
    WT.city_walls(w)
    w.blocked |= {c for c in w.layers["walls"]} | {c for c in w.layers.get("towers", {})}
    g = Graph()

    # ---- road from the west gate out to the desert edge
    road = rect_cells(0, AVE_Y[0], CX0, AVE_Y[1])
    autotile(w, "road", road, RD, WT.ROAD_NINE, WT.ROAD_INNER, center_variants=[(2, 2)] * 3)
    w.blocked |= road

    # ---- canals with bridges where the streets cross
    for cx in CANALS:
        y = CY0 + 6
        for (b0, b1) in BRIDGES + ((CY1 - 5, CY1),):
            if b0 - 1 > y + 1:
                fountain(w, cx, y + 1, cx + 2, b0 - 2)
            y = b1 + 1
        for (b0, b1) in BRIDGES:
            w.blocked |= rect_cells(cx - 1, b0, cx + 3, b1)

    # ---- the Gran Plaza: a great fountain at the crossroads, gardens around
    fountain(w, 95, 76, 104, 89)
    for (x0, y0) in ((86, 70), (110, 70), (86, 93), (110, 93)):
        planter(w, x0, y0, x0 + 3, y0 + 2)
        prop(w, rng.choice(["tree_light", "tree_light2", "tree_round"]), x0 + 2, y0 + 2, dy=-2)
    for (x, y) in ((83, 77), (83, 89), (116, 77), (116, 89)):
        prop(w, "t_banner_big", x, y)
    for (x, y) in ((90, 75), (109, 75), (90, 91), (109, 91)):
        prop(w, "t_bench", x, y)
    # a ring of trees and small fountains around the plaza
    for (x, y) in ((82, 68), (117, 68), (82, 97), (117, 97), (88, 66), (111, 66), (88, 99), (111, 99)):
        prop(w, rng.choice(["tree_round", "tree_light", "tree_oak2"]), x, y, flip=rng.random() < 0.5)
    for (x, y) in ((84, 82), (114, 82)):
        fountain(w, x - 1, y - 1, x + 1, y)
    for _ in range(18):
        prop(w, rng.choice(["flowerbox", "pot", "flower0", "flower3", "bush_round"]), rng.uniform(81, 118), rng.uniform(67, 98))
    trader(w, "lute", 92 * T, 91.5 * T, talk=("Juglar Ilario", ["Canto la historia del cazador que cruzó el desierto. ¿Quieres oírla?"]), bubble=["♪ ♪ ♪"])
    trader(w, "flutist", 107 * T, 91.5 * T, talk=("Mira la flautista", ["En Aurelia la música nunca se detiene."]), bubble=["♪ ~ ♪"])
    w.blocked |= rect_cells(80, 66, 119, 99)

    # ---- palace of Aurelia (north): grand hall, symmetric gardens, guards
    prop(w, "guild_hall", 100, 40)
    for side in (-1, 1):
        for i, y in enumerate((44, 52)):
            x = 100 + side * (10 + i * 2)
            planter(w, x - 2, y - 1, x + 2, y + 1)
            prop(w, "tree_oak" if i == 0 else "tree_light", x, y + 1, dy=-2, flip=side > 0)
        prop(w, "t_banner_big", 100 + side * 6, 43)
        prop(w, "t_banner_big", 100 + side * 6, 56)
        for y in (24, 30):
            prop(w, rng.choice(["tree_round", "tree_oak2", "tree_bushy"]), 100 + side * 16, y)
    fountain(w, 98, 58, 101, 60)
    # the processional way: rows of trees in planters and banners from the plaza up to the palace
    for y in range(48, 66, 6):
        for x in (91, 108):
            planter(w, x - 1, y, x + 1, y + 1)
            prop(w, rng.choice(["tree_light2", "tree_round", "tree_light"]), x, y + 1, dy=-2)
    for (x, y) in ((86, 26), (114, 26), (86, 36), (114, 36), (80, 46), (120, 46)):
        prop(w, "t_banner_big", x, y)
    for _ in range(14):
        prop(w, rng.choice(["bush_a", "bush_round", "flower2", "flower3", "shrub5", "flowerbox"]), rng.uniform(80, 120), rng.uniform(20, 60))
    w.blocked |= rect_cells(78, 18, 122, 62)

    # ---- Mercado Mayor (south): rows of stalls and traders
    stalls = ["fruit_stall", "bread_stall", "cloth_stall", "pastry_stall", "magic_stall", "empty_stall", "fruit_crates", "potion_cart"]
    traders = [("fruits", "Omar el frutero", "Dátiles, higos y granadas del oasis."), ("bread", "Lea la panadera", "Pan de especias. Receta de mi abuela."),
               ("drinks", "Selim el alquimista", "Tónicos del desierto. Refrescan hasta al más cansado."),
               ("magic", "Zaida la adivina", "Veo arena, oro... y un guardián que despierta."), ("eater", "Mercader hambriento", "El pan de Lea vale el viaje.")]
    ti = 0
    for row, y in enumerate((106, 117, 128)):
        for col, x in enumerate((80, 91, 108, 119)):
            prop(w, stalls[(row * 4 + col) % len(stalls)], x, y)
            if (row + col) % 2 == 0 and ti < len(traders):
                k, name, line = traders[ti]
                trader(w, k, (x + 0.5) * T, (y + 1.2) * T, talk=(name, [line]))
                ti += 1
            for _ in range(2):
                prop(w, rng.choice(["barrel", "crate", "sack", "crates_a", "barrels_a", "sack2"]), x + rng.uniform(-4, 4), y + rng.uniform(1.5, 3))
            w.shop_points.append(((x + 0.5) * T, (y + 2.2) * T))
    # the master smith: same forge as Kara's
    prop(w, "weapon_stall", 112, 134)
    smith = trader(w, "weapon", 111.2 * T, 135.4 * T, talk=("Doran, maestro herrero", ["En Aurelia forjamos con oro del desierto. Te mejoro el equipo... o te compro lo que no uses."]),
                   bubble=["El mejor acero del este.", "¿Traes materiales?"])
    smith["opens"] = "forge"
    prop(w, "weapon_rack", 116, 135.3); prop(w, "armor_flag", 107, 133)
    w.blocked |= rect_cells(76, 102, 124, 138)

    # ---- caravan quarter by the west gate: tents, crates, carts
    for (k, x, y) in (("tent_stripes", 24, 106), ("tent_orange", 36, 104), ("tent_white", 46, 108), ("tent_purple", 26, 120),
                      ("tent_green", 40, 124), ("tent_stripes", 22, 134), ("tent_orange", 46, 134)):
        prop(w, k, x, y)
    for _ in range(26):
        prop(w, rng.choice(["crates_c", "crates_a", "barrels_a", "cart", "sack", "barrel_big", "camp_trunk", "camp_chest", "crates_e"]),
             rng.uniform(18, 50), rng.uniform(100, 136))
    w.blocked |= rect_cells(16, 98, 52, 138)

    # ---- arms academy: sand yard with dummies, targets and racks
    for y in range(102, 135):
        for x in range(127, 141):
            w.put("ground", x, y, TW, rng.choice([(19, 10)] * 8 + [(10, 20), (11, 20), (12, 20)]))
    for (k, x, y) in (("t_dummy", 130, 108), ("t_dummy", 134, 108), ("t_dummy", 138, 108), ("t_target", 130, 120), ("t_target2", 134, 120),
                      ("t_target", 138, 120), ("t_rack_swords", 130, 131), ("t_rack_spear", 135, 131), ("t_rack_axes", 139, 131), ("t_shields", 128, 126)):
        prop(w, k, x, y)
    w.blocked |= rect_cells(126, 100, 141, 136)

    # ---- eastern gardens: lawns, trees, a pond, benches
    for y in range(100, 137):
        for x in range(148, 183):
            w.put("ground", x, y, FG, WT.GRASS)
    fountain(w, 160, 114, 168, 120)
    for _ in range(38):
        prop(w, rng.choice(["tree_light", "tree_round", "tree_oak", "tree_bushy", "tree_apple", "tree_light2", "tree_young"]),
             rng.uniform(150, 181), rng.uniform(102, 136), flip=rng.random() < 0.5)
    for _ in range(40):
        prop(w, rng.choice(["bush_a", "bush_b", "bush_round", "flower0", "flower2", "flower3", "shrub2", "shrub5"]), rng.uniform(150, 181), rng.uniform(102, 136))
    for (x, y) in ((158, 112), (170, 112), (158, 123), (170, 123)):
        prop(w, "t_bench", x, y)
    w.blocked |= rect_cells(146, 98, 184, 138)

    # ---- house blocks (old quarter, between the canals, noble quarter, east)
    def pack(xa, xb, base, pool, gap=(0.3, 1.4)):
        x = xa
        last = None
        while True:
            fits = [k for k in pool if x + HOUSES[k] <= xb]
            if not fits:
                break
            k = rng.choice([f for f in fits if f != last] or fits)
            last = k
            prop(w, k, x + HOUSES[k] / 2, base, flip=rng.random() < 0.5, dy=rng.randint(-3, 3))
            x += HOUSES[k]
            gp = rng.uniform(*gap)
            if gp > 1.0:
                prop(w, rng.choice(["barrel", "crate", "sack", "barrel2", "flowerbox", "pot"]), x + gp / 2, base - 0.3)
            x += gp

    blocks = [((17, 52), (27, 39, 51, 63, 76)), ((58, 94), (27, 39, 51, 63, 76)), ((106, 141), (27, 39, 51, 63, 76)),
              ((148, 183), (27, 39, 51, 63, 76)), ((17, 52), (95,)), ((58, 94), (95, 107, 119, 131)), ((148, 183), (95,))]
    for (xa, xb), rows in blocks:
        for base in rows:
            a_, b_ = xa, xb
            if base < 66:            # the palace grounds stay open
                if xb > 76 and xa < 76:
                    b_ = 76
                if xa < 124 and xb > 124:
                    a_ = 124
            if b_ - a_ < 6:
                continue
            noble = xa >= 106 and base < 78
            pack(a_, b_, base, (["house_red", "farmhouse"] if noble else BIG + ["barn", "shed"]))
    # trees and lamps of colour along the avenues
    for x in range(20, 182, 9):
        if not any(c - 2 <= x <= c + 4 for c in CANALS) and not (78 <= x <= 122):
            prop(w, rng.choice(["tree_light3", "tree_young", "tree_sm"]), x, AVE_Y[0] - 0.4)
            prop(w, rng.choice(["tree_light3", "tree_young", "tree_sm"]), x + 4, AVE_Y[1] + 1.6)

    # ---- walk graph along the avenues, and people
    xs = [20, 40, 60, 80, 99.5, 120, 140, 160, 180]
    ys = [22, 40, 60, 82.5, 104, 124, 136]
    for x in xs:
        g.node("v%d" % x, x, 82.5)
    for y in ys:
        g.node("h%d" % y, 99.5, y)
    g.link(*["v%d" % x for x in xs])
    g.link(*["h%d" % y for y in ys])
    for i in range(70):
        x, y = rng.uniform(20, 180), rng.choice([82.5, rng.uniform(20, 136)])
        if not (78 <= x <= 122 and 66 <= y <= 99):
            citizen(w, rng.randint(1, 7), x * T, y * T, "city", LINES)
    for (x, y) in ((18, 79), (18, 86.5), (96, 18), (103, 18), (94, 62), (106, 62), (96, 136), (103, 136), (182, 79), (182, 86.5)):
        citizen(w, 8, x * T, y * T, "city", ["Bienvenido a Aurelia.", "Circula, viajero.", "El palacio está cerrado a visitas.", "Todo en orden."], guard=True)
    for i, c in enumerate(w.walkers):
        c["mode"] = "guard" if c.get("guard") else ("loiterer" if i % 3 == 1 else "stroller")
        if not c.get("guard") and i % 5 in (0, 2, 3):
            c["brain"] = True
    # grass tufts outside the walls
    for _ in range(300):
        x, y = rng.randrange(0, AW), rng.randrange(0, AH)
        if not (CX0 <= x <= CX1 and CY0 <= y <= CY1) and (x, y) not in w.blocked:
            w.put("detail", x, y, GD, rng.choice([(i, 8) for i in range(21)]))
    for _ in range(60):
        x, y = rng.choice([(rng.uniform(2, 12), rng.uniform(2, 146)), (rng.uniform(188, 198), rng.uniform(2, 146)),
                           (rng.uniform(2, 198), rng.uniform(2, 11)), (rng.uniform(2, 198), rng.uniform(142, 148))])
        if not (AVE_Y[0] - 2 <= y <= AVE_Y[1] + 2 and x < 14):
            prop(w, rng.choice(["tr_palm", "tr_fan", "rock_big", "tree_bushy", "tr_palm"]), x, y)
    w.graph = g
    return w


ZONES = [("Gran Plaza de Aurelia", (80, 66, 120, 100)), ("Palacio de Aurelia", (76, 16, 124, 64)), ("Mercado Mayor", (74, 100, 126, 140)),
         ("Barrio de las Caravanas", (14, 98, 54, 140)), ("Academia de Armas", (126, 100, 144, 140)), ("Jardines del Este", (146, 98, 186, 140)),
         ("Barrio Noble", (104, 16, 186, 66)), ("Barrio de los Canales", (54, 16, 76, 140)), ("Barrio Antiguo", (14, 16, 54, 98)),
         ("Aurelia, la Ciudad Dorada", (0, 0, AW, AH))]

AURELIA_CFG = dict(
    out="scenes/world/aurelia.tscn", tileset="res://resources/tilesets/aurelia_tileset.tres",
    walkmask="res://resources/world/aurelia_walkmask.png", player=(6 * 16, 82.5 * 16),
    minimap="res://resources/world/minimap_aurelia.png", title="Aurelia, la Ciudad Dorada", hunters=6,
    preview_layers=["water", "water_fx", "ground", "ground_overlay", "road", "detail", "water_city", "rim", "coast", "dock", "dock_fx", "fence", "walls", "towers"],
    zones=ZONES,
    exits=[dict(name="WestExit", pos=(18, 82.5 * 16), size=(24, 6 * 16), scene="res://scenes/world/desert.tscn", spawn="east", dir="left")],
    spawns={"west": (6 * 16, 82.5 * 16), "respawn": (99.5 * 16, 95 * 16), "start": (6 * 16, 82.5 * 16)},
    left_gap=AVE_Y,
)

if __name__ == "__main__":
    import w_export as WE
    w = build()
    WE.FRAMES_DIR = "aurelia"
    for f in glob.glob(os.path.join(ROOT, "resources/sprite_frames/aurelia/*.tres")):
        os.remove(f)
    for sheet in WP.SHEETS:
        if WP.SHEETS[sheet][0]:
            WE.res_for_raw(os.path.join(RAW, WP.SHEETS[sheet][0]))
    WE.tileset(w, "resources/tilesets/aurelia_tileset.tres")
    WE.walk_mask(w, "resources/world/aurelia_walkmask.png")
    WE.scene(w, AURELIA_CFG)
    print("aurelia: props", len(w.props), "actors", len(w.actors), "walkers", len(w.walkers))
