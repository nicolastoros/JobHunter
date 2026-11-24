"""Shared art for the snowy regions (Bosque Nevado, Villa Escarcha) and the new beasts:
- snow copies of the field's tile sheets (ground, details, shores, water turned icy),
- the snow_forest / snow_village packs registered in the prop catalog, snowy versions of the houses,
- recoloured monster packs (ice slimes, frost goblins, yetis, ice ents & golems, frost wolves...)
  and the beasts made from the animals pack (boar, wolves)."""
import colorsys, glob, os, shutil
from PIL import Image
import w_common as C
from w_common import RAW, ROOT, FG, GD, WD
import w_props as WP
import w_coast  # noqa: F401  (registers the field shore sheet FWCG)
from w_coast import FWCG
import w_field as WF

# ---------------------------------------------------------------- snow tile sheets
SNOW_FG, SNOW_GD, SNOW_SHORE, SNOW_WD = 17, 18, 19, 20
REMAP = {FG: SNOW_FG, GD: SNOW_GD, FWCG: SNOW_SHORE, WD: SNOW_WD}


def _ramp(im, test, lo, hi, v0=0.25, span=0.6, rect=None):
    px = im.load()
    x0, y0, x1, y1 = rect or (0, 0, im.width, im.height)
    for y in range(y0, y1):
        for x in range(x0, x1):
            r, g, b, a = px[x, y]
            if not a:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if test(h, s, v):
                t = min(1.0, max(0.0, (v - v0) / span))
                px[x, y] = tuple(int(lo[i] + (hi[i] - lo[i]) * t) for i in range(3)) + (a,)
    return im


GREEN = lambda h, s, v: 0.14 <= h <= 0.48 and s > 0.15
WARM = lambda h, s, v: h <= 0.13 and s > 0.2
ANY_BLUE = lambda h, s, v: 0.45 <= h <= 0.7


def _make(src_rel, dst_rel, steps):
    im = Image.open(os.path.join(RAW, src_rel)).convert("RGBA")
    for st in steps:
        _ramp(im, *st)
    os.makedirs(os.path.dirname(os.path.join(RAW, dst_rel)), exist_ok=True)
    im.save(os.path.join(RAW, dst_rel))


SNOW_LO, SNOW_HI = (168, 184, 206), (248, 251, 255)
_make(C.SOURCES[FG][0], "snow_gen/ground_snow.png", [(GREEN, SNOW_LO, SNOW_HI),
      (WARM, (128, 132, 150), (196, 204, 220), 0.3, 0.5, (19 * 16, 16, 24 * 16, 4 * 16))])   # paths: packed snow
_make(C.SOURCES[GD][0], "snow_gen/details_snow.png", [(GREEN, (190, 204, 222), (250, 252, 255))])
_make(C.SOURCES[FWCG][0], "snow_gen/shore_snow.png", [(GREEN, SNOW_LO, SNOW_HI)])
_make(C.SOURCES[WD][0], "snow_gen/water_ice.png", [(ANY_BLUE, (120, 170, 205), (214, 236, 248), 0.3, 0.6)])
for sid, dst in ((SNOW_FG, "ground_snow"), (SNOW_GD, "details_snow"), (SNOW_SHORE, "shore_snow"), (SNOW_WD, "water_ice")):
    C.SOURCES[sid] = ("snow_gen/%s.png" % dst, "assets/sprites/snow/tiles/%s.png" % dst)
C.ANIM_ALIAS[SNOW_SHORE] = C.WC
C.ANIM_ALIAS[SNOW_WD] = WD
C.ANIM_ALIAS[SNOW_FG] = FG
C.ANIM_ALIAS[SNOW_GD] = GD


def remap_to_snow(w):
    """Everything drawn with the grass/water sheets now uses their snowy copies."""
    for name, cells in w.layers.items():
        for c, (src, at, alt) in list(cells.items()):
            if src in REMAP:
                cells[c] = (REMAP[src], at, alt)
    for (src, at), kind in list(w.collide.items()):
        if src in REMAP:
            w.collide[(REMAP[src], at)] = kind


# ---------------------------------------------------------------- props from the snow packs
WP.SHEETS["snowf"] = ("snow_forest/All Tileset/16X16.png", "assets/sprites/snow/snow_forest.png")
WP.SHEETS["snowv"] = ("snow_village/All Tileset/16X16.png", "assets/sprites/snow/snow_village.png")
add = WP.add
for k, r in {"sn_tree_big": (128, 1, 176, 63), "sn_tree_round": (176, 9, 224, 60), "sn_dead": (224, 6, 253, 63), "sn_dead2": (261, 12, 282, 60),
             "sn_pine": (129, 66, 176, 127), "sn_pine_green": (177, 66, 224, 127)}.items():
    add(k, "snowf", r, "tree")
for k, r in {"sn_rock": (17, 2, 30, 15), "sn_rock2": (38, 7, 57, 25), "sn_snowman": (4, 38, 28, 77), "sn_tomb": (39, 34, 58, 62),
             "sn_tomb2": (70, 32, 91, 64), "sn_tomb3": (39, 66, 58, 94), "sn_stump": (293, 42, 314, 60), "sn_crystal": (98, 65, 109, 95)}.items():
    add(k, "snowf", r)
for k, r in {"sn_grass": (69, 1, 91, 47), "sn_grass2": (101, 1, 123, 47), "sn_bush": (96, 48, 112, 64), "sn_bush2": (112, 48, 128, 64),
             "sn_twig": (97, 97, 112, 111), "sn_twig2": (113, 96, 127, 112), "sn_stick": (99, 116, 128, 123), "sn_drops": (113, 64, 127, 80)}.items():
    add(k, "snowf", r, None)
add("sv_well", "snowv", (208, 84, 240, 122))
add("sv_well2", "snowv", (240, 84, 272, 122))
add("sv_vase", "snowv", (241, 148, 255, 173))
add("sv_sign", "snowv", (5, 216, 43, 224), None)
add("sv_fire_off", "snowv", (273, 88, 304, 126))
SNOW_TREES = ["sn_pine", "sn_pine", "sn_pine", "sn_tree_big", "sn_tree_round", "sn_pine_green", "sn_dead"]
SNOW_SMALL = ["sn_grass", "sn_grass2", "sn_bush", "sn_bush2", "sn_twig", "sn_twig2", "sn_stick", "sn_drops"]
SNOW_ROCKS = ["sn_rock", "sn_rock2", "gl_rock", "gl_rock2", "gl_stone", "rock_s1", "sn_stump"]
VILLAGE = os.path.join(RAW, "snow_village/All Tileset/16X16.png")


# ---------------------------------------------------------------- snowy houses
def _snow_cap(img):
    """Snow on a building: a white cap following the top of the silhouette, frost on the roof."""
    px = img.load()
    w, h = img.size
    tops = []
    for x in range(w):
        y = next((yy for yy in range(h) if px[x, yy][3] > 200), None)
        tops.append(y)
    import random
    rng = random.Random(w * 31 + h)
    for x in range(w):
        y0 = tops[x]
        if y0 is None:
            continue
        depth = 3 + int(2 * abs(((x * 7) % 11) / 11 - 0.5)) + rng.randint(0, 2)
        for yy in range(y0, min(h, y0 + depth)):
            if px[x, yy][3] > 200:
                px[x, yy] = (245, 249, 255, 255) if yy < y0 + depth - 1 else (206, 220, 236, 255)
        # frost: lighten the roof area (upper part of the sprite)
        for yy in range(y0 + depth, min(h, y0 + int(h * 0.42))):
            r, g, b, a = px[x, yy]
            if a > 200 and rng.random() < 0.5:
                px[x, yy] = (int(r + (235 - r) * 0.45), int(g + (242 - g) * 0.45), int(b + (252 - b) * 0.45), a)
        # a few icicles under the eaves
    return img


SNOW_HOUSES = ["house_red", "farmhouse", "fish_house", "fish_house2", "barn", "shed", "longshed"]


def bake_snow(out_rel="assets/sprites/snow/snow_buildings.png"):
    """Snowy copies of the houses (s_<key>) + the village cabin with its door and windows (sv_cabin, sv_cabin_lit)."""
    parts = []
    for k in SNOW_HOUSES:
        p = WP.P[k]
        img = Image.open(WP.sheet_image_path(p["sheet"])).convert("RGBA").crop(p["rect"])
        parts.append(("s_" + k, _snow_cap(img), p["feet"]))
    v = Image.open(VILLAGE).convert("RGBA")
    for key, door, lit in (("sv_cabin", (27, 156, 53, 192), False), ("sv_cabin_lit", (75, 204, 101, 240), True)):
        cab = v.crop((0, 8, 96, 144)).copy()
        d = v.crop(door)
        cab.alpha_composite(d, ((96 - d.width) // 2, 136 - d.height))
        win = v.crop((225, 160, 239, 183) if lit else (209, 160, 223, 183))
        for wx in (14, 96 - 14 - win.width):
            cab.alpha_composite(win, (wx, 136 - win.height - 8))
        parts.append((key, cab, [(4, 104, 92, 134)]))
    pad = 2
    W = sum(i.width + pad for _, i, _ in parts) + pad
    H = max(i.height for _, i, _ in parts) + 2 * pad
    atlas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    x = pad
    for key, img, feet in parts:
        atlas.alpha_composite(img, (x, pad))
        WP.P[key] = dict(sheet="snowbaked", rect=(x, pad, x + img.width, pad + img.height), feet=feet)
        x += img.width + pad
    WP.SHEETS["snowbaked"] = (None, out_rel)
    dst = os.path.join(ROOT, out_rel)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    atlas.save(dst)
    for k in SNOW_HOUSES:
        if k in WP.DOOR_X:
            WP.DOOR_X["s_" + k] = WP.DOOR_X[k]
    WP.DOOR_X["sv_cabin"] = 48
    WP.DOOR_X["sv_cabin_lit"] = 48


# ---------------------------------------------------------------- monsters
def _hue_map(img, rng_lo, rng_hi, hue, sat=1.0, val=1.0, min_s=0.18):
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a < 200:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            inside = rng_lo <= h <= rng_hi if rng_lo <= rng_hi else (h >= rng_lo or h <= rng_hi)
            if s < min_s or not inside:
                continue
            nr, ng, nb = colorsys.hsv_to_rgb(hue, min(1.0, s * sat), min(1.0, v * val))
            px[x, y] = (int(nr * 255), int(ng * 255), int(nb * 255), a)
    return img


def recolor_pack(src_pack, dst_pack, kinds, rules):
    for kind in kinds:
        src_dir = os.path.join(RAW, src_pack, "PNG", kind, "With_shadow")
        dst_dir = os.path.join(RAW, dst_pack, "PNG", kind, "With_shadow")
        os.makedirs(dst_dir, exist_ok=True)
        for f in glob.glob(os.path.join(src_dir, "*.png")):
            im = Image.open(f).convert("RGBA")
            for rule in rules:
                im = _hue_map(im, *rule)
            im.save(os.path.join(dst_dir, os.path.basename(f)))


ICE = 0.55
recolor_pack("mon_slimes_01", "mon_snow_slimes", ["Slime1", "Slime2", "Slime3"], [(0.0, 1.0, ICE, 0.45, 1.18)])
recolor_pack("mon_goblin_mobs01", "mon_snow_goblins", ["Goblin1", "Goblin2", "Goblin3"], [(0.11, 0.5, 0.56, 0.6, 1.25)])
recolor_pack("mon_gnolls_mobs01", "mon_snow_yetis", ["Gnoll1", "Gnoll2", "Gnoll3"], [(0.9, 0.16, 0.58, 0.12, 1.55, 0.08)])
recolor_pack("mon_golem_bosses01", "mon_snow_golems", ["Golem2"], [(0.7, 0.95, ICE, 0.9, 1.15), (0.0, 0.16, 0.6, 0.25, 1.4, 0.05)])
recolor_pack("mon_ent_bosses_01", "mon_snow_ents", ["Ent3"], [(0.15, 0.48, 0.53, 0.35, 1.45), (0.93, 0.13, 0.6, 0.25, 1.15, 0.1)])
recolor_pack("mon_ent_bosses_01", "mon_snow_ents", ["Ent1"], [(0.93, 0.13, 0.57, 0.3, 1.9, 0.1), (0.15, 0.48, 0.53, 0.5, 1.5)])
recolor_pack("mon_slimes02", "mon_snow_kings", ["Slime_boss1"], [(0.0, 1.0, ICE, 0.55, 1.2)])
recolor_pack("mon_ent_bosses_01", "mon_dry_ents", ["Ent2"], [(0.15, 0.48, 0.07, 0.7, 0.95)])


def _fur(img, ramp):
    """Warm fur -> a ramp between two colours, keeping the shading (as the pet recolours)."""
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


def beast_pack(dst_pack, kind, src_folder, files, ramp=None, swap_lr=()):
    """A monster made from the animals pack: idle/walk/run/attack/hurt/death sheets (32 px cells).
    files: {anim: source file stem}; the fox's run comes with left/right rows swapped."""
    dst_dir = os.path.join(RAW, dst_pack, "PNG", kind, "With_shadow")
    os.makedirs(dst_dir, exist_ok=True)
    for anim, stem in files.items():
        src = os.path.join(RAW, "animals", "PNG", "With_Shadow", src_folder, stem + "_with_shadow.png")
        im = Image.open(src).convert("RGBA")
        if stem in swap_lr:
            a = im.crop((0, 64, im.width, 96)); b = im.crop((0, 96, im.width, 128))
            im.paste(b, (0, 64)); im.paste(a, (0, 96))
        if ramp:
            im = _fur(im, ramp)
        im.save(os.path.join(dst_dir, "%s_%s_with_shadow.png" % (kind, anim)))


# (the hurt / death sheets of the animals pack are lost: the idle pose stands in; dead monsters fade out anyway)
FOX = {"idle": "Fox_Idle", "walk": "Fox_walk", "run": "Fox_Run", "attack": "Fox_Run", "hurt": "Fox_Idle", "death": "Fox_Idle"}
beast_pack("mon_beasts", "Boar", "Boar", {"idle": "Boar_Idle", "walk": "Boar_Walk", "run": "Boar_Run", "attack": "Boar_Attack", "hurt": "Boar_Idle", "death": "Boar_Idle"})
beast_pack("mon_beasts", "Wolf", "Fox", FOX, ((44, 44, 56), (178, 180, 192)), swap_lr=("Fox_Run",))
beast_pack("mon_beasts", "Frostwolf", "Fox", FOX, ((86, 98, 130), (246, 250, 255)), swap_lr=("Fox_Run",))
import gen_beast_anims  # noqa: E402,F401  (real hurt / death animations, built from the idle pose)

WF.MON.update({
    # new beasts on the existing maps
    "boar": dict(pack="mon_beasts", kinds=["Boar"], name="Jabalí salvaje", props=dict(max_hp=9, damage=2, speed=20, chase_speed=58, aggro_radius=90, attack_range=18, gold=4, territory=100, sprite_scale=1.0)),
    "wolf": dict(pack="mon_beasts", kinds=["Wolf"], name="Lobo del bosque", props=dict(max_hp=11, damage=3, speed=26, chase_speed=64, aggro_radius=110, attack_range=18, gold=7, territory=110, sprite_scale=1.3, body_size="Vector2(16, 6)")),
    "withered": dict(pack="mon_dry_ents", kinds=["Ent2"], name="Árbol marchito", props=dict(max_hp=16, damage=3, speed=11, chase_speed=24, aggro_radius=88, attack_range=20, gold=10, territory=70, sprite_scale=0.6, body_size="Vector2(14, 6)")),
    # snow
    "frost_slime": dict(pack="mon_snow_slimes", kinds=["Slime1", "Slime2", "Slime3"], name="Limo de escarcha", props=dict(max_hp=9, damage=2, speed=16, chase_speed=32, aggro_radius=82, attack_range=15, gold=7, territory=90)),
    "frost_goblin": dict(pack="mon_snow_goblins", kinds=["Goblin1", "Goblin2", "Goblin3"], name="Trasgo helado", props=dict(max_hp=12, damage=3, speed=24, chase_speed=50, aggro_radius=104, attack_range=18, gold=9, territory=100)),
    "frost_wolf": dict(pack="mon_beasts", kinds=["Frostwolf"], name="Lobo de escarcha", props=dict(max_hp=13, damage=3, speed=28, chase_speed=68, aggro_radius=120, attack_range=18, gold=10, territory=120, sprite_scale=1.35, body_size="Vector2(16, 6)")),
    "yeti": dict(pack="mon_snow_yetis", kinds=["Gnoll1", "Gnoll2", "Gnoll3"], name="Yeti", props=dict(max_hp=16, damage=4, speed=22, chase_speed=50, aggro_radius=110, attack_range=22, gold=12, territory=110, sprite_scale=1.25, body_size="Vector2(16, 7)")),
    "ice_ent": dict(pack="mon_snow_ents", kinds=["Ent3"], name="Ent helado", props=dict(max_hp=18, damage=4, speed=11, chase_speed=26, aggro_radius=96, attack_range=22, gold=13, territory=80, sprite_scale=0.72, body_size="Vector2(18, 7)")),
    "ice_golem": dict(pack="mon_snow_golems", kinds=["Golem2"], name="Gólem de hielo", props=dict(max_hp=19, damage=4, speed=12, chase_speed=24, aggro_radius=90, attack_range=22, gold=14, territory=70, sprite_scale=0.6, body_size="Vector2(16, 7)")),
    "winter_ent": dict(pack="mon_snow_ents", kinds=["Ent1"], name="Ent Invernal", props=dict(max_hp=80, damage=5, speed=10, chase_speed=20, aggro_radius=130, attack_range=32, gold=140, territory=80, boss="true", respawn_time=220, body_size="Vector2(30, 10)")),
    "frost_king": dict(pack="mon_snow_kings", kinds=["Slime_boss1"], name="Rey Limo de Escarcha", props=dict(max_hp=70, damage=4, speed=14, chase_speed=26, aggro_radius=120, attack_range=30, gold=130, territory=80, boss="true", respawn_time=220, body_size="Vector2(32, 12)")),
})


# ---------------------------------------------------------------- the eclipse (story's end)
VIOLET = 0.77
recolor_pack("mon_golem_bosses01", "mon_eclipse", ["Golem2"], [(0.0, 1.0, VIOLET, 1.0, 0.85)])
recolor_pack("mon_golem_bosses01", "mon_eclipse", ["Golem3"], [(0.45, 0.75, VIOLET, 1.0, 0.95), (0.0, 0.16, 0.13, 1.1, 1.25)])
recolor_pack("mon_slimes_01", "mon_eclipse_slimes", ["Slime1", "Slime2", "Slime3"], [(0.0, 1.0, VIOLET, 0.8, 0.7)])
WF.MON.update({
    "eclipse_golem": dict(pack="mon_eclipse", kinds=["Golem2"], name="Gólem del Eclipse", props=dict(max_hp=22, damage=5, speed=13, chase_speed=26, aggro_radius=100, attack_range=22, gold=16, territory=70, sprite_scale=0.62, body_size="Vector2(16, 7)")),
    "umbral_slime": dict(pack="mon_eclipse_slimes", kinds=["Slime1", "Slime2", "Slime3"], name="Limo umbrío", props=dict(max_hp=12, damage=3, speed=18, chase_speed=36, aggro_radius=90, attack_range=15, gold=10, territory=90)),
    "devourer": dict(pack="mon_eclipse", kinds=["Golem3"], name="Devorador de Eclipses", props=dict(max_hp=180, damage=7, speed=14, chase_speed=26, aggro_radius=400, attack_range=36, gold=500, territory=400, boss="true", respawn_time=99999, sprite_scale=1.45, body_size="Vector2(40, 12)")),
})


# ---------------------------------------------------------------- the Twilight Wastes (post-game)
## The land the Eclipse poisoned, east of Aurelia: the Black Sun cultists and the beasts it twisted.
DUSK = 0.8
recolor_pack("mon_goblin_mobs01", "mon_dusk_cult", ["Goblin1", "Goblin2", "Goblin3"],
             [(0.15, 0.48, DUSK, 0.75, 0.75), (0.0, 0.14, 0.97, 1.0, 0.9)])                       # violet skin, blood-red cloth
recolor_pack("mon_gnolls_mobs01", "mon_dusk_gnolls", ["Gnoll1", "Gnoll2", "Gnoll3"], [(0.0, 0.2, 0.74, 0.55, 0.65, 0.12)])
recolor_pack("mon_ent_bosses_01", "mon_dusk_ents", ["Ent3"], [(0.15, 0.48, 0.86, 0.6, 0.75), (0.93, 0.13, 0.75, 0.25, 0.7, 0.1)])
recolor_pack("mon_ent_bosses_01", "mon_dusk_ents", ["Ent1"], [(0.15, 0.48, 0.9, 0.85, 0.8), (0.93, 0.13, 0.76, 0.35, 0.6, 0.1)])
recolor_pack("mon_golem_bosses01", "mon_dusk_herald", ["Golem1"], [(0.0, 1.0, 0.98, 1.0, 0.55, 0.12)])   # the herald: black stone, red veins
beast_pack("mon_beasts", "Duskwolf", "Fox", FOX, ((34, 18, 52), (156, 104, 196)), swap_lr=("Fox_Run",))
gen_beast_anims.build("Duskwolf")   # hurt / death for the new wolf too
WF.MON.update({
    "dusk_cultist": dict(pack="mon_dusk_cult", kinds=["Goblin1", "Goblin2", "Goblin3"], name="Acólito del Sol Negro", props=dict(max_hp=14, damage=4, speed=24, chase_speed=52, aggro_radius=110, attack_range=18, gold=14, territory=100)),
    "dusk_gnoll": dict(pack="mon_dusk_gnolls", kinds=["Gnoll1", "Gnoll2", "Gnoll3"], name="Gnoll del Ocaso", props=dict(max_hp=17, damage=4, speed=22, chase_speed=50, aggro_radius=110, attack_range=20, gold=15, territory=110, sprite_scale=1.15, body_size="Vector2(16, 7)")),
    "dusk_wolf": dict(pack="mon_beasts", kinds=["Duskwolf"], name="Lobo del Ocaso", props=dict(max_hp=15, damage=4, speed=30, chase_speed=72, aggro_radius=125, attack_range=18, gold=14, territory=120, sprite_scale=1.35, body_size="Vector2(16, 6)")),
    "dusk_ent": dict(pack="mon_dusk_ents", kinds=["Ent3"], name="Ent corrupto", props=dict(max_hp=21, damage=5, speed=11, chase_speed=26, aggro_radius=96, attack_range=22, gold=17, territory=80, sprite_scale=0.75, body_size="Vector2(18, 7)")),
    "dusk_elder": dict(pack="mon_dusk_ents", kinds=["Ent1"], name="Ent Corrupto Anciano", props=dict(max_hp=95, damage=6, speed=10, chase_speed=20, aggro_radius=130, attack_range=32, gold=200, territory=80, boss="true", respawn_time=240, body_size="Vector2(30, 10)")),
    "dusk_herald": dict(pack="mon_dusk_herald", kinds=["Golem1"], name="Heraldo del Sol Negro", props=dict(max_hp=160, damage=7, speed=14, chase_speed=28, aggro_radius=400, attack_range=34, gold=450, territory=400, boss="true", respawn_time=99999, sprite_scale=1.3, body_size="Vector2(36, 12)")),
})
