"""Wave dungeons: five closed arenas, one per theme (crypt, forest, sand, ice, eclipse).
A paved circle in the middle, braziers, and a thick ring of thematic scenery all around.
The waves themselves are run by scripts/world/dungeon.gd."""
import glob, math, os, random
import w_snow_assets as SA
from w_field import *
import w_field as WF
import w_desert as WD
import w_terrain as _WT

DW, DH = 46, 34
THEMES = {
    "crypt": dict(title="Mazmorra", ring=["ruin_column", "ruin_column2", "ruin_pillar", "ruin_pillar2", "ruin_rubble", "gl_rock", "gl_rock2"], snow=False, sand=False),
    "forest": dict(title="Mazmorra", ring=FOREST + GROVE, snow=False, sand=False),
    "sand": dict(title="Mazmorra", ring=["ruin_column", "ruin_pillar2", "ruin_rubble", "tr_palm", "gl_rock3", "gl_rock4", "camp_bones"], snow=False, sand=True),
    "ice": dict(title="Mazmorra", ring=SA.SNOW_TREES + ["sn_crystal", "sn_rock2"], snow=True, sand=False),
    "eclipse": dict(title="Mazmorra", ring=["ruin_column", "ruin_column2", "ruin_pillar", "camp_crystals", "gl_crystalbush", "gl_crystalbush2"], snow=False, sand=False),
}


def torch(w, x, y):
    frames = [(292 - 260, -9, 110), (308 - 260, -7, 110), (324 - 260, -10, 110)]
    return actor(w, "torch", x * T, y * T, SA.VILLAGE, (260, 138, 8, 29), frames, collide=False)


def build(theme):
    cfg = THEMES[theme]
    WP.bake(ROOT + "/assets/sprites/city/baked_buildings.png")
    w = World(DW, DH, seed={"crypt": 11, "forest": 12, "sand": 13, "ice": 14, "eclipse": 15}[theme])
    w.monsters = []
    w.field_path = set()
    w.field_points = []
    rng = w.rng
    for y in range(DH):
        for x in range(DW):
            w.put("ground", x, y, FG, GRASS_TILE)
    w.land = {(x, y) for x in range(DW) for y in range(DH)}
    # the arena floor: a paved oval
    cx, cy = DW / 2, DH / 2 + 1
    floor = {(x, y) for x in range(DW) for y in range(DH) if ((x + 0.5 - cx) / 15.5) ** 2 + ((y + 0.5 - cy) / 11) ** 2 <= 1}
    autotile(w, "road", floor, RD, _WT.ROAD_NINE, _WT.ROAD_INNER, center_variants=[(2, 2), (2, 2), (2, 2)])
    w.blocked |= floor
    # the way out (south) stays clear
    w.blocked |= rect_cells(20, 26, 26, DH)
    # braziers around the floor
    for i in range(8):
        a = i / 8 * math.tau + 0.2
        torch(w, cx + math.cos(a) * 16.8, cy + math.sin(a) * 12.0)
    # the ring of scenery
    ring = [(x, y) for x in range(DW) for y in range(DH) if (x, y) not in floor and not (20 <= x <= 26 and y >= 28)]
    border = [(0, 0, DW, 3), (0, DH - 3, 19, DH), (27, DH - 3, DW, DH), (0, 0, 3, DH), (DW - 3, 0, DW, DH)]
    for r in border:
        scatter(w, cfg["ring"], r, int((r[2] - r[0]) * (r[3] - r[1]) / 6), min_dist=2.2, avoid_path=False)
    scatter(w, cfg["ring"], (2, 2, DW - 2, DH - 2), 46, min_dist=3.0)
    if theme == "eclipse":
        scatter(w, ["camp_crystals", "gl_crystalbush2"], (4, 4, DW - 4, DH - 4), 16, min_dist=4)
    tufts = [(x, 8) for x in range(0, 21)]
    for _ in range(160):
        x, y = rng.randrange(1, DW - 1), rng.randrange(1, DH - 1)
        if (x, y) not in w.blocked and (x, y) not in w.solids:
            w.put("detail", x, y, GD, rng.choice(tufts))
    if cfg["snow"]:
        SA.remap_to_snow(w)
    if cfg["sand"]:
        for name, cells in w.layers.items():
            for c, (src, at, alt) in list(cells.items()):
                if src in WD.REMAP:
                    cells[c] = (WD.REMAP[src], at, alt)
        for (src, at), kind in list(w.collide.items()):
            if src in WD.REMAP:
                w.collide[(WD.REMAP[src], at)] = kind
    w.graph = WL.Graph()
    w.chests = []
    return w


def cfg_for(theme):
    return dict(
        out="scenes/dungeons/%s.tscn" % theme, tileset="res://resources/tilesets/dungeon_%s_tileset.tres" % theme,
        minimap="res://resources/world/minimap_dungeon_%s.png" % theme, title="Mazmorra",
        preview_layers=["water", "water_fx", "ground", "ground_overlay", "hill", "road", "detail", "coast"],
        walkmask="res://resources/world/dungeon_%s_walkmask.png" % theme, player=(23 * 16, 29 * 16),
        zones=[("Mazmorra", (0, 0, DW, DH))], exits=[],
        spawns={"start": (23 * 16, 29 * 16), "respawn": (23 * 16, 29 * 16)},
    )


if __name__ == "__main__":
    import w_export as WE
    WE.LAYERS.insert(4, ("hill", True))
    for theme in THEMES:
        w = build(theme)
        WE.FRAMES_DIR = "dungeon_" + theme
        for f in glob.glob(os.path.join(ROOT, "resources/sprite_frames/dungeon_%s/*.tres" % theme)):
            os.remove(f)
        WE.tileset(w, "resources/tilesets/dungeon_%s_tileset.tres" % theme)
        WE.walk_mask(w, "resources/world/dungeon_%s_walkmask.png" % theme)
        WE.scene(w, cfg_for(theme))
        print("dungeon", theme, "props", len(w.props), "actors", len(w.actors))
