"""Desierto de Ámbar: sand sea east of the Llanura de Valdoria.
The field's grass tiles recoloured to sand (ground, mesas, shores, tufts); palms around the Zafira Oasis
(safe haven at the entrance), the Golden Dunes, the Red Canyon with the raiders' camp, the Glass Flats
and the Ruins of the Sun, where the Sun Guardian sleeps. Monsters are desert-coloured versions of the
plain's creatures."""
import colorsys, glob, math, os, random, shutil
from PIL import Image
from w_field import *
import w_field as WF
import w_common as C

DW, DH = 160, 120
GATE_Y = (58, 64)              # trail to the plain (west edge)
EAST_Y = (58, 64)              # caravan road to Aurelia (east edge)

# ---- sand versions of the field's tile sheets -------------------------------------------
SAND_FG, SAND_GD, SAND_SHORE = 14, 15, 16
_LO, _HI = (150, 108, 58), (243, 221, 156)


def _sand(src_rel, dst_rel):
    im = Image.open(os.path.join(RAW, src_rel)).convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if not a:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if 0.14 <= h <= 0.48 and s > 0.15:      # the greens of the grass
                t = min(1.0, max(0.0, (v - 0.25) / 0.6))
                px[x, y] = tuple(int(_LO[i] + (_HI[i] - _LO[i]) * t) for i in range(3)) + (a,)
    os.makedirs(os.path.dirname(os.path.join(RAW, dst_rel)), exist_ok=True)
    im.save(os.path.join(RAW, dst_rel))


def _packed_sand_trail(dst_rel):
    """The dirt-path tiles (cols 19-23, rows 1-3 of the ground sheet) become packed sand: a caravan trail."""
    im = Image.open(os.path.join(RAW, dst_rel)).convert("RGBA")
    px = im.load()
    lo, hi = (184, 140, 84), (229, 197, 134)
    for y in range(16, 4 * 16):
        for x in range(19 * 16, 24 * 16):
            r, g, b, a = px[x, y]
            if not a:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if h <= 0.13 and s > 0.2:
                t = min(1.0, max(0.0, (v - 0.3) / 0.5))
                px[x, y] = tuple(int(lo[i] + (hi[i] - lo[i]) * t) for i in range(3)) + (a,)
    im.save(os.path.join(RAW, dst_rel))


for sid, src, dst, proj in ((SAND_FG, C.SOURCES[FG][0], "desert/ground_sand.png", "assets/sprites/desert/tiles/ground_sand.png"),
                             (SAND_GD, C.SOURCES[GD][0], "desert/details_sand.png", "assets/sprites/desert/tiles/details_sand.png"),
                             (SAND_SHORE, C.SOURCES[FWCG][0], "desert/shore_sand.png", "assets/sprites/desert/tiles/shore_sand.png")):
    _sand(src, dst)
    C.SOURCES[sid] = (dst, proj)
_packed_sand_trail("desert/ground_sand.png")
C.ANIM_ALIAS[SAND_SHORE] = WC
C.ANIM_ALIAS[SAND_FG] = FG
C.ANIM_ALIAS[SAND_GD] = GD
REMAP = {FG: SAND_FG, GD: SAND_GD, FWCG: SAND_SHORE}


# ---- desert monsters: recoloured copies of the plain's packs ----------------------------
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


recolor_pack("mon_slimes_01", "mon_desert_slimes", ["Slime1", "Slime2", "Slime3"], [(0.0, 1.0, 0.09, 0.75, 1.05)])
recolor_pack("mon_special_slimes_mobs01", "mon_desert_acid", ["Slime1", "Slime2", "Slime3"], [(0.0, 1.0, 0.22, 1.1, 1.1, 0.1)])
recolor_pack("mon_goblin_mobs01", "mon_desert_raiders", ["Goblin1", "Goblin2", "Goblin3"], [(0.17, 0.48, 0.07, 0.8, 1.0)])
recolor_pack("mon_gnolls_mobs01", "mon_desert_jackals", ["Gnoll1", "Gnoll2", "Gnoll3"], [(0.93, 0.16, 0.11, 1.25, 1.12, 0.1)])
recolor_pack("mon_golem_bosses01", "mon_desert_golems", ["Golem1"], [(0.93, 0.16, 0.1, 0.75, 1.3, 0.1)])
recolor_pack("mon_golem_bosses01", "mon_desert_golems", ["Golem3"], [(0.45, 0.75, 0.12, 1.0, 1.35)])

WF.MON.update({
    "sand": dict(pack="mon_desert_slimes", kinds=["Slime1", "Slime2", "Slime3"], name="Limo de arena", props=dict(max_hp=8, damage=2, speed=16, chase_speed=32, aggro_radius=80, attack_range=15, gold=5, territory=90)),
    "acid": dict(pack="mon_desert_acid", kinds=["Slime1", "Slime2", "Slime3"], name="Limo ácido", props=dict(max_hp=9, damage=2, speed=16, chase_speed=32, aggro_radius=80, attack_range=15, gold=6, territory=80)),
    "raider": dict(pack="mon_desert_raiders", kinds=["Goblin1", "Goblin2", "Goblin3"], name="Saqueador de las dunas", props=dict(max_hp=11, damage=2, speed=24, chase_speed=50, aggro_radius=104, attack_range=18, gold=8, territory=100)),
    "jackal": dict(pack="mon_desert_jackals", kinds=["Gnoll1", "Gnoll2", "Gnoll3"], name="Chacal de las dunas", props=dict(max_hp=13, damage=3, speed=26, chase_speed=56, aggro_radius=112, attack_range=20, gold=9, territory=110)),
    "sandgolem": dict(pack="mon_desert_golems", kinds=["Golem1"], name="Gólem de arenisca", props=dict(max_hp=17, damage=3, speed=12, chase_speed=24, aggro_radius=90, attack_range=22, gold=10, territory=70, sprite_scale=0.6, body_size="Vector2(18, 7)")),
    "sunguard": dict(pack="mon_desert_golems", kinds=["Golem3"], name="Guardián del Sol", props=dict(max_hp=70, damage=4, speed=12, chase_speed=24, aggro_radius=130, attack_range=30, gold=120, territory=90, boss="true", respawn_time=220, body_size="Vector2(30, 10)")),
})

SAND_TREES = ["tr_palm", "tr_fan", "tr_fan_m", "tr_palm"]
DRY = ["tr_dead", "tr_dead_m", "gl_stump", "gl_stump2", "tr_log", "tr_stump"]
ZONES = [("Oasis de Zafira", (6, 44, 44, 78)), ("Ruinas del Sol", (96, 8, 152, 50)), ("Cañón Rojo", (100, 74, 154, 112)),
         ("Llanos de Vidrio", (40, 90, 96, 114)), ("Dunas Doradas", (40, 8, 100, 90)), ("Desierto de Ámbar", (0, 0, DW, DH))]


def build():
    WP.bake(ROOT + "/assets/sprites/city/baked_buildings.png")
    w = World(DW, DH, seed=2402)
    w.monsters = []
    w.field_path = set()
    w.field_points = []
    w.mrng = random.Random(31)
    rng = w.rng
    for y in range(DH):
        for x in range(DW):
            w.put("ground", x, y, FG, GRASS_TILE)
    w.land = {(x, y) for x in range(DW) for y in range(DH)}

    # the oasis: a pool ringed by palms
    lake(w, blob(24, 52.5, 7, 4.2, 0.2, 1.7))
    lake(w, blob(104, 98, 3.5, 2.5, 0.2, 0.4))     # a hidden spring in the canyon
    # mesas: red canyon walls and lone buttes on the dunes
    hills = []
    for (cx, cy, rx, ry, sd) in ((112, 84, 6, 4, 0.5), (140, 80, 7, 4, 1.9), (118, 104, 7, 3.5, 2.7), (146, 104, 5, 3.5, 0.9),
                                  (62, 30, 5, 3, 1.2), (82, 70, 4, 3, 2.2), (58, 100, 4, 2.5, 0.3)):
        hc = blob(cx, cy, rx, ry, 0.18, sd)
        hill(w, hc)
        hills.append(hc)
    w.hill_cells = set().union(*hills) | {(x, y + 1) for h in hills for (x, y) in h}

    # caravan trails
    P = [
        [(-1, 61), (12, 61), (26, 64), (40, 62)],                                   # gate -> oasis
        [(40, 62), (56, 56), (72, 50), (88, 42), (104, 34)],                         # -> ruins of the sun
        [(40, 62), (56, 70), (72, 80), (90, 88), (106, 92)],                         # -> red canyon
        [(56, 70), (60, 86), (64, 102)],                                             # -> glass flats
        [(88, 42), (90, 24), (96, 16)],                                              # dunes north
        [(72, 50), (96, 58), (122, 61), (146, 61), (161, 61)],                       # caravan road east, to Aurelia
    ]
    for pts in P:
        path(w, pts, 3.2)

    # Ruins of the Sun: stone paving and broken temple
    paving = set()
    for (cx, cy, rx, ry, sd) in ((124, 28, 13, 9, 0.6), (108, 24, 4, 3, 1.4), (140, 22, 4, 3, 2.1), (124, 42, 5, 3, 0.2)):
        paving |= blob(cx, cy, rx, ry, 0.3, sd)
    paving = {c for c in paving if c not in w.solids}
    import w_terrain as _WT
    autotile(w, "road", paving, RD, _WT.ROAD_NINE, _WT.ROAD_INNER, center_variants=[(2, 2), (2, 2), (2, 2)])
    w.blocked |= paving
    for (k, x, y) in (("ruin_tower2", 124, 23), ("ruin_arch", 112.5, 27), ("ruin_arch2", 136, 28), ("ruin_column", 110, 20.5), ("ruin_column2", 138, 21),
                      ("ruin_pillar", 117.5, 33), ("ruin_pillar2", 130.5, 33), ("ruin_pillar", 118, 18), ("ruin_pillar2", 131, 18.5),
                      ("ruin_rubble", 120, 37.5), ("ruin_rubble", 129, 38), ("ruin_tower", 104, 32), ("ruin_column", 145, 31)):
        prop(w, k, x, y)
    w.blocked |= rect_cells(102, 12, 148, 44)
    w.field_points += [(124, 30), (112, 30), (136, 30)]

    # Zafira Oasis (safe haven): palms, tents of the nomads, a fire
    for (k, x, y) in (("tent_stripes", 14, 66.5), ("tent_orange", 34, 67), ("camp_rug", 22.5, 69.2)):
        prop(w, k, x, y)
    prop(w, "camp_log", 21, 72.6); prop(w, "camp_log", 28, 72.6); prop(w, "camp_trunk", 38.5, 69.5); prop(w, "camp_chest", 10, 69.5)
    for (x, y) in ((14, 49), (34, 48), (12, 56.5), (36, 56), (19, 45.5), (29, 45.5)):
        prop(w, rng.choice(["tr_palm", "tr_fan"]), x, y, flip=rng.random() < 0.5)
    w.blocked |= rect_cells(8, 46, 42, 76)
    camp_actor(w, "nomad", "Lute_player.png", (0, 0, 44, 48), [(0, r * 48) for r in range(6)], 31.5 * 16, 72.5 * 16,
               talk=("Zahir, nómada", ["Bienvenido al Oasis de Zafira, viajero. Bebe, descansa: aquí rellenas tus pociones.",
                                       "Al este, en las Ruinas del Sol, duerme un guardián de oro. Los saqueadores quieren su tesoro.",
                                       "Y cuidado con los chacales de las dunas: cazan en manada, como los gnolls."]), bubble=["♪ ♪"])
    camp_actor(w, "cook3", "Bonfire_boiler_lizardman.png", (0, 0, 62, 58), [(c * 112, r * 112) for c in range(3) for r in range(4)], 24.5 * 16, 71.4 * 16,
               talk=("Saria, cocinera", ["Guiso de dátiles y especias. Lo mejor contra el calor... o eso digo yo."]),
               bubble=["¡Guiso de dátiles!"])

    # Raiders' camp in the Red Canyon
    for (k, x, y) in (("tent_ragged", 124, 92), ("tent_purple", 136, 96), ("camp_bones", 128, 98), ("crates_c", 120, 97), ("camp_crystals", 140, 92)):
        prop(w, k, x, y)
    w.blocked |= rect_cells(118, 88, 142, 100)

    # monsters
    monster(w, "sunguard", 124, 29)
    for (cx, cy) in ((112, 30), (136, 30), (124, 40), (116, 18), (140, 40), (104, 24)):
        pack_monsters(w, "sandgolem", cx, cy, 2, 2.5, own=True)
    for (cx, cy, n) in ((126, 95, 4), (134, 102, 3), (112, 94, 3), (146, 92, 3), (104, 108, 3)):
        pack_monsters(w, "raider", cx, cy, n, 3.5, own=True)
    for (cx, cy) in ((56, 20), (76, 18), (70, 40), (90, 60), (52, 44), (94, 76), (74, 62)):
        pack_monsters(w, "jackal", cx, cy, 3, 4, own=True)
    for (cx, cy) in ((50, 30), (64, 54), (84, 30), (98, 56), (46, 80), (80, 84), (88, 12), (60, 14)):
        pack_monsters(w, "sand", cx, cy, 3, 3, own=True)
    for (cx, cy) in ((48, 100), (66, 108), (82, 104), (92, 112), (56, 110)):
        pack_monsters(w, "acid", cx, cy, 3, 3, own=True)
    for (cx, cy, k) in ((150, 60, "jackal"), (150, 16, "sandgolem"), (20, 100, "acid"), (20, 20, "sand"), (34, 30, "jackal"), (150, 112, "raider")):
        pack_monsters(w, k, cx, cy, 3, 3, own=True)

    # treasure chests
    w.chests = []
    for (x, y, tier) in ((124, 34, 4), (150, 10, 3), (152, 110, 3), (130, 92, 2), (90, 112, 2), (18, 16, 2), (70, 44, 1), (46, 94, 1), (84, 68, 1)):
        c = (x, y)
        for r in range(6):
            free = [(x + dx, y + dy) for dy in range(-r, r + 1) for dx in range(-r, r + 1)
                    if (x + dx, y + dy) not in w.solids and (x + dx, y + dy) not in w.hill_cells and (x + dx, y + dy) not in w.field_path]
            if free:
                c = free[0]
                break
        w.chests.append((c[0] + 0.5, c[1] + 0.9, tier))
        w.blocked |= rect_cells(c[0] - 1, c[1] - 2, c[0] + 1, c[1] + 1)

    # paint the trails
    autotile(w, "ground_overlay", w.field_path, FG, nine_at(19, 1), {"se": (22, 1), "sw": (23, 1), "ne": (22, 2), "nw": (23, 2)}, center_variants=[(20, 2)])
    w.blocked |= w.field_path

    # ---- scenery: rocky edges, dry trees, bones and rocks on the dunes --------------------
    border = [(0, 0, DW, 7), (0, DH - 7, DW, DH), (DW - 7, 0, DW, EAST_Y[0] - 3), (DW - 7, EAST_Y[1] + 3, DW, DH),
              (0, 0, 7, GATE_Y[0] - 3), (0, GATE_Y[1] + 3, 7, DH)]
    for r in border:
        scatter(w, ROCKS + ["tr_dead", "tr_dead_m", "tr_palm"], r, int((r[2] - r[0]) * (r[3] - r[1]) / 13), min_dist=2.6, avoid_path=False)
    scatter(w, ROCKS, (8, 8, 152, 112), 70, min_dist=6)
    scatter(w, DRY, (8, 8, 152, 112), 46, min_dist=7)
    scatter(w, SAND_TREES, (8, 8, 152, 112), 18, min_dist=14)
    scatter(w, ["camp_bones", "camp_bones", "gl_rocks_s", "gl_stone", "gl_stone2", "camp_crystals"], (8, 8, 152, 112), 40, min_dist=6)
    scatter(w, ["gl_grass", "gl_sprout", "weed0", "weed2"], (8, 8, 152, 112), 90, min_dist=2.5)
    tufts = [(x, 8) for x in range(0, 21)]
    for _ in range(700):
        x, y = rng.randrange(1, DW - 1), rng.randrange(1, DH - 1)
        if (x, y) not in w.blocked and (x, y) not in w.solids:
            w.put("detail", x, y, GD, rng.choice(tufts))

    # everything drawn with the grass sheets now uses their sand copies
    for name, cells in w.layers.items():
        for c, (src, at, alt) in list(cells.items()):
            if src in REMAP:
                cells[c] = (REMAP[src], at, alt)
    for (src, at), kind in list(w.collide.items()):
        if src in REMAP:
            w.collide[(REMAP[src], at)] = kind
    w.graph = WL.Graph()
    return w


DESERT_CFG = dict(
    out="scenes/world/desert.tscn", tileset="res://resources/tilesets/desert_tileset.tres", stamina=True,
    minimap="res://resources/world/minimap_desert.png", title="Desierto de Ámbar", hunters=6,
    preview_layers=["water", "water_fx", "ground", "ground_overlay", "hill", "road", "detail", "coast", "dock", "dock_fx"],
    walkmask="res://resources/world/desert_walkmask.png", player=(4 * 16, 61 * 16),
    zones=ZONES,
    exits=[dict(name="WestExit", pos=(18, 61 * 16), size=(24, 6 * 16), scene="res://scenes/world/field.tscn", spawn="east", dir="left"),
           dict(name="EastExit", pos=(DW * 16 - 18, 61 * 16), size=(24, 6 * 16), scene="res://scenes/world/aurelia.tscn", spawn="west", dir="right")],
    spawns={"west": (5 * 16, 61 * 16), "respawn": (24 * 16, 70 * 16), "start": (5 * 16, 61 * 16), "east": (DW * 16 - 6 * 16, 61 * 16)},
    left_gap=GATE_Y, right_gap=EAST_Y,
)


if __name__ == "__main__":
    import w_export as WE
    w = build()
    WE.FRAMES_DIR = "desert"
    for f in glob.glob(os.path.join(ROOT, "resources/sprite_frames/desert/*.tres")):
        os.remove(f)
    for sheet in WP.SHEETS:
        if WP.SHEETS[sheet][0]:
            WE.res_for_raw(os.path.join(RAW, WP.SHEETS[sheet][0]))
    WE.LAYERS.insert(4, ("hill", True))
    WE.tileset(w, "resources/tilesets/desert_tileset.tres")
    WE.walk_mask(w, "resources/world/desert_walkmask.png")
    WE.scene(w, DESERT_CFG)
    print("desert: props", len(w.props), "actors", len(w.actors), "monsters", len(w.monsters), "chests", len(w.chests))
