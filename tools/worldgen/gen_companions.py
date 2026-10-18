"""SpriteFrames for the mount (deer) and the pets (fox, boar): idle/walk/run(/attack) x down/up/left/right.
Sheets: 32x32 cells, rows down, up, left, right (animals pack)."""
import os, shutil
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, "..", "raw", "animals", "PNG", "With_Shadow")
ROOT = "C:/Users/nicol/OneDrive/Documentos/JobHunter"
DIRS = ["down", "up", "left", "right"]
SETS = {
    "deer": ("Deer", {"idle": ("Deer_Idle", 5), "walk": ("Deer_Walk", 9), "run": ("Deer_Run", 12)}),
    "fox": ("Fox", {"idle": ("Fox_Idle", 5), "walk": ("Fox_walk", 9), "run": ("Fox_Run", 12), "attack": ("Fox_Run", 16)}),
    "boar": ("Boar", {"idle": ("Boar_Idle", 5), "walk": ("Boar_Walk", 9), "run": ("Boar_Run", 12), "attack": ("Boar_Attack", 12)}),
}


def build(name, folder, anims):
    out_dir = os.path.join(ROOT, "assets/sprites/animals/companions")
    os.makedirs(out_dir, exist_ok=True)
    tex, subs, defs = [], [], []
    for anim, (file, fps) in anims.items():
        src = os.path.join(RAW, folder, file + "_with_shadow.png")
        dst = os.path.join(out_dir, file + "_with_shadow.png")
        if not os.path.exists(dst):
            shutil.copy2(src, dst)
        img = Image.open(dst).convert("RGBA")
        res = "res://assets/sprites/animals/companions/%s_with_shadow.png" % file
        if res not in tex:
            tex.append(res)
        tid = "t%d" % tex.index(res)
        n = img.width // 32
        for r, d in enumerate(DIRS):
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


for k, (folder, anims) in SETS.items():
    build(k, folder, anims)
