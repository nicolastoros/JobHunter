import sys, os, xml.etree.ElementTree as ET
from PIL import Image, ImageDraw
path, out = sys.argv[1], sys.argv[2]
root = ET.parse(path).getroot(); base = os.path.dirname(path)
ts = []
for t in root.findall('tileset'):
    im = t.find('image')
    ts.append((int(t.get('firstgid')), int(t.get('columns')), Image.open(os.path.join(base, im.get('source'))).convert('RGBA')))
ts.sort(key=lambda a: a[0])
layers = []
def walk(n, p=''):
    for c in n:
        if c.tag == 'group': walk(c, p + c.get('name') + '/')
        elif c.tag == 'layer':
            cells = []
            for ch in c.iter('chunk'):
                cx, cy, w = int(ch.get('x')), int(ch.get('y')), int(ch.get('width'))
                for i, v in enumerate([int(v) for v in ch.text.replace('\n', '').split(',') if v.strip()]):
                    if v: cells.append((cx + i % w, cy + i // w, v))
            if cells: layers.append((p + c.get('name'), cells))
walk(root)
allc = [c for _, cs in layers for c in cs]
mx = min(c[0] for c in allc); my = min(c[1] for c in allc); Mx = max(c[0] for c in allc); My = max(c[1] for c in allc)
W, H = (Mx - mx + 1) * 16, (My - my + 1) * 16
tiles = []
for name, cells in layers:
    im = Image.new('RGBA', (W, H), (60, 60, 70, 255))
    for x, y, g in cells:
        g &= 0x1FFFFFFF
        for fg, cols, sheet in reversed(ts):
            if g >= fg:
                i = g - fg; im.alpha_composite(sheet.crop((i % cols * 16, i // cols * 16, i % cols * 16 + 16, i // cols * 16 + 16)), ((x - mx) * 16, (y - my) * 16)); break
    ImageDraw.Draw(im).text((2, 2), name, fill=(255, 255, 0))
    tiles.append(im)
cols = 4
out_im = Image.new('RGBA', (W * cols, H * ((len(tiles) + cols - 1) // cols)), (0, 0, 0, 255))
for i, t in enumerate(tiles): out_im.paste(t, ((i % cols) * W, (i // cols) * H))
out_im.save(out)
