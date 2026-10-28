import glob, os, sys
from PIL import Image
from collections import defaultdict
sys.stdout.reconfigure(encoding="utf-8")
R = r"C:/Users/nicol/JobHunter_raw"
types = defaultdict(list)
for f in glob.glob(R + "/mon_*/PNG/*/With_shadow/*.png"):
    p = f.replace("\\", "/").split("/")
    pack, kind = p[-5], p[-3]
    im = Image.open(f)
    types[(pack, kind)].append("%s %dx%d" % (os.path.basename(f).replace("_with_shadow.png", ""), *im.size))
for k, v in sorted(types.items()):
    print(k, sorted(v))
for f in sorted(glob.glob(R + "/grassland_01/PNG/*.png") + glob.glob(R + "/trees_01/PNG/*.png") + glob.glob(R + "/user_interface/PNG/*.png")):
    print(f.replace("\\", "/").split("/raw/")[1], Image.open(f).size)
