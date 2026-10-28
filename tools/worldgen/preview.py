import sys
from PIL import Image, ImageDraw
import market_layout as L
import npc_defs as N

SHEETS = {
    L.WS: L.RAW + "/market/PNG/Walls_street.png",
    L.DC: L.RAW + "/market/PNG/Decorative_cracks.png",
}
PROP_SHEETS = {
    L.OBJ: L.RAW + "/market/PNG/Objects.png",
    L.SGL: L.RAW + "/market/PNG/Objects_single.png",
    L.EXT: L.RAW + "/house/PNG/exterior.png",
}
SWORD = L.RAW + "/swordman/PNG/Swordsman_lvl1/With_shadow/Swordsman_lvl1_Idle_with_shadow.png"


def main(out, show_col=False, scale=2, player=None):
    m = L.build()
    imgs = {k: Image.open(v).convert("RGBA") for k, v in SHEETS.items()}
    pimgs = {k: Image.open(v).convert("RGBA") for k, v in PROP_SHEETS.items()}
    can = Image.new("RGBA", (L.W * 16, L.H * 16), (0, 0, 0, 255))
    for layer in (m.ground, m.walls, m.detail):
        for (x, y), (src, (ax, ay)) in layer.items():
            can.alpha_composite(imgs[src].crop((ax * 16, ay * 16, ax * 16 + 16, ay * 16 + 16)), (x * 16, y * 16))
    items = []
    for p in m.props:
        x0, y0, w, h = p["region"]
        im = pimgs[p["sheet"]].crop((x0, y0, x0 + w, y0 + h))
        if p["flip"]:
            im = im.transpose(Image.FLIP_LEFT_RIGHT)
        ox, oy = p["origin"]
        items.append((-1e9 if p["floor"] else p["pos"][1], im, (int(p["pos"][0] - ox), int(p["pos"][1] - oy))))
    for n in m.npcs:
        k = n["kind"]
        if k.startswith("citizen"):
            d = N.citizen(int(k[-1]))
            im = Image.open(d["idle"]).convert("RGBA").crop((0, 0, 32, 32))
            fw, foot = 32, d["foot"]
        else:
            d = N.trader(k)
            fx, fy = d["frames"][0]
            im = Image.open(d["path"]).convert("RGBA").crop((fx, fy, fx + d["fw"], fy + d["fh"]))
            fw, foot = d["fw"], d["foot"]
        items.append((n["pos"][1], im, (int(n["pos"][0] - fw / 2), int(n["pos"][1] - foot))))
    if player:
        im = Image.open(SWORD).convert("RGBA").crop((0, 0, 64, 64))
        items.append((player[1], im, (player[0] - 32, player[1] - 46)))
    items.sort(key=lambda i: i[0])
    for _, im, pos in items:
        can.alpha_composite(im, pos)
    if show_col:
        d = ImageDraw.Draw(can)
        for (x, y), t in m.walls.items():
            k = m.collide.get(t)
            r = {"full": (0, 0, 16, 16), "bottom": (0, 8, 16, 16), "left": (0, 0, 5, 16), "right": (11, 0, 16, 16)}[k]
            d.rectangle((x * 16 + r[0], y * 16 + r[1], x * 16 + r[2] - 1, y * 16 + r[3] - 1), outline=(255, 0, 0, 255))
        for p in m.props:
            for f in p["feet"]:
                fx0, fy0, fx1, fy1 = f
                px, py = p["pos"]
                d.rectangle((px + fx0, py + fy0, px + fx1 - 1, py + fy1 - 1), outline=(0, 255, 255, 255))
        for n in m.npcs:
            px, py = n["pos"]
            d.rectangle((px - 6, py - 4, px + 6, py), outline=(255, 255, 0, 255))
    can.resize((can.width * scale, can.height * scale), Image.NEAREST).save(out)
    return m


if __name__ == "__main__":
    main(sys.argv[1], show_col="--col" in sys.argv, scale=int(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2].isdigit() else 2,
         player=(24 * 16, 30 * 16))
