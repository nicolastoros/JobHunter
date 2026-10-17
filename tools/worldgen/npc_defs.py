# NPC sprite sheet definitions (frame size + frame x-offsets from the Tiled animations).
import xml.etree.ElementTree as ET
from PIL import Image
from market_layout import RAW

CH = RAW + "/market/PNG/Characters/"
OTH = CH + "Character_others_animation/"
CIT = CH + "Character_citizens_animation/"

# kind -> (file, frame_w, frame_h, tmx tileset name)
TRADERS = {
    "trader_fruits": (OTH + "Trader_fruits_animation.png", 32, 32, "Trader_fruits"),
    "trader_weapon": (OTH + "Trader_weapon_animation_with_shadow.png", 32, 32, "Trader_weapon_animation_full"),
    "trader_magic":  (OTH + "Trader_magic_animation_with_shadow.png", 48, 48, "Trader_magic_animation_full"),
    "trader_bread":  (OTH + "Trader_bread_animation_with_shadow.png", 32, 32, "Trader_bread_animation_full"),
    "trader_drinks": (OTH + "Trader_drinks_animation_with_shadow.png", 32, 32, "Trader_drinks_animation_full"),
    "lute":          (OTH + "Lute_player_animation_with_shadow.png", 32, 32, "Lute_player_animation_full"),
    "flutist":       (OTH + "Flutist_animation_with_shadow.png", 32, 48, "Flutist_animation_full"),
    "eater":         (OTH + "Eater_animation.png", 16, 32, "Eater_animation"),
}


def _anims():
    root = ET.parse(RAW + "/market/Tiled_files/Market_square.tmx").getroot()
    out = {}
    for ts in root.findall("tileset"):
        tiles = ts.findall("tile")
        if not tiles:
            continue
        cols = int(ts.get("columns"))
        t0 = tiles[0]
        first = int(t0.get("id"))
        seq = [(int(f.get("tileid")) % cols - first % cols) * 16 for f in t0.iter("frame")]
        out[ts.get("name")] = seq
    return out


_A = _anims()


def foot_y(img, fw, fh):
    bb = img.crop((0, 0, fw, fh)).getbbox()
    return bb[3] - 2 if bb else fh


def trader(kind):
    path, fw, fh, tsname = TRADERS[kind]
    img = Image.open(path).convert("RGBA")
    xs = _A[tsname]
    return dict(path=path, fw=fw, fh=fh, frames=[(x, 0) for x in xs], fps=1000 / 150, foot=foot_y(img, fw, fh))


def citizen(n):
    idle = CIT + "Citizen%d_Idle_with_shadow.png" % n
    walk = CIT + "Citizen%d_Walk_with_shadow.png" % n
    img = Image.open(idle).convert("RGBA")
    return dict(idle=idle, walk=walk, fw=32, fh=32, idle_frames=12, walk_frames=6, foot=foot_y(img, 32, 32))
