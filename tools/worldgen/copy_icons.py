"""Copies the icons used by the game from the icon packs into assets/ui/icons."""
import os, shutil
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, "..", "raw")
ROOT = "C:/Users/nicol/OneDrive/Documentos/JobHunter"

EQUIP = {
    # weapons (weapon_icons01)
    "espada_corta": ("ic_weapon_icons01/Icons/icon_2_01.png"),
    "espada_hierro": ("ic_weapon_icons01/Icons/icon_2_02.png"),
    "hacha_lenador": ("ic_weapon_icons01/Icons/icon_2_43.png"),
    "espada_acero": ("ic_weapon_icons01/Icons/icon_2_03.png"),
    "maza_tachonada": ("ic_weapon_icons01/Icons/icon_2_53.png"),
    "hoja_centinela": ("ic_weapon_icons01/Icons/icon_2_04.png"),
    "espada_ignea": ("ic_weapon_icons01/Icons/icon_2_06.png"),
    "hoja_marina": ("ic_weapon_icons01/Icons/icon_2_08.png"),
    "espada_alba": ("ic_weapon_icons01/Icons/icon_2_18.png"),
    # armour (armor_icons01)
    "gorro_cuero": ("ic_armor_icons01/Icons/Icons_6_41.png"),
    "casco_hierro": ("ic_armor_icons01/Icons/Icons_6_03.png"),
    "yelmo_astado": ("ic_armor_icons01/Icons/Icons_6_06.png"),
    "jubon_cuero": ("ic_armor_icons01/Icons/Icons_6_51.png"),
    "coraza_hierro": ("ic_armor_icons01/Icons/Icons_6_12.png"),
    "coraza_templada": ("ic_armor_icons01/Icons/Icons_6_15.png"),
    "armadura_abisal": ("ic_armor_icons01/Icons/Icons_6_18.png"),
    "guantes_cuero": ("ic_armor_icons01/Icons/Icons_6_61.png"),
    "guanteletes_hierro": ("ic_armor_icons01/Icons/Icons_6_23.png"),
    "botas_viaje": ("ic_armor_icons01/Icons/Icons_6_71.png"),
    "grebas_hierro": ("ic_armor_icons01/Icons/Icons_6_33.png"),
    "botas_igneas": ("ic_armor_icons01/Icons/Icons_6_37.png"),
    # trinkets (trinket_icons01)
    "anillo_cobre": ("ic_trinket_icons01/Icons/icons_8_01.png"),
    "amuleto_cazador": ("ic_trinket_icons01/Icons/icons_8_45.png"),
    "anillo_rubi": ("ic_trinket_icons01/Icons/icons_8_21.png"),
    "amuleto_brasa": ("ic_trinket_icons01/Icons/icons_8_66.png"),
}
SKILLS = {"giro": 26, "embestida": 24, "grito": 41, "respiro": 50, "onda": 34, "tajo": 5}


def main():
    out = os.path.join(ROOT, "assets/ui/icons")
    os.makedirs(os.path.join(out, "equip"), exist_ok=True)
    os.makedirs(os.path.join(out, "skills"), exist_ok=True)
    for k, rel in EQUIP.items():
        src = os.path.join(RAW, rel)
        assert os.path.exists(src), src
        shutil.copy2(src, os.path.join(out, "equip", k + ".png"))
    for k, n in SKILLS.items():
        im = Image.open(os.path.join(RAW, "ic_rpg_splash_icons/PNG/%d.png" % n)).convert("RGBA")
        im.resize((48, 48), Image.LANCZOS).save(os.path.join(out, "skills", k + ".png"))
    for pack in ("ic_weapon_icons01", "ic_armor_icons01", "ic_trinket_icons01"):
        for lic in ("License.txt", "license.txt"):
            p = os.path.join(RAW, pack, lic)
            if os.path.exists(p):
                shutil.copy2(p, os.path.join(ROOT, "assets/licenses", pack[3:] + "_License.txt"))
    print("icons:", len(EQUIP), "equip,", len(SKILLS), "skills")


main()
