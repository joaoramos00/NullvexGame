"""Generates Stage_01T.png — 128x128 (4x4 grid, 32x32 tiles) fire/volcano theme.
Tile layout mirrors Stage_00T. High-contrast palette with lava crack grid and
prominent surface highlights."""
from PIL import Image
import random, os

random.seed(42)

TILE = 32
COLS = ROWS = 4
W = H = TILE * COLS   # 128x128

# ── Palette ─────────────────────────────────────────────
BLANK    = (  0,   0,   0,   0)
INT_BLK  = ( 12,   3,   1, 255)  # near-black interior base
INT_DK   = ( 28,  10,   3, 255)  # dark rock
INT_MD   = ( 50,  20,   7, 255)  # medium rock
INT_LT   = ( 82,  35,  12, 255)  # light rock variation
LV_SEAM  = (110,  15,   2, 255)  # dark lava seam (crack line)
LV_DK    = (175,  32,   0, 255)  # lava glow dark
LV_MD    = (235,  88,   5, 255)  # lava glow mid
LV_BR    = (255, 162,  24, 255)  # bright lava
LV_GL    = (255, 225,  65, 255)  # lava core / glow
SURF_D5  = ( 90,  38,  12, 255)  # surface depth 5 (transition)
SURF_D4  = (120,  55,  18, 255)  # surface depth 4
SURF_D3  = (155,  72,  22, 255)  # surface depth 3
SURF_D2  = (195, 100,  30, 255)  # surface depth 2
SURF_D1  = (225, 125,  40, 255)  # surface depth 1
SURF_D0  = (248, 155,  52, 255)  # outermost highlight (brightest)

img = Image.new("RGBA", (W, H), BLANK)
px  = img.load()

def sp(col, row, x, y, c):
    gx, gy = col * TILE + x, row * TILE + y
    if 0 <= gx < W and 0 <= gy < H:
        px[gx, gy] = c

# ── Surface depth ──
SD = 6   # pixels deep for surface gradient
_SURF = [SURF_D0, SURF_D1, SURF_D2, SURF_D3, SURF_D4, SURF_D5]

def surf(d):
    """Surface color at distance d from exposed edge, with slight noise."""
    base = _SURF[min(d, SD - 1)]
    if random.random() < 0.18:   # slight variation
        return (min(255, base[0] + 12), min(255, base[1] + 6), base[2], 255)
    return base

M = TILE // 2  # half-tile pivot for L-tiles

# ── Interior fill with lava crack grid ──────────────────
CRACK_H = 8   # crack every 8px horizontally
CRACK_V = 9   # crack every 9px vertically (offset grid)

def fill(col, row):
    """Volcanic rock with lava crack grid + random glowing flecks."""
    for y in range(TILE):
        for x in range(TILE):
            # Crack lines
            in_hcrack = (y % CRACK_H == 0)
            in_vcrack = (x % CRACK_V == (col * 2) % CRACK_V)
            at_cross  = in_hcrack and in_vcrack

            if at_cross:
                # Lava pocket at crack intersection
                c = LV_DK if random.random() > 0.4 else LV_MD
            elif in_hcrack or in_vcrack:
                # Crack line — dark lava seam
                c = LV_SEAM if random.random() > 0.3 else INT_DK
            else:
                r = random.random()
                if   r < 0.012: c = LV_BR     # rare bright fleck
                elif r < 0.040: c = LV_DK     # lava glow fleck
                elif r < 0.280: c = INT_BLK
                elif r < 0.620: c = INT_DK
                elif r < 0.860: c = INT_MD
                else:           c = INT_LT
            sp(col, row, x, y, c)

# ── Edge applicators ─────────────────────────────────────

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

def lava_corner(col, row, cx, cy):
    """Tiny lava glow at inner-corner junction pixel."""
    sp(col, row, cx, cy, LV_BR)
    for dx, dy in [(-1,0),(1,0),(0,-1),(0,1)]:
        nx, ny = cx + dx, cy + dy
        if 0 <= nx < TILE and 0 <= ny < TILE:
            sp(col, row, nx, ny, LV_DK)

# ══════════════════════════════════════════════════════════
# ROW 0
# ══════════════════════════════════════════════════════════

# (0,0)  Canto inferior esquerdo — BOTTOM + LEFT
fill(0, 0); ebot(0, 0); eleft(0, 0)

# (1,0)  Lateral direita da coluna lisa — RIGHT
fill(1, 0); eright(1, 0)

# (2,0)  L da coluna com chão do lado direito
# inner corner: right face upper half + top face right half
fill(2, 0)
eright(2, 0, y0=0, y1=M)
etop(2, 0, x0=M, x1=TILE)
lava_corner(2, 0, TILE - 1, M)

# (3,0)  Plataforma reta — TOP
fill(3, 0); etop(3, 0)

# ══════════════════════════════════════════════════════════
# ROW 1
# ══════════════════════════════════════════════════════════

# (0,1)  Canto superior esquerdo com canto inferior direito
# upper-left: TOP+LEFT  /  lower-right: BOTTOM+RIGHT
fill(0, 1)
etop(0, 1, x0=0, x1=M);  eleft(0, 1, y0=0, y1=M)
ebot(0, 1, x0=M, x1=TILE); eright(0, 1, y0=M, y1=TILE)

# (1,1)  L da coluna com chão do lado esquerdo
# inner corner: left face upper half + top face left half
fill(1, 1)
eleft(1, 1, y0=0, y1=M)
etop(1, 1, x0=0, x1=M)
lava_corner(1, 1, 0, M)

# (2,1)  Centro do tile — miolo de preenchimento (no exposed faces)
fill(2, 1)

# (3,1)  L da coluna com teto do lado direito
# inner corner: right face lower half + bottom face right half
fill(3, 1)
eright(3, 1, y0=M, y1=TILE)
ebot(3, 1, x0=M, x1=TILE)
lava_corner(3, 1, TILE - 1, M - 1)

# ══════════════════════════════════════════════════════════
# ROW 2
# ══════════════════════════════════════════════════════════

# (0,2)  Canto superior direito — TOP + RIGHT
fill(0, 2); etop(0, 2); eright(0, 2)

# (1,2)  Teto reto — BOTTOM
fill(1, 2); ebot(1, 2)

# (2,2)  L da coluna com teto do lado esquerdo
# inner corner: left face lower half + bottom face left half
fill(2, 2)
eleft(2, 2, y0=M, y1=TILE)
ebot(2, 2, x0=0, x1=M)
lava_corner(2, 2, 0, M - 1)

# (3,2)  Lateral esquerda da coluna lisa — LEFT
fill(3, 2); eleft(3, 2)

# ══════════════════════════════════════════════════════════
# ROW 3
# ══════════════════════════════════════════════════════════

# (0,3)  Transparente — tile vazio (leave BLANK)

# (1,3)  Canto inferior direito — BOTTOM + RIGHT
fill(1, 3); ebot(1, 3); eright(1, 3)

# (2,3)  Canto inferior esquerdo com canto superior direito
# lower-left: BOTTOM+LEFT  /  upper-right: TOP+RIGHT
fill(2, 3)
ebot(2, 3, x0=0, x1=M);  eleft(2, 3, y0=M, y1=TILE)
etop(2, 3, x0=M, x1=TILE); eright(2, 3, y0=0, y1=M)

# (3,3)  Canto superior esquerdo — TOP + LEFT
fill(3, 3); etop(3, 3); eleft(3, 3)

# ══════════════════════════════════════════════════════════
# Save
# ══════════════════════════════════════════════════════════
out = os.path.join("stages", "stage_01", "Stage_01T.png")
img.save(out)
print(f"Saved: {out}  ({W}x{H})")
