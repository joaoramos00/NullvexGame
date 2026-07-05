"""Downloads and stitches IntroBoss east/south sprites from PixelLab ZIP."""
import urllib.request, os, zipfile, io, sys
from PIL import Image

API_KEY = os.environ.get("PIXELLAB_API_KEY", "")
if not API_KEY:
    sys.exit("PIXELLAB_API_KEY not set")

OUT = r"C:\Users\Usuário\SnesGame\characters\bosses\intro_boss"
BASE_CHAR = "replace_the_round_do"

# (output_name, zip_folder_glob, direction, frame_count)
ANIMS = [
    ("intro_boss_entry", f"{BASE_CHAR}/animations/retnE/south", 9),
    ("intro_boss_idle",  f"{BASE_CHAR}/animations/The_armored_soldier_stands_tall_and_shifts_their_w/east", 8),
    ("intro_boss_walk",  f"{BASE_CHAR}/animations/heavy_tactical_walk_forward_cannon_arm_raised_slig/east", 6),
    ("intro_boss_shoot", f"{BASE_CHAR}/animations/agressive_dash/east-40883755", 7),
    ("intro_boss_dash",  f"{BASE_CHAR}/animations/agressive_dash/east-4d273bd7", 7),
]

print("Downloading character ZIP...")
url = "https://api.pixellab.ai/mcp/characters/a3d973c8-637d-4de8-bf8d-65e325dd7bb0/download"
req = urllib.request.Request(url, headers={"Authorization": f"Bearer {API_KEY}"})
with urllib.request.urlopen(req) as r:
    zip_data = r.read()
print(f"Downloaded {len(zip_data)//1024}KB")

with zipfile.ZipFile(io.BytesIO(zip_data)) as z:
    for out_name, folder, count in ANIMS:
        frames = []
        for i in range(count):
            path = f"{folder}/frame_{i:03d}.png"
            with z.open(path) as f:
                frames.append(Image.open(io.BytesIO(f.read())).convert("RGBA"))
        w, h = frames[0].size
        sheet = Image.new("RGBA", (w * count, h))
        for i, frame in enumerate(frames):
            sheet.paste(frame, (i * w, 0))
        out_path = os.path.join(OUT, f"{out_name}.png")
        sheet.save(out_path)
        print(f"  {out_name}.png  {count}f  {w*count}x{h}px")

print("Done.")
