"""Shared world-generation primitives: tile sources, layers, autotiling."""
import random
import xml.etree.ElementTree as ET
import os

RAW = r"C:/Users/nicol/JobHunter_raw"
ROOT = r"C:/Users/nicol/OneDrive/Documentos/JobHunter"
T = 16

# ---------------------------------------------------------------------------
# Tile atlas sources: id -> (raw path, project path)
SOURCES = {
    0: ("market/PNG/Walls_street.png", "assets/sprites/market/tiles/Walls_street.png"),
    1: ("market/PNG/Decorative_cracks.png", "assets/sprites/market/tiles/Decorative_cracks.png"),
    2: ("farm/Tiled_files/ground_grass_bricks.png", "assets/sprites/farm/tiles/ground_grass_bricks.png"),
    3: ("farm/Tiled_files/Road.png", "assets/sprites/farm/tiles/Road.png"),
    4: ("farm/Tiled_files/Ground_grass_details.png", "assets/sprites/farm/tiles/Ground_grass_details.png"),
    5: ("fishing/Tiled_foles/Water_coasts.png", "assets/sprites/port/tiles/Water_coasts.png"),
    6: ("fishing/Tiled_foles/water_detilazation_v2.png", "assets/sprites/port/tiles/water_detilazation_v2.png"),
    7: ("fishing/Tiled_foles/Exterior_tiles.png", "assets/sprites/port/tiles/Exterior_tiles.png"),
    8: ("fishing/Tiled_foles/piles.png", "assets/sprites/port/tiles/piles.png"),
    9: ("training/Tiled_files/Walls_street.png", "assets/sprites/training/tiles/Walls_street.png"),
    10: ("fishing/Tiled_foles/Water_detailization1.png", "assets/sprites/port/tiles/Water_detailization1.png"),
    11: ("fishing/Tiled_foles/Spots.png", "assets/sprites/port/tiles/Spots.png"),
}
MW, MD, FG, RD, GD, WC, WD, EX, PL, TW, WD1, SP = range(12)

# Maps whose tilesets carry the animation data for our atlases
ANIM_MAPS = ["fishing/Tiled_foles/Fishing_dock.tmx", "farm/Tiled_files/Farm.tmx", "training/Tiled_files/Training_ground.tmx"]


ANIM_ALIAS = {}   # recoloured copies of an atlas share its tile animations


def load_tile_anims():
    """{source_id: {(x,y): (step_rows, n_frames, duration)}} for vertically-stepped animations."""
    by_file = {os.path.normpath(os.path.join(RAW, v[0])).lower(): k for k, v in SOURCES.items()}
    out = {k: {} for k in SOURCES}
    for m in ANIM_MAPS:
        path = os.path.join(RAW, m)
        root = ET.parse(path).getroot()
        for ts in root.findall("tileset"):
            img = ts.find("image")
            if img is None:
                continue
            f = os.path.normpath(os.path.join(os.path.dirname(path), img.get("source"))).lower()
            # match by file name (paths differ between packs)
            sid = None
            for fp, k in by_file.items():
                if os.path.basename(fp) == os.path.basename(f) and SOURCES[k][0].split("/")[0] in m.split("/")[0]:
                    sid = k
            if sid is None:
                for fp, k in by_file.items():
                    if os.path.basename(fp) == os.path.basename(f):
                        sid = k
            if sid is None:
                continue
            cols = int(ts.get("columns"))
            for t in ts.findall("tile"):
                fr = [(int(x.get("tileid")), int(x.get("duration"))) for x in t.iter("frame")]
                tid = int(t.get("id"))
                if len(fr) < 2:
                    continue
                ids = [a for a, _ in fr]
                if any(a % cols != tid % cols for a in ids):
                    continue
                rows = [a // cols for a in ids]
                step = rows[1] - rows[0]
                if step <= 0 or any(rows[i + 1] - rows[i] != step for i in range(len(rows) - 1)) or rows[0] != tid // cols:
                    continue
                out[sid][(tid % cols, tid // cols)] = (step, len(ids), fr[0][1] / 1000.0)
    for k, src in ANIM_ALIAS.items():
        if k in out and src in out:
            out[k] = dict(out[src])
    return out


# ---------------------------------------------------------------------------
class World:
    def __init__(self, w, h, seed=11):
        self.W, self.H = w, h
        self.rng = random.Random(seed)
        self.layers = {}          # name -> {(x,y): (src, (ax,ay), alt)}
        self.layer_order = []
        self.collide = {}         # (src,(ax,ay)) -> kind
        self.props = []
        self.actors = []          # animated non-interactive / interactive characters
        self.walkers = []         # citizens following paths
        self.paths = {}           # name -> list of points (px)
        self.animals = []
        self.zones = []           # (name, rect px) for HUD location names
        self.blocked = set()      # cells reserved (no random decoration)
        self.solids = set()       # invisible collision cells
        self.house_doors = []     # every house door (NPC homes)
        self.doors = []           # enterable doors
        self.shop_points = []     # where shoppers stand

    def layer(self, name):
        if name not in self.layers:
            self.layers[name] = {}
            self.layer_order.append(name)
        return self.layers[name]

    def put(self, layer, x, y, src, at, kind=None, alt=0):
        if not (0 <= x < self.W and 0 <= y < self.H):
            return
        self.layer(layer)[(x, y)] = (src, at, alt)
        if kind:
            key = (src, at)
            prev = self.collide.get(key)
            self.collide[key] = kind if prev in (None, kind) else "full"

    def erase(self, layer, x, y):
        self.layer(layer).pop((x, y), None)


def rect_cells(x0, y0, x1, y1):
    return {(x, y) for x in range(x0, x1 + 1) for y in range(y0, y1 + 1)}


def autotile(world, layer, mask, src, nine, inner=None, center_variants=None, kind=None):
    """Blob autotile. nine = dict tl,t,tr,l,c,r,bl,b,br -> atlas; inner = dict ne,nw,se,sw (missing diagonal)."""
    for (x, y) in mask:
        n = (x, y - 1) in mask; s = (x, y + 1) in mask
        w = (x - 1, y) in mask; e = (x + 1, y) in mask
        if not n and not w: k = "tl"
        elif not n and not e: k = "tr"
        elif not s and not w: k = "bl"
        elif not s and not e: k = "br"
        elif not n: k = "t"
        elif not s: k = "b"
        elif not w: k = "l"
        elif not e: k = "r"
        else:
            k = "c"
            if inner:
                if (x + 1, y - 1) not in mask: k = "ne"
                elif (x - 1, y - 1) not in mask: k = "nw"
                elif (x + 1, y + 1) not in mask: k = "se"
                elif (x - 1, y + 1) not in mask: k = "sw"
        if k == "c" and center_variants:
            at = world.rng.choice(center_variants)
        elif k in ("ne", "nw", "se", "sw"):
            at = inner[k]
        else:
            at = nine[k]
        world.put(layer, x, y, src, at, kind)


def nine_at(x0, y0):
    return {"tl": (x0, y0), "t": (x0 + 1, y0), "tr": (x0 + 2, y0),
            "l": (x0, y0 + 1), "c": (x0 + 1, y0 + 1), "r": (x0 + 2, y0 + 1),
            "bl": (x0, y0 + 2), "b": (x0 + 1, y0 + 2), "br": (x0 + 2, y0 + 2)}
