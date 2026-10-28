import sys
from PIL import Image, ImageDraw
src,out,s=sys.argv[1],sys.argv[2],int(sys.argv[3])
x0,y0,x1,y1=[int(v) for v in sys.argv[4:8]] if len(sys.argv)>4 else (0,0,9999,9999)
im=Image.open(src).convert('RGBA'); cols=im.width//16
x1=min(x1,im.width//16); y1=min(y1,im.height//16)
crop=im.crop((x0*16,y0*16,x1*16,y1*16))
bg=Image.new('RGBA',crop.size,(255,0,255,255)); bg.alpha_composite(crop); bg=bg.resize((crop.width*s,crop.height*s),Image.NEAREST); d=ImageDraw.Draw(bg)
for ty in range(y1-y0):
  for tx in range(x1-x0):
    d.rectangle((tx*16*s,ty*16*s,(tx+1)*16*s-1,(ty+1)*16*s-1),outline=(0,0,0))
    d.text((tx*16*s+2,ty*16*s+1),'%d,%d'%(tx+x0,ty+y0),fill=(255,255,0))
bg.save(out)
