"""The archer and the mage: copies their nine looks (lvl1-9) from the raw packs into the project and builds
one SpriteFrames .tres per look, with the same animation names as the swordsman (idle/walk/run/attack/
hurt/death per direction, plus walk_attack/run_attack = the attack, since these packs shoot standing).
Rows: down, left, right, up. 64x64 frames. Also copies the projectiles: the arrows and the fireball
(cycle + explosion) of the packs, as SpriteFrames for the game's projectile script."""
import glob, os, shutil
from PIL import Image
from even_loops import even_loops

RAW = r"C:/Users/nicol/JobHunter_raw"
ROOT = "C:/Users/nicol/OneDrive/Documentos/JobHunter"
DIRS = ["down", "left", "right", "up"]
# (anim name, file key, fps, loop)
SHEETS = {
    "archer": [("idle", "Idle", 8, True), ("walk", "Walk", 10, True), ("run", "Run", 12, True),
               ("attack", "Attack", 18, False), ("hurt", "Hurt", 12, False), ("death", "Death", 10, False)],
    "mage": [("idle", "Idle", 8, True), ("walk", "Walk", 10, True), ("run", "Run", 12, True),
             ("attack", "attack", 16, False), ("hurt", "Hurt", 12, False), ("death", "Death", 10, False)],
}


def source_dir(cls, lv):
    if cls == "archer":
        d = glob.glob(os.path.join(RAW, "archer", "PNG", "Archer_[Ll]vl%d" % lv))
        return d[0]
    return os.path.join(RAW, "mage", "PNG", "Mage_%dlvl" % lv, "With_shadow")


def find_sheet(cls, lv, key):
    for f in glob.glob(os.path.join(source_dir(cls, lv), "*.png")):
        b = os.path.basename(f).lower()
        if "without" in b:
            continue
        if ("_%s" % key.lower()) in b and b.endswith(".png"):
            return f
    raise FileNotFoundError((cls, lv, key))


def build(cls, lv):
    dst_dir = os.path.join(ROOT, "assets/sprites/characters/%s/lvl%d" % (cls, lv))
    os.makedirs(dst_dir, exist_ok=True)
    tex, subs, anims = [], [], []
    attack_refs = {}
    for name, key, fps, loop in SHEETS[cls]:
        src = find_sheet(cls, lv, key)
        fname = "%s_lvl%d_%s.png" % (cls.capitalize(), lv, key.lower())
        dst = os.path.join(dst_dir, fname)
        shutil.copy2(src, dst)
        img = Image.open(dst).convert("RGBA")
        n = img.width // 64
        res = "res://assets/sprites/characters/%s/lvl%d/%s" % (cls, lv, fname)
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
            if name == "attack":
                attack_refs[d] = (refs, fps)
    for alias in ("walk_attack", "run_attack"):
        for d in DIRS:
            refs, fps = attack_refs[d]
            anims.append('{\n"frames": [%s],\n"loop": false,\n"name": &"%s_%s",\n"speed": %d.0\n}' % (", ".join(refs), alias, d, fps))
    out = ['[gd_resource type="SpriteFrames" format=3]', ""]
    out += ['[ext_resource type="Texture2D" path="%s" id="t%d"]' % (p, i) for i, p in enumerate(tex)]
    out.append("")
    out += subs
    out.append("[resource]")
    out.append("animations = [%s]" % ", ".join(anims))
    with open(os.path.join(ROOT, "resources/sprite_frames/%s_lvl%d.tres" % (cls, lv)), "w", encoding="utf-8", newline="\n") as f:
        f.write(even_loops("\n".join(out) + "\n"))
    print(cls, "lvl%d ok" % lv)


def strip_frames(path, res, fw, fh, rows, fps, loop, names):
    """SpriteFrames from a sheet of `rows` rows (one animation per row, named `names`)."""
    img = Image.open(os.path.join(ROOT, path)).convert("RGBA")
    subs, anims = [], []
    for r in range(rows):
        refs = []
        for i in range(img.width // fw):
            box = (i * fw, r * fh, i * fw + fw, r * fh + fh)
            if not img.crop(box).getbbox():
                continue
            sid = "a%d" % len(subs)
            subs.append('[sub_resource type="AtlasTexture" id="%s"]\natlas = ExtResource("t0")\nregion = Rect2(%d, %d, %d, %d)\n' % (sid, box[0], box[1], fw, fh))
            refs.append('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % sid)
        anims.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %d.0\n}' % (", ".join(refs), "true" if loop else "false", names[r], fps))
    out = ['[gd_resource type="SpriteFrames" format=3]', "", '[ext_resource type="Texture2D" path="res://%s" id="t0"]' % path, ""]
    out += subs
    out += ["[resource]", "animations = [%s]" % ", ".join(anims)]
    with open(os.path.join(ROOT, res), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out) + "\n")


def projectiles():
    fx = os.path.join(ROOT, "assets/sprites/fx/classes")
    os.makedirs(fx, exist_ok=True)
    # arrows: one per look (they get fancier), 4 directions in a 112x32 strip (28x32 each)
    for lv in range(1, 10):
        src = os.path.join(source_dir("archer", lv), "Arrow.png")
        shutil.copy2(src, os.path.join(fx, "arrow_lvl%d.png" % lv))
    shutil.copy2(os.path.join(RAW, "mage/PNG/Fire/Fire_cycle.png"), os.path.join(fx, "fire_cycle.png"))
    shutil.copy2(os.path.join(RAW, "mage/PNG/Fire/Fire_explosion.png"), os.path.join(fx, "fire_explosion.png"))
    # the fireball flies in 4 rows (left, down, up, right): the game rotates the "right" one
    strip_frames("assets/sprites/fx/classes/fire_cycle.png", "resources/sprite_frames/fx_fireball.tres", 32, 32, 4, 14, True,
                 ["left", "down", "up", "right"])
    strip_frames("assets/sprites/fx/classes/fire_explosion.png", "resources/sprite_frames/fx_fire_explosion.tres", 64, 64, 1, 18, False,
                 ["default"])
    # skill effects: lightning (Frostwindz pack) and explosions (explosion pack 1)
    L = os.path.join(RAW, "vfx_lightning")
    E = os.path.join(RAW, "vfx_explosions", "explosion pack 1", "Explosions pack")
    for src, dst, fw, fh, fps in [(os.path.join(L, "VFX3/Sprite-sheet/Sprite-sheet.png"), "lightning_strike", 128, 256, 14),
                                  (os.path.join(L, "VFX1/Sprite-sheet/Sprite-sheet.png"), "lightning_bolt", 256, 128, 16),
                                  (os.path.join(L, "VFX5/Sprite-sheet/Sprite-sheet.png"), "lightning_ring", 128, 128, 12),
                                  (os.path.join(E, "explosion-1-c/spritesheet.png"), "explosion_big", 80, 80, 20),
                                  (os.path.join(E, "explosion-1-b/spritesheet.png"), "explosion_small", 64, 64, 18)]:
        shutil.copy2(src, os.path.join(fx, dst + ".png"))
        strip_frames("assets/sprites/fx/classes/%s.png" % dst, "resources/sprite_frames/fx_%s.tres" % dst, fw, fh, 1, fps, False, ["default"])
    print("projectiles ok")


if __name__ == "__main__":
    for cls in ("archer", "mage"):
        for lv in range(1, 10):
            build(cls, lv)
    projectiles()
