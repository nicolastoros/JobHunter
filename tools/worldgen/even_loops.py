"""Evens out looping animations whose rows have fewer frames than the other directions (the swordsman's
idle facing up has 4 frames, the rest 12): the short row plays back and forth (0-1-2-3-2-1) with longer
frames, so every direction breathes at the same pace instead of twitching."""
import re, sys


def even_loops(text):
    blocks = list(re.finditer(r'\{\n"frames": \[(.*?)\],\n"loop": true,\n"name": &"([a-z_]+)_(down|up|left|right)",\n"speed": ([\d.]+)\n\}', text, re.S))
    longest = {}
    for b in blocks:
        n = b.group(1).count('"texture"')
        longest[b.group(2)] = max(longest.get(b.group(2), 0), n)
    out, last = [], 0
    for b in blocks:
        frames = re.findall(r'SubResource\("([^"]+)"\)', b.group(1))
        want = longest[b.group(2)]
        if 2 < len(frames) < want:
            seq = frames + frames[-2:0:-1]                 # ping-pong
            dur = want / len(seq)
            body = ", ".join('{\n"duration": %s,\n"texture": SubResource("%s")\n}' % (("%.3f" % dur).rstrip("0").rstrip("."), f) for f in seq)
            out.append(text[last:b.start(1)] + body)
            last = b.end(1)
    out.append(text[last:])
    return "".join(out)


if __name__ == "__main__":
    for path in sys.argv[1:]:
        s = open(path, encoding="utf-8").read()
        t = even_loops(s)
        if t != s:
            open(path, "w", encoding="utf-8", newline="\n").write(t)
            print("evened", path)
