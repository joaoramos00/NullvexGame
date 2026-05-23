"""Generates Stage_01T.png — 128x160 spritesheet (4x5 grid, 32x32 tiles) fire/volcano theme."""
from PIL import Image
import random, os

random.seed(1337)

TILE = 32
COLS = 4
ROWS = 5
W = TILE * COLS   # 128
H = TILE * ROWS   # 160

# --- Palette ---
BLANK   = (  0,   0,   0,   0)
RK_VDK  = ( 22,   8,   2, 255)
RK_DK   = ( 42,  18,   5, 255)
RK_MD   = ( 70,  33,  10, 255)
RK_LT   = (100,  52,  20, 255)
RK_HI   = (135,  75,  32, 255)
LV_DK   = (150,  22,   0, 255)
LV_MD   = (220,  72,   0, 255)
LV_BR   = (255, 150,  10, 255)
LV_GL   = (255, 218,  55, 255)
BG_VDK  = (  7,   2,   0, 255)
BG_DK   = ( 18,   7,   1, 255)

img = Image.new("RGBA", (W, H), BLANK)
px  = img.load()

def sp(col, row, x, y, c):
    gx, gy = col * TILE + x, row * TILE + y
    if 0 <= gx < W and 0 <= gy < H and row < ROWS:
        px[gx, gy] = c

def rock_fill(col, row, base=RK_DK):
    for y in range(TILE):
        for x in range(TILE):
            r = random.random()
            c = RK_VDK if r < 0.08 else RK_MD if r < 0.15 else base
            sp(col, row, x, y, c)

def bg_fill(col, row):
    for y in range(TILE):
        for x in range(TILE):
            r = random.random()
            c = BG_VDK if r < 0.7 else BG_DK if r < 0.92 else RK_VDK
            sp(col, row, x, y, c)

# ──────────────────────────────────────────────
# (0,0)  Solid rock fill — interior
# ──────────────────────────────────────────────
rock_fill(0, 0)
for (vx, vy) in [(5,4),(6,5),(7,6),(8,7),(18,12),(19,13),(24,21),(25,22)]:
    sp(0, 0, vx, vy, LV_DK)
    if vx + 1 < TILE: sp(0, 0, vx+1, vy, LV_MD)

# ──────────────────────────────────────────────
# (1,0)  Ground top — walkable surface
# ──────────────────────────────────────────────
rock_fill(1, 0)
for y in range(5):
    for x in range(TILE):
        if y == 0:
            c = RK_HI if random.random() > 0.25 else RK_LT
        elif y == 1:
            c = RK_LT if random.random() > 0.35 else RK_HI
        elif y == 2:
            c = RK_MD if random.random() > 0.3 else RK_LT
        elif y == 3:
            c = RK_DK if random.random() > 0.4 else RK_MD
        else:
            c = RK_VDK if random.random() > 0.5 else RK_DK
        sp(1, 0, x, y, c)

# ──────────────────────────────────────────────
# (2,0)  Ground top-left corner
# ──────────────────────────────────────────────
rock_fill(2, 0)
# surface only on right portion
for y in range(5):
    start_x = max(0, 14 - y * 3)
    for x in range(start_x, TILE):
        if y == 0:
            c = RK_HI if random.random() > 0.25 else RK_LT
        elif y == 1:
            c = RK_LT if random.random() > 0.35 else RK_HI
        elif y == 2:
            c = RK_MD
        else:
            c = RK_DK
        sp(2, 0, x, y, c)
# left edge shadow + transparent cut
for y in range(TILE):
    drop_x = max(0, 6 - y // 4)
    for x in range(drop_x):
        sp(2, 0, x, y, BLANK)
    if drop_x < TILE:
        sp(2, 0, drop_x, y, RK_VDK)

# ──────────────────────────────────────────────
# (3,0)  Ground top-right corner
# ──────────────────────────────────────────────
rock_fill(3, 0)
for y in range(5):
    end_x = min(TILE, TILE - 14 + y * 3)
    for x in range(end_x):
        if y == 0:
            c = RK_HI if random.random() > 0.25 else RK_LT
        elif y == 1:
            c = RK_LT if random.random() > 0.35 else RK_HI
        elif y == 2:
            c = RK_MD
        else:
            c = RK_DK
        sp(3, 0, x, y, c)
for y in range(TILE):
    drop_x = min(TILE - 1, TILE - 1 - max(0, 6 - y // 4))
    for x in range(drop_x + 1, TILE):
        sp(3, 0, x, y, BLANK)
    sp(3, 0, drop_x, y, RK_VDK)

# ──────────────────────────────────────────────
# (0,1)  Platform solid fill
# ──────────────────────────────────────────────
PSLAB_TOP = 10
PSLAB_BOT = 21
for y in range(TILE):
    for x in range(TILE):
        if PSLAB_TOP <= y <= PSLAB_BOT:
            r = random.random()
            c = RK_MD if r < 0.5 else RK_DK if r < 0.82 else RK_LT
            sp(0, 1, x, y, c)

# ──────────────────────────────────────────────
# (1,1)  Platform top — standing surface
# ──────────────────────────────────────────────
for y in range(TILE):
    for x in range(TILE):
        if y == PSLAB_TOP:
            c = RK_HI if random.random() > 0.3 else RK_LT
            sp(1, 1, x, y, c)
        elif y == PSLAB_TOP + 1:
            sp(1, 1, x, y, RK_LT)
        elif PSLAB_TOP + 2 <= y <= PSLAB_BOT:
            r = random.random()
            c = RK_MD if r < 0.5 else RK_DK if r < 0.82 else RK_LT
            sp(1, 1, x, y, c)

# ──────────────────────────────────────────────
# (2,1)  Platform left edge
# ──────────────────────────────────────────────
for y in range(TILE):
    for x in range(TILE):
        if PSLAB_TOP <= y <= PSLAB_BOT:
            if x < 3:
                sp(2, 1, x, y, BLANK)
            elif x < 6:
                sp(2, 1, x, y, RK_VDK)
            elif x < 9:
                sp(2, 1, x, y, RK_DK)
            else:
                r = random.random()
                sp(2, 1, x, y, RK_MD if r < 0.5 else RK_DK)
            if y == PSLAB_TOP and x >= 3:
                sp(2, 1, x, y, RK_HI if x >= 6 else RK_LT)

# ──────────────────────────────────────────────
# (3,1)  Platform right edge
# ──────────────────────────────────────────────
for y in range(TILE):
    for x in range(TILE):
        if PSLAB_TOP <= y <= PSLAB_BOT:
            rx = TILE - 1 - x
            if rx < 3:
                sp(3, 1, x, y, BLANK)
            elif rx < 6:
                sp(3, 1, x, y, RK_VDK)
            elif rx < 9:
                sp(3, 1, x, y, RK_DK)
            else:
                r = random.random()
                sp(3, 1, x, y, RK_MD if r < 0.5 else RK_DK)
            if y == PSLAB_TOP and rx >= 3:
                sp(3, 1, x, y, RK_HI if rx >= 6 else RK_LT)

# ──────────────────────────────────────────────
# (0,2)  Background dark — cave wall
# ──────────────────────────────────────────────
bg_fill(0, 2)

# ──────────────────────────────────────────────
# (1,2)  Lava pool
# ──────────────────────────────────────────────
import math
for y in range(TILE):
    for x in range(TILE):
        wave = int(3 * math.sin(x * 0.45) + 3 * math.sin(x * 0.9 + 1.2))
        surf = 8 + wave
        if y < surf - 2:
            sp(1, 2, x, y, BG_VDK)
        elif y < surf:
            c = LV_GL if random.random() > 0.4 else LV_BR
            sp(1, 2, x, y, c)
        elif y < surf + 5:
            c = LV_BR if random.random() > 0.45 else LV_MD
            sp(1, 2, x, y, c)
        elif y < surf + 14:
            c = LV_MD if random.random() > 0.4 else LV_BR if random.random() > 0.6 else LV_DK
            sp(1, 2, x, y, c)
        else:
            c = LV_DK if random.random() > 0.35 else LV_MD
            sp(1, 2, x, y, c)

# ──────────────────────────────────────────────
# (2,2)  Flame decoration
# ──────────────────────────────────────────────
bg_fill(2, 2)
CX = 16
for y in range(TILE):
    iy = TILE - 1 - y  # 0=bottom, 31=top
    hw = max(0, int(10 * math.pow(max(0, 1 - iy / 26.0), 0.7)) - 1)
    if hw <= 0:
        continue
    for x in range(CX - hw, CX + hw + 1):
        if 0 <= x < TILE:
            d = abs(x - CX) / max(hw, 1)
            if d < 0.25:
                c = LV_GL if iy > 10 else LV_BR
            elif d < 0.55:
                c = LV_BR if iy > 6 else LV_MD
            else:
                c = LV_MD if iy > 4 else LV_DK
            sp(2, 2, x, y, c)

# ──────────────────────────────────────────────
# (3,2)  Stalactite — rock hanging from ceiling
# ──────────────────────────────────────────────
bg_fill(3, 2)
SCX = 16
for y in range(TILE):
    w = max(0, int(13 * (1.0 - y / 23.0)))
    if y > 23:
        break
    for x in range(SCX - w, SCX + w + 1):
        if 0 <= x < TILE:
            d = abs(x - SCX) / max(w, 1) if w > 0 else 0
            if y == 0:
                c = RK_HI
            elif d < 0.25:
                c = RK_LT if y < 6 else RK_MD
            elif d < 0.6:
                c = RK_MD if y < 8 else RK_DK
            else:
                c = RK_DK if y < 8 else RK_VDK
            sp(3, 2, x, y, c)

# ──────────────────────────────────────────────
# (0,3)  Transparent — empty tile
# ──────────────────────────────────────────────
# already BLANK

# ──────────────────────────────────────────────
# (1,3)  Rock bottom — underside
# ──────────────────────────────────────────────
rock_fill(1, 3)
for y in range(26, TILE):
    for x in range(TILE):
        depth = y - 25
        c = RK_VDK if random.random() > 0.35 or depth > 4 else RK_DK
        sp(1, 3, x, y, c)
# jagged bottom edge hints
for x in range(0, TILE, 4):
    jag = random.randint(28, 31)
    for y in range(jag, TILE):
        sp(1, 3, x, y, RK_VDK)

# ──────────────────────────────────────────────
# (2,3)  Lava drip
# ──────────────────────────────────────────────
bg_fill(2, 3)
for drip_x, length in [(10, 14), (22, 19)]:
    for y in range(length):
        hw = 2 if y < length - 4 else max(1, 2 - (y - (length - 4)))
        for x in range(drip_x - hw, drip_x + hw + 1):
            if 0 <= x < TILE:
                d = abs(x - drip_x)
                c = LV_GL if d == 0 else LV_BR if d == 1 else LV_MD
                sp(2, 3, x, y, c)
    # teardrop tip
    for dy in range(4):
        hw2 = max(0, 2 - dy)
        for x in range(drip_x - hw2, drip_x + hw2 + 1):
            ty = length + dy
            if 0 <= x < TILE and ty < TILE:
                d = abs(x - drip_x)
                c = LV_BR if d == 0 and dy < 2 else LV_MD if d <= 1 else LV_DK
                sp(2, 3, x, ty, c)

# ──────────────────────────────────────────────
# (3,3)  Ember sparks
# ──────────────────────────────────────────────
bg_fill(3, 3)
clusters = [
    (8, 24, 3), (16, 18, 2), (22, 26, 2),
    (5, 13, 2), (25, 9, 2), (13, 5, 3),
    (28, 20, 2), (3, 28, 2), (20, 3, 2),
    (11, 30, 1), (29, 4, 1),
]
for (ex, ey, size) in clusters:
    c_center = LV_GL
    c_mid    = LV_BR
    c_outer  = LV_MD
    for dy in range(-size+1, size):
        for dx in range(-size+1, size):
            d = abs(dx) + abs(dy)
            nx, ny = ex + dx, ey + dy
            if 0 <= nx < TILE and 0 <= ny < TILE:
                if d == 0:
                    sp(3, 3, nx, ny, c_center)
                elif d == 1:
                    sp(3, 3, nx, ny, c_mid)
                elif d == 2 and size >= 3:
                    sp(3, 3, nx, ny, c_outer)

# ──────────────────────────────────────────────
# (0,4)  Wall left — face direita visível
# (player encosta à esquerda e pula na face direita)
# ──────────────────────────────────────────────
rock_fill(0, 4)
# lava seams
for (vx, vy) in [(4, 6), (5, 14), (3, 22), (6, 28)]:
    sp(0, 4, vx, vy, LV_DK)
    if vx + 1 < TILE: sp(0, 4, vx + 1, vy, LV_MD)
# highlight na borda direita (face exposta)
for y in range(TILE):
    sp(0, 4, TILE - 1, y, RK_HI if random.random() > 0.25 else RK_LT)
    sp(0, 4, TILE - 2, y, RK_LT if random.random() > 0.35 else RK_HI)
    sp(0, 4, TILE - 3, y, RK_MD)
    sp(0, 4, TILE - 4, y, RK_DK if random.random() > 0.4 else RK_MD)

# ──────────────────────────────────────────────
# (1,4)  Wall right — face esquerda visível
# (player encosta à direita e pula na face esquerda)
# ──────────────────────────────────────────────
rock_fill(1, 4)
for (vx, vy) in [(26, 5), (27, 13), (25, 21), (28, 27)]:
    sp(1, 4, vx, vy, LV_DK)
    if vx + 1 < TILE: sp(1, 4, vx + 1, vy, LV_MD)
for y in range(TILE):
    sp(1, 4, 0, y, RK_HI if random.random() > 0.25 else RK_LT)
    sp(1, 4, 1, y, RK_LT if random.random() > 0.35 else RK_HI)
    sp(1, 4, 2, y, RK_MD)
    sp(1, 4, 3, y, RK_DK if random.random() > 0.4 else RK_MD)

# ──────────────────────────────────────────────
# (2,4)  Canto parede-esquerda + teto
# (junção entre parede esquerda e teto)
# ──────────────────────────────────────────────
rock_fill(2, 4)
# face direita (parede)
for y in range(TILE):
    sp(2, 4, TILE - 1, y, RK_HI if random.random() > 0.25 else RK_LT)
    sp(2, 4, TILE - 2, y, RK_LT)
    sp(2, 4, TILE - 3, y, RK_MD)
# face inferior (teto)
for x in range(TILE):
    sp(2, 4, x, TILE - 1, RK_HI if random.random() > 0.25 else RK_LT)
    sp(2, 4, x, TILE - 2, RK_LT)
    sp(2, 4, x, TILE - 3, RK_MD)
# canto em diagonal
for d in range(8):
    sp(2, 4, TILE - 1 - d, TILE - 1 - (7 - d), RK_VDK)

# ──────────────────────────────────────────────
# (3,4)  Canto parede-direita + teto
# (junção entre parede direita e teto)
# ──────────────────────────────────────────────
rock_fill(3, 4)
# face esquerda (parede)
for y in range(TILE):
    sp(3, 4, 0, y, RK_HI if random.random() > 0.25 else RK_LT)
    sp(3, 4, 1, y, RK_LT)
    sp(3, 4, 2, y, RK_MD)
# face inferior (teto)
for x in range(TILE):
    sp(3, 4, x, TILE - 1, RK_HI if random.random() > 0.25 else RK_LT)
    sp(3, 4, x, TILE - 2, RK_LT)
    sp(3, 4, x, TILE - 3, RK_MD)
# canto em diagonal
for d in range(8):
    sp(3, 4, d, TILE - 1 - (7 - d), RK_VDK)

# ──────────────────────────────────────────────
# Save
# ──────────────────────────────────────────────
out = os.path.join("stages", "stage_01", "Stage_01T.png")
img.save(out)
print(f"Saved: {out}  ({W}x{H})")
