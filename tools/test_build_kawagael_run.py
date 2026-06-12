"""Teste do build_kawagael_run com frames sintéticos (sem dependência de PixelLab)."""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

from PIL import Image
from build_kawagael_run import build_sheet, FRAME, GROUND_PAD


def _synthetic(width: int, height: int) -> Image.Image:
    """Canvas 256x256 com um retângulo opaco; a fileira de baixo do retângulo = 'pés'."""
    img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    x0 = (256 - width) // 2
    y1 = 200
    y0 = y1 - height
    for y in range(y0, y1):
        for x in range(x0, x0 + width):
            img.putpixel((x, y), (0, 200, 120, 255))
    return img


def _lowest_opaque_y(cell: Image.Image) -> int:
    px = cell.load()
    w, h = cell.size
    for y in range(h - 1, -1, -1):
        for x in range(w):
            if px[x, y][3] > 0:
                return y
    return -1


def main() -> None:
    frames = [
        _synthetic(60, 150), _synthetic(70, 120), _synthetic(80, 160),
        _synthetic(65, 140), _synthetic(60, 150), _synthetic(70, 120),
        _synthetic(80, 160), _synthetic(65, 140),
    ]
    sheet = build_sheet(frames)

    assert sheet.size == (FRAME * 8, FRAME), f"tamanho errado: {sheet.size}"

    expected_y = FRAME - GROUND_PAD - 1
    for i in range(8):
        cell = sheet.crop((i * FRAME, 0, (i + 1) * FRAME, FRAME))
        low = _lowest_opaque_y(cell)
        assert low == expected_y, f"frame {i}: pés em y={low}, esperado {expected_y}"
        bbox = cell.getbbox()
        assert bbox is not None, f"frame {i} vazio"

    print("TEST_BUILD_KAWAGAEL: PASS")


if __name__ == "__main__":
    main()
