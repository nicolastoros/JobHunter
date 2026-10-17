"""World layout: places buildings, props, actors and walker routes for every district."""
import json, os
from PIL import Image
from w_common import *
import w_terrain as WT
import w_props as WP

T = 16
ACTORS_JSON = os.path.join(os.path.dirname(RAW), "actors.json")
FWC = 12  # farm Water_coasts atlas (registered below)
SOURCES[FWC] = ("farm/Tiled_files/Water_coasts.png", "assets/sprites/farm/tiles/Water_coasts.png")
ANIM_MAPS_EXTRA = None


# ---------------------------------------------------------------------------
# Props
def prop(w, key, tx, ty, flip=False, dx=0, dy=0, ysort=True):
    """Place catalog prop so its footprint bottom-centre lands on tile coords (tx, ty) (+px offset)."""
    p = WP.P[key]
    x0, y0, x1, y1 = p["rect"]
    pw, ph = x1 - x0, y1 - y0
    feet = p["feet"]
    floor = feet == "floor"
    if floor or not feet:
        feet_l = []
    else:
        feet_l = [(pw - b, c, pw - a, d) for a, c, b, d in feet] if flip else list(feet)
    ox = pw / 2
    oy = max(r[3] for r in feet_l) if feet_l else ph
    if floor:
        oy = ph / 2
    px, py = tx * T + dx, ty * T + dy
    w.props.append(dict(key=key, sheet=p["sheet"], image=WP.sheet_image_path(p["sheet"]), rect=p["rect"],
                        pos=(px, py), origin=(ox, oy), flip=flip, floor=floor,
                        feet=[(a - ox, c - oy, b - ox, d - oy) for a, c, b, d in feet_l]))
    if key in WP.DOOR_X:
        dxl = WP.DOOR_X[key]
        if flip:
            dxl = pw - dxl
        w.house_doors.append(dict(key=key, pos=(px - ox + dxl, py + 3), prop=w.props[-1]))
    return w.props[-1]


# ---------------------------------------------------------------------------
# Actors (animated sprites)
_ACT = None


def actor_spec(tileset, region):
    global _ACT
    if _ACT is None:
        _ACT = json.load(open(ACTORS_JSON))
    for a in _ACT:
        if a["tileset"] == tileset and tuple(a["region"]) == tuple(region):
            return a
    raise KeyError((tileset, region))


def foot_of(image, rect):
    im = Image.open(image).convert("RGBA").crop(rect)
    bb = im.getbbox()
    return (bb[3] - 2) if bb else rect[3] - rect[1]


def actor(w, kind, px, py, image, region, frames, fps=None, flip=False, collide=True, talk=None, bubble=None, foot=None, **kw):
    """frames: list of (dx, dy, duration_ms) offsets from region origin."""
    x, y, fw, fh = region
    rect = (x, y, x + fw, y + fh)
    if foot is None:
        foot = foot_of(image, rect)
    a = dict(kind=kind, image=image, rect=rect, size=(fw, fh), frames=frames, pos=(px, py),
             origin=(fw / 2, foot), flip=flip, collide=collide, talk=talk, bubble=bubble, **kw)
    w.actors.append(a)
    return a


def tmx_actor(w, kind, tileset, region, px, py, **kw):
    s = actor_spec(tileset, region)
    return actor(w, kind, px, py, s["image"], tuple(region), s["frames"], **kw)


def sheet_actor(w, kind, image, fw, fh, row, n, px, py, ms=120, col0=0, **kw):
    frames = [((col0 + i) * fw, 0, ms) for i in range(n)]
    return actor(w, kind, px, py, image, (0, row * fh, fw, fh), [(f[0], 0, f[2]) for f in frames], **kw)


# ---------------------------------------------------------------------------
# Walk graph
class Graph:
    def __init__(self):
        self.nodes = []
        self.edges = set()
        self.index = {}

    def node(self, name, tx, ty):
        if name not in self.index:
            self.index[name] = len(self.nodes)
            self.nodes.append((tx * T + 8, ty * T + 8))
        return self.index[name]

    def link(self, *names):
        for a, b in zip(names, names[1:]):
            i, j = self.index[a], self.index[b]
            self.edges.add((min(i, j), max(i, j)))


# ---------------------------------------------------------------------------
def fountain(w, x0, y0, x1, y1):
    """Stone-rimmed basin: rim ring around water rect x0..x1, y0..y1 (farm Water_coasts ring 5..7 x 1..3)."""
    for y in range(y0 - 1, y1 + 2):
        for x in range(x0 - 1, x1 + 2):
            inside = x0 <= x <= x1 and y0 <= y <= y1
            w.put("water_city", x, y, WD, (36, 0), "full")
            if inside:
                continue
            cx = 5 if x == x0 - 1 else 7 if x == x1 + 1 else 6
            cy = 1 if y == y0 - 1 else 3 if y == y1 + 1 else 2
            w.put("rim", x, y, FWC, (cx, cy), "full")
    w.blocked |= rect_cells(x0 - 1, y0 - 1, x1 + 1, y1 + 1)


def dirt_patch(w, x0, y0, x1, y1, layer="ground"):
    """Market-style dirt quad with brick fringe (Walls_street 0..2 x 12..14)."""
    centers = [(1, 13)] * 6 + [(4, 13), (7, 13), (10, 13)]
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            cx = 0 if x == x0 else 2 if x == x1 else 1
            cy = 12 if y == y0 else 14 if y == y1 else 13
            at = w.rng.choice(centers) if (cx, cy) == (1, 13) else (cx, cy)
            w.put(layer, x, y, MW, at)


def planter(w, x0, y0, x1, y1):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            cx = 2 if x == x0 else 4 if x == x1 else 3
            cy = 8 if y == y0 else 10 if y == y1 else 9
            w.put("walls", x, y, MW, (cx, cy), "full")
    w.blocked |= rect_cells(x0, y0, x1, y1)


MARKET_NPC = os.path.join(RAW, "market/PNG/Characters/")


def trader(w, name, px, py, talk, bubble=None):
    """Market trader using the sheets from the first market."""
    files = {
        "fruits": ("Character_others_animation/Trader_fruits_animation.png", 32, 32, "Trader_fruits"),
        "weapon": ("Character_others_animation/Trader_weapon_animation_with_shadow.png", 32, 32, "Trader_weapon_animation_full"),
        "magic": ("Character_others_animation/Trader_magic_animation_with_shadow.png", 48, 48, "Trader_magic_animation_full"),
        "bread": ("Character_others_animation/Trader_bread_animation_with_shadow.png", 32, 32, "Trader_bread_animation_full"),
        "drinks": ("Character_others_animation/Trader_drinks_animation_with_shadow.png", 32, 32, "Trader_drinks_animation_full"),
        "lute": ("Character_others_animation/Lute_player_animation_with_shadow.png", 32, 32, "Lute_player_animation_full"),
        "flutist": ("Character_others_animation/Flutist_animation_with_shadow.png", 32, 48, "Flutist_animation_full"),
        "eater": ("Character_others_animation/Eater_animation.png", 16, 32, "Eater_animation"),
    }
    import npc_defs as N
    f, fw, fh, ts = files[name]
    xs = N._A[ts]
    return actor(w, "trader_" + name, px, py, MARKET_NPC + f, (0, 0, fw, fh), [(x, 0, 150) for x in xs], talk=talk, bubble=bubble,
                 seller=name not in ("lute", "flutist", "eater"))


GUILD_NPC = os.path.join(RAW, "guild/PNG/")


def citizen_sheet(n):
    if n <= 5:
        return MARKET_NPC + "Character_citizens_animation/Citizen%d_Idle_with_shadow.png" % n
    return GUILD_NPC + {6: "Citizen1_Idle.png", 7: "Citizen2_Idle.png", 8: "Fighter2_Idle.png"}[n]


def citizen(w, n, px, py, route_zone, lines, tint=None, brain=False, guard=False):
    img_idle = citizen_sheet(n)
    a = dict(kind="citizen%d" % n, image=img_idle, rect=(0, 0, 32, 32), pos=(px, py), origin=(16, foot_of(img_idle, (0, 0, 32, 32))),
             zone=route_zone, lines=lines, tint=tint, n=n, brain=brain, guard=guard)
    w.walkers.append(a)
    return a


DIR_ROW = {"down": 0, "left": 1, "right": 2, "up": 3}


def idle_citizen(w, n, px, py, facing, lines):
    img = MARKET_NPC + "Character_citizens_animation/Citizen%d_Idle_with_shadow.png" % n
    r = DIR_ROW[facing]
    frames = [(i * 32, 0, 140) for i in range(12 if facing != "up" else 6)]
    return actor(w, "citizen%d_idle" % n, px, py, img, (0, r * 32, 32, 32), frames,
                 talk=("Vecino", [w.rng.choice(lines)]), bubble=lines, chatter=True)
