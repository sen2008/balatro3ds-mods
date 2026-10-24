#!/usr/bin/env python3
"""Build Balatro3DS sprites for MikasPack from the PC mod's per-card art.

The PC repo ships one 71x95 PNG per card in assets/1x/. For every sprite
named by a `sprite = "..."` line in mikaspack.lua (the negative is derived,
never named), this produces in assets/1x/:
    <name>.png, <name>_negative.png, <name>.t3x, <name>_negative.t3x

Pipeline (matches the shipped packs): resize to 70x94 (PIL LANCZOS),
generate the negative from the resized PNG with the fork's
dev/make_negative.py, then tex3ds (-f rgba) on both.

    python3 make_sprites.py [--src ~/workspace/repos/mikas/assets/1x]
"""

import argparse
import os
import re
import subprocess
import sys

from PIL import Image

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_SRC = os.path.expanduser("~/workspace/repos/mikas/assets/1x")
DEFAULT_OUT = os.path.join(SCRIPT_DIR, "assets", "1x")
NEGATIVE_SCRIPT = os.path.expanduser(
    "~/workspace/balatro3ds-fork/dev/make_negative.py")
TEX3DS = os.path.expanduser(
    "~/devkitpro-root/opt/devkitpro/tools/bin/tex3ds")


def sprite_names():
    with open(os.path.join(SCRIPT_DIR, "mikaspack.lua")) as f:
        text = f.read()
    names = []
    for m in re.finditer(r'(?m)^\s*sprite\s*=\s*"([^"]+)\.png"', text):
        if m.group(1) not in names:
            names.append(m.group(1))
    return names


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--src", default=DEFAULT_SRC)
    p.add_argument("--out", default=DEFAULT_OUT)
    args = p.parse_args(argv)

    os.makedirs(args.out, exist_ok=True)
    names = sprite_names()
    print(f"{len(names)} sprites named in mikaspack.lua")
    missing = []
    for name in names:
        src = os.path.join(args.src, name + ".png")
        if not os.path.isfile(src):
            missing.append(name)
            continue
        resized = os.path.join(args.out, name + ".png")
        Image.open(src).convert("RGBA").resize(
            (70, 94), Image.LANCZOS).save(resized)
        subprocess.run([sys.executable, NEGATIVE_SCRIPT, resized],
                       check=True, capture_output=True)
        for png in (resized, os.path.join(args.out, name + "_negative.png")):
            subprocess.run([TEX3DS, "-f", "rgba", "-o",
                            png[:-4] + ".t3x", png],
                           check=True, capture_output=True)
    if missing:
        print("MISSING SOURCE ART:", ", ".join(missing))
        return 1
    print("done:", len(names), "sprites x (png + negative) x (png + t3x)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
