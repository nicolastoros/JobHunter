"""Terrain: grass, sea & coast, roads, city paving and city walls."""
from w_common import *

W, H = 180, 140
# City wall rectangle (outer bounds, inclusive)
CX0, CX1, CY0, CY1 = 52, 127, 24, 88
GATE_N = (87, 92)      # x range of north/south gate openings
GATE_W = (54, 58)      # y range of west/east gate openings
SHORE_Y = 999          # sea handled by w_coast
PORT_Y0 = 96           # port district top

GRASS = (17, 8)
DIRT_NINE = nine_at(19, 1)
DIRT_INNER = {"se": (22, 1), "sw": (23, 1), "ne": (22, 2), "nw": (23, 2)}
ROAD_NINE = nine_at(1, 1)
ROAD_INNER = {"se": (4, 1), "sw": (6, 1), "ne": (4, 3), "nw": (6, 3)}
STONE_FILL = [(14, 8), (15, 8), (16, 8), (17, 8), (14, 9), (15, 9), (16, 9), (17, 9), (14, 10), (15, 10), (16, 10), (17, 10)]


def in_city(x, y):
    return CX0 <= x <= CX1 and CY0 <= y <= CY1


def build_terrain(w):
    rng = w.rng
    ground = w.layer("ground")
    w.layer("ground_overlay")
    w.layer("road")
    w.layer("detail")
    w.layer("water")
    w.layer("water_fx")
    w.layer("coast")
    w.layer("dock")
    w.layer("walls")

    # --- grass everywhere on land, sea below the shore --------------------------
    for y in range(H):
        for x in range(W):
            if y >= SHORE_Y:
                w.put("water", x, y, WD, (36, 0), "full")
            else:
                w.put("ground", x, y, FG, GRASS)

    # --- coastline: grassy cliff edge along the shore row ---------------------
    for x in range(W):
        w.put("coast", x, SHORE_Y, WC, rng.choice([(1, 7)] * 4 + [(1, 7)]), "full")
        w.erase("water", x, SHORE_Y)
        w.put("water", x, SHORE_Y, WD, (36, 0))

    city_paving(w)
    city_walls(w)
    return w


# ---------------------------------------------------------------------------
def city_paving(w):
    rng = w.rng
    cells = rect_cells(CX0 + 2, CY0 + 2, CX1 - 2, CY1 - 2)
    cells |= rect_cells(GATE_N[0], CY0, GATE_N[1], CY1)          # N/S gate passages
    cells |= rect_cells(CX0, GATE_W[0], CX1, GATE_W[1])          # W/E gate passages
    for (x, y) in cells:
        w.put("ground", x, y, MW, (12 + x % 3, 15 + y % 3))


def stone(w, x, y):
    w.put("walls", x, y, MW, w.rng.choice(STONE_FILL), "full")


UP_FACES = [(MW, (1, 3))] * 4 + [(MD, (1, r)) for r in (0, 3, 6, 9, 12)]
LO_FACES = [(MW, (1, 4))] * 3 + [(MD, (1, r)) for r in (1, 4, 7, 10, 13)]


def wpiece(w, x, y, c, r, kind="full"):
    """Wall block piece column c (0 left end, 1 mid, 2 right end), row r (0 cap .. 4 face)."""
    if c == 1 and r == 3:
        src, at = w.rng.choice(UP_FACES)
    elif c == 1 and r == 4:
        src, at = w.rng.choice(LO_FACES)
    else:
        src, at = MW, (c, r)
    w.put("walls", x, y, src, at, kind)


def tower(w, x, y_bottom, height=7):
    """2-wide tower (Walls_street 11..12 x 0..4) whose lowest face row is y_bottom."""
    rows = [0] + [1] * (height - 4) + [2, 3, 4]
    y0 = y_bottom - height + 1
    for i, r in enumerate(rows):
        for dx in (0, 1):
            w.put("towers", x + dx, y0 + i, MW, (11 + dx, r), "bottom" if r == 0 else "full")


def hwall(w, xa, xb, y0, ends_face, cap_kind="bottom"):
    """Horizontal wall rows y0..y0+4 = cap, walk, merlon, face, face."""
    for x in range(xa, xb + 1):
        c = 0 if x == xa else 2 if x == xb else 1
        wpiece(w, x, y0, c if ends_face else 1, 0, cap_kind)
        wpiece(w, x, y0 + 1, c if ends_face else 1, 1)
        wpiece(w, x, y0 + 2, c, 2)
        wpiece(w, x, y0 + 3, c, 3)
        wpiece(w, x, y0 + 4, c, 4)


def vband(w, x0, ya, yb, inner_left):
    """Vertical 2-wide wall band seen from above, with edge lines on the neighbouring cells."""
    for y in range(ya, yb + 1):
        stone(w, x0, y)
        stone(w, x0 + 1, y)
        w.put("walls", x0 - 1, y, MW, (11, 9 + y % 2), "right")   # line hugging the band's left side
        w.put("walls", x0 + 2, y, MW, (13, 9 + y % 2), "left")    # line hugging the band's right side


def city_walls(w):
    gx0, gx1 = GATE_N
    gy0, gy1 = GATE_W
    w.layer("towers")
    # Side bands
    for x0 in (CX0, CX1 - 1):
        vband(w, x0, CY0 + 1, gy0 - 1, x0 == CX0)
        vband(w, x0, gy1 + 1, CY1 - 3, x0 == CX0)
    # North wall (face looks into the city). Band columns continue as walkway.
    for a, b in ((CX0, gx0 - 1), (gx1 + 1, CX1)):
        for x in range(a, b + 1):
            c = 0 if x == a else 2 if x == b else 1
            wpiece(w, x, CY0, c, 0, "bottom")
            wpiece(w, x, CY0 + 1, c, 1)
            if CX0 + 2 <= x <= CX1 - 2:
                fc = 0 if x == max(a, CX0 + 2) else 2 if x == min(b, CX1 - 2) else 1
                wpiece(w, x, CY0 + 2, fc, 2)
                wpiece(w, x, CY0 + 3, fc, 3)
                wpiece(w, x, CY0 + 4, fc, 4)
            else:
                for y in (CY0 + 2, CY0 + 3, CY0 + 4):
                    stone(w, x, y)
    # South wall: cap seen from inside, face looks outside.
    for a, b in ((CX0, gx0 - 1), (gx1 + 1, CX1)):
        for x in range(a, b + 1):
            c = 0 if x == a else 2 if x == b else 1
            if CX0 + 2 <= x <= CX1 - 2:
                if x == CX0 + 2:
                    w.put("walls", x, CY1 - 4, MW, (3, 4), "full")
                elif x == CX1 - 2:
                    w.put("walls", x, CY1 - 4, MW, (4, 4), "full")
                else:
                    cc = 0 if x == a else 2 if x == b else 1
                    wpiece(w, x, CY1 - 4, cc, 0, "bottom")
                wpiece(w, x, CY1 - 3, c if x in (a, b) and a > CX0 and b < CX1 else 1, 1)
            else:
                stone(w, x, CY1 - 4)
                stone(w, x, CY1 - 3)
            wpiece(w, x, CY1 - 2, c, 2)
            wpiece(w, x, CY1 - 1, c, 3)
            wpiece(w, x, CY1, c, 4)
    # lines only where the neighbour cell is not wall
    for (x, y) in list(w.layers["walls"].keys()):
        pass
    # Towers: corners, gates and rhythm along the walls
    for x in (CX0, CX1 - 1):
        tower(w, x, CY0 + 4, 8)
        tower(w, x, CY1, 8)
        tower(w, x, gy0 - 1, 7)
        tower(w, x, gy1 + 5, 7)
    for x in (gx0 - 2, gx1 + 1):
        tower(w, x, CY0 + 4, 9)
        tower(w, x, CY1, 9)
    for x in (66, 76, 103, 113):
        tower(w, x, CY0 + 4, 7)
        tower(w, x, CY1, 7)
    for y in (38, 74):
        tower(w, CX0, y, 6)
        tower(w, CX1 - 1, y, 6)
