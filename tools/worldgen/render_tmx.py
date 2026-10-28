import sys, xml.etree.ElementTree as ET, os
from PIL import Image
path, out = sys.argv[1], sys.argv[2]
root = ET.parse(path).getroot(); base=os.path.dirname(path)
tsets=[]
for ts in root.findall('tileset'):
    img=ts.find('image')
    if img is None: continue
    f=os.path.join(base,img.get('source'))
    if not os.path.exists(f): print('missing',f); continue
    tsets.append((int(ts.get('firstgid')), int(ts.get('columns')), Image.open(f).convert('RGBA'), ts.get('name')))
tsets.sort()
def tile(gid):
    gid &= 0x1FFFFFFF
    for fg,cols,im,n in reversed(tsets):
        if gid>=fg:
            i=gid-fg; x,y=(i%cols)*16,(i//cols)*16; return im.crop((x,y,x+16,y+16))
cells=[]
def walk(node, visible=True):
    for ch in node:
        v = visible and ch.get('visible','1')!='0'
        if ch.tag=='group': walk(ch,v)
        elif ch.tag=='layer' and v:
            for c in ch.iter('chunk'):
                cx,cy,w=int(c.get('x')),int(c.get('y')),int(c.get('width'))
                vals=[int(t) for t in c.text.replace('\n','').split(',') if t.strip()]
                for i,g in enumerate(vals):
                    if g: cells.append((cx+i%w, cy+i//w, g))
walk(root)
mnx=min(c[0] for c in cells); mny=min(c[1] for c in cells); mxx=max(c[0] for c in cells); mxy=max(c[1] for c in cells)
print('bounds',mnx,mny,mxx,mxy)
canvas=Image.new('RGBA',((mxx-mnx+1)*16,(mxy-mny+1)*16),(30,30,30,255))
for x,y,g in cells:
    t=tile(g); canvas.alpha_composite(t,((x-mnx)*16,(y-mny)*16))
s=int(sys.argv[3]) if len(sys.argv)>3 else 2
canvas.resize((canvas.width*s,canvas.height*s),Image.NEAREST).save(out)
