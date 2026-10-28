import sys, subprocess
from PIL import Image, ImageDraw
import xml.etree.ElementTree as ET
src, out = sys.argv[1], sys.argv[2]
subprocess.run([sys.executable, 'tools/render_tmx.py', src, '_tmp.png', '1'], capture_output=True)
im = Image.open('_tmp.png').convert('RGBA')
# bounds
r = ET.parse(src).getroot(); xs=[];ys=[]
for c in r.iter('chunk'):
    vals=[v for v in c.text.replace('\n','').split(',') if v.strip()]
    for i,v in enumerate(vals):
        if v.strip()!='0': xs.append(int(c.get('x'))+i%int(c.get('width'))); ys.append(int(c.get('y'))+i//int(c.get('width')))
mx,my=min(xs),min(ys)
s=3; im=im.resize((im.width*s,im.height*s),Image.NEAREST); d=ImageDraw.Draw(im)
for tx in range(im.width//(16*s)):
    for ty in range(im.height//(16*s)):
        d.rectangle((tx*48,ty*48,tx*48+47,ty*48+47),outline=(255,255,255,60))
        if tx%2==0 and ty%2==0: d.text((tx*48+2,ty*48+1),'%d,%d'%(tx,ty),fill=(255,255,0))
im.save(out); print(out, 'origin', mx, my)
