"""Outside the walls: roads, meadow, forest border and the training grounds."""
from w_layout import *
import w_terrain as WT

LINES_ROAD = ['Buen día, viajero.', 'El camino está tranquilo hoy.', 'Llevo la cosecha al mercado.', 'Parece que va a llover.', '¿Vienes del puerto?', 'Ya no camino como antes.', 'Qué buen día.']
LINES_TRAIN = ['Uno, dos. Uno, dos.', 'Mantén la guardia alta.', 'Me duele todo el cuerpo.', 'Esa flecha pasó muy cerca.', 'La capitana es exigente.', 'Quiero llegar a ser cazador.', 'Más fuerza en el golpe.', 'Necesito descansar un poco.']

TX0, TY0, TX1, TY1 = 10, 40, 44, 72     # training compound (inclusive)


def build_roads(w, g):
    import w_coast as WC
    # cobbles end a little past the gate; from there a dirt track runs on to the plain,
    # the same kind of path that greets you on the other side
    north = WC.road_mask([(89.5, 26), (89.2, 19), (90.4, 15)], 5.2)
    track = WC.road_mask([(89.6, 19), (91.2, 12.5), (90.6, 6), (89.5, -1)], 3.8)   # runs under the cobbles' rounded end
    track = {c for c in track if c[1] >= 0}
    autotile(w, "ground_overlay", track, FG, nine_at(19, 1), {"se": (22, 1), "sw": (23, 1), "ne": (22, 2), "nw": (23, 2)}, center_variants=[(20, 2)])
    w.blocked |= track
    westr = WC.road_mask([(52, 56.5), (49, 57.4), (45.5, 56.6)], 5.2)
    eastr = WC.road_mask([(127, 56.5), (131, 57.6), (136, 56.8), (139, 56.5)], 5.2)
    road = north | westr | eastr | rect_cells(87, 22, 92, 25)
    autotile(w, "road", road, RD, WT.ROAD_NINE, WT.ROAD_INNER, center_variants=[(2, 2)])
    w.out_road = road
    w.blocked |= road
    N = g.node
    N("n_road2", 89.3, 18); N("n_road1", 91, 11.5); N("n_road0", 89.8, 1.5)
    g.link("n_gate", "n_road2", "n_road1", "n_road0")
    N("w_road", 47, 56.8); g.link("w_gate", "w_road")
    N("e_road", 136, 57); g.link("e_gate", "e_road")
    N("s_road", 89.5, 95); g.link("s_gate", "s_road")


ENTERABLE = [
    # (approx tile position of the door, interior scene, label)
    ((98.6, 42), "guild_1f", "Gremio de Cazadores"),
    ((60, 71), "house_red", "Casa"),
    ((68, 42), "home", "Tu casa"),
    ((112, 83), "house_red", "Casa"),
    ((50.5, 102), "house_red", "Taberna La Gaviota"),
    ((71.5, 102), "port_house", "Pescadería"),
    ((164, 52.6), "farmhouse", "Granja"),
]


def assign_doors(w):
    used = set()
    for (tx, ty), interior, label in ENTERABLE:
        best = None
        for i, d in enumerate(w.house_doors):
            if i in used:
                continue
            dx = d["pos"][0] / T - tx; dy = d["pos"][1] / T - ty
            dist = dx * dx + dy * dy
            if (interior == "guild_1f") != (d["key"] == "guild_hall"):
                continue
            if interior in ("farmhouse", "home") and d["key"] != "farmhouse":
                continue
            if interior == "house_red" and d["key"] != "house_red":
                continue
            if interior == "port_house" and d["key"] not in ("fish_house", "fish_house2"):
                continue
            if best is None or dist < best[0]:
                best = (dist, i)
        if best and best[0] < 120:
            used.add(best[1])
            d = w.house_doors[best[1]]
            w.doors.append(dict(pos=d["pos"], interior=interior, label=label, name="door_%d" % len(w.doors), key=d["key"], prop=d.get("prop")))


def scatter(w, keys, rect, n, avoid=None, min_dist=1.6):
    rng = w.rng
    x0, y0, x1, y1 = rect
    placed = []
    tries = 0
    while len(placed) < n and tries < n * 30:
        tries += 1
        x, y = rng.uniform(x0, x1), rng.uniform(y0, y1)
        cell = (int(x), int(y))
        if cell in w.blocked or (avoid and avoid(x, y)):
            continue
        if any((x - a) ** 2 + (y - b) ** 2 < min_dist ** 2 for a, b in placed):
            continue
        placed.append((x, y))
        prop(w, rng.choice(keys), x, y, flip=rng.random() < 0.5)
    return placed


TREES = ["tree_big", "tree_mid", "pine_big", "pine_mid", "tree_light", "tree_light2", "tree_bushy", "tree_bushy2",
         "tree_round", "tree_oak", "tree_oak2", "pine", "tree_light3"]
BUSHES = ["shrub%d" % i for i in range(12)] + ["bush", "bush_a", "bush_b", "bush_c", "bush_round"]
FLOWERS = ["flower%d" % i for i in range(6)] + ["weed0", "weed1", "weed2", "weed3"]


def forest_border(w):
    """Dense tree line around the land edges; leaves the north road open."""
    def avoid_road(x, y):
        return 84 <= x <= 95 and y < 26
    scatter(w, TREES, (0, 2, 7, 100), 50, avoid=lambda x, y: (int(x), int(y) + 2) not in w.land, min_dist=2.6)
    scatter(w, TREES, (173, 2, 180, 98), 50, avoid=lambda x, y: (int(x), int(y) + 2) not in w.land, min_dist=2.6)
    scatter(w, TREES, (0, 1, 180, 7), 70, avoid=avoid_road, min_dist=2.8)
    scatter(w, BUSHES, (0, 5, 9, 104), 25, avoid=lambda x, y: (int(x), int(y) + 1) not in w.land)
    scatter(w, BUSHES, (171, 5, 180, 100), 25, avoid=lambda x, y: (int(x), int(y) + 1) not in w.land)


def meadow(w, g):
    """North meadow between forest and city wall: flowers, rocks, groves and wild animals."""
    def avoid(x, y):
        return 84 <= x <= 95 or (WT.CX0 - 2 <= x <= WT.CX1 + 2 and y > WT.CY0 - 4)
    scatter(w, TREES, (10, 8, 170, 20), 22, avoid=avoid, min_dist=5)
    scatter(w, BUSHES, (10, 8, 170, 22), 40, avoid=avoid, min_dist=2.5)
    scatter(w, ["rock_big", "rock_big2", "rock_tall", "rock_tall2", "rock_s1", "rock_s2", "stump", "log"], (12, 9, 168, 21), 18, avoid=avoid, min_dist=4)
    scatter(w, FLOWERS, (8, 7, 172, 23), 140, avoid=lambda x, y: 86 <= x <= 93, min_dist=0.9)
    # grass tufts & flower patches as ground details
    tufts = [(x, 8) for x in range(0, 21)]
    for _ in range(500):
        x, y = w.rng.randrange(1, 179), w.rng.randrange(1, WT.SHORE_Y - 1)
        if (x, y) in w.blocked or WT.in_city(x, y) or (x, y) not in w.land or (x, y + 1) not in w.land:
            continue
        w.put("detail", x, y, GD, w.rng.choice(tufts))
    # groves & thickets filling the open countryside so nothing feels empty
    def free(x, y):
        c = (int(x), int(y))
        return (c in w.blocked or WT.in_city(x, y) or c not in w.land or (c[0], c[1] + 2) not in w.land
                or (TX0 - 2 <= x <= TX1 + 2 and TY0 - 6 <= y <= TY1 + 2) or (132 <= x <= 173 and 16 <= y <= 93))
    for rect, nt, nb in (((8, 75, 50, 104), 22, 30), ((42, 24, 51, 92), 8, 14), ((128, 22, 134, 92), 6, 10),
                         ((96, 88, 132, 95), 5, 8), ((44, 88, 84, 95), 5, 8)):
        scatter(w, TREES + ["tree_apple", "tree_apple2", "orchard_green"], rect, nt, avoid=free, min_dist=3.4)
        scatter(w, BUSHES, rect, nb, avoid=free, min_dist=2.0)
        scatter(w, FLOWERS, rect, nb * 2, avoid=free, min_dist=1.0)
    scatter(w, ["rock_s1", "rock_s2", "stump", "log", "mushrooms", "stone_blue"], (8, 75, 50, 104), 8, avoid=free, min_dist=4)

    # wild animals roaming the meadow
    for kind, n in (("Deer", 5), ("Hare", 6), ("Fox", 2), ("Black_grouse", 4)):
        for _ in range(n):
            x, y = w.rng.uniform(14, 166), w.rng.uniform(9, 20)
            if 82 <= x <= 97:
                x += 18
            animal(w, kind, x * T, y * T, (10 * T, 8 * T, 160 * T, 14 * T))


def animal(w, kind, px, py, rect):
    folder = "Black_grouse" if kind == "Black_grouse" else kind
    walk = "Fox_walk" if kind == "Fox" else kind + "_Walk"
    img = os.path.join(RAW, "animals/PNG/With_Shadow/%s/%s_Idle_with_shadow.png" % (folder, kind))
    w.animals.append(dict(kind=kind, image=img, rect=(0, 0, 32, 32), pos=(px, py), origin=(16, foot_of(img, (0, 0, 32, 32))),
                          wander=rect, walk=os.path.join(RAW, "animals/PNG/With_Shadow/%s/%s_with_shadow.png" % (folder, walk))))


# ---------------------------------------------------------------------------
def training_ground(w, g):
    """Barracks yard west of the city: stone wall to the north, wooden fences, sand floor."""
    rng = w.rng
    sand_var = [(19, 10)] * 10 + [(10, 20), (11, 20), (12, 20), (13, 20), (12, 19), (13, 19), (9, 20)]
    for y in range(TY0, TY1 + 1):
        for x in range(TX0, TX1 + 1):
            w.put("ground", x, y, TW, rng.choice(sand_var))
    # north wall with grass foot
    for x in range(TX0, TX1 + 1):
        c = 0 if x == TX0 else 2 if x == TX1 else 1
        w.put("walls", x, TY0 - 4, MW, (c, 0), "bottom")
        w.put("walls", x, TY0 - 3, MW, (c, 1), "full")
        w.put("walls", x, TY0 - 2, MW, (c, 2), "full")
        w.put("walls", x, TY0 - 1, MW, (c, 3) if c != 1 else w.rng.choice([(1, 3), (1, 3), (1, 3)]), "full")
        w.put("walls", x, TY0, TW, (c, 6) if c != 1 else w.rng.choice([(14, 5), (15, 5), (16, 5), (1, 6)]), "full")
    for x in (TX0, TX1 - 1, 20, 34):
        WT.tower(w, x, TY0, 8)
    # side fences
    for y in range(TY0 + 1, TY1):
        w.put("fence", TX0, y, TW, (11, 9 + (y % 3)), "left")
        if not (54 <= y <= 59):
            w.put("fence", TX1, y, TW, (12, 9 + (y % 3)), "right")
    # bottom fence
    for x in range(TX0, TX1 + 1):
        if x == TX0:
            at = (18, 11)
        elif x == TX1:
            at = (20, 11)
        else:
            at = rng.choice([(9, 10), (10, 10), (19, 11), (9, 11), (10, 11)])
        w.put("fence", x, TY1, TW, at, "bottom")
    w.blocked |= rect_cells(TX0, TY0 - 4, TX1, TY1)

    # sparring ring (rope border) with straw floor
    rx0, ry0, rx1, ry1 = 28, 46, 40, 53
    for y in range(ry0, ry1 + 1):
        for x in range(rx0, rx1 + 1):
            w.put("ground", x, y, TW, (19, 10))
    for x in range(rx0, rx1 + 1):
        top = (0, 18) if x == rx0 else (2, 18) if x == rx1 else (1, 18) if x == (rx0 + rx1) // 2 else (3, 18)
        bot = (0, 20) if x == rx0 else (2, 20) if x == rx1 else (3, 18)
        w.put("fence", x, ry0, TW, top, "bottom")
        if x not in (33, 34, 35):
            w.put("fence", x, ry1, TW, bot, "bottom")
    for y in range(ry0 + 1, ry1):
        w.put("fence", rx0, y, TW, (3, 19), "left")
        w.put("fence", rx1, y, TW, (3, 20), "right")

    # archery range along the north wall
    for i, x in enumerate((14, 17, 20)):
        prop(w, "t_target", x, TY0 + 2.4)
    for i, x in enumerate((14, 17, 20)):
        tmx_actor(w, "archer", "Archer%d_with_shadow" % (i + 1), (0, 0, 32, 32), x * T + 8, (TY0 + 9) * T,
                  talk=("Arquero", ["Respira, apunta y suelta. Así de simple."]), bubble=["En el blanco.", "Casi.", "Otra vez."])
    # weapon & shield stands
    for i, (k, x) in enumerate((("t_rack_swords", 13.5), ("t_rack_axes", 13.5), ("t_rack_spear", 13.5))):
        prop(w, k, x, TY0 + 14 + i * 3)
    prop(w, "t_shields", 17.5, TY0 + 14); prop(w, "t_shields2", 17.5, TY0 + 17)
    prop(w, "t_rack_tall", 11.2, TY0 + 22)
    prop(w, "t_armor_crate", 13, TY1 - 3.5); prop(w, "t_crates", 16, TY1 - 3.2); prop(w, "t_supplies", 20, TY1 - 2.8)
    prop(w, "t_sacks", 23.5, TY1 - 1.8)
    # spectators box for nobles
    prop(w, "t_vip_tent", 37, TY1 - 4.2)
    tmx_actor(w, "noble_man", "Aristocrat_man", (0, 0, 32, 48), 34.5 * T, (TY1 - 5.3) * T,
              talk=("Lord Halvar", ["Mis hijos entrenan aquí. Algún día uno de ellos liderará la guardia."]), bubble=["Aceptable.", "Bien hecho."])
    tmx_actor(w, "noble_old", "Aristocrat_old_man", (16, 0, 32, 48), 39.5 * T, (TY1 - 5.3) * T,
              talk=("Barón Orsic", ["En mis tiempos entrenábamos con espadas de verdad."]), bubble=["En mis tiempos..."])
    tmx_actor(w, "servant", "Servant_girl_with_shadow", (0, 0, 32, 48), 42.3 * T, (TY1 - 3.5) * T,
              talk=("Sirvienta", ["El barón quiere su té."]))
    # banners
    for x in (24, 32, 43):
        prop(w, "t_banner_s", x, TY0 + 1.6)
    prop(w, "t_banner_big", 26, TY0 + 2.2); prop(w, "t_banner_big", 42, TY0 + 2.2)
    # benches & resting fighters
    prop(w, "t_bench", 24, TY0 + 10.5); prop(w, "t_bench", 24, TY0 + 13)
    tmx_actor(w, "fighter_sit", "Fighter_sit1", (0, 0, 32, 32), 24 * T, (TY0 + 10.4) * T,
              talk=("Recluta agotado", ["Cinco horas de entrenamiento. No siento los brazos."]), bubble=["Necesito un respiro.", "Cinco minutos más."])
    tmx_actor(w, "fighter_sit2", "Fighter_sit2", (0, 0, 32, 32), 23.4 * T, (TY0 + 12.9) * T)

    # sparring fighters & mannequins, positioned like the authors' training ground
    trainer_lines = ["Guardia alta.", "Otra vez.", "Pies firmes."]
    tmx_actor(w, "trainer", "Trainer_with_shadow", (0, 0, 32, 32), 34 * T, 54.6 * T,
              talk=("Capitana Brenna", ["Si quieres ser cazador, primero aprende a sostener bien la espada.",
                                       "Puedes practicar con los maniquíes cuando quieras."]), bubble=trainer_lines)
    tmx_actor(w, "duel_a", "Fighter_sword2_with_shadow", (0, 16, 48, 32), 32 * T, 50 * T, collide=True)
    tmx_actor(w, "duel_b", "Fighter_sword1_with_shadow", (0, 16, 48, 32), 36.2 * T, 50 * T, collide=True)
    tmx_actor(w, "shield_fighter", "Fighter_sword_shield_with_shadow", (0, 0, 48, 32), 30.5 * T, 59 * T)
    tmx_actor(w, "halberd", "Fighter_halberd_with_shadow", (0, 0, 80, 32), 38 * T, 60.5 * T)
    for (x, y, k) in ((16, 57, ("Attacked_Manequin3_with_shadow", (0, 0, 32, 32))), (20, 57, ("Attacked_Manequin1_with_shadow", (0, 32, 32, 32))),
                      (16, 64, ("Attacked_Manequin5_with_shadow", (0, 64, 32, 32))), (20, 64, ("Attacked_Manequin4_with_shadow", (0, 96, 32, 32))),
                      (24, 64, ("Attacked_Manequin2_with_shadow", (0, 96, 32, 32)))):
        tmx_actor(w, "mannequin", k[0], k[1], x * T + 8, y * T)
    for (x, y, k, reg) in ((16, 59.2, "Fighter_sword3_with_shadow", (0, 208, 64, 32)), (20, 59.2, "Fighter_sword5_with_shadow", (16, 144, 32, 32)),
                           (16, 66.2, "Fighter_sword4_with_shadow", (16, 80, 32, 32))):
        tmx_actor(w, "recruit", k, reg, x * T + 8, y * T, talk=("Recluta", ["Ahora no, estoy concentrado."]), bubble=["¡Ha!", "¡Hya!"])
    for i in range(4):
        prop(w, "t_straw%d" % i, 26 + i * 1.6, TY1 - 9)

    # graph: entrance and a loop through the yard
    N = g.node
    N("t_gate", TX1 + 1, 56.5); N("t_in", 40.5, 56.5); N("t_mid", 27, 56.5); N("t_n", 27, 45.5); N("t_s", 27, 69.5); N("t_w", 21.5, 69.5)
    g.link("w_road", "t_gate", "t_in", "t_mid", "t_n")
    g.link("t_mid", "t_s", "t_w")
    for i in range(4):
        x, y = g.nodes[g.index[["t_in", "t_mid", "t_n", "t_s"][i]]]
        citizen(w, (i + 2) % 5 + 1, x, y, "training", LINES_TRAIN)
