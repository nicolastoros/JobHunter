"""Convert the authors' Tiled interiors into baked Godot interior scenes."""
import os, json, sys
import xml.etree.ElementTree as ET
from collections import deque
from PIL import Image
from w_common import RAW, ROOT

ACTORS = json.load(open(os.path.join(os.path.dirname(RAW), "actors.json")))
FLOOR_NAMES = {"floor", "carpet", "tile layer 6"}
WALL_NAMES = {"walls", "windows"}
TOP_NAMES = {"walls_top"}


def load_map(path):
    root = ET.parse(os.path.join(RAW, path)).getroot()
    base = os.path.dirname(os.path.join(RAW, path))
    ts = []
    for t in root.findall("tileset"):
        im = t.find("image")
        if im is None:
            continue
        f = os.path.join(base, im.get("source"))
        if not os.path.exists(f):
            continue
        anim = {int(x.get("id")) for x in t.findall("tile") if x.find("animation") is not None}
        ts.append((int(t.get("firstgid")), int(t.get("columns")), Image.open(f).convert("RGBA"), anim, t.get("name")))
    ts.sort(key=lambda a: a[0])
    layers = []

    def walk(n, p=""):
        for c in n:
            if c.tag == "group":
                walk(c, p + c.get("name") + "/")
            elif c.tag == "layer" and c.get("visible", "1") != "0":
                cells = []
                for ch in c.iter("chunk"):
                    cx, cy, w = int(ch.get("x")), int(ch.get("y")), int(ch.get("width"))
                    for i, v in enumerate([int(v) for v in ch.text.replace("\n", "").split(",") if v.strip()]):
                        if v:
                            cells.append((cx + i % w, cy + i // w, v))
                if cells:
                    layers.append((p + c.get("name"), cells))
    walk(root)
    return ts, layers


def tile(ts, gid):
    flip_h = bool(gid & 0x80000000)
    gid &= 0x1FFFFFFF
    for fg, cols, sheet, anim, name in reversed(ts):
        if gid >= fg:
            i = gid - fg
            t = sheet.crop((i % cols * 16, i // cols * 16, i % cols * 16 + 16, i // cols * 16 + 16))
            if flip_h:
                t = t.transpose(Image.FLIP_LEFT_RIGHT)
            return t, (i in anim), name
    return None, False, None


def components(img, min_px=20):
    a = img.split()[3].load()
    W, H = img.size
    seen = set()
    out = []
    for y in range(H):
        for x in range(W):
            if a[x, y] > 0 and (x, y) not in seen:
                q = deque([(x, y)]); seen.add((x, y)); x0 = x1 = x; y0 = y1 = y; n = 0
                while q:
                    cx, cy = q.popleft(); n += 1
                    x0 = min(x0, cx); x1 = max(x1, cx); y0 = min(y0, cy); y1 = max(y1, cy)
                    for dx in (-1, 0, 1):
                        for dy in (-1, 0, 1):
                            nx, ny = cx + dx, cy + dy
                            if 0 <= nx < W and 0 <= ny < H and (nx, ny) not in seen and a[nx, ny] > 0:
                                seen.add((nx, ny)); q.append((nx, ny))
                if n >= min_px:
                    out.append((x0, y0, x1 + 1, y1 + 1, n))
    return out


def convert(name, path, exits, title, extra_solid=(), extra_open=()):
    ts, layers = load_map(path)
    allc = [c for _, cs in layers for c in cs]
    mx = min(c[0] for c in allc) - 1; my = min(c[1] for c in allc) - 1
    Mx = max(c[0] for c in allc) + 2; My = max(c[1] for c in allc) + 3
    W, H = (Mx - mx) * 16, (My - my) * 16
    floor = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    top = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    objs = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    has_floor, wall_cov = set(), {}
    for lname, cells in layers:
        low = lname.lower().split("/")[-1]
        kind = "floor" if low in FLOOR_NAMES else "wall" if low in WALL_NAMES else "top" if low in TOP_NAMES else "obj"
        for x, y, g in cells:
            t, animated, tsname = tile(ts, g)
            if t is None:
                continue
            if animated and kind == "obj":
                continue  # characters / fire become animated actors
            px, py = (x - mx) * 16, (y - my) * 16
            target = {"floor": floor, "wall": floor, "top": top, "obj": objs}[kind]
            target.alpha_composite(t, (px, py))
            if kind == "floor" and low == "floor":
                has_floor.add((x - mx, y - my))
            if kind in ("wall", "top"):
                op = sum(1 for p in t.getdata() if p[3] > 0) / 256.0
                wall_cov[(x - mx, y - my)] = max(wall_cov.get((x - mx, y - my), 0), op)
    # objects: rugs/large decals go to the floor, furniture becomes y-sorted props
    props = []
    for (x0, y0, x1, y1, n) in components(objs):
        w, h = x1 - x0, y1 - y0
        if w >= 64 or h >= 64:
            floor.alpha_composite(objs.crop((x0, y0, x1, y1)), (x0, y0))
            continue
        fh = max(6, min(14, int(h * 0.45)))
        props.append(dict(rect=(x0, y0, x1, y1), feet=(x0 + 2, y1 - fh, x1 - 2, y1 - 1)))
    # walkable mask at 4px resolution: wall/top pixels and missing floor are solid
    walls_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for lname, cells in layers:
        low = lname.lower().split("/")[-1]
        if low in WALL_NAMES or low in TOP_NAMES:
            for x, y, g in cells:
                t, _, _ = tile(ts, g)
                if t is not None:
                    walls_img.alpha_composite(t, ((x - mx) * 16, (y - my) * 16))
    alpha = walls_img.split()[3].load()
    B = 4
    cols, rows = W // B, H // B
    solid = set()
    for by in range(rows):
        for bx in range(cols):
            tx, ty = bx * B // 16, by * B // 16
            if (tx, ty) not in has_floor:
                solid.add((bx, by)); continue
            cnt = 0
            for yy in range(by * B, by * B + B):
                for xx in range(bx * B, bx * B + B):
                    if alpha[xx, yy] > 170:
                        cnt += 1
            if cnt >= 2:
                solid.add((bx, by))
    def tiles_to_blocks(cells):
        out = set()
        for (tx, ty) in cells:
            for by in range(ty * 4, ty * 4 + 4):
                for bx in range(tx * 4, tx * 4 + 4):
                    out.add((bx, by))
        return out
    solid |= tiles_to_blocks(extra_solid)
    solid -= tiles_to_blocks(extra_open)
    for e in exits:
        solid -= tiles_to_blocks(e["cells"])
    # animated actors from this map
    acts = []
    mapname = os.path.basename(path)
    for a in ACTORS:
        if a["map"] != mapname or a["layer"].split("/")[-1].lower() in WALL_NAMES | {"house", "flags"}:
            continue
        cx, cy = a["cell"]
        x, y, fw, fh = a["region"]
        img = Image.open(a["image"]).convert("RGBA").crop((x, y, x + fw, y + fh))
        bb = img.getbbox()
        foot = (bb[3] - 2) if bb else fh
        px = (cx - mx) * 16 + fw / 2
        py = (cy - my) * 16 + foot
        acts.append(dict(image=a["image"], rect=(x, y, x + fw, y + fh), frames=a["frames"], pos=(px, py), foot=foot, size=(fw, fh), layer=a["layer"]))
    out_dir = os.path.join(ROOT, "assets/interiors", name)
    os.makedirs(out_dir, exist_ok=True)
    floor.save(os.path.join(out_dir, "floor.png"))
    top.save(os.path.join(out_dir, "top.png"))
    objs.save(os.path.join(out_dir, "objects.png"))
    return dict(name=name, size=(W, H), props=props, solid=solid, cols=cols, rows=rows, actors=acts, exits=exits, title=title, origin=(mx, my))


def ascii_mask(info):
    from PIL import ImageDraw
    im = Image.open(os.path.join(ROOT, "assets/interiors", info["name"], "floor.png")).convert("RGBA")
    ob = Image.open(os.path.join(ROOT, "assets/interiors", info["name"], "objects.png")).convert("RGBA")
    im.alpha_composite(ob)
    ov = Image.new("RGBA", im.size, (0, 0, 0, 0)); d = ImageDraw.Draw(ov)
    for (bx, by) in info["solid"]:
        d.rectangle((bx * 4, by * 4, bx * 4 + 3, by * 4 + 3), fill=(255, 0, 0, 90))
    for p in info["props"]:
        d.rectangle(p["feet"], outline=(0, 255, 255, 255))
    for y in range(0, im.height, 16):
        for x in range(0, im.width, 16):
            if (x // 16) % 2 == 0 and (y // 16) % 2 == 0:
                d.text((x + 1, y), "%d,%d" % (x // 16, y // 16), fill=(255, 255, 0, 255))
    im.alpha_composite(ov)
    return im.resize((im.width * 2, im.height * 2), Image.NEAREST)


if __name__ == "__main__":
    info = convert("test", sys.argv[1], [], "")
    print(info["origin"], info["size"])
    ascii_mask(info).save(sys.argv[2])
    for a in info["actors"]:
        print(a["layer"], a["pos"])
