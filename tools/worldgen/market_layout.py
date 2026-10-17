# Market map definition: tile layers + props + NPCs.
import random

RAW = r"C:/Users/nicol/AppData/Local/Temp/claude/c--Users-nicol-OneDrive-Documentos-JobHunter/7f39b642-3aaa-4323-9d53-2b420a1d2380/scratchpad/raw"
T = 16
W, H = 48, 36
GATE_X0, GATE_X1 = 22, 25          # inclusive gate columns (north & south)
WEST_EDGE, EAST_EDGE = 2, W - 3    # columns holding the thin wall-edge lines
NORTH_FACE = (2, 3)                # rows of north wall face
SOUTH_CAP = H - 3                  # row of south wall crenellation cap

# Atlas sources: 0 = Walls_street.png, 1 = Decorative_cracks.png
WS, DC = 0, 1

# Collision kinds per atlas tile
FULL, BOTTOM, LEFT, RIGHT = "full", "bottom", "left", "right"

rng = random.Random(7)


def fill_tile():
    return (WS, rng.choice([(14, 8), (15, 8), (16, 8), (17, 8), (14, 9), (15, 9), (16, 9), (17, 9),
                            (14, 10), (15, 10), (16, 10), (17, 10)]))


class Map:
    def __init__(self):
        self.ground = {}
        self.walls = {}
        self.detail = {}   # overlay decals, no collision
        self.collide = {}  # (source, atlas) -> kind
        self.props = []
        self.npcs = []

    def wall(self, x, y, tile, kind=FULL):
        self.walls[(x, y)] = tile
        prev = self.collide.get(tile)
        if prev and prev != kind:
            kind = FULL
        self.collide[tile] = kind


def dirt_rect(m, x0, y0, x1, y1):
    """9-slice dirt patch with brick fringe (Walls_street 0..2 x 12..14)."""
    centers = [(1, 13)] * 6 + [(4, 13), (7, 13), (10, 13)]
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            cx = 0 if x == x0 else 2 if x == x1 else 1
            cy = 12 if y == y0 else 14 if y == y1 else 13
            if (cx, cy) == (1, 13):
                m.ground[(x, y)] = (WS, rng.choice(centers))
            else:
                m.ground[(x, y)] = (WS, (cx, cy))


def planter(m, x0, y0, x1, y1):
    """Stone-bordered grass bed (Walls_street 2..4 x 8..10)."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            cx = 2 if x == x0 else 4 if x == x1 else 3
            cy = 8 if y == y0 else 10 if y == y1 else 9
            m.wall(x, y, (WS, (cx, cy)))


def wall_bed(m, x0, x1, y):
    """Grass strip at the foot of the north wall: fill row + bordered bottom row."""
    for x in range(x0, x1 + 1):
        cx = 2 if x == x0 else 4 if x == x1 else 3
        m.wall(x, y, (WS, (cx, 9)))
        m.wall(x, y + 1, (WS, (cx, 10)))


def build():
    m = Map()
    # --- ground: brick paving everywhere ---------------------------------
    for y in range(H):
        for x in range(W):
            m.ground[(x, y)] = (WS, (12 + x % 3, 15 + y % 3))
    # dirt quadrants where the stalls stand
    dirt_rect(m, 4, 7, 19, 15)
    dirt_rect(m, 28, 7, 43, 15)
    dirt_rect(m, 4, 21, 19, 31)
    dirt_rect(m, 28, 21, 43, 31)

    gate = range(GATE_X0, GATE_X1 + 1)

    # --- outer stone fill (wall tops) ------------------------------------
    for y in range(H):
        for x in list(range(0, WEST_EDGE)) + list(range(EAST_EDGE + 1, W)):
            m.wall(x, y, fill_tile())
    for x in range(WEST_EDGE, EAST_EDGE + 1):
        if x in gate:
            continue
        m.wall(x, 0, fill_tile())
        m.wall(x, H - 1, fill_tile())

    # --- north wall ------------------------------------------------------
    up_faces = [(WS, (1, 3))] * 4 + [(DC, (1, r)) for r in (0, 3, 6, 9, 12)]
    lo_faces = [(WS, (1, 4))] * 3 + [(DC, (1, r)) for r in (1, 4, 7, 10, 13)]
    segs = [(WEST_EDGE, GATE_X0 - 1), (GATE_X1 + 1, EAST_EDGE)]
    for a, b in segs:
        for x in range(a, b + 1):
            c = 0 if x == a else 2 if x == b else 1
            if x == WEST_EDGE or x == EAST_EDGE:
                c = 1  # wall continues into the side wall-tops
            m.wall(x, 1, (WS, (c, 2)))
            m.wall(x, 2, (WS, (c, 3)) if c != 1 else rng.choice(up_faces))
            m.wall(x, 3, (WS, (c, 4)) if c != 1 else rng.choice(lo_faces))
    # edges of the wall-top around the north gate opening
    m.wall(GATE_X0, 0, (WS, (13, 9)), LEFT)
    m.wall(GATE_X1, 0, (WS, (11, 9)), RIGHT)

    # --- side wall edges -------------------------------------------------
    for y in range(4, SOUTH_CAP):
        m.wall(WEST_EDGE, y, (WS, (13, 9 + y % 2)), LEFT)
        m.wall(EAST_EDGE, y, (WS, (11, 9 + y % 2)), RIGHT)

    # --- south wall (seen from above: cap + walkway) ---------------------
    for a, b in segs:
        for x in range(a, b + 1):
            if x == WEST_EDGE:
                m.wall(x, SOUTH_CAP, (WS, (3, 4)))
            elif x == EAST_EDGE:
                m.wall(x, SOUTH_CAP, (WS, (4, 4)))
            else:
                c = 0 if x == a else 2 if x == b else 1
                m.wall(x, SOUTH_CAP, (WS, (c, 0)), BOTTOM)
            c = 0 if x == a else 2 if x == b else 1
            if x in (WEST_EDGE, EAST_EDGE):
                m.wall(x, SOUTH_CAP + 1, fill_tile())
            else:
                walk = rng.choice([(1, 1)] * 5 + [(14, 8), (15, 8), (16, 8), (17, 8), (20, 8)]) if c == 1 else (c, 1)
                m.wall(x, SOUTH_CAP + 1, (WS, walk))
    m.wall(GATE_X0, H - 1, (WS, (13, 9)), LEFT)
    m.wall(GATE_X1, H - 1, (WS, (11, 9)), RIGHT)

    # --- grass beds along the north wall --------------------------------
    wall_bed(m, 3, 8, 4)
    wall_bed(m, 15, 19, 4)
    wall_bed(m, 29, 33, 4)
    wall_bed(m, 39, 44, 4)

    # --- planters around the central well --------------------------------
    planter(m, 18, 15, 20, 17)
    planter(m, 27, 15, 29, 17)
    planter(m, 18, 21, 20, 23)
    planter(m, 27, 21, 29, 23)

    # --- floor decals ----------------------------------------------------
    decals = [(15, 15), (16, 15), (17, 15), (18, 15), (15, 16), (16, 16), (17, 16), (18, 16),
              (15, 17), (17, 17), (18, 17), (19, 16), (19, 17), (20, 15), (20, 17)]
    leaves = [(14, 11), (15, 11), (16, 11), (17, 11), (18, 11), (20, 11), (15, 12), (16, 12),
              (19, 12), (20, 12), (15, 13), (16, 13), (18, 13), (20, 13), (13, 14), (15, 14), (16, 14), (17, 14)]
    for _ in range(70):
        x, y = rng.randrange(3, W - 3), rng.randrange(4, H - 3)
        if (x, y) not in m.walls:
            m.detail[(x, y)] = (WS, rng.choice(decals))
    for _ in range(40):
        x, y = rng.randrange(3, W - 3), rng.choice([5, 6, SOUTH_CAP - 1, rng.randrange(4, H - 3)])
        if (x, y) not in m.walls:
            m.detail[(x, y)] = (WS, rng.choice(leaves))

    place_props(m)
    return m



# ---------------------------------------------------------------------------
# Props: sheet key, region (x0,y0,x1,y1) in px, foot rect(s) relative to region,
# "floor" for flat decals drawn under everything, or None for no collision.
OBJ = "objects"; SGL = "single"; EXT = "exterior"
P = {
    "weapon_stall": (OBJ, (14, 0, 140, 135), [(14, 92, 124, 131)]),
    "blue_tent":    (OBJ, (159, 32, 268, 144), [(4, 96, 12, 104), (60, 104, 68, 112), (88, 88, 96, 96)]),
    "fruit_stall":  (OBJ, (11, 152, 122, 249), [(2, 40, 109, 96)]),
    "fruit_small":  (OBJ, (137, 160, 223, 222), [(2, 24, 84, 62)]),
    "fruit_crates": (OBJ, (235, 158, 346, 217), [(8, 22, 108, 58)]),
    "bread_stall":  (OBJ, (105, 260, 183, 325), [(2, 30, 76, 64)]),
    "cloth_stall":  (OBJ, (290, 276, 355, 318), [(0, 18, 65, 41)]),
    "pastry_stall": (OBJ, (201, 276, 279, 325), [(2, 20, 76, 49)]),
    "magic_tent":   (OBJ, (8, 393, 106, 512), [(4, 70, 98, 116)]),
    "magic_table":  (OBJ, (175, 516, 233, 551), [(0, 10, 58, 34)]),
    "sword_table":  (OBJ, (238, 6, 282, 32), [(0, 6, 44, 25)]),
    "red_table":    (OBJ, (158, 6, 202, 32), [(0, 6, 44, 25)]),
    "potion_cart":  (OBJ, (0, 519, 73, 575), [(14, 30, 73, 54)]),
    "cart":         (OBJ, (80, 530, 151, 575), [(2, 18, 71, 44)]),
    "table_a":      (OBJ, (171, 345, 198, 372), [(2, 12, 25, 26)]),
    "table_b":      (OBJ, (267, 345, 294, 372), [(2, 12, 25, 26)]),
    "table_c":      (OBJ, (123, 358, 150, 385), [(2, 12, 25, 26)]),
    "table_d":      (OBJ, (219, 358, 246, 385), [(2, 12, 25, 26)]),
    "stool":        (OBJ, (161, 356, 170, 369), None),
    "orb":          (OBJ, (333, 322, 360, 352), [(3, 18, 24, 29)]),
    "crates_a":     (OBJ, (289, 1, 347, 40), [(0, 12, 58, 39)]),
    "crates_b":     (OBJ, (424, 7, 476, 55), [(0, 18, 52, 47)]),
    "crates_c":     (OBJ, (385, 145, 451, 185), [(0, 12, 66, 39)]),
    "crates_d":     (OBJ, (378, 257, 416, 310), [(0, 22, 38, 52)]),
    "barrels_a":    (OBJ, (421, 298, 462, 332), [(0, 14, 41, 33)]),
    "crates_e":     (OBJ, (368, 344, 424, 374), [(0, 10, 56, 29)]),
    "crates_f":     (OBJ, (336, 370, 381, 417), [(0, 18, 45, 46)]),
    "barrel_big":   (OBJ, (321, 517, 357, 565), [(2, 22, 34, 47)]),
    "banner":       (OBJ, (446, 92, 469, 138), [(7, 40, 16, 46)]),
    "armor_a":      (OBJ, (370, 13, 387, 41), [(2, 20, 15, 28)]),
    "armor_b":      (OBJ, (388, 13, 407, 41), [(2, 20, 17, 28)]),
    "armor_c":      (OBJ, (375, 109, 392, 137), [(2, 20, 15, 28)]),
    "armor_flag":   (OBJ, (367, 54, 392, 85), [(4, 22, 21, 31)]),
    "weapon_rack":  (OBJ, (285, 97, 353, 135), [(0, 24, 68, 38)]),
    "bench":        (OBJ, (288, 60, 351, 85), [(0, 12, 63, 25)]),
    "rug":          (OBJ, (415, 394, 465, 455), "floor"),
    "sack":         (SGL, (97, 33, 112, 47), [(1, 6, 14, 14)]),
    "sack2":        (SGL, (113, 33, 128, 47), [(1, 6, 14, 14)]),
    "barrel":       (SGL, (99, 116, 112, 139), [(0, 12, 13, 24)]),
    "crate":        (SGL, (3, 48, 28, 80), [(0, 14, 25, 32)]),
    "well":         (EXT, (1, 498, 36, 539), [(1, 18, 35, 40)]),
    "tree_apple":   (EXT, (1, 324, 62, 397), [(20, 60, 42, 72)]),
    "tree":         (EXT, (65, 320, 127, 398), [(20, 64, 42, 76)]),
    "bush":         (EXT, (198, 358, 234, 395), [(2, 18, 34, 36)]),
    "bush_berry":   (EXT, (209, 134, 239, 174), [(2, 20, 28, 39)]),
    "bush_round":   (EXT, (194, 322, 221, 349), [(2, 14, 25, 26)]),
}


def prop(m, key, px, py, flip=False):
    """Place prop so that the bottom of its footprint (or sprite) sits at y=py, centred on px."""
    sheet, (x0, y0, x1, y1), foot = P[key]
    w, h = x1 - x0, y1 - y0
    if foot == "floor":
        m.props.append(dict(key=key, sheet=sheet, region=(x0, y0, w, h), pos=(px, py), origin=(w / 2, h / 2),
                            feet=[], floor=True, flip=flip))
        return
    feet = foot or []
    if flip:
        feet = [(w - b, c, w - a, d) for a, c, b, d in feet]
    ox = w / 2
    oy = max(r[3] for r in feet) if feet else h
    m.props.append(dict(key=key, sheet=sheet, region=(x0, y0, w, h), pos=(px, py), origin=(ox, oy),
                        feet=[(a - ox, c - oy, b - ox, d - oy) for a, c, b, d in feet], floor=False, flip=flip))


def npc(m, kind, px, py, **kw):
    m.npcs.append(dict(kind=kind, pos=(px, py), **kw))


def place_props(m):
    t = T
    # ---- NW: greengrocers ------------------------------------------------
    prop(m, "fruit_stall", 8 * t + 8, 13 * t)
    prop(m, "fruit_small", 16 * t, 11 * t + 8)
    npc(m, "trader_fruits", 13 * t, 13 * t + 8, name="Tomás el frutero",
        line="¡Manzanas del valle, melones del sur! Come bien, cazador: allá afuera no hay mesas servidas.")
    prop(m, "crates_c", 6 * t + 8, 15 * t + 10)
    prop(m, "sack", 12 * t + 8, 8 * t + 4)
    prop(m, "barrels_a", 18 * t + 4, 14 * t + 10)
    prop(m, "sack2", 4 * t + 10, 9 * t + 10)

    # ---- NE: armoury -----------------------------------------------------
    prop(m, "weapon_stall", 37 * t, 14 * t)
    npc(m, "trader_weapon", 31 * t + 8, 13 * t + 6, name="Kara la armera",
        line="Lanzas, espadas, escudos... Todo forjado aquí mismo. Los monstruos no perdonan al que va desarmado.")
    prop(m, "sword_table", 31 * t + 8, 9 * t + 8)
    prop(m, "armor_flag", 29 * t + 8, 11 * t)
    prop(m, "armor_c", 43 * t, 9 * t)
    prop(m, "armor_b", 43 * t, 11 * t + 8)
    prop(m, "weapon_rack", 41 * t, 15 * t + 10)
    prop(m, "crates_b", 44 * t - 4, 14 * t)

    # ---- SW: fortune teller & curiosities ------------------------------
    prop(m, "rug", 9 * t, 28 * t + 4)
    prop(m, "magic_tent", 9 * t, 29 * t + 6)
    npc(m, "trader_magic", 13 * t + 8, 28 * t + 4, name="Morga la vidente",
        line="Las cartas hablan de bestias en el bosque del norte... y de un cazador que aún no conoce su destino.")
    prop(m, "magic_table", 16 * t, 24 * t)
    prop(m, "orb", 13 * t + 4, 24 * t)
    prop(m, "crates_d", 5 * t, 23 * t + 8)
    prop(m, "barrel_big", 18 * t, 30 * t + 8)

    # ---- SE: bakery, cloth & tavern ------------------------------------
    prop(m, "bread_stall", 31 * t + 8, 24 * t)
    npc(m, "trader_bread", 34 * t + 8, 23 * t + 8, name="Rosa la panadera",
        line="Pan de centeno recién salido del horno. ¡Ningún cazador se va de aquí con el estómago vacío!")
    prop(m, "cloth_stall", 38 * t + 8, 23 * t + 8)
    prop(m, "potion_cart", 42 * t, 26 * t + 8)
    npc(m, "trader_drinks", 40 * t, 26 * t + 4, name="Ezra el alquimista",
        line="Pociones de vida, tónicos de vigor... Cuando un monstruo te muerda, me lo agradecerás.")
    prop(m, "blue_tent", 36 * t, 32 * t)
    for tx, ty, k in [(34.5, 30.9, "table_a"), (37.6, 30.9, "table_b"), (31.5, 28.6, "table_c"), (41, 31, "table_d")]:
        prop(m, "stool", tx * t - 16, ty * t - 4)
        prop(m, "stool", tx * t + 17, ty * t - 4)
        prop(m, k, tx * t + 1, ty * t)
    npc(m, "eater", 37.6 * t + 15, 30.9 * t - 3)
    prop(m, "crates_e", 30 * t + 4, 31 * t + 10)

    # ---- West & east side lanes -------------------------------------------
    prop(m, "pastry_stall", 7 * t + 8, 19 * t + 6)
    prop(m, "barrel", 11 * t + 8, 19 * t)
    prop(m, "crate", 13 * t, 19 * t + 4)
    prop(m, "bench", 40 * t, 19 * t + 4)
    prop(m, "cart", 34 * t, 19 * t + 6)

    # ---- Centre: well, musicians, planted bushes -----------------------
    prop(m, "well", 24 * t, 19 * t + 6)
    npc(m, "lute", 22 * t, 21 * t + 4)
    npc(m, "flutist", 26 * t, 21 * t + 4)
    for (x, y) in [(19, 17), (28, 17), (19, 23), (28, 23)]:
        prop(m, "bush_round" if (x + y) % 2 else "bush", x * t + 8, y * t + 6)

    # ---- North wall --------------------------------------------------------
    for x in (11, 13, 34, 36):
        prop(m, "banner", x * t + 8, 6 * t)
    prop(m, "tree_apple", 5 * t + 8, 6 * t)
    prop(m, "tree", 42 * t + 8, 6 * t)
    prop(m, "bush_berry", 17 * t + 8, 6 * t)
    prop(m, "bush", 30 * t, 6 * t)
    prop(m, "crates_a", 20 * t + 6, 6 * t - 2)
    prop(m, "crate", 28 * t, 6 * t - 2)
    prop(m, "barrel", 26 * t + 12, 6 * t - 4)
    prop(m, "sack", 27 * t - 2, 6 * t + 6)

    # ---- South gate --------------------------------------------------------
    prop(m, "cart", 18 * t, 33 * t - 2)
    prop(m, "barrel", 21 * t, 32 * t + 8)
    prop(m, "sack2", 27 * t, 32 * t + 8)
    prop(m, "crates_f", 29 * t, 33 * t - 2)

    # ---- Wandering citizens (wander rect in tiles) ---------------------
    lanes = [((21, 6, 26, 31), (23, 9)), ((3, 16, 17, 20), (10, 17)), ((30, 16, 44, 20), (37, 17)),
             ((20, 24, 27, 31), (25, 27)), ((5, 9, 19, 12), (11, 10)), ((28, 21, 44, 23), (36, 22))]
    for i, (rect, (x, y)) in enumerate(lanes):
        npc(m, "citizen%d" % (i % 5 + 1), x * t, y * t, wander=tuple(v * t for v in rect))
