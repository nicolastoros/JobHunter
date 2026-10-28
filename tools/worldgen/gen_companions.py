"""SpriteFrames for the mount (deer) and the pets: idle/walk/run(/attack) x down/up/left/right.
Sheets: 32x32 cells, rows down, up, left, right (animals pack). Some pets are recolors of the
fox and the boar (snow fox, grey wolf, fire fox, ebony boar)."""
import colorsys, os, shutil
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(r"C:/Users/nicol/JobHunter_raw", "animals", "PNG", "With_Shadow")
ROOT = "C:/Users/nicol/OneDrive/Documentos/JobHunter"
OUT = os.path.join(ROOT, "assets/sprites/animals/companions")
DIRS = ["down", "up", "left", "right"]
## Sheets whose left/right rows come swapped in the pack (the fox's run faces backwards otherwise).
SWAP_LR = {"Fox_Run"}
FOX = {"idle": ("Fox_Idle", 5), "walk": ("Fox_walk", 9), "run": ("Fox_Run", 12), "attack": ("Fox_Run", 16)}
BOAR = {"idle": ("Boar_Idle", 5), "walk": ("Boar_Walk", 9), "run": ("Boar_Run", 12), "attack": ("Boar_Attack", 12)}
# name: (raw folder, anims, recolor ramp or None, file prefix of the recolored copy)
SETS = {
    "deer": ("Deer", {"idle": ("Deer_Idle", 5), "walk": ("Deer_Walk", 9), "run": ("Deer_Run", 12)}, None, None),
    "fox": ("Fox", FOX, None, None),
    "boar": ("Boar", BOAR, None, None),
    "hare": ("Hare", {"idle": ("Hare_Idle", 5), "walk": ("Hare_Walk", 9), "run": ("Hare_Run", 12), "attack": ("Hare_Run", 16)}, None, None),
    "grouse": ("Black_grouse", {"idle": ("Black_grouse_Idle", 5), "walk": ("Black_grouse_Walk", 9), "run": ("Black_grouse_Flight", 12),
                                "attack": ("Black_grouse_Flight", 16)}, None, None),
    "snow_fox": ("Fox", FOX, ((86, 98, 130), (246, 250, 255)), "Snowfox"),
    "wolf": ("Fox", FOX, ((44, 44, 56), (178, 180, 192)), "Wolf"),
    "fire_fox": ("Fox", FOX, ((140, 22, 12), (255, 214, 80)), "Firefox"),
    "ebony_boar": ("Boar", BOAR, ((26, 22, 36), (112, 100, 138)), "Ebonyboar"),
}


def recolor(img, ramp):
    """Warm fur (reds, oranges, browns) -> a ramp between two colors, keeping the shading."""
    lo, hi = ramp
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a < 255:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if s < 0.22 or not (h <= 0.14 or h >= 0.93):
                continue
            t = min(1.0, max(0.0, (v - 0.2) / 0.65))
            px[x, y] = tuple(int(lo[i] + (hi[i] - lo[i]) * t) for i in range(3)) + (255,)
    return img


def build(name, folder, anims, ramp, prefix):
    os.makedirs(OUT, exist_ok=True)
    tex, subs, defs = [], [], []
    for anim, (file, fps) in anims.items():
        src = os.path.join(RAW, folder, file + "_with_shadow.png")
        out_file = file if prefix is None else prefix + file[file.index("_"):]
        dst = os.path.join(OUT, out_file + "_with_shadow.png")
        if ramp is not None:
            recolor(Image.open(src).convert("RGBA"), ramp).save(dst)
        elif not os.path.exists(dst):
            shutil.copy2(src, dst)
        img = Image.open(dst).convert("RGBA")
        res = "res://assets/sprites/animals/companions/%s_with_shadow.png" % out_file
        if res not in tex:
            tex.append(res)
        tid = "t%d" % tex.index(res)
        n = img.width // 32
        dirs = ["down", "up", "right", "left"] if file in SWAP_LR else DIRS
        for r, d in enumerate(dirs):
            refs = []
            for i in range(n):
                box = (i * 32, r * 32, i * 32 + 32, r * 32 + 32)
                if not img.crop(box).getbbox():
                    continue
                sid = "a%d" % len(subs)
                subs.append('[sub_resource type="AtlasTexture" id="%s"]\natlas = ExtResource("%s")\nregion = Rect2(%d, %d, 32, 32)\n' % (sid, tid, box[0], box[1]))
                refs.append('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % sid)
            loop = "false" if anim == "attack" else "true"
            defs.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s_%s",\n"speed": %d.0\n}' % (", ".join(refs), loop, anim, d, fps))
    lines = ['[gd_resource type="SpriteFrames" format=3]', ""]
    lines += ['[ext_resource type="Texture2D" path="%s" id="t%d"]' % (p, i) for i, p in enumerate(tex)]
    lines.append("")
    lines += subs
    lines.append("[resource]")
    lines.append("animations = [%s]" % ", ".join(defs))
    os.makedirs(os.path.join(ROOT, "resources/sprite_frames/companions"), exist_ok=True)
    with open(os.path.join(ROOT, "resources/sprite_frames/companions/%s.tres" % name), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    print(name, "ok")


for k, (folder, anims, ramp, prefix) in SETS.items():
    build(k, folder, anims, ramp, prefix)
