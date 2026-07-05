from pathlib import Path
from PIL import Image


ROOT = Path(__file__).resolve().parent
RUN_DIR = ROOT / "run"
OUT = ROOT / "KawagaelRun_v2.png"
FRAME_SIZE = 68
FRAME_COUNT = 8


def main():
    strip = Image.new("RGBA", (FRAME_SIZE * FRAME_COUNT, FRAME_SIZE), (0, 0, 0, 0))
    for index in range(1, FRAME_COUNT + 1):
        frame = Image.open(RUN_DIR / f"run-{index}.png").convert("RGBA")
        bbox = frame.getbbox()
        cell = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
        if bbox:
            crop = frame.crop(bbox)
            scale = min(60 / crop.width, 62 / crop.height, 1.0)
            new_size = (max(1, round(crop.width * scale)), max(1, round(crop.height * scale)))
            crop = crop.resize(new_size, Image.Resampling.NEAREST)
            x = (FRAME_SIZE - crop.width) // 2
            y = FRAME_SIZE - crop.height - 2
            cell.alpha_composite(crop, (x, y))
        strip.alpha_composite(cell, ((index - 1) * FRAME_SIZE, 0))
    strip.save(OUT)
    print(OUT)


if __name__ == "__main__":
    main()
