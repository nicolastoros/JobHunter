import sys, xml.etree.ElementTree as ET
root=ET.parse(sys.argv[1]).getroot(); want=sys.argv[2:]
ts=sorted([(int(t.get('firstgid')),int(t.get('columns')),t.get('name')[:2]) for t in root.findall('tileset')])
def name(g):
  g&=0x1FFFFFFF
  for fg,c,n in reversed(ts):
    if g>=fg: i=g-fg; return '%s%d,%d'%(n[0],i%c,i//c)
def walk(node,path=''):
  for ch in node:
    if ch.tag=='group': walk(ch,path+ch.get('name')+'/')
    elif ch.tag=='layer':
      full=path+ch.get('name')
      if want and not any(w in full for w in want): continue
      cells={}
      for c in ch.iter('chunk'):
        cx,cy,w=int(c.get('x')),int(c.get('y')),int(c.get('width'))
        vals=[int(t) for t in c.text.replace('\n','').split(',') if t.strip()]
        for i,g in enumerate(vals):
          if g: cells[(cx+i%w,cy+i//w)]=name(g)
      if not cells: continue
      print('==',full,'vis' if ch.get('visible','1')=='1' else 'HIDDEN')
      xs=[k[0] for k in cells]; ys=[k[1] for k in cells]
      for y in range(min(ys),max(ys)+1):
        print('%3d '%y+' '.join('%-7s'%cells.get((x,y),'.') for x in range(min(xs),max(xs)+1)))
      print('   x from',min(xs))
walk(root)
