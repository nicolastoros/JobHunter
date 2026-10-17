"""Renders a World to PNG for design review."""
import sys
from PIL import Image, ImageDraw
from w_common import *

_cache = {}


def sheet(path):
    if path not in _cache:
        _cache[path] = Image.open(path).convert("RGBA")
    return _cache[path]


def tile_img(src, at, alt=0):
    im = sheet(os.path.join(RAW, SOURCES[src][0]))
    ax, ay = at
    t = im.crop((ax * 16, ay * 16, ax * 16 + 16, ay * 16 + 16))
    if alt == 1:
        t = t.transpose(Image.FLIP_LEFT_RIGHT)
    return t


LAYER_ORDER = ["water", "water_fx", "ground", "ground_overlay", "road", "detail", "coast", "dock", "dock_fx", "walls"]


def render(w, out, scale=1, crop=None, show_col=False, entities=True):
    can = Image.new("RGBA", (w.W * 16, w.H * 16), (20, 20, 30, 255))
    names = [n for n in LAYER_ORDER if n in w.layers] + [n for n in w.layer_order if n not in LAYER_ORDER and not n.startswith("ysort")]
    tcache = {}
    for name in names:
        for (x, y), (src, at, alt) in w.layers[name].items():
            key = (src, at, alt)
            if key not in tcache:
                tcache[key] = tile_img(src, at, alt)
            can.alpha_composite(tcache[key], (x * 16, y * 16))
    if entities:
        items = []
        for name in w.layer_order:
            if name.startswith("ysort"):
                for (x, y), (src, at, alt) in w.layers[name].items():
                    items.append((y * 16 + 16, tile_img(src, at, alt), (x * 16, y * 16)))
        for p in w.props:
            im = sheet(p["image"]).crop(p["rect"])
            if p.get("flip"):
                im = im.transpose(Image.FLIP_LEFT_RIGHT)
            ox, oy = p["origin"]
            z = -1e9 if p.get("floor") else p["pos"][1]
            items.append((z, im, (int(p["pos"][0] - ox), int(p["pos"][1] - oy))))
        for a in w.actors + w.walkers + w.animals:
            im = sheet(a["image"]).crop(a["rect"])
            if a.get("flip"):
                im = im.transpose(Image.FLIP_LEFT_RIGHT)
            ox, oy = a["origin"]
            items.append((a["pos"][1], im, (int(a["pos"][0] - ox), int(a["pos"][1] - oy))))
        items.sort(key=lambda i: i[0])
        for _, im, pos in items:
            can.alpha_composite(im, pos)
    if show_col:
        d = ImageDraw.Draw(can)
        for (x, y), (src, at, alt) in w.layers.get("walls", {}).items():
            pass
        for p in w.props:
            for (a, b, c, e) in p.get("feet", []):
                px, py = p["pos"]
                d.rectangle((px + a, py + b, px + c - 1, py + e - 1), outline=(0, 255, 255, 255))
        for name, pts in w.paths.items():
            d.line([tuple(pt) for pt in pts], fill=(255, 0, 255, 255), width=2)
    if crop:
        can = can.crop(crop)
    if scale != 1:
        can = can.resize((can.width * scale, can.height * scale), Image.NEAREST)
    can.save(out)
