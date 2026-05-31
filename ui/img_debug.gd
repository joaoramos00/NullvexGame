extends Control
class_name ImgDebug

const _SPRITES: Array = [
    {"char": "ZAEL", "anim": "Idle",      "path": "res://characters/ranged/ZaelIdle.png",      "frames": 8, "fps": 8.0},
    {"char": "ZAEL", "anim": "Run",       "path": "res://characters/ranged/ZaelCorrendo.png",  "frames": 6, "fps": 10.0},
    {"char": "ZAEL", "anim": "Jump",      "path": "res://characters/ranged/ZaelJump_new.png",  "frames": 4, "fps": 10.0},
    {"char": "ZAEL", "anim": "Shot",      "path": "res://characters/ranged/ZaelAtirando.png",  "frames": 9, "fps": 10.0},
    {"char": "ZAEL", "anim": "WallSlide", "path": "res://characters/ranged/ZaelWallSlide.png", "frames": 2, "fps": 6.0},
    {"char": "ZAEL", "anim": "Dash",      "path": "res://characters/ranged/ZaelDash.png",      "frames": 2, "fps": 12.0},
    {"char": "ZAEL", "anim": "RunShoot",  "path": "res://characters/ranged/ZaelRunShoot.png",  "frames": 9, "fps": 10.0},
    {"char": "ZAEL", "anim": "JumpShoot", "path": "res://characters/ranged/ZaelJumpShoot.png", "frames": 2, "fps": 10.0},
    {"char": "ZAEL", "anim": "DashShoot", "path": "res://characters/ranged/ZaelDashShoot.png", "frames": 2, "fps": 12.0},
    {"char": "ZARA", "anim": "Walk",      "path": "res://characters/melee/ZaraAndando.png",    "frames": 5, "fps": 8.0},
    {"char": "ZARA", "anim": "Run",       "path": "res://characters/melee/ZaraCorrendo.png",   "frames": 3, "fps": 10.0},
    {"char": "MINIBOSS", "anim": "Walk",  "path": "res://characters/enemies/miniboss/miniboss_walk.png",  "frames": 6, "fps": 8.0,  "frame_w": 240},
    {"char": "MINIBOSS", "anim": "Idle",  "path": "res://characters/enemies/miniboss/miniboss_idle.png",  "frames": 4, "fps": 6.0,  "frame_w": 240},
    {"char": "MINIBOSS", "anim": "Punch", "path": "res://characters/enemies/miniboss/miniboss_punch.png", "frames": 9, "fps": 12.0, "frame_w": 240, "label": "Punch (novo gif)"},
    {"char": "MINIBOSS", "anim": "Stomp",  "path": "res://characters/enemies/miniboss/miniboss_stomp.png",  "frames": 9, "fps": 12.0, "frame_w": 240},
    {"char": "MINIBOSS", "anim": "Charge", "path": "res://characters/enemies/miniboss/miniboss_charge.png", "frames": 8, "fps": 10.0, "frame_w": 240},
]

const _TILESETS: Array = [
    {"name": "Stage_00T", "path": "res://stages/stage_00/Stage_00T.png", "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_01T", "path": "res://stages/stage_01/Stage_01T.png", "cols": 4, "rows": 4, "tile_size": 32},
]

const _TILE_DESCS: Dictionary = {
    # Stage_00T
    "Stage_00T:0,0": "Canto inferior esquerdo",
    "Stage_00T:1,0": "Lateral direita da coluna lisa",
    "Stage_00T:2,0": "L da coluna com chão do lado direito",
    "Stage_00T:3,0": "Plataforma reta",
    "Stage_00T:0,1": "Canto superior esquerdo com canto inferior direito",
    "Stage_00T:1,1": "L da coluna com chão do lado esquerdo",
    "Stage_00T:2,1": "Centro do tile — miolo de preenchimento todo preenchido",
    "Stage_00T:3,1": "L da coluna com teto do lado direito",
    "Stage_00T:0,2": "Canto superior direito",
    "Stage_00T:1,2": "Teto reto",
    "Stage_00T:2,2": "L da coluna com teto do lado esquerdo",
    "Stage_00T:3,2": "Lateral esquerda da coluna lisa",
    "Stage_00T:0,3": "Transparente — tile vazio (alpha = 0), não utilizado",
    "Stage_00T:1,3": "Canto inferior direito",
    "Stage_00T:2,3": "Canto inferior esquerdo com canto superior direito",
    "Stage_00T:3,3": "Canto superior esquerdo",
    # Stage_01T — fogo/vulcão (mesma estrutura funcional do Stage_00T)
    "Stage_01T:0,0": "Canto inferior esquerdo",
    "Stage_01T:1,0": "Lateral direita da coluna lisa",
    "Stage_01T:2,0": "L da coluna com chão do lado direito",
    "Stage_01T:3,0": "Plataforma reta",
    "Stage_01T:0,1": "Canto superior esquerdo com canto inferior direito",
    "Stage_01T:1,1": "L da coluna com chão do lado esquerdo",
    "Stage_01T:2,1": "Centro do tile — miolo de preenchimento todo preenchido",
    "Stage_01T:3,1": "L da coluna com teto do lado direito",
    "Stage_01T:0,2": "Canto superior direito",
    "Stage_01T:1,2": "Teto reto",
    "Stage_01T:2,2": "L da coluna com teto do lado esquerdo",
    "Stage_01T:3,2": "Lateral esquerda da coluna lisa",
    "Stage_01T:0,3": "Transparente — tile vazio (alpha = 0), não utilizado",
    "Stage_01T:1,3": "Canto inferior direito",
    "Stage_01T:2,3": "Canto inferior esquerdo com canto superior direito",
    "Stage_01T:3,3": "Canto superior esquerdo",
}

# Visualização da colisão lateral: dois Zaels, um em cada parede
class _LateralView extends Control:
    var tile_tex: Texture2D
    var sprite_tex: Texture2D

    const _TILE_SRC  := 32.0
    const _TILE_W    := 64.0
    const _CAP_R     := 10.0
    const _CAP_TOT   := 48.0   # height(28) + 2×radius(10)
    const _SPR_SRC   := 68.0
    const _SPR_SCL   := 2.0
    const _SPR_OFS_Y := -4.0
    const _ML        := 20.0
    const _MT        := 44.0
    const _TILE_X2   := 196.0  # borda esquerda da parede direita (simétrica a _ML)

    func _draw() -> void:
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.14))

        var cy := _MT + _TILE_W

        if tile_tex:
            var src_l := Rect2(3.0 * _TILE_SRC, 2.0 * _TILE_SRC, _TILE_SRC, _TILE_SRC)
            var src_r := Rect2(1.0 * _TILE_SRC, 0.0 * _TILE_SRC, _TILE_SRC, _TILE_SRC)
            for i in 2:
                draw_texture_rect_region(tile_tex, Rect2(_ML, _MT + i * _TILE_W, _TILE_W, _TILE_W), src_l)
                draw_texture_rect_region(tile_tex, Rect2(_TILE_X2, _MT + i * _TILE_W, _TILE_W, _TILE_W), src_r)

        var sd := _SPR_SRC * _SPR_SCL

        # Zael 1: encostando na parede esquerda (vindo da direita)
        var cx1 := _ML + _TILE_W - _CAP_R
        if sprite_tex:
            draw_texture_rect_region(sprite_tex,
                Rect2(cx1 - sd * 0.5, cy + _SPR_OFS_Y - sd * 0.5, sd, sd),
                Rect2(0.0, 0.0, _SPR_SRC, _SPR_SRC))
        var cap1 := Rect2(cx1 - _CAP_R, cy - _CAP_TOT * 0.5, _CAP_R * 2.0, _CAP_TOT)
        draw_rect(cap1, Color(0.0, 1.0, 1.0, 0.25))
        draw_rect(cap1, Color(0.0, 1.0, 1.0, 1.0), false, 2.0)
        draw_line(Vector2(_ML + _TILE_W - 32.0, _MT - 8.0),
            Vector2(_ML + _TILE_W - 32.0, _MT + _TILE_W * 2.0 + 8.0),
            Color(1.0, 0.9, 0.0, 0.85), 2.0)

        # Zael 2: encostando na parede direita (vindo da esquerda, espelhado)
        var cx2 := _TILE_X2 + _CAP_R
        if sprite_tex:
            draw_set_transform(Vector2(cx2 * 2.0, 0.0), 0.0, Vector2(-1.0, 1.0))
            draw_texture_rect_region(sprite_tex,
                Rect2(cx2 - sd * 0.5, cy + _SPR_OFS_Y - sd * 0.5, sd, sd),
                Rect2(0.0, 0.0, _SPR_SRC, _SPR_SRC))
            draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        var cap2 := Rect2(cx2 - _CAP_R, cy - _CAP_TOT * 0.5, _CAP_R * 2.0, _CAP_TOT)
        draw_rect(cap2, Color(0.0, 1.0, 1.0, 0.25))
        draw_rect(cap2, Color(0.0, 1.0, 1.0, 1.0), false, 2.0)
        draw_line(Vector2(_TILE_X2 + 32.0, _MT - 8.0),
            Vector2(_TILE_X2 + 32.0, _MT + _TILE_W * 2.0 + 8.0),
            Color(1.0, 0.9, 0.0, 0.85), 2.0)

# Visualização da interação do Zael com cantos de plataforma (28px offset em X e Y)
class _CornerView extends Control:
    var tile_tex: Texture2D
    var sprite_tex: Texture2D
    var corner: int = 0  # 0=topo-dir  1=topo-esq  2=base-dir  3=base-esq

    const _TW   := 64.0
    const _SRC  := 32.0
    const _CR   := 10.0    # display capsule radius
    const _CH   := 48.0    # display capsule height
    const _CHH  := 24.0    # half of _CH (dist center→foot/head)
    const _OFS  := 10.0    # player offset from wall face = capsule radius
    const _SPR  := 68.0
    const _SCL  := 2.0
    const _SOFY := -4.0

    func _blit(src: Vector2i, dst: Rect2) -> void:
        if not tile_tex:
            return
        draw_texture_rect_region(tile_tex, dst,
            Rect2(src.x * _SRC, src.y * _SRC, _SRC, _SRC))

    func _draw() -> void:
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.14))
        var W := size.x
        var H := size.y
        var wx := W * 0.54   # borda visual do tile de parede
        var fy := H * 0.55   # borda visual do tile de chão/teto

        # Faces de contato de física (32px para dentro do tile — metade sólida)
        var wx_in := wx + (32.0 if corner == 1 or corner == 3 else -32.0)
        var fy_in := fy + (32.0 if corner == 0 or corner == 1 else -32.0)

        # tile coords (col, row no spritesheet 32px)
        var t_corner: Vector2i
        var t_surf: Vector2i
        var t_side: Vector2i
        var t_fill := Vector2i(2, 1)
        var rc: Rect2; var rs: Rect2; var rw: Rect2; var rf: Rect2
        var px: float; var py: float; var flip := false

        match corner:
            0:  # topo-dir: bloco à esq/abaixo do canto (wx,fy); Zael à DIREITA de wx_in, pé em fy_in
                t_corner = Vector2i(0, 0)      # BOT+LEFT: sólido inf-esq → corpo do bloco abaixo-esq
                t_surf   = Vector2i(3, 0)      # TOP: sólido na metade inferior → topo do bloco
                t_side   = Vector2i(3, 2)      # LEFT [X,O]: transparente à dir = face em x=wx (borda dir de rw)
                rc = Rect2(wx - _TW,       fy,        _TW, _TW)
                rs = Rect2(wx - _TW * 2.0, fy,        _TW, _TW)
                rw = Rect2(wx - _TW,       fy + _TW,  _TW, _TW)
                rf = Rect2(wx - _TW * 2.0, fy + _TW,  _TW, _TW)
                px = wx_in + _OFS;  py = fy_in - _CHH;  flip = true
            1:  # topo-esq: bloco à dir/abaixo do canto (wx,fy); Zael à ESQUERDA de wx_in, pé em fy_in
                t_corner = Vector2i(1, 3)      # BOT+RIGHT: sólido inf-dir → corpo do bloco abaixo-dir
                t_surf   = Vector2i(3, 0)      # TOP: topo do bloco
                t_side   = Vector2i(1, 0)      # RIGHT [O,X]: transparente à esq = face em x=wx (borda esq de rw)
                rc = Rect2(wx,       fy,        _TW, _TW)
                rs = Rect2(wx + _TW, fy,        _TW, _TW)
                rw = Rect2(wx,       fy + _TW,  _TW, _TW)
                rf = Rect2(wx + _TW, fy + _TW,  _TW, _TW)
                px = wx_in - _OFS;  py = fy_in - _CHH;  flip = false
            2:  # base-dir: bloco à esq/acima do canto (wx,fy); Zael à DIREITA de wx_in, topo em fy_in
                t_corner = Vector2i(3, 3)      # TOP+LEFT: sólido sup-esq → corpo do bloco acima-esq
                t_surf   = Vector2i(1, 2)      # BOTTOM: sólido na metade superior → teto do bloco
                t_side   = Vector2i(3, 2)      # LEFT [X,O]: transparente à dir = face em x=wx (borda dir de rw)
                rc = Rect2(wx - _TW,       fy - _TW,        _TW, _TW)
                rs = Rect2(wx - _TW * 2.0, fy - _TW,        _TW, _TW)
                rw = Rect2(wx - _TW,       fy - _TW * 2.0,  _TW, _TW)
                rf = Rect2(wx - _TW * 2.0, fy - _TW * 2.0,  _TW, _TW)
                px = wx_in + _OFS;  py = fy_in + _CHH;  flip = true
            3:  # base-esq: bloco à dir/acima do canto (wx,fy); Zael à ESQUERDA de wx_in, topo em fy_in
                t_corner = Vector2i(0, 2)      # TOP+RIGHT: sólido sup-dir → corpo do bloco acima-dir
                t_surf   = Vector2i(1, 2)      # BOTTOM: teto do bloco
                t_side   = Vector2i(1, 0)      # RIGHT [O,X]: transparente à esq = face em x=wx (borda esq de rw)
                rc = Rect2(wx,       fy - _TW,        _TW, _TW)
                rs = Rect2(wx + _TW, fy - _TW,        _TW, _TW)
                rw = Rect2(wx,       fy - _TW * 2.0,  _TW, _TW)
                rf = Rect2(wx + _TW, fy - _TW * 2.0,  _TW, _TW)
                px = wx_in - _OFS;  py = fy_in + _CHH;  flip = false
            _:
                return

        _blit(t_fill, rf)
        _blit(t_surf, rs)
        _blit(t_corner, rc)
        _blit(t_side, rw)

        # Linhas amarelas nas faces de contato
        var yel := Color(1.0, 0.9, 0.0, 0.85)
        draw_line(Vector2(wx_in, 0.0), Vector2(wx_in, H), yel, 2.0)
        draw_line(Vector2(0.0, fy_in), Vector2(W, fy_in), yel, 2.0)

        # Marcadores verdes: px no eixo Y (posição lateral do player) e py no eixo X
        var grn := Color(0.0, 1.0, 0.5, 0.85)
        draw_line(Vector2(px - 9.0, fy_in), Vector2(px + 9.0, fy_in), grn, 2.0)
        draw_line(Vector2(wx_in, py - 9.0), Vector2(wx_in, py + 9.0), grn, 2.0)
        # X no canto acessível
        draw_line(Vector2(px - 5.0, py - 5.0), Vector2(px + 5.0, py + 5.0), grn, 1.5)
        draw_line(Vector2(px + 5.0, py - 5.0), Vector2(px - 5.0, py + 5.0), grn, 1.5)

        # Sprite do Zael
        if sprite_tex:
            var sd := _SPR * _SCL
            if flip:
                draw_set_transform(Vector2(px * 2.0, 0.0), 0.0, Vector2(-1.0, 1.0))
            draw_texture_rect_region(sprite_tex,
                Rect2(px - sd * 0.5, py + _SOFY - sd * 0.5, sd, sd),
                Rect2(0.0, 0.0, _SPR, _SPR))
            if flip:
                draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

        # Cápsula do Zael
        var cap := Rect2(px - _CR, py - _CHH, _CR * 2.0, _CH)
        draw_rect(cap, Color(0.0, 1.0, 1.0, 0.25))
        draw_rect(cap, Color(0.0, 1.0, 1.0, 1.0), false, 2.0)

# Colisão lateral do vidro: dois Zaels contra as faces do painel glass
class _GlassLateralView extends Control:
    var glass_tex:  Texture2D
    var sprite_tex: Texture2D

    const _SRC  := 32.0
    const _TW   := 64.0
    const _CR   := 10.0
    const _CHH  := 24.0
    const _CH   := 48.0
    const _SPR  := 68.0
    const _SCL  := 2.0
    const _SOFY := -4.0
    const _ML   := 20.0
    const _MT   := 44.0
    const _X2   := 196.0

    func _draw() -> void:
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.14))
        var cy  := _MT + _TW
        var cyn := Color(0.5, 0.9, 1.0, 0.9)
        var font := ThemeDB.fallback_font

        if glass_tex:
            var src_l := Rect2(3.0 * _SRC, 2.0 * _SRC, _SRC, _SRC)  # (3,2) face esq
            var src_r := Rect2(1.0 * _SRC, 0.0,         _SRC, _SRC)  # (1,0) face dir
            for i in 2:
                draw_texture_rect_region(glass_tex, Rect2(_ML, _MT + i * _TW, _TW, _TW), src_l)
                draw_texture_rect_region(glass_tex, Rect2(_X2, _MT + i * _TW, _TW, _TW), src_r)

        var sd := _SPR * _SCL

        # Zael 1: encostando no vidro esquerdo (vindo da direita)
        var cx1 := _ML + _TW - _CR
        if sprite_tex:
            draw_texture_rect_region(sprite_tex,
                Rect2(cx1 - sd * 0.5, cy + _SOFY - sd * 0.5, sd, sd),
                Rect2(0.0, 0.0, _SPR, _SPR))
        var cap1 := Rect2(cx1 - _CR, cy - _CHH, _CR * 2.0, _CH)
        draw_rect(cap1, Color(0.0, 1.0, 1.0, 0.25))
        draw_rect(cap1, Color(0.0, 1.0, 1.0, 1.0), false, 2.0)
        draw_line(Vector2(_ML + _TW - 32.0, _MT - 8.0),
            Vector2(_ML + _TW - 32.0, _MT + _TW * 2.0 + 8.0), cyn, 2.0)
        draw_string(font, Vector2(cx1 - 34.0, _MT - 20.0),
            "SEM GRAB", HORIZONTAL_ALIGNMENT_LEFT, 80.0, 15, cyn)

        # Zael 2: encostando no vidro direito (espelhado)
        var cx2 := _X2 + _CR
        if sprite_tex:
            draw_set_transform(Vector2(cx2 * 2.0, 0.0), 0.0, Vector2(-1.0, 1.0))
            draw_texture_rect_region(sprite_tex,
                Rect2(cx2 - sd * 0.5, cy + _SOFY - sd * 0.5, sd, sd),
                Rect2(0.0, 0.0, _SPR, _SPR))
            draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        var cap2 := Rect2(cx2 - _CR, cy - _CHH, _CR * 2.0, _CH)
        draw_rect(cap2, Color(0.0, 1.0, 1.0, 0.25))
        draw_rect(cap2, Color(0.0, 1.0, 1.0, 1.0), false, 2.0)
        draw_line(Vector2(_X2 + 32.0, _MT - 8.0),
            Vector2(_X2 + 32.0, _MT + _TW * 2.0 + 8.0), cyn, 2.0)
        draw_string(font, Vector2(cx2 - 34.0, _MT - 20.0),
            "SEM GRAB", HORIZONTAL_ALIGNMENT_LEFT, 80.0, 15, cyn)

# Cantos do vidro: idêntico a _CornerView mas tile da parede vem de glass_tex
class _GlassCornerView extends Control:
    var tile_tex:   Texture2D   # Stage_00T (chão/teto)
    var glass_tex:  Texture2D   # glass (tile lateral da parede)
    var sprite_tex: Texture2D
    var corner: int = 0         # 0=topo-dir  1=topo-esq  2=base-dir  3=base-esq

    const _TW   := 64.0
    const _SRC  := 32.0
    const _CR   := 10.0
    const _CH   := 48.0
    const _CHH  := 24.0
    const _OFS  := 10.0
    const _SPR  := 68.0
    const _SCL  := 2.0
    const _SOFY := -4.0

    func _blit_tex(tex: Texture2D, src: Vector2i, dst: Rect2) -> void:
        if not tex:
            return
        draw_texture_rect_region(tex, dst,
            Rect2(src.x * _SRC, src.y * _SRC, _SRC, _SRC))

    func _draw() -> void:
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.14))
        var W := size.x
        var H := size.y
        var wx := W * 0.54
        var fy := H * 0.55
        var wx_in := wx + (32.0 if corner == 1 or corner == 3 else -32.0)
        var fy_in := fy + (32.0 if corner == 0 or corner == 1 else -32.0)

        var t_corner: Vector2i
        var t_surf:   Vector2i
        var t_side:   Vector2i
        var t_fill := Vector2i(2, 1)
        var rc: Rect2; var rs: Rect2; var rw: Rect2; var rf: Rect2
        var px: float; var py: float; var flip := false

        match corner:
            0:
                t_corner = Vector2i(0, 0); t_surf = Vector2i(3, 0); t_side = Vector2i(3, 2)
                rc = Rect2(wx - _TW,       fy,        _TW, _TW)
                rs = Rect2(wx - _TW * 2.0, fy,        _TW, _TW)
                rw = Rect2(wx - _TW,       fy + _TW,  _TW, _TW)
                rf = Rect2(wx - _TW * 2.0, fy + _TW,  _TW, _TW)
                px = wx_in + _OFS;  py = fy_in - _CHH;  flip = true
            1:
                t_corner = Vector2i(1, 3); t_surf = Vector2i(3, 0); t_side = Vector2i(1, 0)
                rc = Rect2(wx,       fy,        _TW, _TW)
                rs = Rect2(wx + _TW, fy,        _TW, _TW)
                rw = Rect2(wx,       fy + _TW,  _TW, _TW)
                rf = Rect2(wx + _TW, fy + _TW,  _TW, _TW)
                px = wx_in - _OFS;  py = fy_in - _CHH;  flip = false
            2:
                t_corner = Vector2i(3, 3); t_surf = Vector2i(1, 2); t_side = Vector2i(3, 2)
                rc = Rect2(wx - _TW,       fy - _TW,        _TW, _TW)
                rs = Rect2(wx - _TW * 2.0, fy - _TW,        _TW, _TW)
                rw = Rect2(wx - _TW,       fy - _TW * 2.0,  _TW, _TW)
                rf = Rect2(wx - _TW * 2.0, fy - _TW * 2.0,  _TW, _TW)
                px = wx_in + _OFS;  py = fy_in + _CHH;  flip = true
            3:
                t_corner = Vector2i(0, 2); t_surf = Vector2i(1, 2); t_side = Vector2i(1, 0)
                rc = Rect2(wx,       fy - _TW,        _TW, _TW)
                rs = Rect2(wx + _TW, fy - _TW,        _TW, _TW)
                rw = Rect2(wx,       fy - _TW * 2.0,  _TW, _TW)
                rf = Rect2(wx + _TW, fy - _TW * 2.0,  _TW, _TW)
                px = wx_in - _OFS;  py = fy_in + _CHH;  flip = false
            _:
                return

        # fill, surf, corner de tile_tex; side de glass_tex
        _blit_tex(tile_tex,  t_fill,   rf)
        _blit_tex(tile_tex,  t_surf,   rs)
        _blit_tex(tile_tex,  t_corner, rc)
        _blit_tex(glass_tex, t_side,   rw)

        # Linha ciano para parede de vidro, amarela para chão/teto
        var yel := Color(1.0, 0.9, 0.0, 0.85)
        var cyn := Color(0.5, 0.9, 1.0, 0.9)
        draw_line(Vector2(wx_in, 0.0), Vector2(wx_in, H), cyn, 2.0)
        draw_line(Vector2(0.0, fy_in), Vector2(W, fy_in), yel, 2.0)

        var grn := Color(0.0, 1.0, 0.5, 0.85)
        draw_line(Vector2(px - 9.0, fy_in), Vector2(px + 9.0, fy_in), grn, 2.0)
        draw_line(Vector2(wx_in, py - 9.0), Vector2(wx_in, py + 9.0), grn, 2.0)
        draw_line(Vector2(px - 5.0, py - 5.0), Vector2(px + 5.0, py + 5.0), grn, 1.5)
        draw_line(Vector2(px + 5.0, py - 5.0), Vector2(px - 5.0, py + 5.0), grn, 1.5)

        if sprite_tex:
            var sd := _SPR * _SCL
            if flip:
                draw_set_transform(Vector2(px * 2.0, 0.0), 0.0, Vector2(-1.0, 1.0))
            draw_texture_rect_region(sprite_tex,
                Rect2(px - sd * 0.5, py + _SOFY - sd * 0.5, sd, sd),
                Rect2(0.0, 0.0, _SPR, _SPR))
            if flip:
                draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

        var cap := Rect2(px - _CR, py - _CHH, _CR * 2.0, _CH)
        draw_rect(cap, Color(0.0, 1.0, 1.0, 0.25))
        draw_rect(cap, Color(0.0, 1.0, 1.0, 1.0), false, 2.0)

# Gap inferior do vidro: mostra onde a colisão termina e o player passa andando
class _GlassGapView extends Control:
    var glass_tex:  Texture2D
    var tile_tex:   Texture2D
    var sprite_tex: Texture2D

    const _SRC  := 32.0
    const _TW   := 64.0
    const _CR   := 10.0
    const _CH   := 48.0
    const _CHH  := 24.0
    const _SPR  := 68.0
    const _SCL  := 2.0
    const _SOFY := -4.0

    func _draw() -> void:
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.14))
        var W   := size.x
        var gy  := size.y - 40.0      # floor y
        var gpy := gy - _TW           # gap y = bottom of glass collision
        var gx  := 18.0               # left edge of glass column
        var yel := Color(1.0, 0.9, 0.0, 0.85)
        var cyn := Color(0.5, 0.9, 1.0, 0.9)
        var font := ThemeDB.fallback_font

        # Zonas coloridas: vermelho = colisão do vidro, verde = gap (player passa)
        draw_rect(Rect2(gx + _TW * 2.0 + 4.0, gpy - _TW, _TW * 1.5, _TW),
            Color(1.0, 0.2, 0.2, 0.15))
        draw_rect(Rect2(gx + _TW * 2.0 + 4.0, gpy,       _TW * 1.5, _TW),
            Color(0.2, 1.0, 0.3, 0.15))

        # Floor tiles
        if tile_tex:
            var src_top := Rect2(3.0 * _SRC, 0.0, _SRC, _SRC)
            var tx := 0.0
            while tx <= W:
                draw_texture_rect_region(tile_tex,
                    Rect2(tx, gy - _TW * 0.5, _TW, _TW), src_top)
                tx += _TW

        # Coluna de vidro: lateral (3,2) + fill (2,1), 2 tiles altos, terminando em gpy
        if glass_tex:
            var src_lat  := Rect2(3.0 * _SRC, 2.0 * _SRC, _SRC, _SRC)
            var src_fill := Rect2(2.0 * _SRC, 1.0 * _SRC, _SRC, _SRC)
            for i in 2:
                var ty := gpy - float(i + 1) * _TW
                draw_texture_rect_region(glass_tex, Rect2(gx,        ty, _TW, _TW), src_lat)
                draw_texture_rect_region(glass_tex, Rect2(gx + _TW,  ty, _TW, _TW), src_fill)

        # Linhas
        draw_line(Vector2(0.0, gy), Vector2(W, gy), yel, 2.0)
        draw_line(Vector2(gx - 4.0, gpy),
            Vector2(gx + _TW * 2.0 + 4.0, gpy), cyn, 2.0)

        # Zael no chão (capsule top abaixo de gpy → passa)
        var axc := gx + _TW * 2.0 + _CR + 14.0
        var ayc := gy - _CHH
        if sprite_tex:
            var sd := _SPR * _SCL
            draw_texture_rect_region(sprite_tex,
                Rect2(axc - sd * 0.5, ayc + _SOFY - sd * 0.5, sd, sd),
                Rect2(0.0, 0.0, _SPR, _SPR))
        var cap := Rect2(axc - _CR, ayc - _CHH, _CR * 2.0, _CH)
        draw_rect(cap, Color(0.2, 1.0, 0.3, 0.25))
        draw_rect(cap, Color(0.2, 1.0, 0.3, 1.0), false, 2.0)

        # Labels
        var zx := gx + _TW * 2.0 + 6.0
        draw_string(font, Vector2(zx, gpy - _TW * 0.5 + 8.0),
            "bloqueado", HORIZONTAL_ALIGNMENT_LEFT, 80.0, 14, Color(1.0, 0.4, 0.4))
        draw_string(font, Vector2(zx, gpy + _TW * 0.5 + 8.0),
            "passa", HORIZONTAL_ALIGNMENT_LEFT, 60.0, 14, Color(0.2, 1.0, 0.3))
        draw_string(font, Vector2(gx, gpy + 6.0),
            "gap\n64px", HORIZONTAL_ALIGNMENT_LEFT, 42.0, 13, cyn)

# Comparação lado a lado: parede normal (grab) vs vidro (sem grab)
class _GlassCompareView extends Control:
    var glass_tex:  Texture2D
    var tile_tex:   Texture2D
    var sprite_tex: Texture2D

    const _SRC  := 32.0
    const _TW   := 64.0
    const _CR   := 10.0
    const _CH   := 48.0
    const _CHH  := 24.0
    const _SPR  := 68.0
    const _SCL  := 2.0
    const _SOFY := -4.0
    const _ML   := 20.0
    const _MT   := 44.0

    func _draw() -> void:
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.14))
        var W   := size.x
        var mid := W * 0.5
        var cy  := _MT + _TW
        var yel := Color(1.0, 0.9, 0.0, 0.85)
        var cyn := Color(0.5, 0.9, 1.0, 0.9)
        var font := ThemeDB.fallback_font
        var src_wall := Rect2(3.0 * _SRC, 2.0 * _SRC, _SRC, _SRC)  # (3,2)
        var sd := _SPR * _SCL

        # Divisória central
        draw_line(Vector2(mid, 0.0), Vector2(mid, size.y),
            Color(0.3, 0.3, 0.3, 0.8), 1.0)

        # ── ESQUERDA: parede normal ──────────────────────────
        if tile_tex:
            for i in 2:
                draw_texture_rect_region(tile_tex,
                    Rect2(_ML, _MT + i * _TW, _TW, _TW), src_wall)
        var cx1 := _ML + _TW - _CR
        if sprite_tex:
            draw_texture_rect_region(sprite_tex,
                Rect2(cx1 - sd * 0.5, cy + _SOFY - sd * 0.5, sd, sd),
                Rect2(0.0, 0.0, _SPR, _SPR))
        var cap1 := Rect2(cx1 - _CR, cy - _CHH, _CR * 2.0, _CH)
        draw_rect(cap1, Color(0.0, 1.0, 1.0, 0.25))
        draw_rect(cap1, Color(0.0, 1.0, 1.0, 1.0), false, 2.0)
        draw_line(Vector2(_ML + _TW - 32.0, _MT - 8.0),
            Vector2(_ML + _TW - 32.0, _MT + _TW * 2.0 + 8.0), yel, 2.0)
        draw_string(font, Vector2(_ML, size.y - 34.0),
            "NORMAL — grab", HORIZONTAL_ALIGNMENT_LEFT, mid - _ML, 16, yel)

        # ── DIREITA: vidro ────────────────────────────────────
        var rx := mid + _ML
        if glass_tex:
            for i in 2:
                draw_texture_rect_region(glass_tex,
                    Rect2(rx, _MT + i * _TW, _TW, _TW), src_wall)
        var cx2 := rx + _TW - _CR
        if sprite_tex:
            draw_texture_rect_region(sprite_tex,
                Rect2(cx2 - sd * 0.5, cy + _SOFY - sd * 0.5, sd, sd),
                Rect2(0.0, 0.0, _SPR, _SPR))
        var cap2 := Rect2(cx2 - _CR, cy - _CHH, _CR * 2.0, _CH)
        draw_rect(cap2, Color(0.0, 1.0, 1.0, 0.25))
        draw_rect(cap2, Color(0.0, 1.0, 1.0, 1.0), false, 2.0)
        draw_line(Vector2(rx + _TW - 32.0, _MT - 8.0),
            Vector2(rx + _TW - 32.0, _MT + _TW * 2.0 + 8.0), cyn, 2.0)
        draw_string(font, Vector2(rx, size.y - 34.0),
            "VIDRO — sem grab", HORIZONTAL_ALIGNMENT_LEFT, W - rx, 16, cyn)

# Painel completo de vidro: lateral + fills + lateral, modo Normal ou Espelho
class _GlassPanelView extends Control:
    var glass_tex: Texture2D
    var mirror:    bool = false

    const _FILL_COLS := 5
    const _SRC  := 32.0
    const _TW   := 64.0
    const _ROWS := 2

    func _draw() -> void:
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.14))
        if not glass_tex:
            return
        var total_cols := _FILL_COLS + 2
        var panel_w    := float(total_cols) * _TW
        var sx         := (size.x - panel_w) * 0.5
        var sy         := (size.y - float(_ROWS) * _TW - 28.0) * 0.5

        var src_lat_l  := Rect2(1.0 * _SRC, 0.0,         _SRC, _SRC)  # (1,0)
        var src_lat_r  := Rect2(3.0 * _SRC, 2.0 * _SRC,  _SRC, _SRC)  # (3,2)
        var src_fill   := Rect2(2.0 * _SRC, 1.0 * _SRC,  _SRC, _SRC)  # (2,1)
        var font       := ThemeDB.fallback_font
        var lc         := Color(0.5, 0.9, 1.0, 0.9)

        for row in _ROWS:
            var ty := sy + row * _TW
            for col in total_cols:
                var dx  := sx + col * _TW
                var src: Rect2
                if col == 0:
                    src = src_lat_r if mirror else src_lat_l
                elif col == total_cols - 1:
                    src = src_lat_l if mirror else src_lat_r
                else:
                    src = src_fill
                draw_texture_rect_region(glass_tex, Rect2(dx, ty, _TW, _TW), src)

        # Labels abaixo de cada coluna
        var label_y := sy + float(_ROWS) * _TW + 4.0
        for col in total_cols:
            var dx := sx + col * _TW
            var lbl: String
            if col == 0:
                lbl = "(3,2)" if mirror else "(1,0)"
            elif col == total_cols - 1:
                lbl = "(1,0)" if mirror else "(3,2)"
            else:
                lbl = "(2,1)"
            draw_string(font, Vector2(dx + 2.0, label_y),
                lbl, HORIZONTAL_ALIGNMENT_LEFT, _TW, 14, lc)

# Visualização de plataformas e salas: monta bloco N×M com _tile_at ou _room_at
class _PlatformView extends Control:
    var tile_tex: Texture2D
    var rows: int = 2
    var cols: int = 3
    var mode: String = "platform"   # "platform" | "room"

    const _TS := 32.0   # tamanho source
    const _TD := 48.0   # tamanho exibido
    const _EMPTY := Vector2i(0, 3)

    func set_dims(r: int, c: int) -> void:
        rows = r
        cols = c
        custom_minimum_size = Vector2(c * _TD, r * _TD)
        queue_redraw()

    func _draw() -> void:
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.14))
        if not tile_tex:
            return
        for row in rows:
            for col in cols:
                var t := _room_at(col, cols, row, rows) if mode == "room" else _tile_at(col, cols, row, rows)
                if t == _EMPTY:
                    continue
                draw_texture_rect_region(tile_tex,
                    Rect2(col * _TD, row * _TD, _TD, _TD),
                    Rect2(t.x * _TS, t.y * _TS, _TS, _TS))
        if cols >= 2 and rows >= 2:
            _draw_corner_offsets()

    # Linhas amarelas nas faces de colisão + crosshair nos cantos (offset = raio cápsula 10px)
    # Escala: 10px game / 64px tile * 48px display = 7.5px
    func _draw_corner_offsets() -> void:
        const OFS := 7.5
        const ARM := 5.0
        var yellow := Color(1.0, 0.9, 0.0, 0.9)
        var w := cols * _TD
        var h := rows * _TD
        if mode == "platform":
            # Faces de colisão do bloco (ponto de contato Wang: borda do tile sólido)
            draw_line(Vector2(0.0, 0.0), Vector2(w,   0.0), yellow, 1.5)  # topo
            draw_line(Vector2(0.0, h),   Vector2(w,   h),   yellow, 1.5)  # base
            draw_line(Vector2(0.0, 0.0), Vector2(0.0, h),   yellow, 1.5)  # esquerda
            draw_line(Vector2(w,   0.0), Vector2(w,   h),   yellow, 1.5)  # direita
            # Crosshair nos cantos: onde Zael fica tangente ao canto
            for pt: Vector2 in [
                Vector2(OFS, OFS), Vector2(w - OFS, OFS),
                Vector2(OFS, h - OFS), Vector2(w - OFS, h - OFS),
            ]:
                draw_line(pt - Vector2(ARM, 0.0), pt + Vector2(ARM, 0.0), yellow, 1.5)
                draw_line(pt - Vector2(0.0, ARM), pt + Vector2(0.0, ARM), yellow, 1.5)
        else:  # "room"
            # Faces internas da sala (1 tile de borda em cada lado)
            draw_line(Vector2(_TD,     _TD),     Vector2(w - _TD, _TD),     yellow, 1.5)
            draw_line(Vector2(_TD,     h - _TD), Vector2(w - _TD, h - _TD), yellow, 1.5)
            draw_line(Vector2(_TD,     _TD),     Vector2(_TD,     h - _TD), yellow, 1.5)
            draw_line(Vector2(w - _TD, _TD),     Vector2(w - _TD, h - _TD), yellow, 1.5)
            # Crosshair nos cantos internos
            for pt: Vector2 in [
                Vector2(_TD + OFS, _TD + OFS), Vector2(w - _TD - OFS, _TD + OFS),
                Vector2(_TD + OFS, h - _TD - OFS), Vector2(w - _TD - OFS, h - _TD - OFS),
            ]:
                draw_line(pt - Vector2(ARM, 0.0), pt + Vector2(ARM, 0.0), yellow, 1.5)
                draw_line(pt - Vector2(0.0, ARM), pt + Vector2(0.0, ARM), yellow, 1.5)

    func _room_at(col: int, c: int, row: int, r: int) -> Vector2i:
        var is_left   := col == c - 1
        var is_right  := col == 0
        var is_top    := row == r - 1
        var is_bottom := row == 0
        if not is_left and not is_right and not is_top and not is_bottom:
            return _EMPTY
        if is_bottom and is_left:  return Vector2i(2, 2)   # Inner-BL (visual top-left de sala)
        if is_bottom and is_right: return Vector2i(3, 1)   # Inner-BR (visual top-right de sala)
        if is_top    and is_left:  return Vector2i(1, 1)   # Inner-TL (visual bot-left de sala)
        if is_top    and is_right: return Vector2i(2, 0)   # Inner-TR (visual bot-right de sala)
        if is_bottom: return Vector2i(1, 2)   # teto visto de baixo
        if is_top:    return Vector2i(3, 0)   # chão visto de cima
        if is_left:   return Vector2i(1, 0)   # face interna da parede esquerda = RIGHT
        if is_right:  return Vector2i(3, 2)   # face interna da parede direita  = LEFT
        return _EMPTY

    func _tile_at(col: int, c: int, row: int, r: int) -> Vector2i:
        var is_left   := col == c - 1
        var is_right  := col == 0
        var is_top    := row == r - 1
        var is_bottom := row == 0
        if c == 1:
            if is_top:    return Vector2i(1, 2)
            if is_bottom: return Vector2i(3, 0)
            return Vector2i(2, 1)
        if r == 1:
            if is_left:  return Vector2i(0, 0)
            if is_right: return Vector2i(1, 3)
            return Vector2i(3, 0)
        if is_top:
            if is_left:  return Vector2i(3, 3)
            if is_right: return Vector2i(0, 2)
            return Vector2i(1, 2)
        if is_bottom:
            if is_left:  return Vector2i(0, 0)
            if is_right: return Vector2i(1, 3)
            return Vector2i(3, 0)
        if is_left:  return Vector2i(3, 2)
        if is_right: return Vector2i(1, 0)
        return Vector2i(2, 1)

# Nó que vive dentro do SubViewport — desenha fundo, tiles e linhas de colisão
class _MovWorld extends Node2D:
    const _TS := 32.0
    const _TW := 64.0
    var tile_tex:    Texture2D
    var glass_tex:   Texture2D
    var ground_y:    float = 400.0
    var wall_l:      float = 100.0
    var wall_r:      float = 1820.0
    var glass_wall_l: float = 480.0
    var glass_wall_r: float = 900.0
    var glass_rows:   int   = 4
    # face de contato = centro do tile de parede (32px inward em display 64px)
    var contact_l: float = 68.0
    var contact_r: float = 1852.0
    var player_ref: CharacterBase = null

    func _draw() -> void:
        draw_rect(Rect2(-32000.0, -32000.0, 64000.0, 64000.0), Color(0.07, 0.08, 0.16))
        if not tile_tex:
            return
        var src_top    := Rect2(3.0 * _TS, 0.0,        _TS, _TS)  # (3,0) chão
        var src_fill   := Rect2(2.0 * _TS, 1.0 * _TS,  _TS, _TS)  # (2,1) miolo
        var src_left   := Rect2(3.0 * _TS, 2.0 * _TS,  _TS, _TS)  # (3,2) parede esq
        var src_rght   := Rect2(1.0 * _TS, 0.0,         _TS, _TS)  # (1,0) parede dir
        var src_corn_l := Rect2(2.0 * _TS, 0.0,         _TS, _TS)  # (2,0) canto esq-chão
        var src_corn_r := Rect2(1.0 * _TS, 1.0 * _TS,   _TS, _TS)  # (1,1) canto dir-chão
        # TOP tile tem metade superior transparente → deslocar 32px para cima
        # para que a superfície sólida fique alinhada com a linha amarela (ground_y)
        var floor_y := ground_y - _TW * 0.5
        var tx := wall_l
        while tx <= wall_r:
            draw_texture_rect_region(tile_tex, Rect2(tx, floor_y,        _TW, _TW), src_top)
            draw_texture_rect_region(tile_tex, Rect2(tx, floor_y + _TW,  _TW, _TW), src_fill)
            tx += _TW
        draw_texture_rect_region(tile_tex, Rect2(wall_l - _TW, floor_y, _TW, _TW), src_corn_l)
        draw_texture_rect_region(tile_tex, Rect2(wall_r,       floor_y, _TW, _TW), src_corn_r)
        for i: int in 10:
            var ty := floor_y - float(i + 1) * _TW
            draw_texture_rect_region(tile_tex, Rect2(wall_l - _TW, ty, _TW, _TW), src_left)
            draw_texture_rect_region(tile_tex, Rect2(wall_r,       ty, _TW, _TW), src_rght)
        # Paredes de vidro (glass_tex)
        if glass_tex:
            var src      := _TS
            var fill_src := Rect2(2.0 * src, 1.0 * src, src, src)  # (2,1) fill
            var lat_r    := Rect2(1.0 * src, 0.0,        src, src)  # (1,0) borda dir
            var lat_l    := Rect2(3.0 * src, 2.0 * src,  src, src)  # (3,2) borda esq
            var grows    := glass_rows - 1
            for gx: float in [glass_wall_l, glass_wall_r]:
                var is_left := gx == glass_wall_l
                for i in grows:
                    var ty := ground_y - float(i + 1) * _TW
                    if is_left:
                        draw_texture_rect_region(glass_tex, Rect2(gx - _TW, ty, _TW, _TW), lat_r)
                        draw_texture_rect_region(glass_tex, Rect2(gx,        ty, _TW, _TW), fill_src)
                    else:
                        draw_texture_rect_region(glass_tex, Rect2(gx - _TW, ty, _TW, _TW), fill_src)
                        draw_texture_rect_region(glass_tex, Rect2(gx,        ty, _TW, _TW), lat_l)

        # Linhas amarelas de colisão (mesmo padrão do tab Colisões)
        var yel := Color(1.0, 0.9, 0.0, 0.85)
        draw_line(Vector2(-8000.0, ground_y),  Vector2(8000.0,    ground_y),  yel, 2.0)
        draw_line(Vector2(contact_l, -8000.0), Vector2(contact_l, ground_y),  yel, 2.0)
        draw_line(Vector2(contact_r, -8000.0), Vector2(contact_r, ground_y),  yel, 2.0)
        if glass_tex:
            draw_line(Vector2(glass_wall_l, -8000.0), Vector2(glass_wall_l, ground_y), Color(0.5, 0.9, 1.0, 0.9), 2.0)
            draw_line(Vector2(glass_wall_r, -8000.0), Vector2(glass_wall_r, ground_y), Color(0.5, 0.9, 1.0, 0.9), 2.0)
        # Hitbox do player
        if is_instance_valid(player_ref):
            var cs := player_ref.get_node_or_null("CollisionShape2D") as CollisionShape2D
            if cs and cs.shape is CapsuleShape2D:
                var cap := cs.shape as CapsuleShape2D
                var r  := cap.radius
                var hs := (cap.height - 2.0 * r) * 0.5
                var pos := player_ref.global_position + cs.position
                var hcol := Color(0.2, 1.0, 0.2, 0.9)
                var lw   := 2.0
                draw_arc(pos + Vector2(0.0, -hs), r, PI, TAU, 24, hcol, lw)
                draw_arc(pos + Vector2(0.0,  hs), r, 0.0, PI, 24, hcol, lw)
                draw_line(pos + Vector2(-r, -hs), pos + Vector2(-r, hs), hcol, lw)
                draw_line(pos + Vector2( r, -hs), pos + Vector2( r, hs), hcol, lw)

# Arena jogável: SubViewport com Zael, inimigo, física e câmera
class _MovView extends Control:
    const _PLAYER_PATH := "res://characters/ranged/zael.tscn"
    const _ENEMY_PATHS := [
        "res://characters/enemies/enemy_base.tscn",
        "res://characters/enemies/enemy_flyer.tscn",
        "res://characters/enemies/enemy_miniboss.tscn",
    ]
    const _ENEMY_NAMES := ["Grunt", "Flyer", "MiniBoss"]
    const _GROUND_Y    := 16.0
    const _PLAYER_X    := 600.0
    const _ENEMY_X     := 680.0
    const _ENEMY_Y     := [-40.0, -100.0, 3.0]
    const _WALL_L      := 100.0
    const _WALL_R      := 1820.0
    const _GWL         := 480.0
    const _GWR         := 900.0
    const _GLASS_ROWS  := 4
    const _TW          := 64.0

    var _player: CharacterBase = null
    var _enemy: EnemyBase = null
    var _enemy_index: int = 0
    var _camera: Camera2D = null
    var _world: Node2D = null
    var label_enemy: Label = null      # definido externamente antes de add_child
    var label_move_btn: Button = null  # botão de toggle de movimento
    var attack_row: Control = null     # linha de botões de ataque do MiniBoss
    var lbl_state: Label = null

    func _ready() -> void:
        GameManager.active_character = "zael"
        GameManager.max_hp = 8
        GameManager.zael_selected_shot = "single"
        _build()

    func _build() -> void:
        var ctr := SubViewportContainer.new()
        ctr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        ctr.stretch = true
        add_child(ctr)

        var svp := SubViewport.new()
        svp.size = Vector2i(1280, 480)
        svp.handle_input_locally = false
        ctr.add_child(svp)

        var mw := ImgDebug._MovWorld.new()
        mw.tile_tex    = load("res://stages/stage_00/Stage_00T.png") as Texture2D
        mw.glass_tex   = load("res://stages/stage_00/stage_00_glass.png") as Texture2D
        mw.ground_y    = _GROUND_Y
        mw.wall_l      = _WALL_L
        mw.wall_r      = _WALL_R
        mw.glass_wall_l = _GWL
        mw.glass_wall_r = _GWR
        mw.glass_rows   = _GLASS_ROWS
        mw.contact_l   = _WALL_L - 32.0
        mw.contact_r   = _WALL_R + 32.0
        mw.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        svp.add_child(mw)
        _world = mw

        _camera = Camera2D.new()
        _camera.global_position = Vector2(_PLAYER_X, _GROUND_Y + 80.0)
        _world.add_child(_camera)

        _build_physics()
        _spawn_player()
        _spawn_enemy()

    func _build_physics() -> void:
        var ground := StaticBody2D.new()
        ground.collision_layer = 1
        _world.add_child(ground)
        var gcs := CollisionShape2D.new()
        var gseg := SegmentShape2D.new()
        gseg.a = Vector2(-8000.0, _GROUND_Y)
        gseg.b = Vector2( 8000.0, _GROUND_Y)
        gcs.shape = gseg
        ground.add_child(gcs)
        for wx: float in [_WALL_L - 32.0, _WALL_R + 32.0]:
            var wall := StaticBody2D.new()
            wall.collision_layer = 1
            _world.add_child(wall)
            var wcs := CollisionShape2D.new()
            var wseg := SegmentShape2D.new()
            wseg.a = Vector2(wx, _GROUND_Y - 800.0)
            wseg.b = Vector2(wx, _GROUND_Y)
            wcs.shape = wseg
            wall.add_child(wcs)
        # Paredes de vidro (no_wall_grab) — face interna do tile lateral, sem gap
        for gx: float in [_GWL, _GWR]:
            var gwall := StaticBody2D.new()
            gwall.collision_layer = 1
            gwall.add_to_group("no_wall_grab")
            _world.add_child(gwall)
            var gwcs := CollisionShape2D.new()
            var gwseg := SegmentShape2D.new()
            gwseg.a = Vector2(gx, _GROUND_Y - float(_GLASS_ROWS) * _TW)
            gwseg.b = Vector2(gx, _GROUND_Y)
            gwcs.shape = gwseg
            gwall.add_child(gwcs)

    func _spawn_player() -> void:
        if is_instance_valid(_player):
            _player.queue_free()
        var scene := load(_PLAYER_PATH) as PackedScene
        if not scene:
            return
        _player = scene.instantiate() as CharacterBase
        _world.add_child(_player)
        _player.global_position = Vector2(_PLAYER_X, _GROUND_Y - 90.0)
        _player.died.connect(func(): call_deferred("_spawn_player"))
        (_world as ImgDebug._MovWorld).player_ref = _player

    func _spawn_enemy() -> void:
        if is_instance_valid(_enemy):
            _enemy.queue_free()
        var scene := load(_ENEMY_PATHS[_enemy_index]) as PackedScene
        if not scene:
            return
        _enemy = scene.instantiate() as EnemyBase
        _world.add_child(_enemy)
        _enemy.global_position = Vector2(_ENEMY_X, _ENEMY_Y[_enemy_index])
        _enemy.set_physics_process(false)
        _enemy.show_hitbox = true
        _enemy.max_hp     = 99999
        _enemy.current_hp = 99999
        var spr := _enemy.get_node_or_null("Sprite2D") as Sprite2D
        if spr:
            # MiniBoss: sprite já orienta para esquerda (face ao player) — não inverter
            spr.flip_h = (_ENEMY_NAMES[_enemy_index] != "MiniBoss")
        if is_instance_valid(label_enemy):
            label_enemy.text = _ENEMY_NAMES[_enemy_index]

    func on_prev() -> void:
        _enemy_index = (_enemy_index - 1 + _ENEMY_PATHS.size()) % _ENEMY_PATHS.size()
        _spawn_enemy()
        _update_move_btn()
        _update_attack_row()

    func on_next() -> void:
        _enemy_index = (_enemy_index + 1) % _ENEMY_PATHS.size()
        _spawn_enemy()
        _update_move_btn()
        _update_attack_row()

    func on_toggle_movement() -> void:
        if not is_instance_valid(_enemy):
            return
        var moving := not _enemy.is_physics_processing()
        _enemy.set_physics_process(moving)
        _update_move_btn()

    func on_attack(method_name: String) -> void:
        if not is_instance_valid(_enemy):
            return
        if _enemy.has_method(method_name):
            _enemy.call(method_name)

    func _update_move_btn() -> void:
        if is_instance_valid(label_move_btn):
            var moving := is_instance_valid(_enemy) and _enemy.is_physics_processing()
            label_move_btn.text = "⏸ Parar" if moving else "▶ Mover"

    func _update_attack_row() -> void:
        if is_instance_valid(attack_row):
            attack_row.visible = (_ENEMY_NAMES[_enemy_index] == "MiniBoss")

    func _process(delta: float) -> void:
        if is_instance_valid(_player) and is_instance_valid(lbl_state):
            var ws := _player._is_wall_sliding
            var ow := _player.is_on_wall() and not _player.is_on_floor()
            if ws:
                lbl_state.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
                lbl_state.text = "Parede NORMAL — agarrado  (wall jump: Z)"
            elif ow:
                lbl_state.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
                lbl_state.text = "Parede VIDRO — sem grab  (cai com gravidade normal)"
            elif _player.is_on_floor():
                lbl_state.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
                lbl_state.text = "No chão"
            else:
                lbl_state.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
                lbl_state.text = "No ar"
        if is_instance_valid(_player) and is_instance_valid(_camera):
            var cam_pos: Vector2
            if _ENEMY_NAMES[_enemy_index] == "MiniBoss" and is_instance_valid(_enemy):
                # Target: centro do sprite do MiniBoss (sprite_y = -16)
                var tx := _enemy.global_position.x
                var ty := clampf(_enemy.global_position.y - 146.0, _GROUND_Y - 220.0, _GROUND_Y + 100.0)
                # Lerp suave — Y mais lento para não acompanhar o pulo bruscamente
                var sx := minf(1.0, delta * 6.0)
                var sy := minf(1.0, delta * 3.0)
                cam_pos = Vector2(
                    lerpf(_camera.global_position.x, tx, sx),
                    lerpf(_camera.global_position.y, ty, sy)
                )
            else:
                var cam_y := clampf(_player.global_position.y + 120.0, _GROUND_Y - 400.0, _GROUND_Y + 200.0)
                cam_pos  = Vector2(_player.global_position.x, cam_y)
            _camera.global_position = cam_pos
            _world.queue_redraw()

const _FRAME_SIZE   := 68
const _PREVIEW_SIZE := 136
const _STRIP_SIZE   := 40
const _TILE_DISPLAY := 52

var _section: String   = "SPRITES"
var _char: String      = "ZAEL"
var _anim_idx: int     = 0
var _frame: int        = 0
var _paused: bool      = false
var _anim_timer: float = 0.0
var _current_tex: Texture2D = null

var _section_btns: Dictionary = {}
var _char_btns: Dictionary    = {}
var _anim_btns: Array         = []
var _strip_frames: Array      = []

var _sprites_box: VBoxContainer
var _tiles_box: VBoxContainer
var _moves_box: VBoxContainer
var _anim_tabs_box: HBoxContainer
var _preview_rect: TextureRect
var _info_label: Label
var _strip_box: HBoxContainer
var _tile_info_label: Label
var _tile_preview_rect: TextureRect
var _tile_desc_label: Label
var _tile_displays: Dictionary = {}

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _build_ui()
    _select_char("ZAEL")
    _refresh_tiles()
    _build_moves_box()
    _show_section("SPRITES")

func _process(delta: float) -> void:
    if _section != "SPRITES" or _paused:
        return
    var sd := _current_sprite()
    _anim_timer += delta
    var frame_dur: float = 1.0 / float(sd.fps)
    if _anim_timer >= frame_dur:
        _anim_timer -= frame_dur
        _frame = (_frame + 1) % sd.frames
        _update_preview()

func _current_sprite() -> Dictionary:
    var char_sprites: Array = _SPRITES.filter(func(s): return s.char == _char)
    return char_sprites[_anim_idx]

func _show_section(section: String) -> void:
    _section = section
    _sprites_box.visible = (section == "SPRITES")
    _tiles_box.visible   = (section == "TILES")
    _moves_box.visible   = (section == "MOVIMENTOS")
    for s in _section_btns:
        _section_btns[s].modulate = Color(1, 1, 0) if s == section else Color(0.6, 0.6, 0.6)

func _select_char(char_name: String) -> void:
    _char      = char_name
    _anim_idx  = 0
    _frame     = 0
    _anim_timer = 0.0
    _paused    = false
    for c in _char_btns:
        _char_btns[c].modulate = Color(1, 1, 0) if c == char_name else Color(0.6, 0.6, 0.6)
    _rebuild_anim_tabs()

func _select_anim(idx: int) -> void:
    _anim_idx  = idx
    _frame     = 0
    _anim_timer = 0.0
    _paused    = false
    var sd := _current_sprite()
    _current_tex = load(sd.path) as Texture2D
    for i in _anim_btns.size():
        _anim_btns[i].modulate = Color(0, 1, 0) if i == idx else Color(0.6, 0.6, 0.6)
    _rebuild_strip()
    _update_preview()

func _rebuild_anim_tabs() -> void:
    for child in _anim_tabs_box.get_children():
        child.queue_free()
    _anim_btns.clear()
    var char_sprites: Array = _SPRITES.filter(func(s): return s.char == _char)
    for i in char_sprites.size():
        var btn := Button.new()
        btn.text = char_sprites[i].anim
        btn.add_theme_font_size_override("font_size", 26)
        btn.pressed.connect(_select_anim.bind(i))
        _anim_tabs_box.add_child(btn)
        _anim_btns.append(btn)
    _select_anim(0)

func _rebuild_strip() -> void:
    for child in _strip_box.get_children():
        child.queue_free()
    _strip_frames.clear()
    if _current_tex == null:
        return
    var sd  := _current_sprite()
    var tex := _current_tex
    var fw: int = sd.get("frame_w", _FRAME_SIZE)
    for i in sd.frames:
        var at := AtlasTexture.new()
        at.atlas = tex
        at.filter_clip = true
        at.region = Rect2(i * fw, 0, fw, fw)
        var panel := Panel.new()
        panel.custom_minimum_size = Vector2(_STRIP_SIZE + 4, _STRIP_SIZE + 4)
        panel.mouse_filter = Control.MOUSE_FILTER_STOP
        var r := TextureRect.new()
        r.texture = at
        r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        r.mouse_filter = Control.MOUSE_FILTER_IGNORE
        panel.add_child(r)
        var idx: int = i
        panel.gui_input.connect(func(ev): _on_strip_input(ev, idx))
        _strip_box.add_child(panel)
        _strip_frames.append(panel)

func _update_preview() -> void:
    if _current_tex == null:
        return
    var sd  := _current_sprite()
    var tex := _current_tex
    var fw: int = sd.get("frame_w", _FRAME_SIZE)
    var at  := AtlasTexture.new()
    at.atlas = tex
    at.filter_clip = true
    at.region = Rect2(_frame * fw, 0, fw, fw)
    _preview_rect.texture = at
    var status := "● pausado" if _paused else "● animando"
    _info_label.text = "%s %s\nframe %d/%d  |  %.0f fps\n%s" % [
        _char, sd.anim, _frame + 1, sd.frames, sd.fps, status
    ]
    for i in _strip_frames.size():
        var style := StyleBoxFlat.new()
        style.bg_color = Color(0.08, 0.08, 0.18)
        if i == _frame:
            style.border_color = Color(0, 1, 0)
            style.set_border_width_all(2)
        else:
            style.border_color = Color(0.25, 0.25, 0.25)
            style.set_border_width_all(1)
        _strip_frames[i].add_theme_stylebox_override("panel", style)

func _on_strip_input(event: InputEvent, idx: int) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _paused = true
        _frame  = idx
        _update_preview()

func _on_preview_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _paused = false
        _update_preview()

func _build_ui() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    z_index = 200

    var bg := ColorRect.new()
    bg.color = Color(0, 0, 0, 0.88)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var main := VBoxContainer.new()
    main.add_theme_constant_override("separation", 10)
    main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    main.offset_left   = 24
    main.offset_top    = 20
    main.offset_right  = -24
    main.offset_bottom = -20
    add_child(main)

    # Header
    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 12)
    main.add_child(header)

    var title_lbl := Label.new()
    title_lbl.text = "ImgDebug"
    title_lbl.add_theme_font_size_override("font_size", 30)
    title_lbl.add_theme_color_override("font_color", Color(0.8, 0.75, 1.0))
    title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_lbl)

    if OS.get_name() == "Web":
        var reload_btn := Button.new()
        reload_btn.text = "↺ Hard Refresh"
        reload_btn.add_theme_font_size_override("font_size", 28)
        reload_btn.pressed.connect(func(): JavaScriptBridge.eval("location.reload(true)"))
        header.add_child(reload_btn)

    var close_btn := Button.new()
    close_btn.text = "✕ Fechar"
    close_btn.add_theme_font_size_override("font_size", 28)
    close_btn.pressed.connect(queue_free)
    header.add_child(close_btn)

    # Section row: SPRITES | TILES
    var section_row := HBoxContainer.new()
    section_row.add_theme_constant_override("separation", 6)
    main.add_child(section_row)

    for s in ["SPRITES", "TILES"]:
        var btn := Button.new()
        btn.text = s
        btn.add_theme_font_size_override("font_size", 28)
        btn.pressed.connect(_show_section.bind(s))
        section_row.add_child(btn)
        _section_btns[s] = btn

    var mov_btn := Button.new()
    mov_btn.text = "MOVIMENTOS"
    mov_btn.add_theme_font_size_override("font_size", 28)
    mov_btn.pressed.connect(_show_section.bind("MOVIMENTOS"))
    section_row.add_child(mov_btn)
    _section_btns["MOVIMENTOS"] = mov_btn

    # SPRITES BOX
    _sprites_box = VBoxContainer.new()
    _sprites_box.add_theme_constant_override("separation", 8)
    main.add_child(_sprites_box)

    var char_row := HBoxContainer.new()
    char_row.add_theme_constant_override("separation", 6)
    _sprites_box.add_child(char_row)

    for c in ["ZAEL", "ZARA", "MINIBOSS"]:
        var btn := Button.new()
        btn.text = c
        btn.add_theme_font_size_override("font_size", 28)
        btn.pressed.connect(_select_char.bind(c))
        char_row.add_child(btn)
        _char_btns[c] = btn

    _anim_tabs_box = HBoxContainer.new()
    _anim_tabs_box.add_theme_constant_override("separation", 4)
    _sprites_box.add_child(_anim_tabs_box)

    var preview_row := HBoxContainer.new()
    preview_row.add_theme_constant_override("separation", 16)
    _sprites_box.add_child(preview_row)

    _preview_rect = TextureRect.new()
    _preview_rect.custom_minimum_size = Vector2(_PREVIEW_SIZE, _PREVIEW_SIZE)
    _preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _preview_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _preview_rect.mouse_filter = Control.MOUSE_FILTER_STOP
    _preview_rect.gui_input.connect(_on_preview_input)
    preview_row.add_child(_preview_rect)

    var right_col := VBoxContainer.new()
    right_col.add_theme_constant_override("separation", 6)
    preview_row.add_child(right_col)

    _info_label = Label.new()
    _info_label.add_theme_font_size_override("font_size", 20)
    _info_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
    right_col.add_child(_info_label)

    _strip_box = HBoxContainer.new()
    _strip_box.add_theme_constant_override("separation", 4)
    right_col.add_child(_strip_box)

    var hint_lbl := Label.new()
    hint_lbl.text = "strip: clicar pausa  ·  preview: clicar retoma"
    hint_lbl.add_theme_font_size_override("font_size", 16)
    hint_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
    right_col.add_child(hint_lbl)

    # TILES BOX
    _tiles_box = VBoxContainer.new()
    _tiles_box.add_theme_constant_override("separation", 8)
    main.add_child(_tiles_box)

    # MOVIMENTOS BOX
    _moves_box = VBoxContainer.new()
    _moves_box.add_theme_constant_override("separation", 8)
    main.add_child(_moves_box)

func _build_moves_box() -> void:
    var top_bar := HBoxContainer.new()
    top_bar.add_theme_constant_override("separation", 8)
    _moves_box.add_child(top_bar)

    var hint := Label.new()
    hint.text = "A/D: mover  ·  Z: pular  ·  X: dash  ·  J: atirar"
    hint.add_theme_font_size_override("font_size", 17)
    hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
    hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hint.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
    top_bar.add_child(hint)

    var enemy_lbl := Label.new()
    enemy_lbl.text = "Inimigo:"
    enemy_lbl.add_theme_font_size_override("font_size", 18)
    enemy_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    top_bar.add_child(enemy_lbl)

    var mview := _MovView.new()
    mview.custom_minimum_size        = Vector2(0.0, 480.0)
    mview.size_flags_horizontal      = Control.SIZE_EXPAND_FILL
    mview.size_flags_vertical        = Control.SIZE_EXPAND_FILL

    var btn_prev := Button.new()
    btn_prev.text = "◄"
    btn_prev.add_theme_font_size_override("font_size", 18)
    btn_prev.pressed.connect(mview.on_prev)
    top_bar.add_child(btn_prev)

    var lbl_name := Label.new()
    lbl_name.custom_minimum_size.x = 80.0
    lbl_name.add_theme_font_size_override("font_size", 18)
    lbl_name.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
    lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_name.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
    lbl_name.text = "Grunt"
    top_bar.add_child(lbl_name)

    var btn_next := Button.new()
    btn_next.text = "►"
    btn_next.add_theme_font_size_override("font_size", 18)
    btn_next.pressed.connect(mview.on_next)
    top_bar.add_child(btn_next)

    var btn_move := Button.new()
    btn_move.text = "▶ Mover"
    btn_move.add_theme_font_size_override("font_size", 24)
    btn_move.pressed.connect(mview.on_toggle_movement)
    top_bar.add_child(btn_move)

    mview.label_enemy    = lbl_name
    mview.label_move_btn = btn_move

    var state_lbl := Label.new()
    state_lbl.add_theme_font_size_override("font_size", 16)
    state_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
    state_lbl.text = "No chão"
    _moves_box.add_child(state_lbl)
    mview.lbl_state = state_lbl

    var atk_row := HBoxContainer.new()
    atk_row.add_theme_constant_override("separation", 8)
    atk_row.visible = false
    _moves_box.add_child(atk_row)
    mview.attack_row = atk_row

    var atk_lbl := Label.new()
    atk_lbl.text = "Estado:"
    atk_lbl.add_theme_font_size_override("font_size", 18)
    atk_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    atk_row.add_child(atk_lbl)

    for atk: Array in [
        ["Advance",  "debug_set_patrol",   Color(0.4, 0.9, 0.4)],
        ["Punch",    "debug_set_punch",    Color(1.0, 0.5, 0.9)],
        ["Charge",   "debug_set_charge",   Color(1.0, 0.7, 0.2)],
        ["Stomp",    "debug_set_stomp",    Color(1.0, 0.35, 0.35)],
        ["Backjump", "debug_set_backjump", Color(0.4, 0.8, 1.0)],
        ["Recover",  "debug_set_recover",  Color(0.5, 0.75, 1.0)],
    ]:
        var abtn := Button.new()
        abtn.text = atk[0]
        abtn.add_theme_font_size_override("font_size", 24)
        abtn.modulate = atk[2]
        var mname: String = atk[1]
        abtn.pressed.connect(mview.on_attack.bind(mname))
        atk_row.add_child(abtn)

    _moves_box.add_child(mview)

func _refresh_tiles() -> void:
    _tile_displays.clear()
    for child in _tiles_box.get_children():
        child.queue_free()

    # Tab bar
    var tab_row := HBoxContainer.new()
    tab_row.add_theme_constant_override("separation", 4)
    _tiles_box.add_child(tab_row)

    var panels: Array = []

    var show_tab := func(idx: int) -> void:
        for i in panels.size():
            panels[i].visible = (i == idx)
        for i in tab_row.get_child_count():
            tab_row.get_child(i).modulate = Color(1.0, 1.0, 0.0) if i == idx else Color(0.6, 0.6, 0.6)

    # One tab per tileset
    for ts_idx in _TILESETS.size():
        var ts_data: Dictionary = _TILESETS[ts_idx]

        var tab_btn := Button.new()
        tab_btn.text = ts_data.name.trim_suffix("T")
        tab_btn.add_theme_font_size_override("font_size", 26)
        tab_btn.pressed.connect(show_tab.bind(ts_idx))
        tab_row.add_child(tab_btn)

        var panel := VBoxContainer.new()
        panel.add_theme_constant_override("separation", 8)
        panel.visible = (ts_idx == 0)
        _tiles_box.add_child(panel)
        panels.append(panel)

        var info_lbl := Label.new()
        info_lbl.text = "clique num tile para zoom  ·  %dx%d, %dpx cada" % [ts_data.cols, ts_data.rows, ts_data.tile_size]
        info_lbl.add_theme_font_size_override("font_size", 17)
        info_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
        panel.add_child(info_lbl)

        var content_row := HBoxContainer.new()
        content_row.add_theme_constant_override("separation", 16)
        panel.add_child(content_row)

        var grid := GridContainer.new()
        grid.columns = ts_data.cols
        grid.add_theme_constant_override("h_separation", 4)
        grid.add_theme_constant_override("v_separation", 4)
        content_row.add_child(grid)

        var zoom_panel := Panel.new()
        zoom_panel.custom_minimum_size = Vector2(160, 160)
        var zoom_style := StyleBoxFlat.new()
        zoom_style.bg_color = Color(0.05, 0.05, 0.12)
        zoom_style.border_color = Color(1.0, 0.9, 0.2)
        zoom_style.set_border_width_all(1)
        zoom_panel.add_theme_stylebox_override("panel", zoom_style)
        content_row.add_child(zoom_panel)

        var preview_rect := TextureRect.new()
        preview_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        preview_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        preview_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        zoom_panel.add_child(preview_rect)

        var desc_lbl := Label.new()
        desc_lbl.text = ""
        desc_lbl.add_theme_font_size_override("font_size", 18)
        desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.6))
        desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        panel.add_child(desc_lbl)

        _tile_displays[ts_data.name] = {
            "info":    info_lbl,
            "preview": preview_rect,
            "desc":    desc_lbl,
            "data":    ts_data,
        }

        var tex    := load(ts_data.path) as Texture2D
        var ts_px: int = ts_data.tile_size

        for row in ts_data.rows:
            for col in ts_data.cols:
                var cell := VBoxContainer.new()
                cell.add_theme_constant_override("separation", 2)
                grid.add_child(cell)

                var at := AtlasTexture.new()
                at.atlas = tex
                at.filter_clip = true
                at.region = Rect2(col * ts_px, row * ts_px, ts_px, ts_px)

                var tile_panel := Panel.new()
                tile_panel.custom_minimum_size = Vector2(_TILE_DISPLAY, _TILE_DISPLAY)
                tile_panel.mouse_filter = Control.MOUSE_FILTER_STOP
                var tile_style := StyleBoxFlat.new()
                tile_style.bg_color = Color(0.08, 0.08, 0.18)
                tile_style.border_color = Color(1.0, 0.9, 0.2)
                tile_style.set_border_width_all(1)
                tile_panel.add_theme_stylebox_override("panel", tile_style)
                var c: int = col
                var r: int = row
                var ts_n: String = ts_data.name
                tile_panel.gui_input.connect(func(ev): _on_tile_input(ev, c, r, ts_n))
                cell.add_child(tile_panel)

                var tile_rect := TextureRect.new()
                tile_rect.texture = at
                tile_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
                tile_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                tile_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
                tile_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
                tile_panel.add_child(tile_rect)

                var is_blank: bool = _TILE_DESCS.get("%s:%d,%d" % [ts_data.name, col, row], "").begins_with("Transparente")
                var coord_lbl := Label.new()
                coord_lbl.text = "—" if is_blank else "%d,%d" % [col, row]
                coord_lbl.add_theme_font_size_override("font_size", 15)
                coord_lbl.add_theme_color_override(
                    "font_color",
                    Color(0.3, 0.3, 0.3) if is_blank else Color(0.6, 0.6, 0.6)
                )
                coord_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                cell.add_child(coord_lbl)

    # Colisões tab
    var col_tab_idx: int = panels.size()

    var col_tab_btn := Button.new()
    col_tab_btn.text = "Colisões"
    col_tab_btn.add_theme_font_size_override("font_size", 26)
    col_tab_btn.pressed.connect(show_tab.bind(col_tab_idx))
    tab_row.add_child(col_tab_btn)

    var col_panel := VBoxContainer.new()
    col_panel.add_theme_constant_override("separation", 8)
    col_panel.visible = false
    _tiles_box.add_child(col_panel)
    panels.append(col_panel)

    var col_mode_row := HBoxContainer.new()
    col_mode_row.add_theme_constant_override("separation", 6)
    col_panel.add_child(col_mode_row)
    var col_mode_lbl := Label.new()
    col_mode_lbl.text = "Modo:"
    col_mode_lbl.add_theme_font_size_override("font_size", 18)
    col_mode_row.add_child(col_mode_lbl)

    var lateral_box := VBoxContainer.new()
    col_panel.add_child(lateral_box)
    var col_row := HBoxContainer.new()
    col_row.add_theme_constant_override("separation", 24)
    lateral_box.add_child(col_row)

    var lview := _LateralView.new()
    lview.tile_tex   = load("res://stages/stage_00/Stage_00T.png") as Texture2D
    lview.sprite_tex = load("res://characters/ranged/ZaelIdle.png") as Texture2D
    lview.custom_minimum_size = Vector2(280, 220)
    lview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    col_row.add_child(lview)

    var col_info := VBoxContainer.new()
    col_info.add_theme_constant_override("separation", 4)
    col_row.add_child(col_info)

    var add_info := func(text: String, color: Color) -> void:
        var il := Label.new()
        il.text = text
        il.add_theme_font_size_override("font_size", 18)
        il.add_theme_color_override("font_color", color)
        col_info.add_child(il)

    add_info.call("Tile world: 64 x 64 px", Color(0.8, 0.8, 0.8))
    add_info.call("Capsula (ciano):", Color(0.0, 1.0, 1.0))
    add_info.call("  largura: 20 px  (raio 10)", Color(0.8, 0.8, 0.8))
    add_info.call("  altura: 48 px  (h28 + 2xr10)", Color(0.8, 0.8, 0.8))
    add_info.call("Sprite Zael:", Color(1.0, 0.9, 0.3))
    add_info.call("  68px x escala 2 = 136 px", Color(0.8, 0.8, 0.8))
    add_info.call("  offset Y: -4 px", Color(0.8, 0.8, 0.8))

    var cview_hbox := HBoxContainer.new()
    cview_hbox.visible = false
    col_panel.add_child(cview_hbox)

    var cview_col := _CornerView.new()
    cview_col.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    cview_col.tile_tex   = load("res://stages/stage_00/Stage_00T.png") as Texture2D
    cview_col.sprite_tex = load("res://characters/ranged/ZaelIdle.png") as Texture2D
    cview_col.custom_minimum_size = Vector2(320.0, 260.0)
    cview_col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    cview_hbox.add_child(cview_col)

    var col_corner_row := HBoxContainer.new()
    col_corner_row.add_theme_constant_override("separation", 6)
    col_corner_row.visible = false
    var col_corner_lbl := Label.new()
    col_corner_lbl.text = "Canto:"
    col_corner_lbl.add_theme_font_size_override("font_size", 18)
    col_corner_row.add_child(col_corner_lbl)
    for ci: Array in [["↗ topo-dir", 0], ["↖ topo-esq", 1], ["↘ base-dir", 2], ["↙ base-esq", 3]]:
        var cbtn := Button.new()
        cbtn.text = ci[0]
        cbtn.add_theme_font_size_override("font_size", 24)
        var cidx: int = ci[1]
        cbtn.pressed.connect(func(): cview_col.corner = cidx; cview_col.queue_redraw())
        col_corner_row.add_child(cbtn)
    col_panel.add_child(col_corner_row)

    var col_mode_btns: Array = []
    var _col_sw := func(is_corners: bool) -> void:
        lateral_box.visible = not is_corners
        cview_hbox.visible = is_corners
        col_corner_row.visible = is_corners
        for b: Button in col_mode_btns:
            b.modulate = Color(1.0, 1.0, 0.0) if (b.text == "Cantos") == is_corners else Color(0.6, 0.6, 0.6)
    for ml: Array in [["Lateral", false], ["Cantos", true]]:
        var mbtn := Button.new()
        mbtn.text = ml[0]
        mbtn.add_theme_font_size_override("font_size", 24)
        var is_c: bool = ml[1]
        mbtn.pressed.connect(func(): _col_sw.call(is_c))
        col_mode_row.add_child(mbtn)
        col_mode_btns.append(mbtn)
    col_mode_btns[0].modulate = Color(1.0, 1.0, 0.0)

    # ── Seção Vidro ──────────────────────────────────────────────────────────
    var glass_sep := HSeparator.new()
    col_panel.add_child(glass_sep)

    var glass_hdr := Label.new()
    glass_hdr.text = "Vidro (stage_00_glass.png)"
    glass_hdr.add_theme_font_size_override("font_size", 20)
    glass_hdr.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
    col_panel.add_child(glass_hdr)

    var glass_mode_row := HBoxContainer.new()
    glass_mode_row.add_theme_constant_override("separation", 6)
    col_panel.add_child(glass_mode_row)
    var glass_mode_lbl := Label.new()
    glass_mode_lbl.text = "Modo:"
    glass_mode_lbl.add_theme_font_size_override("font_size", 18)
    glass_mode_row.add_child(glass_mode_lbl)

    var gl_tex  := load("res://stages/stage_00/stage_00_glass.png") as Texture2D
    var tile_t  := load("res://stages/stage_00/Stage_00T.png")      as Texture2D
    var spr_t   := load("res://characters/ranged/ZaelIdle.png")     as Texture2D

    # ── Boxes por modo ───────────────────────────────────────────────────────
    var gbox_lat := VBoxContainer.new()
    var gbox_cor := VBoxContainer.new()
    var gbox_gap := VBoxContainer.new()
    var gbox_cmp := VBoxContainer.new()
    var gbox_pan := VBoxContainer.new()

    # Lateral
    var glat := _GlassLateralView.new()
    glat.glass_tex  = gl_tex
    glat.sprite_tex = spr_t
    glat.custom_minimum_size = Vector2(280, 220)
    glat.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    gbox_lat.add_child(glat)

    # Cantos
    var gcor := _GlassCornerView.new()
    gcor.tile_tex   = tile_t
    gcor.glass_tex  = gl_tex
    gcor.sprite_tex = spr_t
    gcor.custom_minimum_size = Vector2(320, 260)
    gcor.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    gcor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    gbox_cor.add_child(gcor)

    var gcor_btn_row := HBoxContainer.new()
    gcor_btn_row.add_theme_constant_override("separation", 6)
    var gcor_lbl := Label.new()
    gcor_lbl.text = "Canto:"
    gcor_lbl.add_theme_font_size_override("font_size", 18)
    gcor_btn_row.add_child(gcor_lbl)
    for gci: Array in [["↗ topo-dir", 0], ["↖ topo-esq", 1], ["↘ base-dir", 2], ["↙ base-esq", 3]]:
        var gcbtn := Button.new()
        gcbtn.text = gci[0]
        gcbtn.add_theme_font_size_override("font_size", 24)
        var gcidx: int = gci[1]
        gcbtn.pressed.connect(func(): gcor.corner = gcidx; gcor.queue_redraw())
        gcor_btn_row.add_child(gcbtn)
    gbox_cor.add_child(gcor_btn_row)

    # Gap
    var ggap := _GlassGapView.new()
    ggap.glass_tex  = gl_tex
    ggap.tile_tex   = tile_t
    ggap.sprite_tex = spr_t
    ggap.custom_minimum_size = Vector2(300, 260)
    ggap.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    gbox_gap.add_child(ggap)

    # Comparação
    var gcmp := _GlassCompareView.new()
    gcmp.glass_tex  = gl_tex
    gcmp.tile_tex   = tile_t
    gcmp.sprite_tex = spr_t
    gcmp.custom_minimum_size = Vector2(380, 220)
    gcmp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    gbox_cmp.add_child(gcmp)

    # Painel
    var gpan := _GlassPanelView.new()
    gpan.glass_tex = gl_tex
    gpan.custom_minimum_size = Vector2(540, 180)
    gpan.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    gbox_pan.add_child(gpan)

    var gpan_row := HBoxContainer.new()
    gpan_row.add_theme_constant_override("separation", 6)
    var gpan_norm_btn := Button.new()
    gpan_norm_btn.text = "Normal"
    gpan_norm_btn.add_theme_font_size_override("font_size", 22)
    gpan_norm_btn.modulate = Color(1.0, 1.0, 0.0)
    var gpan_mirr_btn := Button.new()
    gpan_mirr_btn.text = "Espelho"
    gpan_mirr_btn.add_theme_font_size_override("font_size", 22)
    gpan_mirr_btn.modulate = Color(0.6, 0.6, 0.6)
    gpan_norm_btn.pressed.connect(func():
        gpan.mirror = false; gpan.queue_redraw()
        gpan_norm_btn.modulate = Color(1.0, 1.0, 0.0)
        gpan_mirr_btn.modulate = Color(0.6, 0.6, 0.6))
    gpan_mirr_btn.pressed.connect(func():
        gpan.mirror = true; gpan.queue_redraw()
        gpan_mirr_btn.modulate = Color(1.0, 1.0, 0.0)
        gpan_norm_btn.modulate = Color(0.6, 0.6, 0.6))
    gpan_row.add_child(gpan_norm_btn)
    gpan_row.add_child(gpan_mirr_btn)
    gbox_pan.add_child(gpan_row)

    # Adicionar boxes ao col_panel (lateral visível por padrão)
    var glass_boxes: Array = [gbox_lat, gbox_cor, gbox_gap, gbox_cmp, gbox_pan]
    for gb: VBoxContainer in glass_boxes:
        gb.visible = false
        col_panel.add_child(gb)
    gbox_lat.visible = true

    # Toggle de modos
    var glass_mode_btns: Array = []
    var _glass_sw := func(idx: int) -> void:
        for i in glass_boxes.size():
            glass_boxes[i].visible = (i == idx)
        for i in glass_mode_btns.size():
            glass_mode_btns[i].modulate = \
                Color(1.0, 1.0, 0.0) if i == idx else Color(0.6, 0.6, 0.6)
    for gml: Array in [["Lateral", 0], ["Cantos", 1], ["Gap", 2], ["Comparação", 3], ["Painel", 4]]:
        var gmbtn := Button.new()
        gmbtn.text = gml[0]
        gmbtn.add_theme_font_size_override("font_size", 24)
        var gidx: int = gml[1]
        gmbtn.pressed.connect(func(): _glass_sw.call(gidx))
        glass_mode_row.add_child(gmbtn)
        glass_mode_btns.append(gmbtn)
    glass_mode_btns[0].modulate = Color(1.0, 1.0, 0.0)

    # Plataformas tab
    var plat_tab_idx: int = panels.size()

    var plat_tab_btn := Button.new()
    plat_tab_btn.text = "Plataformas"
    plat_tab_btn.add_theme_font_size_override("font_size", 26)
    plat_tab_btn.pressed.connect(show_tab.bind(plat_tab_idx))
    tab_row.add_child(plat_tab_btn)

    var plat_panel := VBoxContainer.new()
    plat_panel.add_theme_constant_override("separation", 8)
    plat_panel.visible = false
    _tiles_box.add_child(plat_panel)
    panels.append(plat_panel)

    var pview := _PlatformView.new()
    pview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    pview.tile_tex = load(_TILESETS[0].path) as Texture2D

    var plat_ts_row := HBoxContainer.new()
    plat_ts_row.add_theme_constant_override("separation", 6)
    plat_panel.add_child(plat_ts_row)

    var plat_ts_lbl := Label.new()
    plat_ts_lbl.text = "Tileset:"
    plat_ts_lbl.add_theme_font_size_override("font_size", 18)
    plat_ts_row.add_child(plat_ts_lbl)

    for ts_data2 in _TILESETS:
        var ts_btn := Button.new()
        ts_btn.text = ts_data2.name.trim_suffix("T")
        ts_btn.add_theme_font_size_override("font_size", 24)
        var ts_path2: String = ts_data2.path
        ts_btn.pressed.connect(func():
            pview.tile_tex = load(ts_path2) as Texture2D
            pview.queue_redraw())
        plat_ts_row.add_child(ts_btn)

    # Modo: Plataforma | Sala
    var mode_row := HBoxContainer.new()
    mode_row.add_theme_constant_override("separation", 6)
    plat_panel.add_child(mode_row)

    var mode_lbl := Label.new()
    mode_lbl.text = "Modo:"
    mode_lbl.add_theme_font_size_override("font_size", 18)
    mode_row.add_child(mode_lbl)

    var ctrl_row := HBoxContainer.new()
    ctrl_row.add_theme_constant_override("separation", 20)

    var mode_btns: Array = []
    var _sw := func(mkey: String, mlbl: String) -> void:
        pview.mode = mkey
        pview.queue_redraw()
        for b: Button in mode_btns:
            b.modulate = Color(1.0, 1.0, 0.0) if b.text == mlbl else Color(0.6, 0.6, 0.6)

    for me: Array in [["Plataforma", "platform"], ["Sala", "room"]]:
        var mbtn := Button.new()
        mbtn.text = me[0]
        mbtn.add_theme_font_size_override("font_size", 24)
        var mk: String = me[1]
        var ml: String = me[0]
        mbtn.pressed.connect(func(): _sw.call(mk, ml))
        mode_row.add_child(mbtn)
        mode_btns.append(mbtn)
    mode_btns[0].modulate = Color(1.0, 1.0, 0.0)

    plat_panel.add_child(ctrl_row)

    var cols_lbl := Label.new()
    cols_lbl.text = "Cols: 3"
    cols_lbl.add_theme_font_size_override("font_size", 18)
    cols_lbl.custom_minimum_size = Vector2(80.0, 0.0)
    var cols_hb := HBoxContainer.new()
    cols_hb.add_theme_constant_override("separation", 4)
    var cols_m := Button.new()
    cols_m.text = "−"
    cols_m.add_theme_font_size_override("font_size", 18)
    cols_m.pressed.connect(func():
        if pview.cols > 1:
            pview.set_dims(pview.rows, pview.cols - 1)
            cols_lbl.text = "Cols: %d" % pview.cols)
    var cols_p := Button.new()
    cols_p.text = "+"
    cols_p.add_theme_font_size_override("font_size", 18)
    cols_p.pressed.connect(func():
        if pview.cols < 8:
            pview.set_dims(pview.rows, pview.cols + 1)
            cols_lbl.text = "Cols: %d" % pview.cols)
    cols_hb.add_child(cols_m)
    cols_hb.add_child(cols_lbl)
    cols_hb.add_child(cols_p)
    ctrl_row.add_child(cols_hb)

    var rows_lbl := Label.new()
    rows_lbl.text = "Rows: 2"
    rows_lbl.add_theme_font_size_override("font_size", 18)
    rows_lbl.custom_minimum_size = Vector2(80.0, 0.0)
    var rows_hb := HBoxContainer.new()
    rows_hb.add_theme_constant_override("separation", 4)
    var rows_m := Button.new()
    rows_m.text = "−"
    rows_m.add_theme_font_size_override("font_size", 18)
    rows_m.pressed.connect(func():
        if pview.rows > 1:
            pview.set_dims(pview.rows - 1, pview.cols)
            rows_lbl.text = "Rows: %d" % pview.rows)
    var rows_p := Button.new()
    rows_p.text = "+"
    rows_p.add_theme_font_size_override("font_size", 18)
    rows_p.pressed.connect(func():
        if pview.rows < 8:
            pview.set_dims(pview.rows + 1, pview.cols)
            rows_lbl.text = "Rows: %d" % pview.rows)
    rows_hb.add_child(rows_m)
    rows_hb.add_child(rows_lbl)
    rows_hb.add_child(rows_p)
    ctrl_row.add_child(rows_hb)

    plat_panel.add_child(pview)
    pview.set_dims(2, 3)

    show_tab.call(0)

func _on_tile_input(event: InputEvent, col: int, row: int, ts_name: String) -> void:
    if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
        return
    if not _tile_displays.has(ts_name):
        return
    var d: Dictionary = _tile_displays[ts_name]
    var ts_data: Dictionary = d.data
    var is_empty: bool = _TILE_DESCS.get("%s:%d,%d" % [ts_name, col, row], "").begins_with("Transparente")
    if is_instance_valid(d.info):
        if is_empty:
            d.info.text = "Tile (%d,%d) — transparente (alpha = 0)" % [col, row]
        else:
            d.info.text = "Tile selecionado: (%d, %d)" % [col, row]
    if is_instance_valid(d.preview) and not is_empty:
        var ts_px: int = ts_data.tile_size
        var at := AtlasTexture.new()
        at.atlas = load(ts_data.path) as Texture2D
        at.filter_clip = true
        at.region = Rect2(col * ts_px, row * ts_px, ts_px, ts_px)
        d.preview.texture = at
    if is_instance_valid(d.desc):
        d.desc.text = _TILE_DESCS.get("%s:%d,%d" % [ts_name, col, row], "")
