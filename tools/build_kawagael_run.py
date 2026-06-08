#!/usr/bin/env python3
"""Monta KawagaelRun.png a partir das rotações east dos 8 character states.

Pipeline por frame: trim do bbox opaco -> escala global única (mesmo tamanho em
todos os frames) -> alinhamento dos pés a uma linha fixa -> stitch horizontal.

Uso:
  python tools/build_kawagael_run.py
Lê:  characters/ranged/kawagael/_raw/f*/f*_east.png  (ordenado f0..f7)
Grava: characters/ranged/kawagael/KawagaelRun.png
"""
from pathlib import Path

from PIL import Image

FRAME = 68
GROUND_PAD = 2   # px do fundo da célula até a linha dos pés
TOP_PAD = 2      # respiro no topo
RAW_DIR = Path("characters/ranged/kawagael/_raw")
OUT = Path("characters/ranged/kawagael/KawagaelRun.png")

# Ordem de exibição no ciclo (nomes das subpastas em _raw). A sequência de
# GERAÇÃO no PixelLab (f0..f4) não é a ordem boa de animação — esta é a corrigida.
# Frames presentes que não estiverem aqui entram ao final.
FRAME_ORDER = ["f0", "f2", "f3", "f4", "f1"]


def trim(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    bbox = img.getbbox()
    return img.crop(bbox) if bbox else img


def build_sheet(images: list[Image.Image]) -> Image.Image:
    trimmed = [trim(im) for im in images]
    max_h = max(t.height for t in trimmed)
    max_w = max(t.width for t in trimmed)
    avail_h = FRAME - GROUND_PAD - TOP_PAD
    avail_w = FRAME
    scale = min(avail_h / max_h, avail_w / max_w)

    sheet = Image.new("RGBA", (FRAME * len(trimmed), FRAME), (0, 0, 0, 0))
    for i, t in enumerate(trimmed):
        nw = max(1, round(t.width * scale))
        nh = max(1, round(t.height * scale))
        scaled = t.resize((nw, nh), Image.LANCZOS)
        x = i * FRAME + (FRAME - nw) // 2
        y = FRAME - GROUND_PAD - nh   # fundo (pés) na linha fixa
        sheet.paste(scaled, (x, y), scaled)
    return sheet


def _ordered_paths() -> list[Path]:
    raw = {p.parent.name: p for p in RAW_DIR.glob("f*/f*_east.png")}
    ordered = [raw[name] for name in FRAME_ORDER if name in raw]
    for name in sorted(raw):               # frames presentes fora de FRAME_ORDER → ao final
        if name not in FRAME_ORDER:
            ordered.append(raw[name])
    return ordered


def main() -> None:
    paths = _ordered_paths()
    if len(paths) < 2:
        raise SystemExit(f"Preciso de >=2 PNGs east em {RAW_DIR}, achei {len(paths)}: {paths}")
    if len(paths) != 8:
        print(f"AVISO: {len(paths)}/8 frames (placeholder).")
    print(f"Ordem dos frames: {[p.parent.name for p in paths]}")
    images = [Image.open(p) for p in paths]
    sheet = build_sheet(images)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    print(f"Salvo: {OUT} ({sheet.size[0]}x{sheet.size[1]})")


if __name__ == "__main__":
    main()
