#!/usr/bin/env python3
"""Build Balatro3DS sprites for BuncoPack from a PC Bunco atlas.

Usage:
    python3 make_sprites.py mapping.json [--atlas PATH] [--out DIR]
                            [--cell-w 71] [--cell-h 95]
                            [--out-w 70] [--out-h 94]
                            [--tex3ds PATH] [--negative-script PATH]

mapping.json maps sprite name -> [col, row] (0-indexed atlas cell), e.g.
    {"calling_card": [0, 0], "claw": [10, 1]}

For each name this produces, in the output dir:
    <name>.png, <name>_negative.png, <name>.t3x, <name>_negative.t3x

Pipeline (matches the shipped PokermonPack / BuncoPack sprites exactly):
crop the cell (--cell-w x --cell-h, default 71x95) from the atlas, resize to
--out-w x --out-h (default 70x94, PIL LANCZOS), save the PNG, generate the
negative from the *resized* PNG with the fork's dev/make_negative.py, then
run tex3ds (-f rgba) on both PNGs.

Defaults target the Jokers atlas. Reuse for Minor Arcana with:
    python3 make_sprites.py minor.json \\
        --atlas /tmp/paperback-pc/assets/1x/MinorArcana.png
(cell size is the same 71x95 there; pass --cell-w/--cell-h if it ever differs.)
"""

import argparse
import json
import os
import shutil
import subprocess
import sys

from PIL import Image

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_ATLAS = os.path.expanduser(
    "~/workspace/bunco-src/src/assets/1x/Jokers/Jokers.png")
DEFAULT_OUT = os.path.join(SCRIPT_DIR, "assets", "1x")
DEFAULT_NEGATIVE_SCRIPT = os.path.expanduser(
    "~/workspace/balatro3ds-fork/dev/make_negative.py")
DEFAULT_TEX3DS = os.path.expanduser(
    "~/devkitpro-root/opt/devkitpro/tools/bin/tex3ds")


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
    p.add_argument("mapping", help="JSON file: sprite name -> [col, row]")
    p.add_argument("--atlas", default=DEFAULT_ATLAS, help=f"atlas PNG (default {DEFAULT_ATLAS})")
    p.add_argument("--out", default=DEFAULT_OUT, help=f"output dir (default {DEFAULT_OUT})")
    p.add_argument("--cell-w", type=int, default=71, help="atlas cell width (default 71)")
    p.add_argument("--cell-h", type=int, default=95, help="atlas cell height (default 95)")
    p.add_argument("--out-w", type=int, default=70, help="output sprite width (default 70)")
    p.add_argument("--out-h", type=int, default=94, help="output sprite height (default 94)")
    p.add_argument("--tex3ds", default=None, help="path to tex3ds (default: PATH, else devkitPro)")
    p.add_argument("--negative-script", default=DEFAULT_NEGATIVE_SCRIPT,
                   help="path to make_negative.py")
    args = p.parse_args(argv)

    tex3ds = find_tex3ds(args.tex3ds)
    if not os.path.isfile(args.negative_script):
        raise SystemExit(f"make_negative.py not found: {args.negative_script}")

    with open(args.mapping, encoding="utf-8") as f:
        mapping = json.load(f)

    atlas = Image.open(args.atlas).convert("RGBA")
    os.makedirs(args.out, exist_ok=True)

    for name, cell in mapping.items():
        col, row = int(cell[0]), int(cell[1])
        x0, y0 = col * args.cell_w, row * args.cell_h
        box = (x0, y0, x0 + args.cell_w, y0 + args.cell_h)
        if box[2] > atlas.width or box[3] > atlas.height:
            raise SystemExit(
                f"{name}: cell ({col},{row}) box {box} exceeds atlas {atlas.size}")
        sprite = atlas.crop(box).resize((args.out_w, args.out_h), Image.LANCZOS)
        png = os.path.join(args.out, name + ".png")
        sprite.save(png)

        # Negative from the resized PNG, via the fork's tool (exact transform).
        subprocess.run([sys.executable, args.negative_script, png],
                       check=True, stdout=subprocess.DEVNULL)
        neg_png = os.path.join(args.out, name + "_negative.png")
        if not os.path.isfile(neg_png):
            raise SystemExit(f"{name}: negative PNG was not produced")

        for src in (png, neg_png):
            t3x = os.path.splitext(src)[0] + ".t3x"
            subprocess.run([tex3ds, "-f", "rgba", src, "-o", t3x],
                           check=True, stdout=subprocess.DEVNULL)
        print(f"{name}: cell ({col},{row}) -> {name}.png/_negative.png + .t3x x2")

    print(f"done: {len(mapping)} sprites in {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
