import glob, os, re, sys
from PIL import Image, ImageDraw

RAW = r"C:/Users/nicol/JobHunter_raw"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def num(f):
    m = re.findall(r"(\d+)", os.path.basename(f))
    return int(m[-1]) if m else 0


def sheet(name, pat, cell, cols=10, scale=1):
    fs = sorted([f for f in glob.glob(os.path.join(RAW, pat)) if "__MACOSX" not in f], key=num)
    rows = (len(fs) + cols - 1) // cols
    out = Image.new("RGBA", (cols * (cell + 4), rows * (cell + 12)), (60, 50, 45, 255))
    d = ImageDraw.Draw(out)
    for i, f in enumerate(fs):
        im = Image.open(f).convert("RGBA")
        im.thumbnail((cell, cell), Image.NEAREST if im.width <= 64 else Image.LANCZOS)
        x = (i % cols) * (cell + 4)
        y = (i // cols) * (cell + 12)
        out.alpha_composite(im, (x, y))
        d.text((x, y + cell), str(num(f)), fill=(255, 255, 200, 255))
    if scale > 1:
        out = out.resize((out.width * scale, out.height * scale), Image.NEAREST)
    out.save(os.path.join(OUT, "cs_%s.png" % name))
    print(name, len(fs))


if __name__ == "__main__":
    for spec in sys.argv[1:]:
        name, pat, cell, cols, scale = spec.split("|")
        sheet(name, pat, int(cell), int(cols), int(scale))
