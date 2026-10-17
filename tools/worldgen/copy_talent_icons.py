"""Copies the talent-tree and main-attribute icons into assets/ui/icons/talents."""
import os, shutil

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, "..", "raw")
ROOT = "C:/Users/nicol/OneDrive/Documentos/JobHunter"
W = "ic_weapon_icons01/Icons/icon_2_%02d.png"
A = "ic_armor_icons01/Icons/Icons_6_%02d.png"
T = "ic_trinket_icons01/Icons/icons_8_%02d.png"
R = "ic_pixe_resource_icon1/Icons/icons_30_%02d.png"
ICONS = {
    # main attributes
    "main_vida": T % 62, "main_energia": A % 77, "main_magia": T % 80,
    # warrior
    "vigor": T % 66, "filo": W % 3, "piel_hierro": A % 13, "aguante": A % 4, "golpe_certero": W % 5,
    "coraza_viva": A % 16, "sed_sangre": T % 22, "golpe_brutal": W % 47, "furia": W % 27,
    # explorer
    "pulmones": A % 72, "paso_ligero": A % 37, "reflejos": T % 47, "recuperacion": R % 54, "ojo_mercader": R % 4,
    "incansable": A % 78, "botin": R % 10, "aprendiz": T % 79, "instinto": T % 72,
    # mystic
    "mente": T % 76, "concentracion": T % 33, "poder_arcano": W % 78, "alquimia": R % 58, "celeridad": T % 17,
    "eficiencia": T % 74, "escudo_mana": A % 18, "vinculo": T % 71, "maestria": W % 88,
}
out = os.path.join(ROOT, "assets/ui/icons/talents")
os.makedirs(out, exist_ok=True)
for k, rel in ICONS.items():
    src = os.path.join(RAW, rel)
    assert os.path.exists(src), src
    shutil.copy2(src, os.path.join(out, k + ".png"))
lic = os.path.join(RAW, "ic_pixe_resource_icon1", "license.txt")
if os.path.exists(lic):
    shutil.copy2(lic, os.path.join(ROOT, "assets/licenses", "pixe_resource_icon1_License.txt"))
print(len(ICONS), "icons")
