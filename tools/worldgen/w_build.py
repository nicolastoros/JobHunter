import sys
import w_common as C, w_terrain as WT, w_props as WP, w_layout as WL, w_preview as PV
import w_city, w_outside, w_farm_port, w_coast, w_waterfront
def build():
    WP.bake(C.ROOT + "/assets/sprites/city/baked_buildings.png")
    w = C.World(WT.W, WT.H)
    WT.build_terrain(w)
    g = WL.Graph()
    w_coast.build_coast(w)
    w_city.build_city(w, g)
    w_outside.build_roads(w, g)
    w_outside.training_ground(w, g)
    w_farm_port.build_farm(w, g)
    w_coast.build_harbour(w, g)
    w_waterfront.build_waterfront(w, g)
    w_outside.forest_border(w)
    w_outside.meadow(w, g)
    w_outside.assign_doors(w)
    # guards at the gates, and a "brain" for a good share of the townsfolk
    for k in ("n_av", "s_av", "w_av", "e_av", "q48", "mid_n"):
        if k in g.index:
            x, y = g.nodes[g.index[k]]
            WL.citizen(w, 8, x, y, "city", ["Todo en orden.", "Sigue tu camino.", "Mantente atento fuera de las murallas.", "Buen día."], guard=True)
    for i, c in enumerate(w.walkers):
        if c.get("guard"):
            c["mode"] = "guard"
            continue
        c["mode"] = "loiterer" if i % 3 == 1 else "stroller"
        if i % 5 in (0, 2, 3):
            c["brain"] = True
    for k in ("kobold",):
        for a in w.actors:
            if a["kind"] == k:
                a["seller"] = True
    w.graph = g
    return w
if __name__ == "__main__":
    w = build()
    PV.LAYER_ORDER[:] = ["water", "water_fx", "ground", "ground_overlay", "road", "detail", "water_city", "rim", "coast", "dock", "dock_fx", "fence", "walls", "towers"]
    for g_ in [w.graph]:
        w.paths = {"e%d"%i: [g_.nodes[a], g_.nodes[b]] for i,(a,b) in enumerate(g_.edges)}
    crop = {"city": (50, 20, 130, 92), "west": (0, 30, 56, 80), "north": (0, 0, 180, 30), "full": (0, 0, 180, 140),
            "east": (125, 10, 180, 100), "port": (30, 86, 160, 140)}[sys.argv[1] if len(sys.argv) > 1 else "city"]
    sc = 1
    PV.render(w, "../w_%s.png" % (sys.argv[1] if len(sys.argv) > 1 else "city"), sc, crop=tuple(v * 16 for v in crop), show_col="--col" in sys.argv)
