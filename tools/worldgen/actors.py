"""Extract animated actors (characters, animals, sails...) from the authors' Tiled maps."""
import os, sys, json
import xml.etree.ElementTree as ET

RAW = r"C:/Users/nicol/AppData/Local/Temp/claude/c--Users-nicol-OneDrive-Documentos-JobHunter/7f39b642-3aaa-4323-9d53-2b420a1d2380/scratchpad/raw"
MAPS = [
    "farm/Tiled_files/Farm.tmx",
    "farm/Tiled_files/Plants_animals.tmx",
    "fishing/Tiled_foles/Fishing_dock.tmx",
    "fishing/Tiled_foles/Boats_fish_characters.tmx",
    "training/Tiled_files/Training_ground.tmx",
    "training/Tiled_files/Characters.tmx",
    "animals/Tiled/Animals.tmx",
    "guild/Tiled_files/Exterior.tmx",
    "guild/Tiled_files/Interior_1st_floor.tmx",
    "guild/Tiled_files/Interior_2nd_floor.tmx",
    "guild/Tiled_files/Characters.tmx",
    "house/Tiled_files/Interior1.tmx",
    "farm/Tiled_files/House_interior.tmx",
    "fishing/Tiled_foles/Interior.tmx",
]


def load(path):
    root = ET.parse(os.path.join(RAW, path)).getroot()
    base = os.path.dirname(os.path.join(RAW, path))
    tsets = []
    for ts in root.findall("tileset"):
        img = ts.find("image")
        if img is None:
            continue
        cols = int(ts.get("columns"))
        anims = {}
        for t in ts.findall("tile"):
            fr = [(int(f.get("tileid")), int(f.get("duration"))) for f in t.iter("frame")]
            if fr:
                anims[int(t.get("id"))] = fr
        tsets.append(dict(first=int(ts.get("firstgid")), cols=cols, name=ts.get("name"),
                          image=os.path.normpath(os.path.join(base, img.get("source"))), anims=anims))
    tsets.sort(key=lambda t: t["first"])
    return root, tsets


def lookup(tsets, gid):
    gid &= 0x1FFFFFFF
    for ts in reversed(tsets):
        if gid >= ts["first"]:
            return ts, gid - ts["first"]


def extract(path):
    root, tsets = load(path)
    out = []

    def walk(node, prefix=""):
        for ch in node:
            if ch.tag == "group":
                walk(ch, prefix + ch.get("name") + "/")
            elif ch.tag == "layer":
                cells = {}
                for c in ch.iter("chunk"):
                    cx, cy, w = int(c.get("x")), int(c.get("y")), int(c.get("width"))
                    vals = [int(v) for v in c.text.replace("\n", "").split(",") if v.strip()]
                    for i, g in enumerate(vals):
                        if g:
                            ts, tid = lookup(tsets, g)
                            if ts["anims"]:
                                cells[(cx + i % w, cy + i // w)] = (ts, tid)
                # group connected cells sharing a tileset
                seen = set()
                for start in sorted(cells):
                    if start in seen:
                        continue
                    ts0 = cells[start][0]
                    stack, grp = [start], []
                    seen.add(start)
                    while stack:
                        p = stack.pop()
                        grp.append(p)
                        for d in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                            q = (p[0] + d[0], p[1] + d[1])
                            if q in cells and q not in seen and cells[q][0] is ts0:
                                seen.add(q)
                                stack.append(q)
                    xs = [p[0] for p in grp]; ys = [p[1] for p in grp]
                    mx, my = min(xs), min(ys)
                    w, h = max(xs) - mx + 1, max(ys) - my + 1
                    cols = ts0["cols"]
                    # atlas origin = atlas coords of cell (mx,my) minus nothing; find a cell with known offset
                    ref = None
                    for p in grp:
                        tid = cells[p][1]
                        if tid in ts0["anims"]:
                            ref = (p, tid)
                            break
                    if ref is None:
                        continue
                    (px, py), tid = ref
                    ax, ay = tid % cols - (px - mx), tid // cols - (py - my)
                    seq = ts0["anims"][tid]
                    frames = [((f % cols) - tid % cols, (f // cols) - tid // cols, d) for f, d in seq]
                    out.append(dict(map=os.path.basename(path), layer=prefix + ch.get("name"), tileset=ts0["name"],
                                    image=ts0["image"], region=(ax * 16, ay * 16, w * 16, h * 16),
                                    frames=[(dx * 16, dy * 16, d) for dx, dy, d in frames], cell=(mx, my)))

    walk(root)
    return out


if __name__ == "__main__":
    allacts = []
    for m in MAPS:
        acts = extract(m)
        allacts += acts
    json.dump(allacts, open(sys.argv[1], "w"), indent=0)
    seen = set()
    for a in allacts:
        key = (a["tileset"], a["region"])
        if key in seen:
            continue
        seen.add(key)
        fr = a["frames"]
        print("%-22s %-28s %-34s reg=%s n=%d step=%s" % (a["map"][:22], a["layer"][:28], a["tileset"][:34], a["region"], len(fr),
                                                       (fr[1][0], fr[1][1]) if len(fr) > 1 else None))
