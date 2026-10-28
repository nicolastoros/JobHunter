import sys
from PIL import Image, ImageDraw
import w_props as WP
WP.bake(r"C:/Users/nicol/AppData/Local/Temp/claude/c--Users-nicol-OneDrive-Documentos-JobHunter/7f39b642-3aaa-4323-9d53-2b420a1d2380/scratchpad/baked_test.png")
WP.SHEETS["baked"]=(None,"x")
cache={}
def img(sheet):
    if sheet not in cache:
        p = r"C:/Users/nicol/AppData/Local/Temp/claude/c--Users-nicol-OneDrive-Documentos-JobHunter/7f39b642-3aaa-4323-9d53-2b420a1d2380/scratchpad/baked_test.png" if sheet=="baked" else WP.sheet_image_path(sheet)
        cache[sheet]=Image.open(p).convert("RGBA")
    return cache[sheet]
keys=[k for k in WP.P if (sys.argv[2] in k or sys.argv[2]=='all')] if len(sys.argv)>2 else list(WP.P)
cells=[]
for k in keys:
    p=WP.P[k]; im=img(p["sheet"]).crop(p["rect"])
    c=Image.new("RGBA",(max(im.width,60)+4,im.height+14),(90,140,90,255)); c.alpha_composite(im,(2,12))
    d=ImageDraw.Draw(c)
    if isinstance(p["feet"],list):
        for a,b,e,f in p["feet"]: d.rectangle((2+a,12+b,2+e-1,12+f-1),outline=(0,255,255))
    d.text((1,0),k[:14],fill=(255,255,255))
    cells.append(c)
W=1400; x=y=0; rowh=0; pos=[]
for c in cells:
    if x+c.width>W: x=0; y+=rowh+4; rowh=0
    pos.append((x,y)); x+=c.width+4; rowh=max(rowh,c.height)
out=Image.new("RGBA",(W,y+rowh),(30,30,30,255))
for c,p in zip(cells,pos): out.alpha_composite(c,p)
out.save(sys.argv[1])
print(out.size)
