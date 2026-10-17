"""Prop catalog: sprite regions on each sheet + ground footprints (collision) in local px."""
import os
from PIL import Image
from w_common import RAW, ROOT

# sheet key -> (raw path, project path)
SHEETS = {
    "mk_obj": ("market/PNG/Objects.png", "assets/sprites/market/props/Objects.png"),
    "mk_single": ("market/PNG/Objects_single.png", "assets/sprites/market/props/Objects_single.png"),
    "ext": ("house/PNG/exterior.png", "assets/sprites/nature/exterior.png"),
    "houses": ("farm/Tiled_files/Houses.png", "assets/sprites/farm/props/Houses.png"),
    "objout": ("farm/Tiled_files/Objects_outside.png", "assets/sprites/farm/props/Objects_outside.png"),
    "trees": ("farm/Tiled_files/trees.png", "assets/sprites/farm/props/trees.png"),
    "plants": ("farm/Tiled_files/Plants.png", "assets/sprites/farm/props/Plants.png"),
    "fish": ("fishing/Tiled_foles/Exterior_objetcs.png", "assets/sprites/port/props/Exterior_objetcs.png"),
    "train": ("training/Tiled_files/Objects.png", "assets/sprites/training/props/Objects.png"),
    "baked": (None, "assets/sprites/city/baked_buildings.png"),
    "guild": (None, "assets/sprites/city/guild_hall.png"),
}


def tree_feet(w, h, base=6):
    return [(int(w * 0.36), h - base - 8, int(w * 0.64), h - base)]


def bush_feet(w, h):
    return [(int(w * 0.12), int(h * 0.45), int(w * 0.88), h - 2)]


def low_feet(w, h, frac=0.55):
    return [(1, int(h * (1 - frac)), w - 1, h - 1)]


P = {}


def add(key, sheet, rect, feet="low", **kw):
    x0, y0, x1, y1 = rect
    w, h = x1 - x0, y1 - y0
    if feet == "low":
        feet = low_feet(w, h)
    elif feet == "tree":
        feet = tree_feet(w, h)
    elif feet == "bush":
        feet = bush_feet(w, h)
    P[key] = dict(sheet=sheet, rect=rect, feet=feet, **kw)


# ---- Market (from the first iteration) ------------------------------------
M = "mk_obj"
add("weapon_stall", M, (14, 0, 140, 135), [(14, 92, 124, 131)])
add("blue_tent", M, (159, 32, 268, 144), [(4, 96, 12, 104), (60, 104, 68, 112), (88, 88, 96, 96)])
add("fruit_stall", M, (11, 152, 122, 249), [(2, 40, 109, 96)])
add("fruit_small", M, (137, 160, 223, 222), [(2, 24, 84, 62)])
add("fruit_crates", M, (235, 158, 346, 217), [(8, 22, 108, 58)])
add("bread_stall", M, (105, 260, 183, 325), [(2, 30, 76, 64)])
add("pastry_stall", M, (201, 276, 279, 325), [(2, 20, 76, 49)])
add("cloth_stall", M, (290, 276, 355, 318), [(0, 18, 65, 41)])
add("empty_stall", M, (9, 264, 95, 334), [(4, 34, 84, 69)])
add("magic_tent", M, (8, 393, 106, 512), [(4, 70, 98, 116)])
add("magic_table", M, (175, 516, 233, 551), [(0, 10, 58, 34)])
add("magic_stall", M, (343, 434, 413, 503), [(0, 34, 70, 68)])
add("sword_table", M, (238, 6, 282, 32), [(0, 6, 44, 25)])
add("red_table", M, (158, 6, 202, 32), [(0, 6, 44, 25)])
add("potion_cart", M, (0, 519, 73, 575), [(14, 30, 73, 54)])
add("cart", M, (80, 530, 151, 575), [(2, 18, 71, 44)])
add("green_canopy", M, (8, 339, 105, 370), None)
for k, r in (("table_a", (171, 345, 198, 372)), ("table_b", (267, 345, 294, 372)), ("table_c", (123, 358, 150, 385)), ("table_d", (219, 358, 246, 385))):
    add(k, M, r, [(2, 12, 25, 26)])
add("stool", M, (161, 356, 170, 369), None)
add("orb", M, (333, 322, 360, 352), [(3, 18, 24, 29)])
add("crates_a", M, (289, 1, 347, 40), [(0, 12, 58, 39)])
add("crates_b", M, (424, 7, 476, 55), [(0, 18, 52, 47)])
add("crates_c", M, (385, 145, 451, 185), [(0, 12, 66, 39)])
add("crates_d", M, (378, 257, 416, 310), [(0, 22, 38, 52)])
add("barrels_a", M, (421, 298, 462, 332), [(0, 14, 41, 33)])
add("crates_e", M, (368, 344, 424, 374), [(0, 10, 56, 29)])
add("crates_f", M, (336, 370, 381, 417), [(0, 18, 45, 46)])
add("barrel_big", M, (321, 517, 357, 565), [(2, 22, 34, 47)])
add("banner", M, (446, 92, 469, 138), [(7, 40, 16, 46)])
add("armor_a", M, (370, 13, 387, 41), [(2, 20, 15, 28)])
add("armor_b", M, (388, 13, 407, 41), [(2, 20, 17, 28)])
add("armor_c", M, (375, 109, 392, 137), [(2, 20, 15, 28)])
add("armor_flag", M, (367, 54, 392, 85), [(4, 22, 21, 31)])
add("weapon_rack", M, (285, 97, 353, 135), [(0, 24, 68, 38)])
add("bench", M, (288, 60, 351, 85), [(0, 12, 63, 25)])
add("rug", M, (415, 394, 465, 455), "floor")
S = "mk_single"
add("sack", S, (97, 33, 112, 47), [(1, 6, 14, 14)])
add("sack2", S, (113, 33, 128, 47), [(1, 6, 14, 14)])
add("barrel", S, (99, 116, 112, 139), [(0, 12, 13, 24)])
add("barrel2", S, (130, 116, 143, 139), [(0, 12, 13, 24)])
add("crate", S, (3, 48, 28, 80), [(0, 14, 25, 32)])
add("crate2", S, (35, 48, 60, 80), [(0, 14, 25, 32)])
add("pot", S, (149, 116, 168, 137), [(2, 10, 17, 21)])
add("jar", S, (181, 120, 189, 137), None)
add("big_barrel", S, (1, 2, 30, 43), [(1, 20, 28, 41)])
add("melons", S, (214, 4, 233, 27), [(1, 10, 18, 22)])

# ---- House asset (nature) --------------------------------------------------
E = "ext"
add("house_red", E, (14, 0, 147, 125), [(2, 84, 131, 124)])
add("well", E, (1, 498, 36, 539), [(1, 18, 35, 40)])
add("well_grass", E, (48, 498, 86, 536), [(3, 16, 35, 36)])
add("tree_apple", E, (1, 324, 62, 397), "tree")
add("tree_round", E, (65, 320, 127, 398), "tree")
add("tree_apple2", E, (135, 336, 186, 400), "tree")
add("tree_oak", E, (155, 467, 227, 544), "tree")
add("tree_oak2", E, (179, 558, 236, 623), "tree")
add("tree_small", E, (164, 192, 217, 256), "tree")
add("tree_young", E, (198, 272, 237, 319), "tree")
add("pine", E, (3, 610, 46, 653), "tree")
add("pine_small", E, (49, 626, 78, 653), "tree")
add("bush", E, (198, 358, 234, 395), "bush")
add("bush_berry", E, (209, 134, 239, 174), "bush")
add("bush_round", E, (194, 322, 221, 349), "bush")
add("bush_a", E, (2, 178, 47, 223), "bush")
add("bush_b", E, (3, 227, 46, 271), "bush")
add("bush_c", E, (124, 545, 165, 587), "bush")
add("rock_big", E, (1, 656, 54, 719), [(4, 34, 50, 60)])
add("rock_big2", E, (69, 656, 122, 716), [(4, 32, 49, 57)])
add("rock_tall", E, (132, 672, 170, 717), [(3, 24, 35, 43)])
add("rock_tall2", E, (179, 672, 219, 719), [(3, 25, 37, 45)])
add("rock_s1", E, (7, 726, 39, 760), [(3, 16, 29, 32)])
add("rock_s2", E, (56, 726, 86, 758), [(3, 16, 27, 30)])
add("stump", E, (101, 731, 138, 759), [(5, 12, 32, 26)])
add("stump2", E, (161, 288, 192, 319), [(4, 14, 27, 29)])
add("log", E, (85, 630, 124, 652), [(2, 6, 36, 20)])
add("mushrooms", E, (138, 595, 158, 623), None)
add("mushroom_big", E, (64, 548, 96, 589), [(10, 28, 22, 39)])
add("scarecrow", E, (4, 547, 56, 603), [(20, 46, 32, 55)])
add("stone_blue", E, (213, 729, 239, 759), [(3, 14, 26, 28)])
add("stone_blue2", E, (178, 729, 207, 759), [(3, 14, 26, 28)])
for i, r in enumerate([(149, 408, 168, 424), (185, 409, 203, 426), (213, 406, 233, 425), (115, 409, 141, 429), (84, 406, 106, 426)]):
    add("pebbles%d" % i, E, r, None)
for i, r in enumerate([(128, 775, 144, 798), (160, 771, 176, 782), (192, 768, 208, 784), (182, 784, 201, 800), (212, 770, 220, 783), (149, 774, 158, 792)]):
    add("flower%d" % i, E, r, None)

# ---- Farm buildings ----------------------------------------------------------
Hs = "houses"
add("farmhouse", Hs, (277, 16, 402, 141), [(4, 74, 121, 124)])
add("barn", Hs, (403, 12, 494, 95), [(2, 38, 89, 82)])
add("shed", Hs, (128, 6, 208, 80), [(0, 26, 80, 73)])
add("longshed", Hs, (133, 96, 204, 144), [(3, 14, 68, 46)])
add("coop", Hs, (229, 16, 265, 76), [(2, 30, 34, 59)])
add("coop2", Hs, (421, 208, 457, 268), [(2, 30, 34, 59)])
add("mill", Hs, (83, 158, 148, 288), [(6, 88, 59, 129)])
add("flowerbox", Hs, (240, 123, 257, 137), None)
add("waterbox", Hs, (240, 91, 257, 105), None)
add("porch", Hs, (15, 256, 80, 288), [(0, 8, 65, 31)])
add("doors_big", Hs, (8, 307, 57, 332), None)

# ---- Farm outdoor trees & bushes -------------------------------------------
O = "objout"
add("tree_big", O, (17, 18, 80, 96), "tree")
add("tree_mid", O, (80, 30, 128, 96), "tree")
add("tree_sm", O, (129, 64, 159, 96), "tree")
add("pine_big", O, (181, 21, 252, 95), "tree")
add("pine_mid", O, (258, 32, 317, 94), "tree")
add("pine_sm", O, (324, 54, 363, 93), "tree")
add("tree_light", O, (385, 16, 446, 96), "tree")
add("tree_light2", O, (451, 22, 504, 91), "tree")
add("tree_light3", O, (517, 48, 556, 96), "tree")
add("tree_bushy", O, (19, 101, 77, 171), "tree")
add("tree_bushy2", O, (87, 116, 139, 174), "tree")
add("tree_bushy3", O, (153, 136, 184, 171), "tree")
for i, r in enumerate([(198, 115, 234, 152), (245, 116, 282, 154), (294, 118, 330, 152), (340, 119, 380, 155),
                       (385, 98, 414, 126), (419, 101, 444, 125), (448, 96, 479, 128), (483, 100, 509, 125),
                       (517, 100, 541, 125), (406, 128, 441, 160), (450, 130, 477, 157), (485, 131, 507, 156)]):
    add("shrub%d" % i, O, r, "bush")
for i, r in enumerate([(544, 97, 560, 112), (545, 113, 560, 144), (517, 135, 538, 154), (544, 144, 558, 160)]):
    add("weed%d" % i, O, r, None)

# ---- Orchard trees (trees.png) -------------------------------------------
Tr = "trees"
add("orchard_green", Tr, (133, 14, 184, 78), "tree")
add("orchard_apple", Tr, (197, 14, 248, 78), "tree")
add("orchard_green2", Tr, (131, 94, 184, 160), "tree")
add("orchard_orange", Tr, (195, 94, 248, 160), "tree")
add("orchard_dense", Tr, (131, 174, 187, 239), "tree")
add("orchard_lemon", Tr, (195, 174, 251, 239), "tree")
add("orchard_bush", Tr, (133, 254, 185, 318), "tree")
add("orchard_cherry", Tr, (197, 254, 249, 318), "tree")
add("sapling", Tr, (78, 27, 114, 78), "tree")
add("sapling2", Tr, (77, 109, 116, 158), "tree")

# ---- Crops (no collision; fields are fenced) --------------------------------
Pl = "plants"
for k, r in {"cabbage": (69, 57, 89, 75), "cabbage2": (101, 57, 121, 75), "pumpkin": (194, 55, 221, 77),
             "melon": (324, 54, 350, 78), "eggplant": (452, 54, 475, 77), "tomato": (354, 10, 379, 46),
             "corn": (483, 11, 507, 47), "corn_young": (451, 11, 475, 47), "carrot": (32, 89, 46, 109),
             "beet": (97, 89, 111, 109), "leek": (162, 89, 174, 109), "pepper": (454, 87, 472, 110),
             "sprout": (266, 32, 280, 46), "berry": (192, 7, 223, 45), "leafy": (224, 7, 255, 45)}.items():
    add("crop_" + k, Pl, r, None)

# ---- Port --------------------------------------------------------------------
F = "fish"
add("fish_house", F, (12, 12, 115, 112), [(2, 46, 101, 97)])
add("fish_house2", F, (132, 7, 235, 107), [(2, 46, 101, 97)])
add("fish_sign", F, (123, 122, 150, 139), None)
add("fish_sign2", F, (211, 127, 238, 144), None)
add("fish_rack", F, (70, 276, 136, 316), [(4, 30, 10, 40), (56, 30, 62, 40)])
add("fish_rack2", F, (155, 278, 221, 318), [(4, 30, 10, 40), (56, 30, 62, 40)])
add("cargo_pile", F, (8, 287, 57, 341))
add("cargo_pile2", F, (5, 453, 54, 507))
add("cargo_fish", F, (3, 357, 50, 399))
add("barrel_fish", F, (68, 363, 107, 395))
add("shark", F, (116, 362, 188, 393), [(6, 14, 66, 30)])
add("barrel_crate", F, (201, 352, 229, 390))
add("fish_pile", F, (3, 403, 44, 442))
add("crate_fish", F, (48, 413, 83, 441))
add("crate_fish2", F, (110, 412, 144, 441))
add("crate_fish3", F, (145, 415, 176, 441))
add("sacks_fish", F, (189, 412, 231, 443))
add("net_frame", F, (70, 454, 124, 505), [(2, 44, 8, 51), (46, 44, 52, 51)])
add("crate_fish4", F, (130, 460, 161, 489))
add("barrel_f1", F, (180, 460, 206, 488))
add("barrel_f2", F, (212, 450, 238, 478))
add("barrel_f3", F, (211, 488, 239, 521))
add("barrel_open", F, (7, 515, 25, 541))
add("barrel_open2", F, (39, 515, 57, 541))
add("sack_f", F, (16, 552, 32, 570), None)
add("sack_f2", F, (39, 550, 57, 572), None)
add("crate_f", F, (72, 325, 88, 346))
add("crate_f2", F, (134, 322, 156, 351))
add("table_dark", F, (195, 324, 223, 347))

# ---- Training ground ----------------------------------------------------------
Tg = "train"
add("t_banner_big", Tg, (10, 8, 40, 84), [(12, 70, 18, 76)])
add("t_vip_tent", Tg, (60, 9, 149, 80), [(2, 30, 87, 70)])
add("t_awning", Tg, (172, 9, 261, 77), [(2, 62, 8, 68), (81, 62, 87, 68)])
add("t_target", Tg, (194, 50, 218, 75), [(6, 16, 18, 25)])
add("t_target2", Tg, (231, 53, 250, 75), [(4, 14, 15, 22)])
add("t_crates", Tg, (59, 88, 94, 139))
add("t_armor_crate", Tg, (104, 87, 144, 139))
add("t_supplies", Tg, (144, 94, 203, 139))
add("t_carpet", Tg, (210, 84, 255, 126), "floor")
add("t_carpet_long", Tg, (242, 132, 319, 158), "floor")
add("t_banner_s", Tg, (1, 97, 10, 139), [(2, 36, 8, 42)])
add("t_rack_tall", Tg, (321, 136, 344, 240), [(4, 6, 20, 104)])
add("t_rack_swords", Tg, (0, 153, 48, 185))
add("t_rack_axes", Tg, (64, 151, 112, 185))
add("t_rack_spear", Tg, (128, 153, 176, 185))
add("t_rack_empty", Tg, (192, 160, 240, 185))
add("t_dummy", Tg, (267, 165, 284, 190), [(4, 18, 13, 25)])
add("t_shields", Tg, (5, 195, 44, 223))
add("t_shields2", Tg, (53, 195, 90, 223))
add("t_hurdle", Tg, (101, 195, 138, 223))
for i, r in enumerate([(171, 196, 188, 222), (203, 196, 219, 222), (235, 196, 252, 222), (267, 196, 284, 222)]):
    add("t_straw%d" % i, Tg, r, [(4, 18, 13, 26)])
add("t_crate1", Tg, (3, 231, 28, 264))
add("t_crate2", Tg, (35, 231, 60, 264))
add("t_bench", Tg, (246, 236, 282, 251), [(0, 6, 36, 15)])
add("t_crate3", Tg, (293, 245, 315, 269))
add("t_crate4", Tg, (325, 245, 347, 269))
add("t_sacks", Tg, (32, 276, 63, 299))
add("t_throne", Tg, (301, 10, 324, 39))
add("t_armchair", Tg, (278, 17, 297, 39))

# ---- Baked composite buildings ------------------------------------------------
BAKED = []   # (key, (w,h), layers[(sheet, rect, (dx,dy), flip)], feet)


def bake_def(key, size, layers, feet):
    BAKED.append((key, size, layers, feet))


add("guild_hall", "guild", (0, 0, 144, 135), [(6, 92, 138, 128), (52, 124, 92, 133)])
bake_def("stone_hall", (117, 115), [("houses", (294, 233, 409, 304), (1, 44), False),
                                     ("houses", (293, 145, 400, 221), (0, 0), False),
                                     ("houses", (400, 176, 410, 221), (107, 31), False),
                                     ("houses", (425, 184, 438, 200), (8, 82), False),
                                     ("houses", (425, 184, 438, 200), (96, 82), False)],
         [(2, 76, 115, 114)])


def bake(out_path):
    """Compose BAKED buildings into one atlas; registers them in P."""
    pad = 2
    x = pad
    hmax = max(s[1] for _, s, _, _ in BAKED)
    atlas = Image.new("RGBA", (sum(s[0] + pad for _, s, _, _ in BAKED) + pad, hmax + 2 * pad), (0, 0, 0, 0))
    cache = {}
    for key, (bw, bh), layers, feet in BAKED:
        canvas = Image.new("RGBA", (bw, bh), (0, 0, 0, 0))
        for sheet, r, (dx, dy), flip in layers:
            if sheet not in cache:
                cache[sheet] = Image.open(os.path.join(RAW, SHEETS[sheet][0])).convert("RGBA")
            part = cache[sheet].crop(r)
            if flip:
                part = part.transpose(Image.FLIP_LEFT_RIGHT)
            canvas.alpha_composite(part, (dx, dy))
        atlas.alpha_composite(canvas, (x, pad))
        P[key] = dict(sheet="baked", rect=(x, pad, x + bw, pad + bh), feet=feet)
        x += bw + pad
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    atlas.save(out_path)
    return out_path


def sheet_image_path(sheet):
    raw, proj = SHEETS[sheet]
    if raw is None:
        return os.path.join(ROOT, proj)
    return os.path.join(RAW, raw)


# Door positions: x from the sprite's left edge (unflipped), on the footprint bottom
DOOR_X = {"house_red": 95, "farmhouse": 58.5, "fish_house": 51, "fish_house2": 51, "guild_hall": 72, "barn": 45.5}
