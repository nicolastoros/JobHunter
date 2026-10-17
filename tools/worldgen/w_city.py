"""Castle town: central market plaza, fountain, house rows, guild and avenues."""
from w_layout import *

OX, OY = 66, 39   # offset from the first market's coordinates into the plaza


def o(x, y):
    return x + OX, y + OY


LINES_MARKET = ['Hoy hay mucha gente en el mercado.', 'El pan subió de precio otra vez.', 'Dicen que se vieron lobos al norte.', 'Mi abuela vendía flores en esta plaza.', 'Algún día compraré una buena espada.', 'La fuente está más limpia que antes.', '¿Vas al Gremio de Cazadores?', 'Huele a pan recién horneado.', 'La vidente sabe cosas que nadie le cuenta.', 'Cuida tu bolsa entre tanta gente.', 'Llegó un barco con especias.', 'Conviene llevar pociones antes de salir.', 'El herrero dice que el acero escasea.', 'El bardo toca muy bien.', 'Mañana hay feria en el puerto.', 'Los guardias están atentos últimamente.', 'Compré manzanas del valle.', 'Hace calor hoy.']
LINES_GUARD = ['Todo en orden.', 'Sigue tu camino.', 'Mantente atento fuera de las murallas.']


def build_city(w, g):
    rng = w.rng
    # ---------------------------------------------------------------- plaza ground
    for (a, b, c, d) in ((4, 7, 19, 15), (28, 7, 43, 15), (4, 21, 19, 31), (28, 21, 43, 31)):
        x0, y0 = o(a, b); x1, y1 = o(c, d)
        dirt_patch(w, x0, y0, x1, y1)
    fountain(w, 87, 56, 92, 58)
    for (x0, y0) in ((81, 52), (96, 52), (81, 61), (96, 61)):
        planter(w, x0, y0, x0 + 2, y0 + 2)
    prop(w, "tree_light2", 82.5, 54, dy=-2)
    prop(w, "tree_light2", 97.5, 54, dy=-2, flip=True)
    prop(w, "tree_light", 82.5, 63, dy=-2)
    prop(w, "tree_light", 97.5, 63, dy=-2, flip=True)
    for x in (85, 94):
        prop(w, "t_bench", x, 55, dx=0)
    prop(w, "t_bench", 89.5, 54.4)

    # ---------------------------------------------------------------- stalls (first market layout)
    def P(key, x, y, **kw):
        tx, ty = o(x, y)
        return prop(w, key, tx, ty, **kw)

    P("fruit_stall", 8.5, 13)
    P("fruit_small", 16, 11.5)
    trader(w, "fruits", *[v * T for v in o(13, 13.5)], talk=("Tomás el frutero", ["Manzanas del valle y melones del sur. Come bien antes de salir de viaje."]),
           bubble=["Frutas frescas.", "Melones dulces.", "Manzanas del valle."])
    P("crates_c", 6.5, 15.4)
    P("sack", 12.5, 8.25)
    P("barrels_a", 18.25, 14.4)
    P("sack2", 4.6, 9.6)
    P("melons", 5.2, 12.2)

    P("weapon_stall", 37, 14)
    kara = trader(w, "weapon", *[v * T for v in o(31.5, 13.4)], talk=("Kara la herrera", ["Tráeme lo que sueltan las bestias y te mejoro el equipo."]),
           bubble=["Acero de calidad.", "Mejoro armas y armaduras.", "¿Traes materiales?"])
    kara["opens"] = "forge"
    P("sword_table", 31.5, 9.5)
    P("armor_flag", 29.5, 11)
    P("armor_c", 43, 9)
    P("armor_b", 43, 11.5)
    P("weapon_rack", 41, 15.4)
    P("crates_b", 43.6, 14)

    P("rug", 9, 28.25)
    P("magic_tent", 9, 29.4)
    trader(w, "magic", *[v * T for v in o(9.1, 30.15)], talk=("Morga la vidente", ["Las cartas hablan de una bestia en el norte... y de alguien que todavía no conoce su destino."]),
           bubble=["Las cartas no mienten.", "¿Quieres conocer tu futuro?"])
    P("magic_table", 16, 24)
    P("orb", 12.6, 29.9)
    P("crates_d", 5, 23.5)
    P("barrel_big", 18, 30.5)

    P("bread_stall", 31.5, 24)
    trader(w, "bread", *[v * T for v in o(34.5, 23.5)], talk=("Rosa la panadera", ["Pan de centeno recién horneado. Llévate uno para el camino."]),
           bubble=["Pan caliente.", "Pasteles de miel."])
    P("cloth_stall", 38.5, 23.5)
    P("potion_cart", 42, 26.5)
    trader(w, "drinks", *[v * T for v in o(40, 26.25)], talk=("Ezra el alquimista", ["Pociones curativas y tónicos. Si sales de la ciudad, lleva al menos una."]),
           bubble=["Pociones y tónicos.", "Remedios naturales."])
    P("blue_tent", 36, 32)
    for tx, ty, k in [(34.5, 30.9, "table_a"), (37.6, 30.9, "table_b"), (31.5, 28.6, "table_c")]:
        P("stool", tx - 1, ty - 0.25)
        P("stool", tx + 1.06, ty - 0.25)
        P(k, tx + 0.06, ty)
    trader(w, "eater", *[v * T for v in o(38.5, 30.7)], talk=("Viajero hambriento", ["El estofado de Rosa es el mejor de Valdoria."]))
    P("crates_e", 30.25, 31.6)

    P("pastry_stall", 7.5, 19.4)
    P("barrel", 11.5, 19)
    P("crate", 13, 19.25)
    P("cart", 41, 19.4)
    P("barrel2", 44, 19)

    trader(w, "lute", 88 * T, 61.6 * T, talk=("Bardo Anselmo", ["Esta canción habla de un héroe que cruzó la llanura solo. Nadie recuerda su nombre."]),
           bubble=["♪ ♪ ♪", "♪ La llanura de Valdoria... ♪"])
    trader(w, "flutist", 91.5 * T, 61.6 * T, talk=("Nell la flautista", ["Tocamos aquí cada día de mercado. A la gente le gusta."]), bubble=["♪ ~ ♪"])

    # ---------------------------------------------------------------- houses
    houses_w = {"house_red": 8.3, "fish_house": 6.4, "fish_house2": 6.4, "farmhouse": 7.8, "barn": 5.7,
                "shed": 5.0, "longshed": 4.4, "coop": 2.3}
    clutter = ["barrel", "barrel2", "crate", "crate2", "sack", "sack2", "big_barrel", "crates_a", "pot", "barrels_a"]

    def pack(xa, xb, base, pool, jitter=4, gap=(0.2, 1.2), fill=True):
        x = xa
        last = None
        while True:
            fits = [k for k in pool if x + houses_w[k] <= xb]
            if not fits:
                break
            k = rng.choice([f for f in fits if f != last] or fits)
            last = k
            wdt = houses_w[k]
            prop(w, k, x + wdt / 2, base, flip=rng.random() < 0.5, dy=rng.randint(-jitter, jitter))
            x += wdt
            g_ = rng.uniform(*gap)
            if fill and g_ > 0.9:
                prop(w, rng.choice(["barrel", "crate", "sack", "barrel2"]), x + g_ / 2, base - 0.3)
            x += g_

    big = ["house_red", "fish_house", "fish_house2", "farmhouse"]
    # north: back row (roofs peek behind) and front row facing the plaza
    pack(54.5, 86, 35.5, big + ["barn"], fill=False)
    pack(93.5, 125.5, 35.5, big + ["barn"], fill=False)
    pack(54.8, 85.5, 42, big)
    prop(w, "guild_hall", 98.6, 42)
    s_ = actor_spec("Flags_animation", (0, 0, 96, 48))
    gx0, gy0 = 98.6 * T - 72, 42 * T - 133
    actor(w, "guild_flags", gx0 + 24 + 48, 42 * T + 1, s_["image"], (0, 0, 96, 48), s_["frames"], collide=False, foot=42 * T + 1 - (gy0 + 39))
    prop(w, "t_carpet_long", 97.8, 44.2, ysort=False) if False else None
    prop(w, "t_banner_big", 93.6, 43); prop(w, "t_banner_big", 103.6, 43)
    pack(104.4, 125.2, 42, big)
    # south row (fronts face the south wall street)
    pack(54.8, 85.5, 83, big + ["shed"])
    pack(94.2, 125.2, 83, big + ["shed"])
    # side blocks
    prop(w, "fish_house", 59.5, 52.6); prop(w, "longshed", 65.2, 52.4)
    prop(w, "fish_house2", 120.5, 52.6, flip=True); prop(w, "longshed", 114.8, 52.4, flip=True)
    prop(w, "house_red", 60, 71); prop(w, "coop", 66, 70.6)
    prop(w, "farmhouse", 120, 71, flip=True); prop(w, "coop2", 114, 70.6, flip=True)
    # side gardens with trees, bench and well
    for (x, y, k) in ((56.5, 63.4, "tree_round"), (66.2, 62.8, "tree_apple"), (113.8, 62.8, "tree_apple2"), (123.4, 63.4, "tree_round")):
        prop(w, k, x, y)
    prop(w, "t_bench", 61.3, 61.6); prop(w, "t_bench", 118.7, 61.6)
    prop(w, "well_grass", 61.3, 65.2); prop(w, "bush_round", 118.6, 65.6); prop(w, "bush_berry", 121, 66)
    for i in range(16):
        x, y = rng.choice([(rng.uniform(55.5, 67), rng.uniform(59.5, 66.5)), (rng.uniform(113, 124.5), rng.uniform(59.5, 66.5))])
        prop(w, rng.choice(["flower0", "flower1", "flower2", "flower3", "flower4", "weed0", "weed2"]), x, y)
    for (x, y) in ((66, 46.5), (113.5, 46.5)):
        prop(w, "crates_a", x, y)
    prop(w, "cart", 63, 46.4)
    prop(w, "barrels_a", 117.5, 46.4)

    # chatting groups (idle citizens facing each other)
    groups = [((76, 44.2), "right", (78.2, 44.2), "left"), ((101, 72.2), "right", (103.2, 72.2), "left"),
              ((63, 58.7), "down", (63.6, 60.3), "up"), ((116.5, 54.4), "right", (118.7, 54.4), "left"),
              ((87.2, 33), "right", (89.4, 33.4), "left"), ((92, 78), "left", (89.8, 78.4), "right")]
    for i, (p1, d1, p2, d2) in enumerate(groups):
        for (x, y), d in ((p1, d1), (p2, d2)):
            idle_citizen(w, (i * 2 + (d in ("left", "up"))) % 5 + 1, x * T, y * T, d, LINES_MARKET)

    # ---------------------------------------------------------------- avenues decoration
    for y in (31, 36):
        prop(w, "banner", 86.3, y); prop(w, "banner", 93.7, y)
    for y in (77, 82):
        prop(w, "banner", 86.3, y); prop(w, "banner", 93.7, y)
    for x in (56.5, 66):
        prop(w, "banner", x, 53.4)
        prop(w, "banner", x, 60.2)
    for x in (113.5, 123):
        prop(w, "banner", x, 53.4)
        prop(w, "banner", x, 60.2)

    # cobbled avenues & ring street (grey cobbles over the beige brick)
    road = set()
    road |= rect_cells(87, 24, 92, 44)      # north avenue
    road |= rect_cells(87, 71, 92, 89)      # south avenue
    road |= rect_cells(52, 54, 70, 59)      # west avenue
    road |= rect_cells(109, 54, 127, 59)    # east avenue
    road |= rect_cells(68, 42, 111, 44)     # plaza north edge street
    road |= rect_cells(68, 71, 111, 73)     # plaza south edge street
    road |= rect_cells(68, 42, 70, 73)      # plaza west edge street
    road |= rect_cells(109, 42, 111, 73)    # plaza east edge street
    autotile(w, "road", road, RD, WT.ROAD_NINE, WT.ROAD_INNER, center_variants=[(2, 2)])
    w.city_road = road

    # floor decals across the paving
    decals = [(15, 15), (16, 15), (17, 15), (18, 15), (15, 16), (16, 16), (17, 16), (18, 16), (15, 17), (17, 17), (18, 17), (19, 16), (19, 17), (20, 15), (20, 17)]
    for _ in range(260):
        x, y = rng.randrange(WT.CX0 + 2, WT.CX1 - 1), rng.randrange(WT.CY0 + 5, WT.CY1 - 4)
        if (x, y) not in w.blocked:
            w.put("detail", x, y, MW, rng.choice(decals))

    # ---------------------------------------------------------------- walk graph
    N = g.node
    pts = {
        "n_gate": (89.5, 23), "n_av": (89.5, 33), "n_front": (89.5, 42.6),
        "s_gate": (89.5, 89), "s_av": (89.5, 79), "s_front": (89.5, 72.6),
        "w_gate": (51.5, 56), "w_av": (61, 56.5), "w_front": (69, 57),
        "e_gate": (128.5, 56), "e_av": (118, 56.5), "e_front": (110, 57),
        "i_n": (89.5, 53.2), "i_ne": (94.6, 53.6), "i_e": (95.3, 57.5), "i_se": (94.8, 60.6),
        "i_s": (89.5, 63.6), "i_sw": (84.5, 60.6), "i_w": (84.4, 57.5), "i_nw": (84.6, 53.6),
        "ns_1": (56, 42.6), "ns_2": (72, 42.6), "ns_3": (106, 42.6), "ns_4": (123, 42.6),
        "ss_1": (56, 72.6), "ss_2": (70.5, 72.6), "ss_3": (108.5, 72.6), "ss_4": (123, 72.6),
        "pw_n": (69, 44.5), "pe_n": (110, 44.5), "pw_s": (69, 71), "pe_s": (110, 71),
        "mid_n": (89.5, 45.5), "mid_s": (89.5, 69.5),
    }
    for k, (x, y) in pts.items():
        N(k, x, y)
    g.link("n_gate", "n_av", "n_front", "mid_n", "i_n")
    g.link("s_gate", "s_av", "s_front", "mid_s", "i_s")
    g.link("w_gate", "w_av", "w_front", "i_w")
    g.link("e_gate", "e_av", "e_front", "i_e")
    g.link("i_n", "i_ne", "i_e", "i_se", "i_s", "i_sw", "i_w", "i_nw", "i_n")
    g.link("ns_1", "ns_2", "n_front", "ns_3", "ns_4")
    g.link("ss_1", "ss_2", "s_front", "ss_3", "ss_4")
    g.link("ns_2", "pw_n", "w_front", "pw_s", "ss_2")
    g.link("ns_3", "pe_n", "e_front", "pe_s", "ss_3")
    g.link("pw_n", "mid_n", "pe_n")
    g.link("pw_s", "mid_s", "pe_s")
    g.link("ns_1", "w_av"); g.link("ss_1", "w_av")
    g.link("ns_4", "e_av"); g.link("ss_4", "e_av")

    # ---------------------------------------------------------------- citizens
    spots = ["i_n", "i_e", "i_s", "i_w", "n_front", "s_front", "w_front", "e_front", "mid_n", "mid_s",
             "ns_2", "ns_3", "ss_2", "ss_3", "pw_n", "pe_s", "i_ne", "i_sw", "n_av", "s_av", "w_av", "e_av",
             "pw_s", "pe_n", "i_nw", "i_se", "ns_1", "ss_4"]
    for i, s in enumerate(spots):
        x, y = g.nodes[g.index[s]]
        citizen(w, i % 5 + 1, x, y, "city", LINES_MARKET)
