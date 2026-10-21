#!/usr/bin/env python3
"""Find / tap UI nodes on the box through uiautomator dump + input tap.
  uitap.py --id input_source_url            tap node whose resource-id ends with /input_source_url
  uitap.py --text "4K 60Hz (3840x2160)"     tap node with exact text
  uitap.py --contains 欧乐 --find            print matches, do not tap
  uitap.py --id confirmBtn --wait 8         retry dump for up to 8 s until found
  uitap.py --text X --scroll 6              swipe up (list scroll) up to 6 times until found
  uitap.py --dump                           print all texts/ids
Exit 0 when found (and tapped), 1 when not found."""
import argparse, html, os, re, subprocess, sys, time
TOOLKIT = os.environ.get("TOOLKIT", os.path.expanduser("~/src/ubox/cleanyourtv"))
PY = os.path.join(TOOLKIT, "tools", "venv", "bin", "python"); TVPY = os.path.join(TOOLKIT, "tools", "tv.py")

def sh(cmd):
    return subprocess.run([PY, "-I", TVPY, cmd], capture_output=True, text=True).stdout

def dump():
    return sh("uiautomator dump /data/local/tmp/ui.xml >/dev/null 2>&1; cat /data/local/tmp/ui.xml")

NODE = re.compile(r'<node ([^>]*)/?>')
def nodes(xml):
    out = []
    for m in NODE.finditer(xml):
        a = dict(re.findall(r'(\S+?)="([^"]*)"', m.group(1)))
        b = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', a.get("bounds", ""))
        if not b: continue
        x1, y1, x2, y2 = map(int, b.groups())
        a["_c"] = ((x1 + x2) // 2, (y1 + y2) // 2); a["_text"] = html.unescape(a.get("text", "")); a["_rid"] = a.get("resource-id", "")
        a["_area"] = (x2 - x1) * (y2 - y1)
        out.append(a)
    return out

def match(n, args):
    if args.id and not n["_rid"].endswith("/" + args.id) and n["_rid"] != args.id: return False
    if args.text and n["_text"] != args.text: return False
    if args.contains and args.contains not in n["_text"]: return False
    if args.pkg and n.get("package") != args.pkg: return False
    return bool(args.id or args.text or args.contains)

def main():
    p = argparse.ArgumentParser(); p.add_argument("--id"); p.add_argument("--text"); p.add_argument("--contains"); p.add_argument("--pkg")
    p.add_argument("--find", action="store_true"); p.add_argument("--dump", action="store_true"); p.add_argument("--wait", type=float, default=0)
    p.add_argument("--scroll", type=int, default=0); p.add_argument("--swipe", default="1500,950,1500,250")
    args = p.parse_args()
    if args.dump:
        for n in nodes(dump()):
            if n["_text"].strip() or n["_rid"]: print(f'{n["_text"][:60]!r} | {n["_rid"].split("/")[-1]} | {n.get("class","").split(".")[-1]} | {n.get("bounds")} | focused={n.get("focused")} checked={n.get("checked")}')
        return 0
    deadline = time.time() + args.wait; scrolls = 0
    while True:
        found = [n for n in nodes(dump()) if match(n, args) and n["_area"] > 0]
        if found:
            n = found[0]
            if args.find:
                for f in found: print(f'{f["_text"]!r} | {f["_rid"].split("/")[-1]} | {f.get("bounds")}')
                return 0
            x, y = n["_c"]; sh(f"input tap {x} {y}"); print(f'tapped {n["_text"]!r}/{n["_rid"].split("/")[-1]} at {x},{y}'); return 0
        if args.scroll and scrolls < args.scroll:
            x1, y1, x2, y2 = args.swipe.split(","); sh(f"input swipe {x1} {y1} {x2} {y2} 400"); scrolls += 1; time.sleep(1.2); continue
        if time.time() < deadline: time.sleep(1); continue
        print("not found:", args.id or args.text or args.contains, file=sys.stderr); return 1

if __name__ == "__main__": sys.exit(main())
