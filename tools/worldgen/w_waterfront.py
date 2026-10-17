"""Port quarter between the city's south wall and the quay: warehouses, taverns, fish market, people."""
from w_layout import *
from w_coast import QY, HX0, HX1, coast_y

LINES_PORT = ['Llegó el barco del sur.', 'Hay pescado fresco en el mercado.', 'Cuidado con las cuerdas.', 'El mar está picado hoy.', 'Ese tiburón es enorme.', 'Cargamos sal y especias.', 'Dicen que hay piratas al este.', 'Pronto zarpamos.', 'Me gusta el olor del mar.', 'El puerto nunca duerme.', '¿Conoces la taberna La Gaviota?', 'Mañana zarpa el Albatros.']


def build_waterfront(w, g):
    rng = w.rng
    RY = QY - 5                      # quay road top row
    BASE = RY - 1                    # building footprints rest just above the road
    for y in range(RY - 1, QY - 1):
        for x in range(HX0, HX1 + 1):
            w.put("ground", x, y, MW, (12 + x % 3, 15 + y % 3))
    quarter = rect_cells(HX0 + 1, 95, HX1 - 1, RY)
    autotile(w, "ground_overlay", quarter, FG, nine_at(19, 1), {"se": (22, 1), "sw": (23, 1), "ne": (22, 2), "nw": (23, 2)},
             center_variants=[(20, 2)])
    w.blocked |= quarter
    west = [("fish_house", 35.5), ("barn", 42.5), ("house_red", 50.5), ("fish_house2", 58.5), ("longshed", 64.8),
            ("fish_house", 71.5), ("shed", 78.2)]
    east = [("shed", 101.3), ("fish_house2", 107.5), ("barn", 114.5), ("farmhouse", 122), ("fish_house", 130.2),
            ("longshed", 136.6), ("house_red", 144)]
    for k, x in west + east:
        prop(w, k, x, BASE + rng.uniform(-0.15, 0.1), flip=k in ("fish_house2", "farmhouse") and rng.random() < 0.5)
    prop(w, "fish_sign", 71.5, BASE - 3.6)
    prop(w, "fish_sign2", 130.2, BASE - 3.6)
    # fish market around the south road
    market = [("fish_rack", 83.2, 97.5), ("fish_rack2", 96, 97.5), ("shark", 84, 101.2), ("net_frame", 96.5, 101.4),
              ("fish_pile", 82.2, 94.5), ("crate_fish", 85.5, 94.6), ("barrel_fish", 94, 94.5), ("crate_fish2", 97, 94.5),
              ("sacks_fish", 92.5, 101.8), ("barrel_f1", 81.3, 99.3), ("crate_fish3", 98.3, 99.4)]
    for k, x, y in market:
        prop(w, k, x, y)
    # cargo along the water's edge
    for x in range(HX0 + 3, HX1 - 2, 3):
        if any(abs(x - (px + 0.5)) < 2.5 for px in w.piers) or 86 <= x <= 93:
            continue
        r = rng.random()
        if r < 0.45:
            prop(w, rng.choice(["barrel", "crate", "crate2", "barrel_f1", "barrel_open", "crate_f", "sack_f", "sack"]),
                 x + rng.uniform(0, 1), RY + 3.75)
        elif r < 0.6:
            prop(w, rng.choice(["cargo_pile", "cargo_pile2", "crates_a", "barrels_a"]), x + 0.5, RY + 3.75)
    for x in (40, 75, 105, 140):
        prop(w, "t_bench", x, RY - 0.1)
    # gardens and trees behind the waterfront houses (between them and the city wall)
    for i in range(26):
        x = rng.uniform(HX0 + 2, HX1 - 2)
        if 84 <= x <= 95:
            continue
        prop(w, rng.choice(["tree_round", "tree_light2", "tree_bushy2", "tree_apple", "orchard_green", "bush_a", "bush_b", "shrub3"]),
             x, rng.uniform(90.6, 93.2), flip=rng.random() < 0.5)
    # people of the port
    tmx_actor(w, "captain", "Old_man_orders", (0, 0, 32, 32), (w.piers[2] + 4.5) * T, (RY + 3.4) * T,
              talk=("Capitán Brask", ["Carguen esas cajas. El Albatros zarpa con la marea.",
                                      "Este puerto conecta Valdoria con el resto del reino."]),
              bubble=["Carguen esas cajas.", "Con cuidado.", "Ya casi zarpamos."])
    tmx_actor(w, "old_fisher", "Old_man_idle", (0, 0, 32, 32), (w.piers[4] + 1) * T, (QY + 8.2) * T,
              talk=("Pescador Ulrik", ["Cuarenta años pescando aquí. El mar da y el mar quita.",
                                       "Algo rompe mis redes por las noches. Lo anoté en el tablón del Gremio."]),
              bubble=["Hoy hay buena pesca.", "Pican poco."])
    tmx_actor(w, "boy_amazed", "Boy_amazed", (0, 0, 32, 48), 86.4 * T, 103 * T,
              talk=("Jory", ["¿Viste ese tiburón? Lo pescó mi papá."]), bubble=["Es enorme.", "Un tiburón de verdad."])
    tmx_actor(w, "boy_wave", "Boy_weaves", (0, 0, 32, 48), (w.piers[1] + 1) * T, (QY + 7.6) * T,
              talk=("Pip", ["Saludo a los barcos que salen. Algún día seré marinero."]), bubble=["¡Adiós!", "Buen viaje."])
    tmx_actor(w, "boy_look", "Boy_looking", (0, 0, 32, 48), (w.piers[3] + 1) * T, (QY + 7.8) * T,
              talk=("Tim", ["Shh. Estoy mirando los peces."]))
    tmx_actor(w, "kobold", "Cobold_on_floor", (0, 0, 32, 32), 94.2 * T, 99 * T,
              talk=("Kobold mercader", ["Vendo escamas brillantes. Precio justo."]),
              bubble=["Escamas brillantes.", "Precio justo."])
    w.shop_points += [(85.5 * T, 99.6 * T), (92.6 * T, 99.2 * T), (96 * T, 99.6 * T)]
    # walk graph: quay road, piers, coastal paths and the market
    N = g.node
    xs = list(range(HX0 + 3, HX1 - 1, 9))
    for x in xs:
        N("q%d" % x, x, RY + 1.6)
    g.link(*["q%d" % x for x in xs])
    N("pm", 89.5, 98.5)
    g.link("s_road", "pm")
    near = min(xs, key=lambda x: abs(x - 89.5))
    g.link("pm", "q%d" % near)
    for i, px in enumerate(w.piers):
        N("pier%d" % i, px + 1, QY + 6)
        qx = min(xs, key=lambda x: abs(x - px))
        g.link("q%d" % qx, "pier%d" % i)
    N("cw0", HX0 - 6, coast_y(HX0 - 6) - 4.5); N("cw1", 10, coast_y(10) - 4.5)
    N("ce0", HX1 + 6, coast_y(HX1 + 6) - 4.5); N("ce1", 172, coast_y(172) - 4.5)
    g.link("q%d" % xs[0], "cw0", "cw1")
    g.link("q%d" % xs[-1], "ce0", "ce1")
    spots = ["pm", "q%d" % xs[1], "q%d" % xs[3], "q%d" % xs[6], "q%d" % xs[9], "pier1", "pier4", "cw0", "ce0", "q%d" % xs[11]]
    for i, k in enumerate(spots):
        x, y = g.nodes[g.index[k]]
        citizen(w, i % 7 + 1, x, y, "port", LINES_PORT)
