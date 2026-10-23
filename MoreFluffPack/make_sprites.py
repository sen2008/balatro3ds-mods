#!/usr/bin/env python3
"""Build Balatro3DS sprites for MoreFluffPack from PC MoreFluff atlases.

Usage:
    python3 make_sprites.py mapping.json [--repo PATH] [--out DIR]
                            [--tex3ds PATH] [--negative-script PATH]

mapping.json maps sprite name -> [atlas, col, row] or
[atlas, col, row, cell_h], e.g. {"jester": ["mf_jokers", 3, 0]}.
Atlas PNGs live in <repo>/assets/1x/<atlas>.png. Cell width is 71;
cell height is 95 except mf_letterjokers (78).

For each name this produces, in the output dir:
    <name>.png, <name>_negative.png, <name>.t3x, <name>_negative.t3x

Pipeline (matches the shipped sibling packs): crop the cell, resize
to 70x94 (PIL LANCZOS), save the PNG, generate the negative from the
resized PNG with the fork's dev/make_negative.py, then run tex3ds
(-f rgba) on both PNGs.
"""

import argparse
import json
import os
import shutil
import subprocess
import sys

from PIL import Image

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_REPO = os.path.expanduser("~/workspace/repos/MoreFluff")
DEFAULT_OUT = os.path.join(SCRIPT_DIR, "assets", "1x")
DEFAULT_NEGATIVE_SCRIPT = os.path.expanduser(
    "~/workspace/balatro3ds-fork/dev/make_negative.py")
DEFAULT_TEX3DS = os.path.expanduser(
    "~/devkitpro-root/opt/devkitpro/tools/bin/tex3ds")
CELL_H = {"mf_letterjokers": 78}


def find_tex3ds(explicit):
    if explicit:
        return explicit
    found = shutil.which("tex3ds")
    if found:
        return found
    if os.path.isfile(DEFAULT_TEX3DS):
        return DEFAULT_TEX3DS
    raise SystemExit("tex3ds not found: pass --tex3ds or put it on PATH")


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("mapping", help="JSON file: sprite name -> [atlas, col, row]")
    p.add_argument("--repo", default=DEFAULT_REPO, help=f"PC MoreFluff repo (default {DEFAULT_REPO})")
    p.add_argument("--out", default=DEFAULT_OUT, help=f"output dir (default {DEFAULT_OUT})")
    p.add_argument("--tex3ds", default=None, help="path to tex3ds")
    p.add_argument("--negative-script", default=DEFAULT_NEGATIVE_SCRIPT,
                   help="path to make_negative.py")
    args = p.parse_args(argv)

    tex3ds = find_tex3ds(args.tex3ds)
    if not os.path.isfile(args.negative_script):
        raise SystemExit(f"make_negative.py not found: {args.negative_script}")

    with open(args.mapping, encoding="utf-8") as f:
        mapping = json.load(f)

    atlases = {}
    os.makedirs(args.out, exist_ok=True)
    for name, spec in sorted(mapping.items()):
        atlas_name, col, row = spec[0], int(spec[1]), int(spec[2])
        cell_h = int(spec[3]) if len(spec) > 3 else CELL_H.get(atlas_name, 95)
        if atlas_name not in atlases:
            path = os.path.join(args.repo, "assets", "1x", atlas_name + ".png")
            atlases[atlas_name] = Image.open(path).convert("RGBA")
        atlas = atlases[atlas_name]
        cell = atlas.crop((col * 71, row * cell_h, col * 71 + 71, row * cell_h + cell_h))
        img = cell.resize((70, 94), Image.LANCZOS)
        png = os.path.join(args.out, name + ".png")
        img.save(png)
        subprocess.run([sys.executable, args.negative_script, png],
                       check=True, capture_output=True)
        for src in (png, os.path.join(args.out, name + "_negative.png")):
            t3x = os.path.splitext(src)[0] + ".t3x"
            subprocess.run([tex3ds, "-f", "rgba", src, "-o", t3x],
                           check=True, capture_output=True)
        print(f"{name}: {atlas_name} ({col},{row}) cell_h={cell_h} ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
