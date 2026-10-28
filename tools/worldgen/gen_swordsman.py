"""Copies the swordsman looks lvl1-9 into the project and builds one SpriteFrames .tres per look.
Rows: down, left, right, up. 64x64 frames; frame count is taken from each sheet's width."""
import glob, os, shutil
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = r"C:/Users/nicol/JobHunter_raw"
ROOT = "C:/Users/nicol/OneDrive/Documentos/JobHunter"
DIRS = ["down", "left", "right", "up"]
# (anim name, file key, fps, loop)
SHEETS = [("idle", "Idle", 8, True), ("walk", "Walk", 10, True), ("run", "Run", 12, True),
          ("attack", "attack", 16, False), ("walk_attack", "Walk_Attack", 14, False),
          ("run_attack", "Run_Attack", 16, False), ("hurt", "Hurt", 12, False), ("death", "Death", 10, False)]


def source_dir(lv):
    pack = "swordman" if lv <= 3 else ("ic_swordman_part2" if lv <= 6 else "ic_swordman_part3")
    return os.path.join(RAW, pack, "PNG", "Swordsman_lvl%d" % lv, "With_shadow")


def find_sheet(lv, key):
    fs = glob.glob(os.path.join(source_dir(lv), "*.png"))
    want = ("_%s_with_shadow.png" % key).lower()
    for f in fs:
        if os.path.basename(f).lower().endswith(want):
            return f
    raise FileNotFoundError((lv, key))


def build(lv):
    dst_dir = os.path.join(ROOT, "assets/sprites/characters/swordsman/lvl%d" % lv)
    os.makedirs(dst_dir, exist_ok=True)
    tex, subs, anims = [], [], []
    for name, key, fps, loop in SHEETS:
        src = find_sheet(lv, key)
        fname = "Swordsman_lvl%d_%s_with_shadow.png" % (lv, key)
        dst = os.path.join(dst_dir, fname)
        if not os.path.exists(dst):
            shutil.copy2(src, dst)
        img = Image.open(dst).convert("RGBA")
        n = img.width // 64
        res = "res://assets/sprites/characters/swordsman/lvl%d/%s" % (lv, fname)
        tex.append(res)
        tid = "t%d" % (len(tex) - 1)
        for r, d in enumerate(DIRS):
            refs = []
            for i in range(n):
                box = (i * 64, r * 64, i * 64 + 64, r * 64 + 64)
                if not img.crop(box).getbbox():
                    continue
                sid = "a%d" % len(subs)
                subs.append('[sub_resource type="AtlasTexture" id="%s"]\natlas = ExtResource("%s")\nregion = Rect2(%d, %d, 64, 64)\n' % (sid, tid, box[0], box[1]))
                refs.append('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % sid)
            anims.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s_%s",\n"speed": %d.0\n}' % (
                ", ".join(refs), "true" if loop else "false", name, d, fps))
    out = ['[gd_resource type="SpriteFrames" format=3]', ""]
    out += ['[ext_resource type="Texture2D" path="%s" id="t%d"]' % (p, i) for i, p in enumerate(tex)]
    out.append("")
    out += subs
    out.append("[resource]")
    out.append("animations = [%s]" % ", ".join(anims))
    with open(os.path.join(ROOT, "resources/sprite_frames/swordsman_lvl%d.tres" % lv), "w", encoding="utf-8", newline="\n") as f:
        from even_loops import even_loops   # the idle facing up has 4 frames, the rest 12
        f.write(even_loops("\n".join(out) + "\n"))
    print("lvl%d ok" % lv)


if __name__ == "__main__":
    for lv in range(4, 10):
        build(lv)
