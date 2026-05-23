"""Generates Stage_01T.png — 128x128 (4x4 grid, 32x32 tiles) fire/volcano theme.
Tile layout mirrors Stage_00T exactly so both share the same positional descriptions."""
from PIL import Image
import random, os

random.seed(42)

TILE = 32
COLS = ROWS = 4
W = H = TILE * COLS   # 128x128

# --- Fire/Volcano Palette ---
BLANK  = (  0,   0,   0,   0)
RK_VDK = ( 22,   8,   2, 255)   # very dark volcanic rock
RK_DK  = ( 42,  18,   5, 255)   # dark rock
RK_MD  = ( 70,  33,  10, 255)   # mid rock
RK_LT  = (100,  52,  20, 255)   # light rock surface
RK_HI  = (135,  75,  32, 255)   # brightest highlight
LV_DK  = (150,  22,   0, 255)   # dark lava vein
LV_MD  = (220,  72,   0, 255)   # bright lava vein

img = Image.new("RGBA", (W, H), BLANK)
px  = img.load()

def sp(col, row, x, y, c):
    gx, gy = col * TILE + x, row * TILE + y
    if 0 <= gx < W and 0 <= gy < H:
        px[gx, gy] = c

# ── Surface gradient: distance 0 = outermost exposed edge ──
SD = 4   # surface depth in pixels
M  = TILE // 2   # half-tile pivot for L-tiles

def surf(d):
    r = random.random()
    if d == 0: return RK_HI if r > 0.25 else RK_LT
    if d == 1: return RK_LT if r > 0.35 else RK_HI
    if d == 2: return RK_MD if r > 0.30 else RK_LT
    return      RK_DK if r > 0.40 else RK_MD

def fill(col, row):
    """Dark volcanic rock interior with rare lava veins."""
    for y in range(TILE):
        for x in range(TILE):
            r = random.random()
            if   r < 0.03: c = LV_DK
            elif r < 0.38: c = RK_VDK
            elif r < 0.74: c = RK_DK
            else:          c = RK_MD
            sp(col, row, x, y, c)

def etop(col, row, x0=0, x1=TILE):
    for y in range(SD):
        for x in range(x0, x1):
            sp(col, row, x, y, surf(y))

def ebot(col, row, x0=0, x1=TILE):
    for y in range(SD):
        for x in range(x0, x1):
            sp(col, row, x, TILE - 1 - y, surf(y))

def eleft(col, row, y0=0, y1=TILE):
    for x in range(SD):
        for y in range(y0, y1):
            sp(col, row, x, y, surf(x))

def eright(col, row, y0=0, y1=TILE):
    for x in range(SD):
        for y in range(y0, y1):
            sp(col, row, TILE - 1 - x, y, surf(x))

def corner_accent(col, row, px_x, px_y):
    """Extra warm pixel at inner-corner junction."""
    sp(col, row, px_x, px_y, RK_LT)

# ══════════════════════════════════════════════════════════
# ROW 0
# ══════════════════════════════════════════════════════════

# (0,0)  Canto inferior esquerdo — exposed: BOTTOM + LEFT
fill(0, 0)
ebot(0, 0)
eleft(0, 0)

# (1,0)  Lateral direita da coluna lisa — exposed: RIGHT
fill(1, 0)
eright(1, 0)

# (2,0)  L da coluna com chão do lado direito
# inner corner: right face of left column (y 0→M) + top face of right floor (x M→TILE)
fill(2, 0)
eright(2, 0, y0=0, y1=M)
etop(2, 0, x0=M, x1=TILE)
corner_accent(2, 0, TILE - 1, M)   # junction pixel

# (3,0)  Plataforma reta — exposed: TOP
fill(3, 0)
etop(3, 0)

# ══════════════════════════════════════════════════════════
# ROW 1
# ══════════════════════════════════════════════════════════

# (0,1)  Canto superior esquerdo com canto inferior direito
# upper-left quadrant: TOP + LEFT; lower-right quadrant: BOTTOM + RIGHT
fill(0, 1)
etop(0, 1, x0=0, x1=M)
eleft(0, 1, y0=0, y1=M)
ebot(0, 1, x0=M, x1=TILE)
eright(0, 1, y0=M, y1=TILE)

# (1,1)  L da coluna com chão do lado esquerdo
# inner corner: left face of right column (y 0→M) + top face of left floor (x 0→M)
fill(1, 1)
eleft(1, 1, y0=0, y1=M)
etop(1, 1, x0=0, x1=M)
corner_accent(1, 1, 0, M)

# (2,1)  Centro do tile — miolo de preenchimento todo preenchido (no exposed faces)
fill(2, 1)

# (3,1)  L da coluna com teto do lado direito
# inner corner: right face of left column (y M→TILE) + bottom face of right ceiling (x M→TILE)
fill(3, 1)
eright(3, 1, y0=M, y1=TILE)
ebot(3, 1, x0=M, x1=TILE)
corner_accent(3, 1, TILE - 1, M - 1)

# ══════════════════════════════════════════════════════════
# ROW 2
# ══════════════════════════════════════════════════════════

# (0,2)  Canto superior direito — exposed: TOP + RIGHT
fill(0, 2)
etop(0, 2)
eright(0, 2)

# (1,2)  Teto reto — exposed: BOTTOM
fill(1, 2)
ebot(1, 2)

# (2,2)  L da coluna com teto do lado esquerdo
# inner corner: left face of right column (y M→TILE) + bottom face of left ceiling (x 0→M)
fill(2, 2)
eleft(2, 2, y0=M, y1=TILE)
ebot(2, 2, x0=0, x1=M)
corner_accent(2, 2, 0, M - 1)

# (3,2)  Lateral esquerda da coluna lisa — exposed: LEFT
fill(3, 2)
eleft(3, 2)

# ══════════════════════════════════════════════════════════
# ROW 3
# ══════════════════════════════════════════════════════════

# (0,3)  Transparente — tile vazio (already BLANK, nothing to draw)

# (1,3)  Canto inferior direito — exposed: BOTTOM + RIGHT
fill(1, 3)
ebot(1, 3)
eright(1, 3)

# (2,3)  Canto inferior esquerdo com canto superior direito
# lower-left quadrant: BOTTOM + LEFT; upper-right quadrant: TOP + RIGHT
fill(2, 3)
ebot(2, 3, x0=0, x1=M)
eleft(2, 3, y0=M, y1=TILE)
etop(2, 3, x0=M, x1=TILE)
eright(2, 3, y0=0, y1=M)

# (3,3)  Canto superior esquerdo — exposed: TOP + LEFT
fill(3, 3)
etop(3, 3)
eleft(3, 3)

# ══════════════════════════════════════════════════════════
# Save
# ══════════════════════════════════════════════════════════
out = os.path.join("stages", "stage_01", "Stage_01T.png")
img.save(out)
print(f"Saved: {out}  ({W}x{H})")
