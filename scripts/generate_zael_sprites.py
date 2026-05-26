import math
from pathlib import Path
from PIL import Image, ImageDraw

FW = 68
FH = 68
ROOT = Path(__file__).parent.parent
CHARS = ROOT / "characters" / "ranged"


def get_frame(img: Image.Image, index: int) -> Image.Image:
    return img.crop((index * FW, 0, (index + 1) * FW, FH)).convert("RGBA")


def make_sheet(frames: list) -> Image.Image:
    sheet = Image.new("RGBA", (FW * len(frames), FH), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * FW, 0))
    return sheet


def flash_white(frame: Image.Image, alpha: float) -> Image.Image:
    overlay = Image.new("RGBA", frame.size, (255, 255, 255, int(255 * alpha)))
    return Image.alpha_composite(frame.copy(), overlay)


def shift_frame(frame: Image.Image, dx: int, dy: int) -> Image.Image:
    result = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    result.paste(frame, (dx, dy))
    return result


def stretch_down(frame: Image.Image, scale_x: float, push_y: int) -> Image.Image:
    new_w = int(FW * scale_x)
    new_h = FH - push_y
    stretched = frame.resize((new_w, new_h), Image.NEAREST)
    result = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    x_off = (FW - new_w) // 2
    result.paste(stretched, (x_off, push_y))
    return result


def dissolve(frame: Image.Image, keep: float) -> Image.Image:
    """
    Mantém aproximadamente `keep` fração dos pixels não-transparentes.
    keep=0.75 → remove 1 em cada 4 (checkerboard grosso)
    keep=0.50 → remove 1 em cada 2 (checkerboard fino)
    keep=0.25 → mantém apenas pixels em posições (x ímpar, y ímpar)
    """
    result = frame.copy()
    px = result.load()
    for y in range(FH):
        for x in range(FW):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if keep >= 0.75:
                remove = (x % 4 == 0 and y % 4 == 0)
            elif keep >= 0.50:
                remove = ((x + y) % 2 == 0)
            else:  # keep ~0.25: manter só onde x e y são ímpares
                remove = not (x % 2 == 1 and y % 2 == 1)
            if remove:
                px[x, y] = (r, g, b, 0)
    return result


# ── Carregar fontes ───────────────────────────────────────────────────────────
idle  = Image.open(CHARS / "ZaelIdle.png").convert("RGBA")
run   = Image.open(CHARS / "ZaelCorrendo.png").convert("RGBA")
jump  = Image.open(CHARS / "ZaelJump_new.png").convert("RGBA")
shoot = Image.open(CHARS / "ZaelAtirando.png").convert("RGBA")

idle_f0  = get_frame(idle,  0)
run_f2   = get_frame(run,   2)
run_f3   = get_frame(run,   3)
jump_f2  = get_frame(jump,  2)
jump_f3  = get_frame(jump,  3)
shoot_f4 = get_frame(shoot, 4)

# ── ZaelDash (2 frames) ───────────────────────────────────────────────────────
dash_f0 = stretch_down(run_f2, 1.05, 3)

dash_f1_base = stretch_down(run_f3, 1.10, 5)
trail = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
trail.paste(run_f3.crop((0, 0, 8, FH)), (0, 0))
tp = trail.load()
for y in range(FH):
    for x in range(8):
        r, g, b, a = tp[x, y]
        tp[x, y] = (r, g, b, int(a * 0.3))
dash_f1 = Image.alpha_composite(dash_f1_base, trail)

make_sheet([dash_f0, dash_f1]).save(CHARS / "ZaelDash.png")
print("ZaelDash.png ✓")

# ── ZaelWallSlide (2 frames) ──────────────────────────────────────────────────
# Sprite gerado virado para a DIREITA; flip_h no código cuida da parede esquerda
ws_f0 = jump_f2.rotate(-15, resample=Image.NEAREST, fillcolor=(0, 0, 0, 0))
ws_f1 = shift_frame(
    idle_f0.rotate(-20, resample=Image.NEAREST, fillcolor=(0, 0, 0, 0)),
    4, 2
)
make_sheet([ws_f0, ws_f1]).save(CHARS / "ZaelWallSlide.png")
print("ZaelWallSlide.png ✓")

# ── ZaelHurt (3 frames) ───────────────────────────────────────────────────────
hurt_f0 = flash_white(idle_f0, 0.85)
hurt_f1 = flash_white(shift_frame(idle_f0, -6, -4), 0.40)
hurt_f2 = flash_white(shift_frame(idle_f0, -3, -2), 0.15)
make_sheet([hurt_f0, hurt_f1, hurt_f2]).save(CHARS / "ZaelHurt.png")
print("ZaelHurt.png ✓")

# ── ZaelDeath (6 frames) ──────────────────────────────────────────────────────
death_f0 = flash_white(idle_f0, 0.85)

death_f1_base = shift_frame(jump_f2, 0, -4)
# Aplicar tint vermelho apenas nos pixels visíveis (não no fundo transparente)
red_full = Image.new("RGBA", death_f1_base.size, (255, 80, 80, int(255 * 0.4)))
sprite_mask = death_f1_base.split()[3]
red_masked = Image.new("RGBA", death_f1_base.size, (0, 0, 0, 0))
red_masked.paste(red_full, mask=sprite_mask)
death_f1 = Image.alpha_composite(death_f1_base, red_masked)

death_f2 = dissolve(jump_f3, 0.75)
death_f3 = dissolve(jump_f3, 0.50)

death_f4 = dissolve(jump_f3, 0.25)
draw4 = ImageDraw.Draw(death_f4)
for i in range(8):
    angle = (math.tau / 8) * i
    px = int(FW / 2 + math.cos(angle) * 20)
    py = int(FH / 2 + math.sin(angle) * 20)
    draw4.ellipse([px - 3, py - 3, px + 3, py + 3], fill=(30, 100, 220, 180))

death_f5 = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
draw5 = ImageDraw.Draw(death_f5)
for i in range(8):
    angle = (math.tau / 8) * i
    px = int(FW / 2 + math.cos(angle) * 28)
    py = int(FH / 2 + math.sin(angle) * 28)
    draw5.ellipse([px - 3, py - 3, px + 3, py + 3], fill=(30, 100, 220, 120))
for i in range(4):
    angle = (math.tau / 4) * i + math.tau / 8
    px = int(FW / 2 + math.cos(angle) * 14)
    py = int(FH / 2 + math.sin(angle) * 14)
    draw5.ellipse([px - 2, py - 2, px + 2, py + 2], fill=(200, 50, 50, 120))

make_sheet([death_f0, death_f1, death_f2, death_f3, death_f4, death_f5]).save(CHARS / "ZaelDeath.png")
print("ZaelDeath.png ✓")

# ── ZaelRunShoot (6 frames) ───────────────────────────────────────────────────
# Extrair braço+canhão do frame 4 de ZaelAtirando (metade direita superior)
arm = shoot_f4.crop((32, 16, FW, 52))

frames_rs = []
for i in range(6):
    base = get_frame(run, i)
    result = base.copy()
    result.paste(arm, (32, 16), arm)
    frames_rs.append(result)

make_sheet(frames_rs).save(CHARS / "ZaelRunShoot.png")
print("ZaelRunShoot.png ✓")

# ── ZaelJumpShoot (2 frames) ──────────────────────────────────────────────────
arm = shoot_f4.crop((32, 16, FW, 52))

jump_shoot_f0 = jump_f2.copy()
jump_shoot_f0.paste(arm, (32, 16), arm)

jump_shoot_f1 = jump_f2.copy()
jump_shoot_f1.paste(arm, (33, 15), arm)

make_sheet([jump_shoot_f0, jump_shoot_f1]).save(CHARS / "ZaelJumpShoot.png")
print("ZaelJumpShoot.png ✓")

# ── ZaelDashShoot (2 frames) ──────────────────────────────────────────────────
arm = shoot_f4.crop((32, 16, FW, 52))

dash_shoot_f0 = dash_f0.copy()
dash_shoot_f0.paste(arm, (32, 16), arm)

dash_shoot_f1 = dash_f1.copy()
dash_shoot_f1.paste(arm, (32, 16), arm)

make_sheet([dash_shoot_f0, dash_shoot_f1]).save(CHARS / "ZaelDashShoot.png")
print("ZaelDashShoot.png ✓")

print("\nTodos os sprites gerados com sucesso!")
