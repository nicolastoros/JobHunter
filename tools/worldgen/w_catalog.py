"""Exports the in-game editor catalog (props, characters, animals) to resources/editor/catalog.json."""
import json, os
import w_export as WE
import w_props as WP
import w_common as C

CATEGORY_BY_SHEET = {"mk_obj": "Mercado", "mk_single": "Mercado", "houses": "Edificios", "baked": "Edificios",
                     "guild": "Edificios", "objout": "Naturaleza", "trees": "Naturaleza", "plants": "Cultivos",
                     "fish": "Puerto", "train": "Cuartel", "ext": "Naturaleza"}
BUILDINGS = {"house_red", "fish_house", "fish_house2", "farmhouse", "barn", "shed", "longshed", "coop", "coop2", "mill",
             "guild_hall", "stone_hall", "porch"}
NAMES = {"house_red": "Casa de piedra", "fish_house": "Casa de madera", "fish_house2": "Casa de madera 2", "farmhouse": "Casa de campo",
         "barn": "Granero", "shed": "Cobertizo", "longshed": "Almacén", "coop": "Gallinero", "mill": "Molino", "guild_hall": "Gremio",
         "well": "Pozo", "fruit_stall": "Puesto de frutas", "weapon_stall": "Armería", "bread_stall": "Panadería", "magic_tent": "Carpa mística",
         "blue_tent": "Toldo azul", "potion_cart": "Carro de pociones", "cart": "Carreta"}


def build(w):
    items = []
    for key, p in WP.P.items():
        sheet = p["sheet"]
        cat = "Edificios" if key in BUILDINGS else CATEGORY_BY_SHEET.get(sheet, "Varios")
        x0, y0, x1, y1 = p["rect"]
        wd, ht = x1 - x0, y1 - y0
        feet = p["feet"]
        floor = feet == "floor"
        fl = [] if (floor or not feet) else list(feet)
        ox = wd / 2
        oy = ht / 2 if floor else (max(r[3] for r in fl) if fl else ht)
        items.append(dict(key=key, name=NAMES.get(key, key.replace("_", " ").capitalize()), category=cat,
                          texture=WE.res_for_image(WP.sheet_image_path(sheet)), region=[x0, y0, wd, ht],
                          origin=[ox, oy], feet=[[a - ox, b - oy, c - ox, d - oy] for a, b, c, d in fl], floor=floor))
    # animated characters & objects already used in the world
    seen = set()
    chars = []
    for a in w.actors:
        fr = WE.actor_frames(a)
        if fr in seen:
            continue
        seen.add(fr)
        fw, fh = a["size"]
        name = a["talk"][0] if a.get("talk") else a["kind"].replace("_", " ").capitalize()
        chars.append(dict(name=name, frames=fr, offset_y=fh / 2 - a["origin"][1], collide=bool(a.get("collide", True)),
                          talk=bool(a.get("talk")), category="Personajes"))
    for n in range(1, 9):
        chars.append(dict(name=("Guardia" if n == 8 else "Ciudadano %d" % n), frames=WE.citizen_frames(n), offset_y=-13,
                          walker=True, guard=n == 8, category="Ciudadanos"))
    for kind in ("Deer", "Hare", "Fox", "Black_grouse", "Boar"):
        chars.append(dict(name={"Deer": "Ciervo", "Hare": "Liebre", "Fox": "Zorro", "Black_grouse": "Urogallo", "Boar": "Jabalí"}[kind],
                          frames=WE.animal_frames(kind), animal=True, category="Animales"))
    out = dict(items=items, characters=chars)
    path = os.path.join(C.ROOT, "resources/editor/catalog.json")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    json.dump(out, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    return len(items), len(chars)
