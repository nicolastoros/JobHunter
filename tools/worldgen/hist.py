import sys, xml.etree.ElementTree as ET, collections
path=sys.argv[1]; want=sys.argv[2:]
root=ET.parse(path).getroot()
ts=sorted([(int(t.get('firstgid')),int(t.get('columns') or 1),t.get('name')) for t in root.findall('tileset')])
def name(g):
  flip=g>>29; g&=0x1FFFFFFF
  for fg,c,n in reversed(ts):
    if g>=fg: i=g-fg; return '%s(%d,%d)%s'%(n[:6],i%c,i//c,'F%d'%flip if flip else '')
def walk(node,p=''):
  for ch in node:
    if ch.tag=='group': walk(ch,p+ch.get('name')+'/')
    elif ch.tag=='layer' and any(w==p+ch.get('name') for w in want):
      cnt=collections.Counter()
      for c in ch.iter('chunk'):
        for t in c.text.replace('\n','').split(','):
          if t.strip() and t.strip()!='0': cnt[name(int(t))]+=1
      print('==',p+ch.get('name'),len(cnt),'distinct'); print('  ',' '.join('%s:%d'%kv for kv in cnt.most_common(60)))
walk(root)
