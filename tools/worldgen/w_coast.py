"""Organic coastline, stone harbour (quay wall + coastal road), piers, breakwater with lighthouse."""
import math
from w_layout import *
import w_terrain as WT

QY = 108                   # first row of the quay wall face; open water starts at QY + 2
HX0, HX1 = 30, 152          # harbour quay extent (inclusive)
GRASS_ISLAND = nine_at(0, 5)
GRASS_INNER = {"se": (3, 5), "sw": (4, 5), "ne": (3, 6), "nw": (4, 6)}

# The port's grassy shore tiles, recoloured to the farm grass used on land so every shore blends in.
FWCG = 13
_SHORE_RAW = "fishing/Tiled_foles/Water_coasts_field.png"
SOURCES[FWCG] = (_SHORE_RAW, "assets/sprites/field/tiles/Water_coasts_field.png")
ANIM_ALIAS[FWCG] = WC
_REMAP = {(122, 173, 85): (160, 179, 90), (150, 197, 95): (193, 201, 96), (186, 211, 98): (219, 219, 93),
          (91, 146, 82): (121, 154, 81), (75, 122, 76): (99, 130, 74), (38, 69, 50): (50, 69, 38)}


def _make_shore_sheet():
    src = Image.open(os.path.join(RAW, SOURCES[WC][0])).convert("RGBA")
    px = src.load()
    for y in range(src.height):
        for x in range(src.width):
            r, g, b, a = px[x, y]
            if a and (r, g, b) in _REMAP:
                px[x, y] = _REMAP[(r, g, b)] + (a,)
    src.save(os.path.join(RAW, _SHORE_RAW))


_make_shore_sheet()


def coast_y(x):
    """Row where the sea begins for column x."""
    if HX0 <= x <= HX1:
        return QY + 2
    if x < HX0:
        t = (HX0 - x) / HX0
        return int(round(QY + 2 + 7 * t + 2.2 * math.sin(x / 4.3) + 1.3 * math.sin(x / 1.9 + 1)))
    t = (x - HX1) / (WT.W - HX1)
    return int(round(QY + 2 - 6 * math.sin(t * math.pi * 0.9) + 1.8 * math.sin(x / 3.7) + 1.1 * math.sin(x / 1.7)))


def road_mask(points, width):
    """Cells covered by a thick polyline through tile-space points."""
    cells = set()
    r = width / 2.0
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        steps = int(max(abs(x1 - x0), abs(y1 - y0)) * 3) + 1
        for i in range(steps + 1):
            t = i / steps
            cx, cy = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            for y in range(int(cy - r - 1), int(cy + r + 2)):
                for x in range(int(cx - r - 1), int(cx + r + 2)):
                    if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r:
                        cells.add((x, y))
    return cells


def build_coast(w):
    rng = w.rng
    land = set()
    for x in range(WT.W):
        cy = coast_y(x)
        for y in range(WT.H):
            if y < cy:
                land.add((x, y))
    # water under everything at sea level, grass on land interior
    for y in range(WT.H):
        for x in range(WT.W):
            if (x, y) not in land:
                w.put("water", x, y, WD, (36, 0))
                w.erase("ground", x, y)
                w.solids.add((x, y))
    # natural coast (outside the harbour) via grass-island autotile on land border cells
    natural = {(x, y) for (x, y) in land if not (HX0 <= x <= HX1 and y >= QY - 1)}
    def inb(x, y):
        return 0 <= x < WT.W and 0 <= y < WT.H

    border = set()
    for (x, y) in natural:
        if any(inb(x + dx, y + dy) and (x + dx, y + dy) not in land for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
            border.add((x, y))
    # outside the map counts as land so edge cells keep a straight shore
    shore = {(x, y) for (x, y) in land} | {(x, y) for x in range(-1, WT.W + 1) for y in (-1,)} \
        | {(x, y) for x in (-1, WT.W) for y in range(-1, WT.H + 1) if y < coast_y(0 if x < 0 else WT.W - 1)}
    for (x, y) in border:
        n = (x, y - 1) in shore; s = (x, y + 1) in shore; we = (x - 1, y) in shore; e = (x + 1, y) in shore
        if not s and not we: k = "bl"
        elif not s and not e: k = "br"
        elif not n and not we: k = "tl"
        elif not n and not e: k = "tr"
        elif not s: k = "b"
        elif not n: k = "t"
        elif not we: k = "l"
        elif not e: k = "r"
        elif (x + 1, y + 1) not in shore: k = "se"
        elif (x - 1, y + 1) not in shore: k = "sw"
        elif (x + 1, y - 1) not in shore: k = "ne"
        else: k = "nw"
        at = GRASS_INNER[k] if k in GRASS_INNER else GRASS_ISLAND[k]
        w.erase("ground", x, y)
        w.put("water", x, y, WD, (36, 0))
        w.put("coast", x, y, FWCG, at)
        w.solids.add((x, y))
    w.land = land
    # rocks along the natural shore & in shallow water
    for _ in range(40):
        x = rng.choice(list(range(2, HX0 - 1)) + list(range(HX1 + 3, WT.W - 2)))
        y = coast_y(x) + rng.choice([-2, 1, 2])
        prop(w, rng.choice(["rock_s1", "rock_s2", "stone_blue", "stone_blue2", "rock_tall"]), x + 0.5, y + 0.5)


def build_harbour(w, g):
    rng = w.rng
    # ---- wooden boardwalk over the water (like the fishing dock): planks, front rim, mooring posts, piles
    for x in range(HX0, HX1 + 1):
        for y in (QY, QY + 1, QY + 2):
            w.erase("ground", x, y)
            w.put("water", x, y, WD, (36, 0))
        for r, y in enumerate((QY - 1, QY, QY + 1, QY + 2)):
            w.put("dock", x, y, EX, (x % 7, r))
            w.solids.discard((x, y))
        if x % 3 == 0:
            w.put("dock_fx", x, QY + 2, EX, (4, 9))      # mooring post on the rim
            w.put("dock_fx", x, QY + 3, EX, (4, 10))     # its foot in the water
        elif x % 3 == 2 and x % 2 == 0:
            w.put("dock_fx", x, QY + 3, PL, (0, 0)); w.put("dock_fx", x, QY + 4, PL, (0, 1))
    for (x, side) in ((HX0, (3, 9)), (HX1, (3, 9))):
        w.put("dock_fx", x, QY - 1, EX, side); w.put("dock_fx", x, QY, EX, (side[0], 10))
    # ---- coastal road on the quay and along the coast both ways
    quay_road = rect_cells(HX0 + 1, QY - 5, HX1 - 1, QY)
    autotile(w, "road", quay_road, RD, WT.ROAD_NINE, WT.ROAD_INNER, center_variants=[(2, 2)])
    w.blocked |= quay_road
    WEST_END, EAST_END = 9, WT.W - 10
    west = [(HX0 + 2, QY - 3.5)] + [(x, coast_y(x) - 4.5) for x in range(HX0 - 2, WEST_END - 1, -4)]
    east = [(HX1 - 2, QY - 3.5)] + [(x, coast_y(x) - 4.5) for x in range(HX1 + 2, EAST_END + 1, 4)]
    path = (road_mask(west, 3.2) | road_mask(east, 3.2)) - quay_road
    path = {c for c in path if c in w.land and c not in w.solids}
    # lookouts where the walks end: a bench facing the sea, fishing gear, and a thicket closing the way
    for (ex, flip) in ((west[-1][0], False), (east[-1][0], True)):
        ey = coast_y(int(ex)) - 4.5
        prop(w, "bench", ex + (1.5 if flip else -1.5), ey + 0.6, flip=flip)
        prop(w, "fish_rack" if flip else "fish_rack2", ex + (-2.5 if flip else 2.5), ey - 1.8)
        prop(w, "barrel_fish", ex + (3.5 if flip else -3.5), ey + 1.2)
        side = range(int(ex) + 4, WT.W) if flip else range(0, int(ex) - 3)
        for x in side:
            for y in range(int(ey) - 7, coast_y(x) - 1):
                if rng.random() < 0.16 and (x, y) in w.land and (x, y + 2) in w.land and (x, y) not in w.blocked:
                    prop(w, rng.choice(["tree_big", "pine_big", "tree_oak", "tree_bushy", "pine_mid", "tree_round"]), x + 0.5, y + 0.9)
                    w.blocked |= rect_cells(x - 1, y - 1, x + 1, y + 1)
    autotile(w, "ground_overlay", path, FG, nine_at(19, 1), {"se": (22, 1), "sw": (23, 1), "ne": (22, 2), "nw": (23, 2)}, center_variants=[(20, 2)])
    w.blocked |= path
    # south road from the city gate down to the quay, gently curving
    sroad = road_mask([(89.5, 88), (89.5, 92), (88.5, 96), (89.5, QY - 4)], 6)
    autotile(w, "road", sroad | rect_cells(87, 88, 92, 92), RD, WT.ROAD_NINE, WT.ROAD_INNER, center_variants=[(2, 2)])
    w.blocked |= sroad
    # ---- piers (wooden jetties) reaching out from the boardwalk
    piers = [44, 62, 80, 100, 118, 136]
    for i, px in enumerate(piers):
        length = 11 if i % 2 == 0 else 8
        y0 = QY + 3
        for y in range(y0, y0 + length):
            r = 3 if y == y0 + length - 1 else (1 if y % 2 else 2)
            w.put("dock", px, y, EX, (7, r)); w.put("dock", px + 1, y, EX, (8, r))
            w.solids.discard((px, y)); w.solids.discard((px + 1, y))
        w.erase("dock_fx", px, QY + 2); w.erase("dock_fx", px + 1, QY + 2)
        w.erase("dock_fx", px, QY + 3); w.erase("dock_fx", px + 1, QY + 3)
        for y in range(y0 + 1, y0 + length, 3):
            w.put("dock_fx", px - 1, y, EX, (4, 9)); w.put("dock_fx", px - 1, y + 1, EX, (4, 10))
            w.put("dock_fx", px + 2, y, EX, (4, 9)); w.put("dock_fx", px + 2, y + 1, EX, (4, 10))
        prop(w, rng.choice(["barrel", "crate", "sack_f"]), px + 0.5 + rng.choice([-0.1, 1.4]), y0 + length - 1.6)
    w.piers = piers
    # ---- water life
    import w_farm_port as FP
    waves = FP.tmx_layer_cells("fishing/Tiled_foles/Fishing_dock.tmx", ["water_detailsation1", "water_detailsation3"])
    srcmap = {"water_detilazation_v2.png": WD, "Water_detailization1.png": WD1}
    minx = min(c[0] for c in waves); miny = min(c[1] for c in waves)
    for ox in range(-6, WT.W, 30):
        for oy in (QY + 6, QY + 18):
            dx = ox + rng.randint(0, 8); dy = oy + rng.randint(-2, 4)
            for (x, y, img, at) in waves:
                tx, ty = x - minx + dx, y - miny + dy
                if img in srcmap and (tx, ty) not in w.land and (tx, ty) not in w.layers.get("dock", {}) and ty > QY + 3:
                    w.put("water_fx", tx, ty, srcmap[img], at)
    # ---- ships moored alongside the long piers, boats at the short ones
    tmx_actor(w, "ship", "Boat1", (0, 0, 176, 128), (piers[0] + 7.2) * T, (QY + 13) * T, collide=False)
    tmx_actor(w, "ship2", "Boat2", (0, 0, 160, 112), (piers[2] + 6.6) * T, (QY + 12.5) * T, collide=False)
    tmx_actor(w, "ship3", "Boat1", (0, 0, 176, 128), (piers[4] - 5.2) * T, (QY + 13.5) * T, collide=False, flip=True)
    for px in (piers[1], piers[3], piers[5]):
        tmx_actor(w, "boat", "Small_boat_v1_1", (0, 0, 48, 96), (px - 1.4) * T, (QY + 8.5) * T, collide=False)
        tmx_actor(w, "boat", "Small_boat_v2_1-Sheet", (0, 0, 48, 112), (px + 3.4) * T, (QY + 9.5) * T, collide=False)
    tmx_actor(w, "fishing_boat", "Small_boat_v2_1-Sheet", (0, 0, 48, 112), 20 * T, (QY + 22) * T, collide=False)
    tmx_actor(w, "fishing_boat", "Small_boat_v1_1", (0, 0, 48, 96), 128 * T, (QY + 24) * T, collide=False)
    for i in range(9):
        k = rng.choice([("Fish1", (0, 0, 32, 32)), ("Fish3", (0, 0, 48, 32))])
        tmx_actor(w, "fish", k[0], k[1], rng.uniform(8, 172) * T, rng.uniform(QY + 6, WT.H - 3) * T, collide=False)
