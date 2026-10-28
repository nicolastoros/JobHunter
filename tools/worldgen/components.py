import sys
from PIL import Image, ImageDraw
from collections import deque
src,out=sys.argv[1],sys.argv[2]; gap=int(sys.argv[3]) if len(sys.argv)>3 else 1
im=Image.open(src).convert('RGBA'); W,H=im.size; a=im.split()[3].load()
seen=set(); comps=[]
for y in range(H):
  for x in range(W):
    if a[x,y]>0 and (x,y) not in seen:
      q=deque([(x,y)]); seen.add((x,y)); x0=x1=x; y0=y1=y
      while q:
        cx,cy=q.popleft(); x0=min(x0,cx);x1=max(x1,cx);y0=min(y0,cy);y1=max(y1,cy)
        for dx in range(-gap,gap+1):
          for dy in range(-gap,gap+1):
            nx,ny=cx+dx,cy+dy
            if 0<=nx<W and 0<=ny<H and (nx,ny) not in seen and a[nx,ny]>0:
              seen.add((nx,ny)); q.append((nx,ny))
      if (x1-x0)*(y1-y0)>=12: comps.append((x0,y0,x1+1,y1+1))
comps.sort(key=lambda r:(r[1]//16,r[0]))
s=2; big=im.resize((W*s,H*s),Image.NEAREST); bg=Image.new('RGBA',big.size,(60,60,70,255)); bg.alpha_composite(big); d=ImageDraw.Draw(bg)
for i,(x0,y0,x1,y1) in enumerate(comps):
  d.rectangle((x0*s,y0*s,x1*s-1,y1*s-1),outline=(255,0,0)); d.text((x0*s+1,y0*s+1),str(i),fill=(255,255,0))
  print(i,(x0,y0,x1,y1),x1-x0,y1-y0)
bg.save(out)
