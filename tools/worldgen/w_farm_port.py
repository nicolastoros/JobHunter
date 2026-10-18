"""Farms east of the city and the commercial port on the southern coast."""
from w_layout import *
import w_terrain as WT
import xml.etree.ElementTree as ET

LINES_FARM = ['La cosecha viene buena este año.', 'Las gallinas se escapan a cada rato.', 'El molino no se detiene nunca.', 'Parece que va a llover.', 'Llevo calabazas al mercado.', 'Mi vaca da la mejor leche del valle.', 'De noche los zorros rondan el gallinero.']
LINES_PORT = ['Llegó el barco del sur.', 'Hay pescado fresco en el mercado.', 'Cuidado con las cuerdas.', 'El mar está picado hoy.', 'Ese tiburón es enorme.', 'Cargamos sal y especias.', 'Dicen que hay piratas al este.', 'Pronto zarpamos.', 'Me gusta el olor del mar.', 'El puerto nunca duerme.', '¿Conoces la taberna La Gaviota?', 'Mañana zarpa el Albatros.']

FIELD = {"tl": (1, 1), "t": (2, 1), "tr": (4, 1), "l": (1, 2), "c": (2, 2), "r": (4, 2), "bl": (1, 4), "b": (2, 4), "br": (4, 4)}
FIELD_C = [(2, 2), (3, 2), (2, 3), (3, 3)]
PEN = nine_at(20, 15)
FARM_X0 = 134


def field(w, x0, y0, x1, y1, crops):
    cells = rect_cells(x0, y0, x1, y1)
    autotile(w, "ground_overlay", cells, FG, FIELD, None, center_variants=FIELD_C)
    w.blocked |= cells
    for y in range(y0 + 1, y1, 2):
        crop = w.rng.choice(crops)
        for x in range(x0 + 1, x1):
            if w.rng.random() < 0.92:
                prop(w, crop, x + 0.5, y + 0.85, dy=w.rng.randint(-1, 1))
    # collision so the player walks around the beds, not over the crops
    w.solids |= {(x, y) for (x, y) in cells if x0 < x < x1 and y0 < y < y1}


def pen(w, x0, y0, x1, y1, gate_x=None):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            k = ("t" if y == y0 else "b" if y == y1 else "") + ("l" if x == x0 else "r" if x == x1 else "")
            k = {"": "c", "t": "t", "b": "b", "l": "l", "r": "r"}.get(k, k)
            if k == "c":
                w.put("ground", x, y, FG, PEN["c"])
            elif gate_x is not None and y == y1 and x in (gate_x, gate_x + 1):
                w.put("ground", x, y, FG, PEN["c"])
            else:
                w.put("fence", x, y, FG, PEN[k], "full")
    w.blocked |= rect_cells(x0, y0, x1, y1)


def dirt_path(w, cells):
    autotile(w, "ground_overlay", cells, FG, nine_at(19, 1), {"se": (22, 1), "sw": (23, 1), "ne": (22, 2), "nw": (23, 2)},
             center_variants=[(20, 2)])
    w.blocked |= cells


def build_farm(w, g):
    rng = w.rng
    # dirt lanes
    lanes = rect_cells(138, 54, 170, 59) | rect_cells(142, 32, 145, 88) | rect_cells(156, 30, 159, 88) | rect_cells(142, 74, 170, 76)
    dirt_path(w, lanes)
    # windmill (body + animated sails)
    mill = prop(w, "mill", 150, 50)
    base_y = 50 * T
    s = actor_spec("Sails_animation", (0, 0, 160, 144))
    hub_x, hub_y = 150 * T, base_y - 129 + 44
    actor(w, "sails", hub_x, base_y + 1, s["image"], (0, 0, 160, 144), s["frames"], collide=False, foot=72 + (base_y + 1 - hub_y))
    # buildings
    prop(w, "farmhouse", 164, 52.6)
    prop(w, "barn", 152, 31)
    # the stable: its keeper in front of the barn and a paddock with the animals for sale
    keeper = tmx_actor(w, "stable_keeper", "Old_man_idle", (0, 0, 32, 32), 149.2 * T, 33.6 * T,
                       talk=("Bruno, mozo de cuadra", ["Ciervos de monta y compañeros de caza. No son baratos, pero valen lo que cuestan."]),
                       bubble=["¡Ciervos de monta!", "Compañeros de caza fieles.", "Cuido a cada animal como a un hijo."])
    keeper["opens"] = "stable"
    pen(w, 133, 19, 143, 28, gate_x=138)
    import w_outside as WO
    for kind, x, y in (("Deer", 136, 22.5), ("Fox", 140, 24), ("Boar", 137, 26)):
        WO.animal(w, kind, x * T, y * T, (134 * T, 20.5 * T, 8 * T, 6 * T))
    prop(w, "shed", 166, 31)
    prop(w, "longshed", 137.5, 52.3)
    prop(w, "coop", 170.5, 42)
    prop(w, "coop2", 147.5, 41)
    prop(w, "scarecrow", 151, 67.5)
    for (x, y) in ((139.5, 49), (161, 46.5), (168, 46.5)):
        prop(w, rng.choice(["barrel", "crate", "sack"]), x, y)
    prop(w, "cart", 154.5, 57.6, flip=True)
    prop(w, "well_grass", 141.5, 45)
    # animal pens
    pen(w, 160, 18, 171, 28, gate_x=164)
    for (x, y, reg) in ((162.5, 22.5, (384, 16, 64, 32)), (167.5, 25.5, (272, 16, 32, 32)), (164.5, 26.8, (384, 16, 64, 32))):
        tmx_actor(w, "cow", "Cow_animation", reg, x * T, y * T, flip=rng.random() < .5,
                  talk=("Vaca", ["Muuu."]), bubble=["Muuu."])
    pen(w, 146, 18, 154, 26, gate_x=149)
    for (x, y, reg) in ((148, 21, (160, 0, 32, 32)), (151.5, 22.5, (0, 0, 32, 32)), (149.5, 24.8, (64, 0, 32, 32))):
        tmx_actor(w, "pig", "Pig_animation", reg, x * T, y * T, flip=rng.random() < .5, talk=("Cerdo", ["Oink."]), bubble=["Oink."])
    pen(w, 160, 36, 170, 44, gate_x=163)
    for i in range(6):
        tmx_actor(w, "chicken", "Chicken_animation", (160, 0, 32, 32), (161.5 + (i % 3) * 3) * T, (38.5 + (i // 3) * 3.5) * T,
                  flip=rng.random() < .5, collide=False)
    # fields & orchard
    field(w, 136, 62, 140 + 0, 72, ["crop_cabbage", "crop_cabbage2"])
    field(w, 146, 62, 154, 72, ["crop_corn", "crop_corn_young"])
    field(w, 161, 62, 171, 72, ["crop_pumpkin", "crop_melon"])
    field(w, 136, 79, 140, 90, ["crop_carrot", "crop_beet", "crop_leek"])
    field(w, 146, 79, 154, 90, ["crop_tomato", "crop_pepper", "crop_eggplant"])
    for y in (81, 86, 91):
        for x in (162, 166, 170):
            prop(w, rng.choice(["orchard_apple", "orchard_orange", "orchard_lemon", "orchard_cherry"]), x + rng.uniform(-.3, .3), y)
    farmer_spots = [(144, 60), (157.5, 60), (143.5, 77), (157.5, 77), (157.5, 36)]
    N = g.node
    N("f_gate", 140, 56.5); N("f_mid", 157.5, 56.5); N("f_n", 157.5, 33); N("f_s", 157.5, 75); N("f_w", 143.5, 75); N("f_nw", 143.5, 44)
    N("f_e", 168, 56.5); N("f_se", 168, 75)
    g.link("e_road", "f_gate", "f_mid", "f_e", "f_se", "f_s", "f_mid", "f_n")
    g.link("f_gate", "f_nw", "f_w", "f_s")
    for i, (x, y) in enumerate(farmer_spots):
        citizen(w, (i + 1) % 5 + 1, x * T, y * T, "farm", LINES_FARM)


# ---------------------------------------------------------------------------
def tmx_layer_cells(path, layer_names):
    root = ET.parse(os.path.join(RAW, path)).getroot()
    ts = sorted([(int(t.get("firstgid")), int(t.get("columns") or 1), t.find("image").get("source") if t.find("image") is not None else "")
                 for t in root.findall("tileset")])
    out = []
    for lay in root.iter("layer"):
        if lay.get("name") not in layer_names:
            continue
        for c in lay.iter("chunk"):
            cx, cy, wd = int(c.get("x")), int(c.get("y")), int(c.get("width"))
            vals = [int(v) for v in c.text.replace("\n", "").split(",") if v.strip()]
            for i, gid in enumerate(vals):
                if not gid:
                    continue
                gid &= 0x1FFFFFFF
                for fg, cols, img in reversed(ts):
                    if gid >= fg:
                        t = gid - fg
                        out.append((cx + i % wd, cy + i // wd, os.path.basename(img), (t % cols, t // cols)))
                        break
    return out


def build_port(w, g):
    rng = w.rng
    SY = WT.SHORE_Y
    PX0, PX1 = 34, 150
    # dirt ground of the harbour
    dirt_path(w, rect_cells(PX0, 97, PX1, SY + 1) | rect_cells(84, 89, 95, 97))
    for x in range(PX0 + 1, PX1):
        w.put("coast", x, SY, WC, (1, 3), "full")
    # invisible solids: open sea + shore row (docks reopen it below)
    for y in range(SY, WT.H):
        for x in range(WT.W):
            w.solids.add((x, y))
    # boardwalk along the shore
    bx0, bx1 = 40, 144
    for x in range(bx0, bx1 + 1):
        for r in range(4):
            w.put("dock", x, SY + r, EX, (x % 7, r))
            w.solids.discard((x, SY + r))
        if x % 4 == 0:
            w.put("dock_fx", x, SY + 4, PL, (0, 0)); w.put("dock_fx", x, SY + 5, PL, (0, 1))
    # piers
    piers = [50, 66, 98, 114, 130]
    for px in piers:
        for y in range(SY + 4, SY + 15):
            r = 3 if y == SY + 14 else (1 if y % 2 else 2)
            w.put("dock", px, y, EX, (7, r)); w.put("dock", px + 1, y, EX, (8, r))
            w.solids.discard((px, y)); w.solids.discard((px + 1, y))
        for y in (SY + 8, SY + 13):
            w.put("dock_fx", px - 1, y, PL, (0, 0)); w.put("dock_fx", px - 1, y + 1, PL, (0, 1))
            w.put("dock_fx", px + 2, y, PL, (2, 0)); w.put("dock_fx", px + 2, y + 1, PL, (2, 1))
    # water life: stamp the authors' wave & sparkle layers across the sea
    waves = tmx_layer_cells("fishing/Tiled_foles/Fishing_dock.tmx", ["water_detailsation1", "water_detailsation3"])
    srcmap = {"water_detilazation_v2.png": WD, "Water_detailization1.png": WD1}
    minx = min(c[0] for c in waves); miny = min(c[1] for c in waves)
    for ox in range(-4, WT.W, 34):
        for oy in (SY + 4, SY + 16):
            dx = ox + rng.randint(0, 10); dy = oy + rng.randint(-2, 3)
            for (x, y, img, at) in waves:
                if img in srcmap:
                    tx, ty = x - minx + dx, y - miny + dy
                    if ty > SY + 3 and (tx, ty) not in w.layers.get("dock", {}):
                        w.put("water_fx", tx, ty, srcmap[img], at)
    # ships
    tmx_actor(w, "ship", "Boat1", (0, 0, 176, 128), 82 * T, (SY + 16) * T, collide=False)
    tmx_actor(w, "ship2", "Boat2", (0, 0, 160, 112), 146 * T, (SY + 15) * T, collide=False)
    tmx_actor(w, "ship3", "Boat1", (0, 0, 176, 128), 40 * T, (SY + 21) * T, collide=False, flip=True)
    for px in piers:
        for side, reg, ts in ((-1.6, (0, 0, 48, 96), "Small_boat_v1_1"), (3.6, (0, 0, 48, 112), "Small_boat_v2_1-Sheet")):
            if rng.random() < 0.8:
                tmx_actor(w, "boat", ts, reg, (px + side) * T, (SY + 10 + rng.uniform(0, 3)) * T, collide=False)
    for i in range(8):
        k = rng.choice([("Fish1", (0, 0, 32, 32)), ("Fish3", (0, 0, 48, 32))])
        tmx_actor(w, "fish", k[0], k[1], rng.uniform(20, 170) * T, rng.uniform(SY + 7, WT.H - 3) * T, collide=False)
    # warehouses & fish market
    for (x, k, fl) in ((40, "fish_house", False), (49, "fish_house2", True), (130, "fish_house", True), (139, "fish_house2", False),
                       (103, "barn", False), (75, "shed", False)):
        prop(w, k, x, 104, flip=fl)
    prop(w, "fish_sign", 40, 101.6); prop(w, "fish_sign2", 139, 101.6)
    prop(w, "house_red", 59, 104); prop(w, "farmhouse", 121, 104, flip=True)
    prop(w, "longshed", 81, 103.6); prop(w, "longshed", 98, 103.6, flip=True)
    prop(w, "fruit_crates", 71, 109.3); prop(w, "empty_stall", 105, 109.6); prop(w, "cloth_stall", 128, 109.4)
    for x in range(42, 144, 3):
        if not (85 <= x <= 94) and rng.random() < 0.55:
            prop(w, rng.choice(["barrel", "crate", "crate2", "sack", "barrel_f1", "barrel_open", "crate_f", "sack_f"]), x + rng.uniform(0, 1.5), 111.6)
    for (x, y) in ((36, 99), (145, 99), (33, 108), (148, 108)):
        prop(w, rng.choice(["tree_round", "tree_light2", "tree_bushy"]), x, y)
    stalls = [("fish_rack", 59, 107), ("fish_rack2", 66, 107), ("shark", 113, 107.3), ("net_frame", 120, 106.5),
              ("fish_rack", 109, 107.2), ("cargo_pile", 82, 106.8), ("cargo_pile2", 97, 106.8),
              ("cargo_fish", 55, 108.8), ("barrel_fish", 64, 109.6), ("crate_fish", 68, 104), ("sacks_fish", 72, 107.5),
              ("fish_pile", 124, 108), ("barrel_f1", 126.5, 105), ("barrel_f3", 46, 108.5), ("crate_fish3", 52, 109),
              ("barrel_crate", 135, 109), ("cargo_pile", 143, 107.5), ("crate_f2", 78.5, 109), ("barrel_open", 99.6, 109.5),
              ("big_barrel", 101.5, 109.6), ("crate_fish2", 106, 109.3)]
    for k, x, y in stalls:
        prop(w, k, x, y, flip=rng.random() < 0.3)
    # port people
    tmx_actor(w, "old_sailor", "Old_man_orders", (0, 0, 32, 32), 88 * T, 110.6 * T,
              talk=("Capitán Brask", ["¡Muevan esas cajas! El Gaviota zarpa con la marea.", "Si necesitas viajar, este puerto conecta con todo el reino."]),
              bubble=["¡Muevan esas cajas!", "¡Más rápido, holgazanes!"])
    tmx_actor(w, "old_idle", "Old_man_idle", (0, 0, 32, 32), 128.5 * T, 108.2 * T,
              talk=("Pescador Ulrik", ["Cuarenta años pescando aquí. El mar da y el mar quita."]), bubble=["Buena pesca hoy..."])
    tmx_actor(w, "boy_amazed", "Boy_amazed", (0, 0, 32, 48), 115.5 * T, 109.5 * T,
              talk=("Jory", ["¿Viste ese tiburón? Lo pescó mi papá."]), bubble=["Es enorme.", "Un tiburón de verdad."])
    tmx_actor(w, "boy_wave", "Boy_weaves", (0, 0, 32, 48), 67.5 * T, (SY + 13.6) * T,
              talk=("Pip", ["¡Estoy saludando a los barcos! Algún día seré marinero."]), bubble=["¡Adióóós!"])
    tmx_actor(w, "boy_look", "Boy_looking", (0, 0, 32, 48), 131 * T, (SY + 14) * T, talk=("Tim", ["Shh. Estoy mirando los peces."]))
    tmx_actor(w, "cobold", "Cobold_on_floor", (0, 0, 32, 32), 64 * T, 104.2 * T,
              talk=("Kobold mercader", ["Vendo escamas brillantes. Precio justo."]), bubble=["¡Gzz! ¡Ofertas!"])
    # walk graph along the harbour
    N = g.node
    pts = {"p_top": (89.5, 99), "p_w1": (70, 104.6), "p_w2": (52, 104.6), "p_e1": (109, 104.6), "p_e2": (126, 104.6),
           "p_bw": (45, SY + 1.5), "p_bc": (89.5, SY + 1.5), "p_be": (140, SY + 1.5), "p_bw2": (66.5, SY + 1.5), "p_be2": (114.5, SY + 1.5)}
    for k, (x, y) in pts.items():
        N(k, x, y)
    g.link("s_road", "p_top", "p_w1", "p_w2", "p_bw", "p_bw2", "p_bc", "p_be2", "p_be", "p_e2", "p_e1", "p_top", "p_bc")
    for i, px in enumerate(piers):
        N("pier%d" % i, px + 1, SY + 13)
        N("pierb%d" % i, px + 1, SY + 1.5)
        g.link("pierb%d" % i, "pier%d" % i)
    g.link("p_bw", "pierb0", "p_bw2"); g.link("pierb1", "p_bw2")
    g.link("p_bc", "pierb2", "p_be2"); g.link("pierb3", "p_be2"); g.link("pierb4", "p_be")
    for i, k in enumerate(["p_top", "p_w1", "p_e1", "p_bc", "p_bw2", "p_be2", "p_w2", "p_e2", "pier1", "pier3"]):
        x, y = g.nodes[g.index[k]]
        citizen(w, i % 5 + 1, x, y, "port", LINES_PORT)
