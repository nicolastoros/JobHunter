"""Hurt and death animations for the beasts (boar, wolves), whose original sheets are lost.
Built from their own idle pose: hurt = a red flash and a jolt (3 frames), death = the body tips
over onto its side, sinks and fades (6 frames). Rows: down, up, left, right (32 px cells)."""
import os
from PIL import Image, ImageEnhance

RAW = r"C:/Users/nicol/JobHunter_raw"
CELL = 32


def _tint(im, rgb, amount):
    over = Image.new("RGBA", im.size, rgb + (0,))
    px, ov = im.load(), over.load()
    for y in range(im.height):
        for x in range(im.width):
            a = px[x, y][3]
            if a:
                ov[x, y] = rgb + (int(a * amount),)
    out = im.copy()
    out.alpha_composite(over)
    return out


def build(kind):
    d = os.path.join(RAW, "mon_beasts", "PNG", kind, "With_shadow")
    idle = Image.open(os.path.join(d, "%s_idle_with_shadow.png" % kind)).convert("RGBA")
    hurt = Image.new("RGBA", (CELL * 3, CELL * 4), (0, 0, 0, 0))
    death = Image.new("RGBA", (CELL * 6, CELL * 4), (0, 0, 0, 0))
    for row in range(4):
        base = idle.crop((0, row * CELL, CELL, row * CELL + CELL))
        for i, (dx, amt) in enumerate(((-2, 0.75), (2, 0.5), (0, 0.2))):
            f = _tint(base, (255, 60, 50), amt)
            hurt.alpha_composite(f, (i * CELL + dx, row * CELL))
        for i in range(6):
            k = i / 5
            ang = -78 * k if row != 2 else 78 * k          # tips over away from the side it faces
            f = base.rotate(ang, resample=Image.NEAREST, center=(16, 26))
            f = ImageEnhance.Brightness(f).enhance(1.0 - 0.35 * k)
            if k > 0.5:
                a = f.split()[3].point(lambda v, k=k: int(v * (1.0 - (k - 0.5) * 1.4)))
                f.putalpha(a)
            death.alpha_composite(f, (i * CELL, row * CELL + int(3 * k)))
    hurt.save(os.path.join(d, "%s_hurt_with_shadow.png" % kind))
    death.save(os.path.join(d, "%s_death_with_shadow.png" % kind))
    print(kind, "ok")


for k in ("Boar", "Wolf", "Frostwolf"):
    build(k)
