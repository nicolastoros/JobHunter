"""Copies the icons used by the game from the icon packs into assets/ui/icons."""
import os, shutil
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = r"C:/Users/nicol/JobHunter_raw"
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
    "daga_bronce": ("ic_weapon_icons03/Icons/Icon_4_01.png"),
    "daga_sombra": ("ic_weapon_icons03/Icons/Icon_4_04.png"),
    "colmillo_dunas": ("ic_weapon_icons03/Icons/Icon_4_07.png"),
    "daga_eclipse": ("ic_weapon_icons03/Icons/Icon_4_10.png"),
    "lanza_cazador": ("ic_weapon_icons01/Icons/icon_2_31.png"),
    "lanza_acero": ("ic_weapon_icons01/Icons/icon_2_34.png"),
    "pica_dunas": ("ic_weapon_icons01/Icons/icon_2_37.png"),
    "lanza_sol": ("ic_weapon_icons01/Icons/icon_2_39.png"),
    "hacha_doble": ("ic_weapon_icons03/Icons/Icon_4_13.png"),
    "hacha_berserker": ("ic_weapon_icons03/Icons/Icon_4_16.png"),
    "hacha_titan": ("ic_weapon_icons03/Icons/Icon_4_19.png"),
    "martillo_guerra": ("ic_weapon_icons01/Icons/icon_2_93.png"),
    "martillo_runico": ("ic_weapon_icons01/Icons/icon_2_97.png"),
    "cimitarra": ("ic_weapon_icons02/Icons/icon_3_81.png"),
    "cimitarra_dorada": ("ic_weapon_icons02/Icons/icon_3_85.png"),
    "cimitarra_faraon": ("ic_weapon_icons02/Icons/icon_3_88.png"),
    "estoque": ("ic_weapon_icons03/Icons/Icon_4_84.png"),
    "katana_luna": ("ic_weapon_icons03/Icons/Icon_4_95.png"),
    "hoz_segador": ("ic_weapon_icons02/Icons/icon_3_43.png"),
    "guadana_alma": ("ic_weapon_icons02/Icons/icon_3_49.png"),
    "tridente_marea": ("ic_weapon_icons02/Icons/icon_3_33.png"),
    "tridente_abismo": ("ic_weapon_icons02/Icons/icon_3_38.png"),
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
## Desert materials (painted icons, scaled down to 32 px).
ITEM_ICONS = {
    "polvo_dorado": "ic_rpg_craft_resources/PNG/Without background/13.png",
    "arenisca": "ic_rpg_craft_resources/PNG/Without background/19.png",
    "colmillo_chacal": "ic_rpg_hunting_icons/PNG/without background/19.png",
    "acido": "ic_rpg_craft_resources/PNG/Without background/50.png",
    "tesoro_sol": "ic_rpg_craft_resources/PNG/Without background/30.png",
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
    os.makedirs(os.path.join(out, "items"), exist_ok=True)
    for k, rel in ITEM_ICONS.items():
        im = Image.open(os.path.join(RAW, rel)).convert("RGBA")
        im.thumbnail((32, 32), Image.LANCZOS)
        canvas = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
        canvas.alpha_composite(im, ((32 - im.width) // 2, (32 - im.height) // 2))
        canvas.save(os.path.join(out, "items", k + ".png"))
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
