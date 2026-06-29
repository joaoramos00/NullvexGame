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
    # Kawagael (reskin do Zael) — corrida placeholder 5/8 frames. Atualizar "frames" p/ 8 ao completar f5-f7.
    {"char": "KAWAGAEL", "anim": "Run",   "path": "res://characters/ranged/kawagael/KawagaelRun.png", "frames": 4, "fps": 10.0},
    {"char": "ZARA", "anim": "Walk",      "path": "res://characters/melee/ZaraAndando.png",    "frames": 5, "fps": 8.0},
    {"char": "ZARA", "anim": "Run",       "path": "res://characters/melee/ZaraCorrendo.png",   "frames": 3, "fps": 10.0},
    {"char": "MINIBOSS", "anim": "Walk",  "path": "res://characters/enemies/miniboss/stage_00/miniboss_walk.png",  "frames": 6, "fps": 8.0,  "frame_w": 240},
    {"char": "MINIBOSS", "anim": "Idle",  "path": "res://characters/enemies/miniboss/stage_00/miniboss_idle.png",  "frames": 4, "fps": 6.0,  "frame_w": 240},
    {"char": "MINIBOSS", "anim": "Punch", "path": "res://characters/enemies/miniboss/stage_00/miniboss_punch.png", "frames": 9, "fps": 12.0, "frame_w": 240, "label": "Punch (novo gif)"},
    {"char": "MINIBOSS", "anim": "Stomp",  "path": "res://characters/enemies/miniboss/stage_00/miniboss_stomp.png",  "frames": 9, "fps": 12.0, "frame_w": 240},
    {"char": "MINIBOSS", "anim": "Charge", "path": "res://characters/enemies/miniboss/stage_00/miniboss_charge.png", "frames": 8, "fps": 10.0, "frame_w": 240},
]

const _HITBOX_ENTITIES: Array = [
    {"name": "Zael", "path": "res://characters/ranged/zael.tscn", "group": "Personagens", "kind": "Personagens", "stage": ""},
    {"name": "Kawagael", "path": "res://characters/ranged/kawagael/kawagael.tscn", "group": "Personagens", "kind": "Personagens", "stage": ""},
    {"name": "Zara", "path": "res://characters/melee/zara.tscn", "group": "Personagens", "kind": "Personagens", "stage": ""},
    {"name": "Enemy Base", "path": "res://characters/enemies/enemy_base.tscn", "group": "Inimigos", "kind": "Inimigos", "stage": "Stage 00"},
    {"name": "Enemy Flyer", "path": "res://characters/enemies/enemy_flyer.tscn", "group": "Inimigos", "kind": "Inimigos", "stage": "Stage 00"},
    {"name": "Enemy Miniboss", "path": "res://characters/enemies/enemy_miniboss.tscn", "group": "Bosses", "kind": "Inimigos", "stage": "Stage 00", "anims": [
        {"label": "Walk",   "path": "res://characters/enemies/miniboss/stage_00/miniboss_walk.png",   "frames": 6},
        {"label": "Idle",   "path": "res://characters/enemies/miniboss/stage_00/miniboss_idle.png",   "frames": 4},
        {"label": "Punch",  "path": "res://characters/enemies/miniboss/stage_00/miniboss_punch.png",  "frames": 9},
        {"label": "Stomp",  "path": "res://characters/enemies/miniboss/stage_00/miniboss_stomp.png",  "frames": 9},
        {"label": "Charge", "path": "res://characters/enemies/miniboss/stage_00/miniboss_charge.png", "frames": 9},
    ]},
    {"name": "Intro Boss", "path": "res://characters/bosses/intro_boss.tscn", "group": "Bosses", "kind": "Inimigos", "stage": "Stage 00", "anims": [
        {"label": "Entry", "path": "res://characters/bosses/intro_boss/intro_boss_entry.png", "frames": 9},
        {"label": "Idle",  "path": "res://characters/bosses/intro_boss/intro_boss_idle.png",  "frames": 8},
        {"label": "Walk",  "path": "res://characters/bosses/intro_boss/intro_boss_walk.png",  "frames": 6},
        {"label": "Dash",  "path": "res://characters/bosses/intro_boss/intro_boss_dash.png",  "frames": 7},
        {"label": "Shoot", "path": "res://characters/bosses/intro_boss/intro_boss_shoot.png", "frames": 7},
    ]},
    {"name": "Ice Grunt", "path": "res://characters/enemies/stage_02/enemy_ice_grunt.tscn", "group": "Inimigos", "kind": "Inimigos", "stage": "Stage 02"},
    {"name": "Ice Flyer", "path": "res://characters/enemies/stage_02/enemy_ice_flyer.tscn", "group": "Inimigos", "kind": "Inimigos", "stage": "Stage 02"},
    {"name": "Ice Archer", "path": "res://characters/enemies/stage_02/enemy_ice_archer.tscn", "group": "Inimigos", "kind": "Inimigos", "stage": "Stage 02"},
    {"name": "Frost Turret", "path": "res://characters/enemies/stage_02/enemy_frost_turret.tscn", "group": "Inimigos", "kind": "Inimigos", "stage": "Stage 02"},
    {"name": "Cryo Bomber", "path": "res://characters/enemies/stage_02/enemy_cryo_bomber.tscn", "group": "Inimigos", "kind": "Inimigos", "stage": "Stage 02"},
    {"name": "Glacier Shield", "path": "res://characters/enemies/stage_02/enemy_glacier_shield.tscn", "group": "Inimigos", "kind": "Inimigos", "stage": "Stage 02"},
    {"name": "Ice Wisp", "path": "res://characters/enemies/stage_02/enemy_ice_wisp.tscn", "group": "Inimigos", "kind": "Inimigos", "stage": "Stage 02"},
    {"name": "Ice Miniboss", "path": "res://characters/enemies/stage_02/enemy_ice_miniboss.tscn", "group": "Bosses", "kind": "Inimigos", "stage": "Stage 02"},
    {"name": "Cryovex", "path": "res://characters/bosses/cryovex.tscn", "group": "Bosses", "kind": "Inimigos", "stage": "Stage 02"},
    {"name": "Magma Grunt", "path": "res://characters/enemies/stage_01/enemy_magma_grunt.tscn", "group": "Inimigos", "kind": "Inimigos", "stage": "Stage 01"},
    {"name": "Molten Ram", "path": "res://characters/enemies/stage_01/enemy_molten_ram.tscn", "group": "Inimigos", "kind": "Inimigos", "stage": "Stage 01"},
    {"name": "Ash Hopper", "path": "res://characters/enemies/stage_01/enemy_ash_hopper.tscn", "group": "Inimigos", "kind": "Inimigos", "stage": "Stage 01"},
    {"name": "Ember Orbiter", "path": "res://characters/enemies/stage_01/enemy_ember_orbiter.tscn", "group": "Inimigos", "kind": "Inimigos", "stage": "Stage 01"},
    {"name": "Flame Skimmer", "path": "res://characters/enemies/stage_01/enemy_flame_skimmer.tscn", "group": "Inimigos", "kind": "Inimigos", "stage": "Stage 01"},
    {"name": "Cinder Flyer", "path": "res://characters/enemies/stage_01/enemy_cinder_flyer.tscn", "group": "Inimigos", "kind": "Inimigos", "stage": "Stage 01"},
    {"name": "Heat Mortar", "path": "res://characters/enemies/stage_01/enemy_heat_mortar.tscn", "group": "Inimigos", "kind": "Inimigos", "stage": "Stage 01"},
    {"name": "Magma Turret", "path": "res://characters/enemies/stage_01/enemy_magma_turret.tscn", "group": "Inimigos", "kind": "Inimigos", "stage": "Stage 01"},
    {"name": "Lava Serpent", "path": "res://characters/enemies/stage_01/enemy_lava_serpent.tscn", "group": "Inimigos", "kind": "Inimigos", "stage": "Stage 01"},
    {"name": "Boss Base", "path": "res://characters/bosses/boss_base.tscn", "group": "Bosses", "kind": "Bosses", "stage": ""},
    {"name": "Intro Boss", "path": "res://characters/bosses/intro_boss.tscn", "group": "Bosses", "kind": "Bosses", "stage": "Stage 00", "anims": [
        {"label": "Entry", "path": "res://characters/bosses/intro_boss/intro_boss_entry.png", "frames": 9},
        {"label": "Idle",  "path": "res://characters/bosses/intro_boss/intro_boss_idle.png",  "frames": 8},
        {"label": "Walk",  "path": "res://characters/bosses/intro_boss/intro_boss_walk.png",  "frames": 6},
        {"label": "Dash",  "path": "res://characters/bosses/intro_boss/intro_boss_dash.png",  "frames": 7},
        {"label": "Shoot", "path": "res://characters/bosses/intro_boss/intro_boss_shoot.png", "frames": 7},
    ]},
    {"name": "Cryovex", "path": "res://characters/bosses/cryovex.tscn", "group": "Bosses", "kind": "Bosses", "stage": "Stage 02"},
    {"name": "Galerix", "path": "res://characters/bosses/galerix.tscn", "group": "Bosses", "kind": "Bosses", "stage": ""},
    {"name": "Gravitus", "path": "res://characters/bosses/gravitus.tscn", "group": "Bosses", "kind": "Bosses", "stage": ""},
    {"name": "Ignarath", "path": "res://characters/bosses/ignarath.tscn", "group": "Bosses", "kind": "Bosses", "stage": "", "anims": [
        {"label": "Walk",       "path": "res://characters/bosses/ignarath/ignarath_walking.png",   "frames": 9},
        {"label": "Enter",      "path": "res://characters/bosses/ignarath/ignarath_enter.png",      "frames": 9},
        {"label": "Firebreath", "path": "res://characters/bosses/ignarath/ignarath_firebreath.png", "frames": 9},
        {"label": "Claw",       "path": "res://characters/bosses/ignarath/ignarath_claw.png",       "frames": 9},
        {"label": "TakingHit",  "path": "res://characters/bosses/ignarath/ignarath_takinghit.png",  "frames": 9},
    ]},
    {"name": "Luxar", "path": "res://characters/bosses/luxar.tscn", "group": "Bosses", "kind": "Bosses", "stage": ""},
    {"name": "Nullvex", "path": "res://characters/bosses/nullvex.tscn", "group": "Bosses", "kind": "Bosses", "stage": ""},
    {"name": "Terragor", "path": "res://characters/bosses/terragor.tscn", "group": "Bosses", "kind": "Bosses", "stage": ""},
    {"name": "Umbraex", "path": "res://characters/bosses/umbraex.tscn", "group": "Bosses", "kind": "Bosses", "stage": ""},
    {"name": "Voltrix", "path": "res://characters/bosses/voltrix.tscn", "group": "Bosses", "kind": "Bosses", "stage": ""},
    {"name": "Zael Bullet", "path": "res://characters/ranged/zael_bullet.tscn", "group": "Projeteis", "kind": "Projeteis", "stage": ""},
    {"name": "Boss Projectile", "path": "res://characters/bosses/boss_projectile.tscn", "group": "Projeteis", "kind": "Projeteis", "stage": ""},
    {"name": "Ice Projectile", "path": "res://characters/enemies/stage_02/enemy_ice_projectile.tscn", "group": "Projeteis", "kind": "Projeteis", "stage": "Stage 02"},
    {"name": "Fire Projectile", "path": "res://characters/enemies/stage_01/fire_projectile.tscn", "group": "Projeteis", "kind": "Projeteis", "stage": "Stage 01"},
    {"name": "Zara Hitbox", "path": "res://characters/melee/zara_hitbox.tscn", "group": "Projeteis", "kind": "Projeteis", "stage": ""},
]

const _BOSS_BATTLE: Array = [
    {"name": "Ignarath",    "path": "res://characters/bosses/ignarath.tscn"},
    {"name": "Cryovex",     "path": "res://characters/bosses/cryovex.tscn"},
    {"name": "Voltrix",     "path": "res://characters/bosses/voltrix.tscn"},
    {"name": "Gravitus",    "path": "res://characters/bosses/gravitus.tscn"},
    {"name": "Galerix",     "path": "res://characters/bosses/galerix.tscn"},
    {"name": "Umbraex",     "path": "res://characters/bosses/umbraex.tscn"},
    {"name": "Luxar",       "path": "res://characters/bosses/luxar.tscn"},
    {"name": "Terragor",    "path": "res://characters/bosses/terragor.tscn"},
    {"name": "IntroBoss",   "path": "res://characters/bosses/intro_boss.tscn"},
    {"name": "Nullvex",     "path": "res://characters/bosses/nullvex.tscn"},
    {"name": "Nullvex True","path": "res://characters/bosses/nullvex_true.tscn"},
]

const _TILESETS: Array = [
    # Stage 00 — intro
    {"name": "Stage_00T",       "path": "res://stages/stage_00/Stage_00T.png",       "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_00_glass",  "path": "res://stages/stage_00/stage_00_glass.png",  "cols": 4, "rows": 4, "tile_size": 32},
    # Stage 01 — Ignarath (fogo/vulcão)
    {"name": "Stage_01T_z1",    "path": "res://stages/stage_01/Stage_01T_z1.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_01T_z2",    "path": "res://stages/stage_01/Stage_01T_z2.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_01T_z3",    "path": "res://stages/stage_01/Stage_01T_z3.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_01T_z4",    "path": "res://stages/stage_01/Stage_01T_z4.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_01_glass",  "path": "res://stages/stage_01/stage_01_glass.png",  "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_01_lava",   "path": "res://stages/stage_01/Stage_01_lava.png",   "cols": 4, "rows": 4, "tile_size": 32},
    # Stage 02 — Cryovex (gelo)
    {"name": "Stage_02T_z1",    "path": "res://stages/stage_02/Stage_02T_z1.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_02T_z2",    "path": "res://stages/stage_02/Stage_02T_z2.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_02T_z3",    "path": "res://stages/stage_02/Stage_02T_z3.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_02T_z4",    "path": "res://stages/stage_02/Stage_02T_z4.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_02_glass",  "path": "res://stages/stage_02/stage_02_glass.png",  "cols": 4, "rows": 4, "tile_size": 32},
    # Stage 03 — Voltrix (raio)
    {"name": "Stage_03T_z1",    "path": "res://stages/stage_03/Stage_03T_z1.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_03T_z2",    "path": "res://stages/stage_03/Stage_03T_z2.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_03T_z3",    "path": "res://stages/stage_03/Stage_03T_z3.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_03T_z4",    "path": "res://stages/stage_03/Stage_03T_z4.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_03_glass",  "path": "res://stages/stage_03/stage_03_glass.png",  "cols": 4, "rows": 4, "tile_size": 32},
    # Stage 04 — Gravitus (gravidade)
    {"name": "Stage_04T_z1",    "path": "res://stages/stage_04/Stage_04T_z1.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_04T_z2",    "path": "res://stages/stage_04/Stage_04T_z2.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_04T_z3",    "path": "res://stages/stage_04/Stage_04T_z3.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_04T_z4",    "path": "res://stages/stage_04/Stage_04T_z4.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_04_glass",  "path": "res://stages/stage_04/stage_04_glass.png",  "cols": 4, "rows": 4, "tile_size": 32},
    # Stage 05 — Galerix (vento)
    {"name": "Stage_05T_z1",    "path": "res://stages/stage_05/Stage_05T_z1.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_05T_z2",    "path": "res://stages/stage_05/Stage_05T_z2.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_05T_z3",    "path": "res://stages/stage_05/Stage_05T_z3.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_05T_z4",    "path": "res://stages/stage_05/Stage_05T_z4.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_05_glass",  "path": "res://stages/stage_05/stage_05_glass.png",  "cols": 4, "rows": 4, "tile_size": 32},
    # Stage 06 — Umbraex (sombra)
    {"name": "Stage_06T_z1",    "path": "res://stages/stage_06/Stage_06T_z1.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_06T_z2",    "path": "res://stages/stage_06/Stage_06T_z2.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_06T_z3",    "path": "res://stages/stage_06/Stage_06T_z3.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_06T_z4",    "path": "res://stages/stage_06/Stage_06T_z4.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_06_glass",  "path": "res://stages/stage_06/stage_06_glass.png",  "cols": 4, "rows": 4, "tile_size": 32},
    # Stage 07 — Luxar (luz)
    {"name": "Stage_07T_z1",    "path": "res://stages/stage_07/Stage_07T_z1.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_07T_z2",    "path": "res://stages/stage_07/Stage_07T_z2.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_07T_z3",    "path": "res://stages/stage_07/Stage_07T_z3.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_07T_z4",    "path": "res://stages/stage_07/Stage_07T_z4.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_07_glass",  "path": "res://stages/stage_07/stage_07_glass.png",  "cols": 4, "rows": 4, "tile_size": 32},
    # Stage 08 — Terragor (terra)
    {"name": "Stage_08T_z1",    "path": "res://stages/stage_08/Stage_08T_z1.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_08T_z2",    "path": "res://stages/stage_08/Stage_08T_z2.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_08T_z3",    "path": "res://stages/stage_08/Stage_08T_z3.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_08T_z4",    "path": "res://stages/stage_08/Stage_08T_z4.png",    "cols": 4, "rows": 4, "tile_size": 32},
    {"name": "Stage_08_glass",  "path": "res://stages/stage_08/stage_08_glass.png",  "cols": 4, "rows": 4, "tile_size": 32},
]

# Descrições funcionais — mesma estrutura 4×4 para todos os zone tilesets.
# Prefixo do nome do tileset + ":col,row"
const _ZONE_TILE_DESCS: Dictionary = {
    "0,0": "Canto inferior esquerdo",
    "1,0": "Lateral direita da coluna lisa",
    "2,0": "L da coluna com chão do lado direito",
    "3,0": "Plataforma reta",
    "0,1": "Canto superior esquerdo com canto inferior direito",
    "1,1": "L da coluna com chão do lado esquerdo",
    "2,1": "Centro — miolo de preenchimento (100% opaco)",
    "3,1": "L da coluna com teto do lado direito",
    "0,2": "Canto superior direito",
    "1,2": "Teto reto",
    "2,2": "L da coluna com teto do lado esquerdo",
    "3,2": "Lateral esquerda da coluna lisa",
    "0,3": "Transparente — tile vazio (alpha = 0)",
    "1,3": "Canto inferior direito",
    "2,3": "Canto inferior esquerdo com canto superior direito",
    "3,3": "Canto superior esquerdo",
}

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

# Tile de preenchimento (2,1) lado a lado: Stage_00T vs Glass
class _FillTileView extends Control:
    var tile_tex:  Texture2D
    var glass_tex: Texture2D

    const _SRC  := 32.0
    const _TW   := 64.0
    const _COLS := 5
    const _ROWS := 3

    func _draw() -> void:
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.14))
        var src  := Rect2(2.0 * _SRC, 1.0 * _SRC, _SRC, _SRC)
        var font := ThemeDB.fallback_font
        var lc   := Color(0.85, 0.85, 0.6)
        var mg   := 20.0
        var gap  := 48.0
        var pw   := _COLS * _TW
        var ph   := _ROWS * _TW

        if tile_tex:
            for row in _ROWS:
                for col in _COLS:
                    draw_texture_rect_region(tile_tex,
                        Rect2(mg + col * _TW, mg + row * _TW, _TW, _TW), src)
        draw_string(font, Vector2(mg, mg + ph + 18.0),
            "Stage_00T  (2,1)", HORIZONTAL_ALIGNMENT_LEFT, pw, 15, lc)

        var x1 := mg + pw + gap
        if glass_tex:
            for row in _ROWS:
                for col in _COLS:
                    draw_texture_rect_region(glass_tex,
                        Rect2(x1 + col * _TW, mg + row * _TW, _TW, _TW), src)
        draw_string(font, Vector2(x1, mg + ph + 18.0),
            "Glass  (2,1)", HORIZONTAL_ALIGNMENT_LEFT, pw, 15, lc)

# Visualização de plataformas e salas: monta bloco N×M com _tile_at ou _room_at
class _PlatformView extends Control:
    var tile_tex: Texture2D
    var rows: int = 2
    var cols: int = 3
    var mode: String = "platform"   # "platform" | "room" | "floor_platform" | "floor_platform_hole" | "floor_hole" | "foothold" | "ceil_flat" | "ceil_step" | "ceil_hole" | "ceil_platform" | "ceil_plat_pit"
    var mirror_hole: bool = false    # floor_platform_hole: false = abismo à direita, true = à esquerda; ceil_step: false = degrau à direita, true = à esquerda

    const _TS := 32.0   # tamanho source
    const _TD := 48.0   # tamanho exibido
    const _EMPTY := Vector2i(0, 3)
    # Modo "floor_platform": piso reto + plataforma elevada (sem vão) + piso reto.
    # cols = largura da plataforma; rows = elevação dela acima do piso.
    const _FP_SIDE  := 3   # tiles de piso de cada lado da plataforma
    const _FP_DEPTH := 2   # tiles de piso abaixo da superfície
    # Modo "floor_hole": piso reto com um poço 2×2 cortado (mesmos tiles do jogo).
    const _FH_SIDE := 3    # tiles de piso de cada lado do poço
    const _FH_ROWS := 4    # profundidade do piso mostrada
    const _CG := 3         # gap de jogo entre face do teto e superfície do piso
    const _FD := 2         # profundidade do piso (linhas abaixo da superfície)
    const _BW := 1         # largura do buraco (vão sem teto) em cada lado — modo ceil_plat_pit

    func set_dims(r: int, c: int) -> void:
        rows = r
        cols = c
        var _is_fp := mode == "floor_platform" or mode == "floor_platform_hole" or mode == "foothold"
        var _is_ceil := mode == "ceil_flat" or mode == "ceil_step" or mode == "ceil_hole" or mode == "ceil_platform" or mode == "ceil_plat_pit"
        var gd: Vector2i
        if _is_fp:              gd = _fp_grid()
        elif mode == "floor_hole": gd = _fh_grid()
        elif _is_ceil:          gd = _ceil_combined_grid()
        else:                   gd = Vector2i(c, r)
        custom_minimum_size = Vector2(gd.x * _TD, gd.y * _TD)
        queue_redraw()

    func _draw() -> void:
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.14))
        if not tile_tex:
            return
        if mode == "foothold":
            _draw_foothold()
            return
        if mode == "floor_platform" or mode == "floor_platform_hole":
            _draw_floor_platform()
            return
        if mode == "floor_hole":
            _draw_floor_hole()
            return
        if mode == "ceil_flat" or mode == "ceil_step" or mode == "ceil_hole" or mode == "ceil_platform" or mode == "ceil_plat_pit":
            _draw_ceil_combined()
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

    # ── Modo piso+plataforma+piso ─────────────────────────────────────────────
    # Heightfield: colunas das laterais têm topo no nível do piso; colunas do meio
    # sobem `rows` tiles. Marching-squares por célula escolhe o tile pela máscara
    # de faces expostas (eixos em screen-space, row 0 = topo).

    # Direção do buraco no modo floor_platform_hole: +1 = direita vazia, -1 = esquerda vazia.
    # 0 nos demais modos → floor_platform clássico fica intocado.
    func _fp_hole_dir() -> int:
        if mode != "floor_platform_hole":
            return 0
        return -1 if mirror_hole else 1

    func _fp_grid() -> Vector2i:
        var ctot: int = _FP_SIDE + cols + _FP_SIDE
        var rtot: int = rows + _FP_DEPTH
        return Vector2i(ctot, rtot)

    # ── Modo "Buraco no Piso" ─────────────────────────────────────────────────
    # Piso reto com um poço 2×2 cortado no meio (mesmos tiles do corte real no jogo:
    # col esq topo (0,0)/baixo (2,0); col dir topo (1,3)/baixo (1,1); abaixo = aberto).
    func _fh_grid() -> Vector2i:
        return Vector2i(_FH_SIDE + 2 + _FH_SIDE, _FH_ROWS)

    func _draw_floor_hole() -> void:
        var g := _fh_grid()
        var pit_l := _FH_SIDE        # coluna esquerda do poço
        var pit_r := _FH_SIDE + 1    # coluna direita do poço
        for r in g.y:
            for c in g.x:
                var t: Vector2i
                if c == pit_l or c == pit_r:
                    if c == pit_l:
                        if   r == 0: t = Vector2i(0, 0)   # canto sup-dir
                        elif r == 1: t = Vector2i(2, 0)   # canto inner-TR
                        else:        t = Vector2i(3, 2)   # parede face dir
                    else:
                        if   r == 0: t = Vector2i(1, 3)   # canto sup-esq
                        elif r == 1: t = Vector2i(1, 1)   # canto inner-TL
                        else:        t = Vector2i(1, 0)   # parede face esq
                else:
                    t = Vector2i(3, 0) if r == 0 else Vector2i(2, 1)   # piso: topo (3,0), corpo (2,1)
                draw_texture_rect_region(tile_tex,
                    Rect2(c * _TD, r * _TD, _TD, _TD),
                    Rect2(t.x * _TS, t.y * _TS, _TS, _TS))

    func _fp_solid(c: int, r: int) -> bool:
        var g := _fp_grid()
        if c < 0 or r < 0 or c >= g.x or r >= g.y:
            return false
        var in_plat: bool = c >= _FP_SIDE and c < _FP_SIDE + cols
        if in_plat:
            return true              # plataforma: sólida do topo (row 0) até a base
        var hole := _fp_hole_dir()
        if hole > 0 and c >= _FP_SIDE + cols:
            return false             # buraco à direita: lado direito é abismo (vazio total)
        if hole < 0 and c < _FP_SIDE:
            return false             # buraco à esquerda: lado esquerdo é abismo
        return r >= rows             # piso lateral: sólido a partir da superfície

    func _fp_tile(c: int, r: int) -> Vector2i:
        return _fp_tile_for(c, r, func(cc, rr): return _fp_solid(cc, rr))

    func _fp_tile_for(c: int, r: int, solid: Callable) -> Vector2i:
        var eu: bool = not solid.call(c, r - 1)   # exposto em cima
        var ed: bool = not solid.call(c, r + 1)   # exposto embaixo
        var el: bool = not solid.call(c - 1, r)   # exposto à esquerda
        var er: bool = not solid.call(c + 1, r)   # exposto à direita
        # Cantos convexos (dois lados adjacentes expostos)
        if eu and el: return Vector2i(1, 3)   # canto sup-esq (sólido inf-dir)
        if eu and er: return Vector2i(0, 0)   # canto sup-dir (sólido inf-esq)
        if ed and el: return Vector2i(0, 2)   # canto inf-esq (sólido sup-dir)
        if ed and er: return Vector2i(3, 3)   # canto inf-dir (sólido sup-esq)
        # Faces (um lado exposto) — eixos invertidos do tileset: parede visual
        # esquerda usa (1,0) e direita usa (3,2) (mesma convenção de _tile_at).
        if eu: return Vector2i(3, 0)   # TOP
        if ed: return Vector2i(1, 2)   # BOTTOM
        if el: return Vector2i(1, 0)   # parede esquerda visual
        if er: return Vector2i(3, 2)   # parede direita visual
        # Cantos côncavos (degrau): diagonal superior vazia, ortogonais sólidas.
        # Espelhados pela mesma convenção (cf. _room_at): entalhe sup-esq → (1,1).
        if not (solid.call(c - 1, r - 1) as bool): return Vector2i(1, 1)   # entalhe sup-esq
        if not (solid.call(c + 1, r - 1) as bool): return Vector2i(2, 0)   # entalhe sup-dir
        return Vector2i(2, 1)   # FILL

    func _draw_floor_platform() -> void:
        var g := _fp_grid()
        for r in g.y:
            for c in g.x:
                if not _fp_solid(c, r):
                    continue
                var t := _fp_tile(c, r)
                draw_texture_rect_region(tile_tex,
                    Rect2(c * _TD, r * _TD, _TD, _TD),
                    Rect2(t.x * _TS, t.y * _TS, _TS, _TS))
        # Linha amarela na superfície que o player percorre. Com buraco, o caminho
        # para no penhasco do lado vazio (não desce nem segue como piso).
        var yellow := Color(1.0, 0.9, 0.0, 0.9)
        var floor_y := rows * _TD
        var plat_y  := 0.0
        var lx := _FP_SIDE * _TD
        var rx := (_FP_SIDE + cols) * _TD
        var w  := g.x * _TD
        var hole := _fp_hole_dir()
        if hole >= 0:
            draw_line(Vector2(0.0, floor_y), Vector2(lx, floor_y), yellow, 1.5)   # piso esq
            draw_line(Vector2(lx, floor_y), Vector2(lx, plat_y), yellow, 1.5)     # sobe (esq)
        draw_line(Vector2(lx, plat_y), Vector2(rx, plat_y), yellow, 1.5)          # topo plat
        if hole <= 0:
            draw_line(Vector2(rx, plat_y), Vector2(rx, floor_y), yellow, 1.5)     # desce (dir)
            draw_line(Vector2(rx, floor_y), Vector2(w, floor_y), yellow, 1.5)     # piso dir

    # Modo "Saliência": parede vertical de 1 tile + ressalto de `cols`×`rows` tiles
    # projetando pra dentro. Mostra as coords de tile do bump (cantos convexos + faces).
    func _draw_foothold() -> void:
        var g := _fp_grid()
        var wall_col := 0 if not mirror_hole else g.x - 1   # coluna da parede de fundo
        var bump_top := _FP_DEPTH                            # ressalto começa abaixo do topo da parede
        var _fsolid := func(c: int, r: int) -> bool:
            if c < 0 or r < 0 or c >= g.x or r >= g.y:
                return false
            if c == wall_col:
                return true                                  # parede de fundo (coluna cheia)
            # ressalto: `cols` colunas a partir da parede, `rows` linhas a partir de bump_top
            var near := (c >= 1 and c <= cols) if not mirror_hole else (c <= g.x - 2 and c >= g.x - 1 - cols)
            return near and r >= bump_top and r < bump_top + rows
        for r in g.y:
            for c in g.x:
                if not _fsolid.call(c, r):
                    continue
                var t := _fp_tile_for(c, r, _fsolid)
                draw_texture_rect_region(tile_tex,
                    Rect2(c * _TD, r * _TD, _TD, _TD),
                    Rect2(t.x * _TS, t.y * _TS, _TS, _TS))

    # ── Modos de teto (vista combinada: teto + zona de jogo + piso) ─────────
    # rows = espessura do teto no lado mais profundo (ou elevação do degrau/plataforma).
    # O tipo descreve o PISO abaixo; o teto acompanha mantendo gap _CG constante:
    #   Reto    → piso plano,  teto plano
    #   Escada  → piso com degrau, teto com degrau correspondente
    #   Buraco  → piso com abertura central, teto reto (sem gap no teto)
    #   Plat    → piso com plataforma elevada, teto elevado acima dela

    # Linha da face inferior do teto para cada coluna (-1 = sem teto/gap)
    func _ceil_face_at(c: int) -> int:
        match mode:
            "ceil_flat":
                return rows - 1
            "ceil_step":
                var is_deep := (c < _FP_SIDE + cols) if not mirror_hole else (c >= _FP_SIDE)
                return (rows - 1) if is_deep else 0
            "ceil_hole":
                return rows - 1   # teto sempre reto; só o piso tem buraco
            "ceil_platform":
                if c >= _FP_SIDE and c < _FP_SIDE + cols: return 0
                return rows - 1
            "ceil_plat_pit":
                # piso | escada | plataforma | escada(espelho) | piso
                # teto continuo: buraco so no PISO, teto baixo cobre piso+buraco
                if c >= _FP_SIDE + _BW and c < _FP_SIDE + _BW + cols: return 0   # plataforma: teto alto
                return rows - 1                                                    # piso+buraco: teto baixo
        return 0

    func _floor_top_at(c: int) -> int:
        var cf := _ceil_face_at(c)
        return -1 if cf < 0 else cf + _CG + 1

    func _ceil_combined_grid() -> Vector2i:
        var w := cols if mode == "ceil_flat" else \
                 (_FP_SIDE + _BW + cols + _BW + _FP_SIDE) if mode == "ceil_plat_pit" else \
                 (_FP_SIDE + cols + _FP_SIDE)
        var max_h := 0
        for cc in w:
            var ft := _floor_top_at(cc)
            if ft >= 0: max_h = maxi(max_h, ft + _FD)
        return Vector2i(w, max_h)

    func _ceil_solid_c(c: int, r: int) -> bool:
        if c < 0 or r < 0: return false
        var cf := _ceil_face_at(c)
        var gd := _ceil_combined_grid()
        if c >= gd.x or r >= gd.y: return false
        return cf >= 0 and r <= cf

    func _floor_solid_c(c: int, r: int) -> bool:
        if c < 0 or r < 0: return false
        if mode == "ceil_hole" and c >= _FP_SIDE and c < _FP_SIDE + cols:
            return false   # buraco no piso (teto continua reto acima)
        if mode == "ceil_plat_pit":
            var lb := _FP_SIDE; var rb := _FP_SIDE + _BW + cols
            if (c >= lb and c < lb + _BW) or (c >= rb and c < rb + _BW):
                return false   # buraco no piso de cada lado da plataforma
        var ft := _floor_top_at(c)
        var gd := _ceil_combined_grid()
        if c >= gd.x or r >= gd.y: return false
        return ft >= 0 and r >= ft

    # Marching-squares para teto: ignora face superior (fundo sempre sólido = 2,1).
    func _ceil_tile_for(c: int, r: int, solid: Callable) -> Vector2i:
        var ed: bool = not solid.call(c, r + 1)
        var el: bool = not solid.call(c - 1, r)
        var er: bool = not solid.call(c + 1, r)
        if ed and el: return Vector2i(0, 2)
        if ed and er: return Vector2i(3, 3)
        if ed:        return Vector2i(1, 2)
        if el:        return Vector2i(1, 0)
        if er:        return Vector2i(3, 2)
        if not (solid.call(c - 1, r + 1) as bool): return Vector2i(2, 2)
        if not (solid.call(c + 1, r + 1) as bool): return Vector2i(3, 1)
        return Vector2i(2, 1)

    func _draw_ceil_combined() -> void:
        var g := _ceil_combined_grid()
        var csol := func(cc: int, rr: int) -> bool: return _ceil_solid_c(cc, rr)
        var fsol := func(cc: int, rr: int) -> bool: return _floor_solid_c(cc, rr)
        for r in g.y:
            for c in g.x:
                if _ceil_solid_c(c, r):
                    var t := _ceil_tile_for(c, r, csol)
                    draw_texture_rect_region(tile_tex, Rect2(c * _TD, r * _TD, _TD, _TD),
                        Rect2(t.x * _TS, t.y * _TS, _TS, _TS))
                elif _floor_solid_c(c, r):
                    var t := _fp_tile_for(c, r, fsol)
                    draw_texture_rect_region(tile_tex, Rect2(c * _TD, r * _TD, _TD, _TD),
                        Rect2(t.x * _TS, t.y * _TS, _TS, _TS))
        _draw_ceil_guide(g)

    func _draw_ceil_guide(g: Vector2i) -> void:
        var yellow := Color(1.0, 0.9, 0.0, 0.9)
        for c in g.x:
            var cf := _ceil_face_at(c)
            var ft := _floor_top_at(c)
            var x0 := float(c) * _TD;  var x1 := float(c + 1) * _TD
            # Linha da face inferior do teto
            if cf >= 0:
                draw_line(Vector2(x0, (cf + 1) * _TD), Vector2(x1, (cf + 1) * _TD), yellow, 1.5)
                if c > 0:
                    var pcf := _ceil_face_at(c - 1)
                    if pcf >= 0 and pcf != cf:
                        draw_line(Vector2(x0, (pcf + 1) * _TD), Vector2(x0, (cf + 1) * _TD), yellow, 1.5)
            # Linha da superfície do piso
            if ft >= 0:
                draw_line(Vector2(x0, float(ft) * _TD), Vector2(x1, float(ft) * _TD), yellow, 1.5)
                if c > 0:
                    var pft := _floor_top_at(c - 1)
                    if pft >= 0 and pft != ft:
                        draw_line(Vector2(x0, float(minf(ft, pft)) * _TD),
                                  Vector2(x0, float(maxf(ft, pft)) * _TD), yellow, 1.5)

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
            draw_line(Vector2(glass_wall_l - 32.0, -8000.0), Vector2(glass_wall_l - 32.0, ground_y), Color(0.5, 0.9, 1.0, 0.9), 2.0)
            draw_line(Vector2(glass_wall_r + 32.0, -8000.0), Vector2(glass_wall_r + 32.0, ground_y), Color(0.5, 0.9, 1.0, 0.9), 2.0)
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

# Mundo do teste de teto de fill: chão + paredes + painel de glass como teto
class _FillCeilWorld extends Node2D:
    const _TS        := 32.0
    const _TW        := 64.0
    const _FILL_COLS := 14
    const _GROUND_Y  := 60.0
    const _CEIL_Y    := -68.0     # _GROUND_Y - 128.0 — face inferior do glass
    const _LAT_X     := 60.0     # left edge do tile lateral
    const _FILL_X    := 124.0    # _LAT_X + _TW
    const _WALL_L    := -4.0     # _LAT_X - _TW
    const _WALL_R    := 1020.0   # _FILL_X + _FILL_COLS * _TW

    var tile_tex:   Texture2D
    var glass_tex:  Texture2D
    var fixed_mode: bool = false
    var player_ref: CharacterBase = null

    func _draw() -> void:
        draw_rect(Rect2(-5000.0, -5000.0, 15000.0, 15000.0), Color(0.07, 0.08, 0.16))
        if not tile_tex or not glass_tex:
            return
        var src_top  := Rect2(3.0 * _TS, 0.0,          _TS, _TS)
        var src_fill := Rect2(2.0 * _TS, 1.0 * _TS,    _TS, _TS)
        var src_lat  := Rect2(1.0 * _TS, 0.0,          _TS, _TS)
        var src_left := Rect2(3.0 * _TS, 2.0 * _TS,    _TS, _TS)
        var src_rght := Rect2(1.0 * _TS, 0.0,          _TS, _TS)
        # Chão
        var floor_ty := _GROUND_Y - _TW * 0.5
        var tx := _WALL_L
        while tx < _WALL_R + _TW * 2.0:
            draw_texture_rect_region(tile_tex, Rect2(tx, floor_ty, _TW, _TW), src_top)
            tx += _TW
        # Paredes laterais
        for i: int in 5:
            var ty := floor_ty - float(i + 1) * _TW
            draw_texture_rect_region(tile_tex, Rect2(_WALL_L - _TW, ty, _TW, _TW), src_left)
            draw_texture_rect_region(tile_tex, Rect2(_WALL_R, ty, _TW, _TW), src_rght)
        # Teto de glass (4 fileiras visuais acima de _CEIL_Y)
        for row: int in 4:
            var dy := _CEIL_Y - float(row + 1) * _TW
            draw_texture_rect_region(glass_tex, Rect2(_LAT_X, dy, _TW, _TW), src_lat)
            for col: int in _FILL_COLS:
                draw_texture_rect_region(glass_tex, Rect2(_FILL_X + col * _TW, dy, _TW, _TW), src_fill)
        # Linhas de colisão
        var yel := Color(1.0, 0.9, 0.0, 0.85)
        var cyn := Color(0.5, 0.9, 1.0, 0.9)
        var grn := Color(0.3, 1.0, 0.5, 0.9)
        var red := Color(1.0, 0.3, 0.3, 0.6)
        draw_line(Vector2(-5000.0, _GROUND_Y), Vector2(5000.0, _GROUND_Y), yel, 2.0)
        draw_line(Vector2(_WALL_L - 32.0, -5000.0), Vector2(_WALL_L - 32.0, _GROUND_Y), yel, 2.0)
        draw_line(Vector2(_WALL_R + 32.0, -5000.0), Vector2(_WALL_R + 32.0, _GROUND_Y), yel, 2.0)
        # Body1 — cyan (lateral + 1º fill, 2 tiles)
        draw_line(Vector2(_LAT_X, _CEIL_Y), Vector2(_LAT_X + _TW * 2.0, _CEIL_Y), cyn, 3.0)
        if fixed_mode:
            # Body2 — verde (todos os fills)
            draw_line(Vector2(_FILL_X, _CEIL_Y), Vector2(_FILL_X + _FILL_COLS * _TW, _CEIL_Y), grn, 3.0)
        else:
            # Gap sem colisão — vermelho tracejado
            var gx := _LAT_X + _TW * 2.0
            var gw := (_FILL_COLS - 1) * _TW
            var sw := gw / 7.0
            for i: int in 7:
                draw_line(Vector2(gx + i * sw, _CEIL_Y), Vector2(gx + i * sw + sw - 6.0, _CEIL_Y), red, 2.5)
        # Hitbox do player
        if is_instance_valid(player_ref):
            var cs := player_ref.get_node_or_null("CollisionShape2D") as CollisionShape2D
            if cs and cs.shape is CapsuleShape2D:
                var cap := cs.shape as CapsuleShape2D
                var r   := cap.radius
                var hs  := (cap.height - 2.0 * r) * 0.5
                var pos := player_ref.global_position + cs.position
                var hcol := Color(0.2, 1.0, 0.2, 0.9)
                draw_arc(pos + Vector2(0.0, -hs), r, PI, TAU, 24, hcol, 2.0)
                draw_arc(pos + Vector2(0.0,  hs), r, 0.0, PI, 24, hcol, 2.0)
                draw_line(pos + Vector2(-r, -hs), pos + Vector2(-r, hs), hcol, 2.0)
                draw_line(pos + Vector2( r, -hs), pos + Vector2( r, hs), hcol, 2.0)

class _HitboxOverlay extends Node2D:
    const _TILE_SRC := 32.0
    const _TILE_DRAW := 64.0
    # Texturas reais dos projéteis que têm sprite (fogo). Desenhadas no preview
    # no tamanho de jogo (frame único da sheet 2x2, escala 0.35 = igual ao fire_projectile.tscn).
    const _PROJ_TEX := {
        "fire_bolt": preload("res://characters/enemies/stage_01/fire_bolt.png"),
        "fire_glob": preload("res://characters/enemies/stage_01/fire_glob.png"),
        "fire_spit": preload("res://characters/enemies/stage_01/fire_spit.png"),
        "heat_mortar_shell": preload("res://characters/enemies/stage_01/heat_mortar_shell.png"),
        "fire_beam_body":   preload("res://characters/bosses/ignarath/fire_beam_body.png"),
        "fire_beam_origin": preload("res://characters/bosses/ignarath/fire_beam_origin.png"),
        "fire_beam_end":    preload("res://characters/bosses/ignarath/fire_beam_end.png"),
    }
    const _PROJ_TEX_SCALE := 0.35

    var floor_tex: Texture2D = null
    var floor_body_rows: int = 1
    var ground_y: float = 300.0
    var shape_infos: Array = []
    var projectile_preview: Dictionary = {}
    var show_labels: bool = true
    var show_floor: bool = true
    var show_hitboxes: bool = true
    var show_ruler: bool = false
    var ruler_origin: Vector2 = Vector2.ZERO
    # Editor por mouse
    var edit_shapes: Array = []
    var sel_shape: int = -1
    var edit_proj: Dictionary = {}
    var editing: bool = false
    var sprite_handle: Vector2 = Vector2.INF

    func _draw() -> void:
        if show_floor:
            _draw_floor()
        if show_ruler:
            _draw_ruler()
        if not show_hitboxes:
            return
        draw_line(Vector2(0.0, ground_y), Vector2(900.0, ground_y), Color(1.0, 0.9, 0.0, 0.9), 2.0)
        for info: Dictionary in shape_infos:
            var cs := info.node as CollisionShape2D
            if cs == null or cs.shape == null:
                continue
            var color := _shape_color(String(info.path))
            _draw_shape(cs, color)
            if show_labels:
                draw_string(ThemeDB.fallback_font, cs.global_position + Vector2(8.0, -8.0), String(info.path), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13.0, color)
        _draw_projectile_preview()
        _draw_edit_handles()

    func _draw_edit_handles() -> void:
        if not editing:
            return
        if sel_shape >= 0 and sel_shape < edit_shapes.size():
            var s: Dictionary = edit_shapes[sel_shape]
            var c := ruler_origin + Vector2(float(s["pos"][0]), float(s["pos"][1]))
            var half := Vector2(float(s["size"][0]), float(s["size"][1])) * 0.5
            draw_rect(Rect2(c - half, half * 2.0), Color(1.0, 1.0, 0.0, 0.9), false, 2.0)
            var hs := 5.0
            for hxi in 3:
                for hyi in 3:
                    var hx: float = float(hxi) - 1.0
                    var hy: float = float(hyi) - 1.0
                    if hx == 0.0 and hy == 0.0:
                        continue
                    var hp := c + Vector2(half.x * hx, half.y * hy)
                    draw_rect(Rect2(hp - Vector2(hs, hs), Vector2(hs * 2.0, hs * 2.0)), Color(1.0, 1.0, 0.0, 0.95))
        if edit_proj.has("offset"):
            var po: Array = edit_proj["offset"] as Array
            var pp := ruler_origin + Vector2(float(po[0]), float(po[1]))
            draw_circle(pp, 6.0, Color(0.2, 1.0, 0.4, 0.9))
        if sprite_handle != Vector2.INF:
            draw_rect(Rect2(sprite_handle - Vector2(6, 6), Vector2(12, 12)), Color(0.3, 0.85, 1.0, 0.95))

    # Régua de pixels centrada na origem da entidade: ticks a cada 10px, marcas
    # maiores + rótulo a cada 50px. Os números são em GAME-PX (= o valor que vai
    # direto nos offsets do código, 1:1). Ler sempre pelo NÚMERO impresso, nunca
    # contando pixels na tela (a câmera amplia 2x — é só zoom visual).
    func _draw_ruler() -> void:
        var o := ruler_origin
        var ext := 420.0
        var font := ThemeDB.fallback_font
        var axis_col := Color(0.5, 0.9, 1.0, 0.7)
        var minor_col := Color(1.0, 1.0, 1.0, 0.22)
        var major_col := Color(1.0, 1.0, 1.0, 0.7)
        draw_line(o + Vector2(-ext, 0.0), o + Vector2(ext, 0.0), axis_col, 1.0)
        draw_line(o + Vector2(0.0, -ext), o + Vector2(0.0, ext), axis_col, 1.0)
        var d := -int(ext)
        while d <= int(ext):
            var major := (d % 50 == 0)
            var tick: float = 12.0 if major else 5.0
            var col := major_col if major else minor_col
            draw_line(o + Vector2(d, -tick), o + Vector2(d, tick), col, 1.0)   # marca no eixo X
            draw_line(o + Vector2(-tick, d), o + Vector2(tick, d), col, 1.0)   # marca no eixo Y
            if major and d != 0:
                _draw_ruler_label(font, str(d), o + Vector2(d + 2.0, -tick - 11.0))   # rótulo eixo X (acima)
                _draw_ruler_label(font, str(d), o + Vector2(tick + 4.0, d - 1.0))     # rótulo eixo Y (à dir)
            d += 10
        _draw_ruler_label(font, "0 (game-px)", o + Vector2(6.0, -6.0))

    # Rótulo com fundo escuro p/ legibilidade sobre o sprite. Fonte 9px (mundo).
    func _draw_ruler_label(font: Font, txt: String, at: Vector2) -> void:
        var fs := 9
        var size := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs)
        draw_rect(Rect2(at + Vector2(-1.0, -size.y), size + Vector2(2.0, 3.0)), Color(0.0, 0.0, 0.0, 0.6), true)
        draw_string(font, at, txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, Color(1.0, 1.0, 1.0, 0.95))

    func _shape_color(path: String) -> Color:
        if path.contains("ContactZone"):
            return Color(0.2, 0.9, 1.0, 0.95)
        if path.contains("BodyHurtbox") or path.contains("Head"):
            return Color(1.0, 0.45, 0.95, 0.95)
        if path.contains("PunchZone"):
            return Color(1.0, 0.55, 0.2, 0.95)
        return Color(1.0, 0.9, 0.0, 0.95)

    func _draw_shape(cs: CollisionShape2D, color: Color) -> void:
        var shape := cs.shape
        var pos := cs.global_position
        var fill := Color(color.r, color.g, color.b, 0.16)
        if shape is RectangleShape2D:
            var size := (shape as RectangleShape2D).size
            var rect := Rect2(pos - size * 0.5, size)
            draw_rect(rect, fill, true)
            draw_rect(rect, color, false, 2.0)
        elif shape is CircleShape2D:
            var radius := (shape as CircleShape2D).radius
            draw_circle(pos, radius, fill)
            draw_arc(pos, radius, 0.0, TAU, 48, color, 2.0)
        elif shape is CapsuleShape2D:
            var cap := shape as CapsuleShape2D
            var r := cap.radius
            var half_segment := maxf(0.0, (cap.height - 2.0 * r) * 0.5)
            draw_rect(Rect2(pos + Vector2(-r, -half_segment), Vector2(r * 2.0, half_segment * 2.0)), fill, true)
            draw_circle(pos + Vector2(0.0, -half_segment), r, fill)
            draw_circle(pos + Vector2(0.0, half_segment), r, fill)
            draw_arc(pos + Vector2(0.0, -half_segment), r, PI, TAU, 32, color, 2.0)
            draw_arc(pos + Vector2(0.0, half_segment), r, 0.0, PI, 32, color, 2.0)
            draw_line(pos + Vector2(-r, -half_segment), pos + Vector2(-r, half_segment), color, 2.0)
            draw_line(pos + Vector2(r, -half_segment), pos + Vector2(r, half_segment), color, 2.0)
        else:
            draw_circle(pos, 6.0, color)

    func _draw_projectile_preview() -> void:
        if projectile_preview.is_empty() or not bool(projectile_preview.get("visible", false)):
            return
        var pos := projectile_preview.get("position", Vector2.ZERO) as Vector2
        var variant := String(projectile_preview.get("variant", "ice_ball"))
        var parabolic := bool(projectile_preview.get("parabolic", false))
        var color := Color(1.0, 0.48, 0.12, 0.95)
        var traj_angle := 0.0
        # Trajetória reta diagonal até o chão à frente (projétil que mira no player no solo).
        if String(projectile_preview.get("trajectory", "")) == "floor":
            var target := Vector2(pos.x + 240.0, ground_y)
            traj_angle = (target - pos).angle()
            draw_line(pos, target, Color(1.0, 0.6, 0.2, 0.85), 2.0)
            draw_circle(target, 5.0, Color(1.0, 0.6, 0.2, 0.6))
        if parabolic:
            traj_angle = Vector2(52.0, -60.0).angle()   # tangente inicial do arco
            var points := PackedVector2Array([
                pos,
                pos + Vector2(52.0, -60.0),
                pos + Vector2(112.0, -72.0),
                pos + Vector2(176.0, 10.0),
            ])
            for i in range(points.size() - 1):
                draw_line(points[i], points[i + 1], Color(1.0, 0.48, 0.12, 0.72), 2.0)
            draw_circle(pos + Vector2(52.0, -60.0), 4.0, Color(1.0, 0.72, 0.32, 0.75))
            draw_circle(pos + Vector2(112.0, -72.0), 4.0, Color(1.0, 0.72, 0.32, 0.55))
        match variant:
            "ice_arrow":
                draw_polygon(
                    PackedVector2Array([pos + Vector2(17, 0), pos + Vector2(3, -6), pos + Vector2(-17, -4), pos + Vector2(-10, 0), pos + Vector2(-17, 4), pos + Vector2(3, 6)]),
                    PackedColorArray([Color(0.65, 1.0, 1.0), Color(0.35, 0.78, 1.0), Color(0.18, 0.45, 0.9), Color(0.5, 0.9, 1.0), Color(0.18, 0.45, 0.9), Color(0.35, 0.78, 1.0)])
                )
                draw_rect(Rect2(pos - Vector2(17.0, 5.0), Vector2(34.0, 10.0)), Color(1.0, 0.48, 0.12, 0.18), true)
                draw_rect(Rect2(pos - Vector2(17.0, 5.0), Vector2(34.0, 10.0)), color, false, 2.0)
            "ice_cannonball":
                draw_circle(pos, 12.0, Color(0.35, 0.82, 1.0, 0.35))
                draw_arc(pos, 12.0, 0.0, TAU, 32, color, 2.0)
            "eye_beam":
                draw_rect(Rect2(pos + Vector2(-4.0, -6.0), Vector2(42.0, 12.0)), Color(0.38, 0.95, 1.0, 0.35), true)
                draw_rect(Rect2(pos + Vector2(-4.0, -6.0), Vector2(42.0, 12.0)), color, false, 2.0)
            "fire_bolt", "fire_glob", "fire_spit", "heat_mortar_shell":
                _draw_proj_sprite(variant, pos, traj_angle)
            "fire_beam":
                # Beam a 45° (facing=-1 → baixo-esquerda) usando os sprites reais.
                var _depth := maxf(8.0, ground_y - pos.y)
                var _beam_end := Vector2(pos.x - _depth, ground_y)
                var _beam_len := _depth * sqrt(2.0)
                var _beam_angle := Vector2(-1.0, 1.0).angle()
                var _beam_w := 40.0   # largura do beam em px de jogo (half_width*2)
                # Corpo tileado ao longo do beam.
                var _btex: Texture2D = _PROJ_TEX.get("fire_beam_body")
                if _btex != null:
                    var _bfw := float(_btex.get_width()) * 0.5
                    var _bfh := float(_btex.get_height()) * 0.5
                    var _bsc := _beam_w / _bfh
                    var _tile_w := _bfw * _bsc
                    var _bdir := Vector2(-1.0, 1.0).normalized()
                    var _n := maxi(1, int(ceil(_beam_len / _tile_w)))
                    for _i in range(_n):
                        var _tp := pos + _bdir * (_tile_w * (float(_i) + 0.5))
                        draw_set_transform(_tp, _beam_angle, Vector2(_bsc, _bsc))
                        draw_texture_rect_region(_btex, Rect2(-_bfw * 0.5, -_bfh * 0.5, _bfw, _bfh), Rect2(0.0, 0.0, _bfw, _bfh))
                    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
                # Origem (swirl na boca).
                var _otex: Texture2D = _PROJ_TEX.get("fire_beam_origin")
                if _otex != null:
                    var _ofw := float(_otex.get_width()) * 0.5
                    var _ofh := float(_otex.get_height()) * 0.5
                    var _osc := _beam_w / _ofh
                    draw_set_transform(pos, _beam_angle, Vector2(_osc, _osc))
                    draw_texture_rect_region(_otex, Rect2(-_ofw * 0.5, -_ofh * 0.5, _ofw, _ofh), Rect2(0.0, 0.0, _ofw, _ofh))
                    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
                # Impacto no chão.
                var _etex: Texture2D = _PROJ_TEX.get("fire_beam_end")
                if _etex != null:
                    var _efw := float(_etex.get_width()) * 0.5
                    var _efh := float(_etex.get_height()) * 0.5
                    var _esc := (_beam_w * 1.3) / _efh
                    draw_set_transform(_beam_end, _beam_angle, Vector2(_esc, _esc))
                    draw_texture_rect_region(_etex, Rect2(-_efw * 0.5, -_efh * 0.5, _efw, _efh), Rect2(0.0, 0.0, _efw, _efh))
                    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
                # Fallback se texturas não carregaram.
                if _btex == null:
                    draw_line(pos, _beam_end, Color(1.0, 0.9, 0.3, 0.9), 10.0)
                    draw_line(pos, _beam_end, Color(1.0, 0.35, 0.05, 0.45), 36.0)
                    draw_circle(pos, 10.0, Color(1.0, 0.55, 0.1, 0.9))
                    draw_circle(_beam_end, 18.0, Color(1.0, 0.45, 0.05, 0.35))
            _:
                draw_circle(pos, 9.0, Color(0.55, 0.92, 1.0, 0.35))
                draw_arc(pos, 9.0, 0.0, TAU, 32, color, 2.0)

    # Desenha o sprite real do projétil (1º frame da sheet 2x2) centrado no ponto de
    # spawn, no tamanho de jogo, + um marcador do ponto exato.
    func _draw_proj_sprite(variant: String, pos: Vector2, angle: float = 0.0) -> void:
        var tex: Texture2D = _PROJ_TEX.get(variant)
        if tex == null:
            return
        var fw := tex.get_width() * 0.5
        var fh := tex.get_height() * 0.5
        var sz := Vector2(fw, fh) * _PROJ_TEX_SCALE
        # Rotaciona o sprite p/ o ângulo da trajetória (igual ao jogo: rotation = velocity.angle()).
        draw_set_transform(pos, angle, Vector2.ONE)
        draw_texture_rect_region(tex, Rect2(-sz * 0.5, sz), Rect2(0.0, 0.0, fw, fh))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        draw_circle(pos, 3.0, Color(1.0, 1.0, 1.0, 0.9))

    func _draw_floor() -> void:
        if floor_tex == null:
            draw_rect(Rect2(0.0, ground_y, 900.0, 160.0), Color(0.16, 0.2, 0.24))
            return
        var top_src := Rect2(3.0 * _TILE_SRC, 0.0, _TILE_SRC, _TILE_SRC)
        var fill_src := Rect2(2.0 * _TILE_SRC, 1.0 * _TILE_SRC, _TILE_SRC, _TILE_SRC)
        var x := -_TILE_DRAW
        while x < 900.0 + _TILE_DRAW:
            draw_texture_rect_region(floor_tex, Rect2(x, ground_y - _TILE_DRAW * 0.5, _TILE_DRAW, _TILE_DRAW), top_src)
            for row in range(floor_body_rows):
                draw_texture_rect_region(floor_tex, Rect2(x, ground_y + _TILE_DRAW * (0.5 + float(row)), _TILE_DRAW, _TILE_DRAW), fill_src)
            x += _TILE_DRAW

class _HitboxView extends Control:
    const _VIEW_SIZE := Vector2(1100.0, 640.0)
    const _ENTITY_POS := Vector2(450.0, 300.0)
    const _CAMERA_ZOOM := Vector2(2.0, 2.0)
    const _CAMERA_OFFSET_Y := -76.0   # 24 - 100: câmera sobe 100px (mais espaço acima da entidade)
    const _FLY_HEIGHT := 140.0        # altura do pulo: voadores flutuam isto acima do chão no preview
    const _PROJECTILE_DEFS := {
        "Ice Archer": {"label": "Ice Arrow", "variant": "ice_arrow", "release_frame": 4, "offset": Vector2(52.0, -82.0), "parabolic": false},
        "Frost Turret": {"label": "Ice Cannonball", "variant": "ice_cannonball", "release_frame": 3, "offset": Vector2(32.0, 0.0), "parabolic": false},
        "Cryo Bomber": {"label": "Ice Ball", "variant": "ice_ball", "release_frame": 3, "offset": Vector2(16.0, -56.0), "parabolic": true},
        "Glacier Shield": {"label": "Eye Beam", "variant": "eye_beam", "release_frame": 2, "offset": Vector2(34.0, -18.0), "parabolic": false},
        # Stage 01 — offsets espelham o _fire() de cada inimigo (turret usa face_dir=-1 → muzzle à esquerda).
        "Ember Orbiter": {"label": "Fire Bolt", "variant": "fire_bolt", "release_frame": 2, "offset": Vector2(0.0, 0.0), "parabolic": false},
        "Cinder Flyer": {"label": "Fire Bolt", "variant": "fire_bolt", "release_frame": 1, "offset": Vector2(10.0, 40.0), "parabolic": false, "trajectory": "floor"},
        "Heat Mortar": {"label": "Heat Mortar Shell", "variant": "heat_mortar_shell", "release_frame": 4, "offset": Vector2(17.0, -40.0), "parabolic": true},
        "Magma Turret": {"label": "Fire Glob", "variant": "fire_glob", "release_frame": 2, "offset": Vector2(-38.0, -5.0), "parabolic": false},
        "Lava Serpent": {"label": "Fire Spit", "variant": "fire_spit", "release_frame": 9, "offset": Vector2(50.0, -20.0), "parabolic": false},
        # Bosses
        "Ignarath": {"label": "Firebreath (boca)", "variant": "fire_beam", "release_frame": 4, "offset": Vector2(-50.8, -32.0), "parabolic": false},
    }

    var _current_index: int = 0
    var _current_instance: Node2D = null
    var _shape_infos: Array = []
    var _filter_group: String = "Todos"
    var _selected_stage: String = "Todos"
    var _selected_frame: int = 0
    var _frame_count: int = 1
    var _show_sprite: bool = true
    var _show_labels: bool = true
    var _viewport: SubViewport = null
    var _scene_root: Node2D = null
    var _camera: Camera2D = null
    var _world_root: Node2D = null
    var _overlay: _HitboxOverlay = null
    var _floor_overlay: _HitboxOverlay = null
    var _shape_overlay: _HitboxOverlay = null
    var _name_label: Label = null
    var _meta_label: Label = null
    var _sprite_btn: Button = null
    var _labels_btn: Button = null
    var _ruler_btn: Button = null
    var _show_ruler: bool = false
    var _type_opt: OptionButton = null
    var _stage_opt: OptionButton = null
    var _entity_opt: OptionButton = null
    var _anim_row: HBoxContainer = null
    var _anim_opt: OptionButton = null
    var _frame_row: HBoxContainer = null
    var _frame_lbl: Label = null
    var _projectile_row: HBoxContainer = null
    var _projectile_label: Label = null
    var _current_projectile_info: Dictionary = {}
    # ── Editor por mouse ──────────────────────────────────────────────────────
    var _viewport_container: SubViewportContainer = null
    var _edit: Dictionary = {}
    var _edit_id: String = ""
    var _sel_shape: int = -1
    var _edit_target: String = "body"
    var _edit_this_frame: bool = false
    var _drag_mode: String = ""          # "", move_shape, resize_<e>, move_sprite, scale_sprite, move_proj
    var _drag_last_world: Vector2 = Vector2.ZERO
    var _edit_toolbar: HBoxContainer = null
    var _edit_toggle_btn: Button = null
    var _frame_scope_btn: Button = null
    var _target_opt: OptionButton = null

    func _ready() -> void:
        _build()
        _select_index(0)

    func _build() -> void:
        var root := VBoxContainer.new()
        root.add_theme_constant_override("separation", 8)
        root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        root.size_flags_vertical = Control.SIZE_EXPAND_FILL
        add_child(root)

        var sel_row := HBoxContainer.new()
        sel_row.add_theme_constant_override("separation", 10)
        root.add_child(sel_row)

        _type_opt = OptionButton.new()
        _type_opt.add_theme_font_size_override("font_size", 26)
        _type_opt.get_popup().add_theme_font_size_override("font_size", 26)
        for g in ["Todos", "Personagens", "Inimigos", "Bosses", "Projeteis"]:
            _type_opt.add_item(g)
        _type_opt.item_selected.connect(func(i): _set_filter(_type_opt.get_item_text(i)))
        sel_row.add_child(_make_label("Tipo:"))
        sel_row.add_child(_type_opt)

        _stage_opt = OptionButton.new()
        _stage_opt.add_theme_font_size_override("font_size", 26)
        _stage_opt.get_popup().add_theme_font_size_override("font_size", 26)
        _stage_opt.item_selected.connect(func(i): _set_stage(_stage_opt.get_item_text(i)))
        sel_row.add_child(_make_label("Stage:"))
        sel_row.add_child(_stage_opt)

        _entity_opt = OptionButton.new()
        _entity_opt.add_theme_font_size_override("font_size", 26)
        _entity_opt.get_popup().add_theme_font_size_override("font_size", 26)
        _entity_opt.item_selected.connect(func(_i): _select_index(int(_entity_opt.get_selected_metadata())))
        sel_row.add_child(_make_label("Entidade:"))
        sel_row.add_child(_entity_opt)

        _anim_row = HBoxContainer.new()
        _anim_row.add_theme_constant_override("separation", 10)
        _anim_row.visible = false
        root.add_child(_anim_row)
        _anim_row.add_child(_make_label("Anim:"))
        _anim_opt = OptionButton.new()
        _anim_opt.add_theme_font_size_override("font_size", 26)
        _anim_opt.get_popup().add_theme_font_size_override("font_size", 26)
        _anim_opt.item_selected.connect(func(i): _apply_anim_opt(i))
        _anim_row.add_child(_anim_opt)

        _frame_row = HBoxContainer.new()
        _frame_row.add_theme_constant_override("separation", 6)
        root.add_child(_frame_row)

        _projectile_row = HBoxContainer.new()
        _projectile_row.add_theme_constant_override("separation", 6)
        root.add_child(_projectile_row)

        var toolbar := HBoxContainer.new()
        toolbar.add_theme_constant_override("separation", 6)
        root.add_child(toolbar)
        _sprite_btn = _make_button("Sprite ON", _toggle_sprite)
        toolbar.add_child(_sprite_btn)
        _labels_btn = _make_button("Labels ON", _toggle_labels)
        toolbar.add_child(_labels_btn)
        _ruler_btn = _make_button("Regua OFF", _toggle_ruler)
        toolbar.add_child(_ruler_btn)
        # Nome da entidade compacto na toolbar (o painel de descrição foi removido p/
        # dar toda a largura ao viewport de hitbox).
        _name_label = Label.new()
        _name_label.add_theme_font_size_override("font_size", 24)
        _name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
        _name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        _name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        toolbar.add_child(_name_label)

        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 16)
        row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.size_flags_vertical = Control.SIZE_EXPAND_FILL
        root.add_child(row)

        _viewport_container = SubViewportContainer.new()
        var viewport_container := _viewport_container
        viewport_container.custom_minimum_size = _VIEW_SIZE
        viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
        row.add_child(viewport_container)

        _viewport = SubViewport.new()
        _viewport.size = Vector2i(int(_VIEW_SIZE.x), int(_VIEW_SIZE.y))
        _viewport.transparent_bg = false
        _viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
        viewport_container.add_child(_viewport)

        var bg := ColorRect.new()
        bg.color = Color(0.06, 0.07, 0.14)
        bg.size = _VIEW_SIZE
        _viewport.add_child(bg)
        _scene_root = Node2D.new()
        _viewport.add_child(_scene_root)
        _camera = Camera2D.new()
        _camera.position = _ENTITY_POS + Vector2(0.0, _CAMERA_OFFSET_Y)
        _camera.zoom = _CAMERA_ZOOM
        _camera.position_smoothing_enabled = false
        _camera.process_callback = Camera2D.CAMERA2D_PROCESS_IDLE
        _scene_root.add_child(_camera)
        _camera.call_deferred("make_current")
        _floor_overlay = _HitboxOverlay.new()
        _floor_overlay.floor_tex = load("res://stages/stage_00/Stage_00T.png") as Texture2D
        _floor_overlay.ground_y = _ENTITY_POS.y
        _floor_overlay.show_hitboxes = false
        _floor_overlay.z_index = 0
        _scene_root.add_child(_floor_overlay)
        _world_root = Node2D.new()
        _world_root.z_index = 1
        _scene_root.add_child(_world_root)
        _shape_overlay = _HitboxOverlay.new()
        _shape_overlay.ground_y = _ENTITY_POS.y
        _shape_overlay.show_floor = false
        _shape_overlay.ruler_origin = _ENTITY_POS
        _shape_overlay.show_ruler = _show_ruler
        _shape_overlay.z_index = 2
        _scene_root.add_child(_shape_overlay)
        _overlay = _floor_overlay

        # ── Toolbar do editor por mouse ──────────────────────────────────────
        _edit_toolbar = HBoxContainer.new()
        _edit_toolbar.add_theme_constant_override("separation", 6)
        root.add_child(_edit_toolbar)

        _edit_toggle_btn = _make_button("Editar OFF", _on_toggle_edit)
        _edit_toolbar.add_child(_edit_toggle_btn)

        var add_btn := _make_button("+ Hitbox", _on_add_shape)
        _edit_toolbar.add_child(add_btn)

        var del_btn := _make_button("Deletar", _on_delete_shape)
        _edit_toolbar.add_child(del_btn)

        var tgt_lbl := _make_label("Alvo:")
        _edit_toolbar.add_child(tgt_lbl)

        _target_opt = OptionButton.new()
        _target_opt.add_item("body")
        _target_opt.add_item("contact")
        _target_opt.add_theme_font_size_override("font_size", 26)
        _target_opt.get_popup().add_theme_font_size_override("font_size", 26)
        _target_opt.item_selected.connect(func(i): _edit_target = _target_opt.get_item_text(i))
        _edit_toolbar.add_child(_target_opt)

        _frame_scope_btn = _make_button("Frame: Todos", _on_toggle_frame_scope)
        _edit_toolbar.add_child(_frame_scope_btn)

        var save_btn := _make_button("Salvar", _on_save)
        _edit_toolbar.add_child(save_btn)

        # gui_input do container de viewport (sem stretch → coords diretas ao viewport)
        viewport_container.gui_input.connect(_on_viewport_gui_input)
        viewport_container.mouse_filter = Control.MOUSE_FILTER_STOP

        # Painel de descrição removido: o viewport de hitbox usa a linha inteira.
        # _meta_label fica null (os usos em _set_meta já têm null-guard).
        _refresh_hierarchy_rows()

    func _find_first_group(group_name: String) -> int:
        for i in ImgDebug._HITBOX_ENTITIES.size():
            if String(ImgDebug._HITBOX_ENTITIES[i].group) == group_name:
                return i
        return -1

    func _select_index(index: int) -> void:
        if ImgDebug._HITBOX_ENTITIES.is_empty():
            return
        _current_index = wrapi(index, 0, ImgDebug._HITBOX_ENTITIES.size())
        var entry: Dictionary = ImgDebug._HITBOX_ENTITIES[_current_index]
        _clear_current()
        var scene := load(String(entry.path)) as PackedScene
        if scene == null:
            _set_meta(entry, ["Cena nao carregou"])
            return
        var inst := scene.instantiate()
        if inst is Node2D:
            _current_instance = inst as Node2D
        else:
            _current_instance = Node2D.new()
            _current_instance.add_child(inst)
        _current_instance.position = _ENTITY_POS
        _world_root.add_child(_current_instance)
        _set_sprites_visible(_current_instance, _show_sprite)
        _selected_frame = mini(_selected_frame, max(0, _detect_frame_count(_current_instance) - 1))
        _apply_selected_frame()
        _shape_infos = _collect_shapes(_current_instance)
        _align_current_to_floor()
        # Voadores (têm bob_amplitude) sobem p/ a altura do pulo, p/ ver a relação espacial real.
        if _current_instance.get("bob_amplitude") != null:
            _current_instance.position.y -= _FLY_HEIGHT
        _freeze_node_tree(_current_instance)
        _current_instance.visible = true   # inimigos que se auto-escondem no _ready (ex.: lava_serpent submersa)
        _apply_selected_frame()
        _shape_infos = _collect_shapes(_current_instance)
        if _shape_overlay != null:
            _shape_overlay.shape_infos = _shape_infos
            _shape_overlay.show_labels = _show_labels
            # régua ancorada na origem real da entidade (após alinhar ao chão) → os
            # números batem com os offsets do _PROJECTILE_DEFS / _fire().
            _shape_overlay.ruler_origin = _current_instance.global_position
            _shape_overlay.queue_redraw()
        _set_meta(entry, _shape_infos)
        _refresh_anim_row(entry)
        _refresh_frame_row()
        _refresh_projectile_row()
        _load_edit_state()

    func _refresh_anim_row(entry: Dictionary) -> void:
        if _anim_row == null or _anim_opt == null:
            return
        var anims: Array = entry.get("anims", [])
        if anims.is_empty():
            _anim_row.visible = false
            _anim_opt.clear()
            return
        _anim_row.visible = true
        _anim_opt.clear()
        for anim: Dictionary in anims:
            _anim_opt.add_item(String(anim.label))
        _anim_opt.select(0)
        _apply_anim(anims[0])

    func _apply_anim_opt(idx: int) -> void:
        var entry: Dictionary = ImgDebug._HITBOX_ENTITIES[_current_index]
        var anims: Array = entry.get("anims", [])
        if idx >= 0 and idx < anims.size():
            _apply_anim(anims[idx])

    func _apply_anim(anim: Dictionary) -> void:
        if _current_instance == null:
            return
        var sprite := _find_sprite2d(_current_instance)
        if sprite == null:
            return
        var tex: Texture2D = load(String(anim.path))
        if tex == null:
            return
        sprite.texture = tex
        sprite.hframes = int(anim.frames)
        sprite.vframes = 1
        sprite.frame   = 0
        _selected_frame = 0
        _frame_count    = int(anim.frames)
        _refresh_frame_row()
        _refresh_projectile_row()

    func _clear_current() -> void:
        _shape_infos.clear()
        if is_instance_valid(_current_instance):
            _current_instance.queue_free()
        _current_instance = null

    func _collect_shapes(root: Node) -> Array:
        var found: Array = []
        _collect_shapes_into(root, found)
        return found

    func _collect_shapes_into(node: Node, found: Array) -> void:
        if node is CollisionShape2D:
            var cs := node as CollisionShape2D
            found.append({
                "path": String(_current_instance.get_path_to(cs)) if _current_instance != null else cs.name,
                "node": cs,
                "summary": _shape_summary(cs.shape),
            })
        for child in node.get_children():
            _collect_shapes_into(child, found)

    func _shape_summary(shape: Shape2D) -> String:
        if shape == null:
            return "sem shape"
        if shape is RectangleShape2D:
            return "Rectangle size=" + str((shape as RectangleShape2D).size)
        if shape is CapsuleShape2D:
            var cap := shape as CapsuleShape2D
            return "Capsule radius=%.1f height=%.1f" % [cap.radius, cap.height]
        if shape is CircleShape2D:
            return "Circle radius=%.1f" % [(shape as CircleShape2D).radius]
        return shape.get_class()

    func _align_current_to_floor() -> void:
        if _current_instance == null or _overlay == null or _shape_infos.is_empty():
            return
        var bottom := -INF
        for info: Dictionary in _shape_infos:
            var cs := info.node as CollisionShape2D
            if cs != null:
                bottom = maxf(bottom, _collision_shape_bottom(cs))
        if bottom > -INF:
            _current_instance.position.y += _overlay.ground_y - bottom

    func _collision_shape_bottom(cs: CollisionShape2D) -> float:
        if cs.shape is RectangleShape2D:
            return cs.global_position.y + (cs.shape as RectangleShape2D).size.y * 0.5
        if cs.shape is CircleShape2D:
            return cs.global_position.y + (cs.shape as CircleShape2D).radius
        if cs.shape is CapsuleShape2D:
            return cs.global_position.y + (cs.shape as CapsuleShape2D).height * 0.5
        return cs.global_position.y

    func _freeze_node_tree(node: Node) -> void:
        if node == null:
            return
        node.set_process(false)
        node.set_physics_process(false)
        node.set_process_input(false)
        node.set_process_unhandled_input(false)
        node.process_mode = Node.PROCESS_MODE_DISABLED
        if node is CharacterBody2D:
            (node as CharacterBody2D).velocity = Vector2.ZERO
        for child in node.get_children():
            _freeze_node_tree(child)

    func _set_meta(entry: Dictionary, infos: Array) -> void:
        if _name_label != null:
            _name_label.text = String(entry.name)
        if _meta_label == null:
            return
        var lines: Array[String] = [
            "Grupo: " + String(entry.group),
            "Cena: " + String(entry.path),
            "Shapes: " + str(infos.size()),
        ]
        for info in infos:
            if info is Dictionary:
                lines.append("%s | %s" % [String(info.path), String(info.summary)])
            else:
                lines.append(String(info))
        _meta_label.text = "\n".join(lines)

    func _make_button(text: String, callback: Callable) -> Button:
        var btn := Button.new()
        btn.text = text
        btn.add_theme_font_size_override("font_size", 28)
        btn.pressed.connect(callback)
        return btn

    func _make_label(txt: String) -> Label:
        var l := Label.new()
        l.text = txt
        l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        l.add_theme_font_size_override("font_size", 26)
        return l

    func _clear_container(container: Container) -> void:
        if container == null:
            return
        for child in container.get_children():
            container.remove_child(child)
            child.free()

    func _set_filter(group_name: String) -> void:
        _filter_group = group_name
        _selected_stage = "Todos"
        _refresh_stage_options()
        _refresh_entity_options()

    func _set_stage(stage_name: String) -> void:
        _selected_stage = stage_name
        _refresh_entity_options()

    func _refresh_hierarchy_rows() -> void:
        _refresh_stage_options()
        _refresh_entity_options()

    func _refresh_stage_options() -> void:
        if _stage_opt == null:
            return
        _stage_opt.clear()
        var stages := ["Todos"]
        for e in ImgDebug._HITBOX_ENTITIES:
            if _filter_group != "Todos" and String(e.group) != _filter_group:
                continue
            var st := String(e.get("stage", ""))
            if st != "" and not stages.has(st):
                stages.append(st)
        for s in stages:
            _stage_opt.add_item(s)
        for i in _stage_opt.item_count:
            if _stage_opt.get_item_text(i) == _selected_stage:
                _stage_opt.select(i)
                return
        _selected_stage = "Todos"
        _stage_opt.select(0)

    func _refresh_entity_options() -> void:
        if _entity_opt == null:
            return
        _entity_opt.clear()
        for i in ImgDebug._HITBOX_ENTITIES.size():
            var e: Dictionary = ImgDebug._HITBOX_ENTITIES[i]
            if _filter_group != "Todos" and String(e.group) != _filter_group:
                continue
            if _selected_stage != "Todos" and String(e.get("stage", "")) != _selected_stage:
                continue
            var idx := _entity_opt.item_count
            _entity_opt.add_item(String(e.name))
            _entity_opt.set_item_metadata(idx, i)
        if _entity_opt.item_count > 0:
            _entity_opt.select(0)
            _select_index(int(_entity_opt.get_selected_metadata()))

    func _toggle_sprite() -> void:
        _show_sprite = not _show_sprite
        if _sprite_btn != null:
            _sprite_btn.text = "Sprite ON" if _show_sprite else "Sprite OFF"
        _set_sprites_visible(_current_instance, _show_sprite)

    func _toggle_labels() -> void:
        _show_labels = not _show_labels
        if _labels_btn != null:
            _labels_btn.text = "Labels ON" if _show_labels else "Labels OFF"
        if _shape_overlay != null:
            _shape_overlay.show_labels = _show_labels
            _shape_overlay.queue_redraw()

    func _toggle_ruler() -> void:
        _show_ruler = not _show_ruler
        if _ruler_btn != null:
            _ruler_btn.text = "Regua ON" if _show_ruler else "Regua OFF"
        if _shape_overlay != null:
            _shape_overlay.show_ruler = _show_ruler
            _shape_overlay.queue_redraw()

    func _set_sprites_visible(node: Node, visible: bool) -> void:
        if node == null:
            return
        if node is Sprite2D or node is AnimatedSprite2D:
            (node as CanvasItem).visible = visible
        for child in node.get_children():
            _set_sprites_visible(child, visible)

    func _refresh_frame_row() -> void:
        _clear_container(_frame_row)
        _frame_count = _detect_frame_count(_current_instance)
        if _frame_count <= 1:
            _frame_row.visible = false
            return
        _frame_row.visible = true
        _frame_row.add_child(_make_button("<", func(): _select_frame(wrapi(_selected_frame - 1, 0, _frame_count))))
        _frame_lbl = _make_label("Frame %d/%d" % [_selected_frame + 1, _frame_count])
        _frame_row.add_child(_frame_lbl)
        _frame_row.add_child(_make_button(">", func(): _select_frame(wrapi(_selected_frame + 1, 0, _frame_count))))

    func _detect_frame_count(node: Node) -> int:
        var sprite := _find_sprite2d(node)
        if sprite != null:
            return max(1, sprite.hframes * sprite.vframes)
        var animated := _find_animated_sprite2d(node)
        if animated != null and animated.sprite_frames != null and animated.animation != "":
            return max(1, animated.sprite_frames.get_frame_count(animated.animation))
        return 1

    func _select_frame(frame_index: int) -> void:
        _selected_frame = clampi(frame_index, 0, max(0, _frame_count - 1))
        if _frame_lbl != null:
            _frame_lbl.text = "Frame %d/%d" % [_selected_frame + 1, _frame_count]
        _apply_selected_frame()
        _shape_infos = _collect_shapes(_current_instance)
        if _shape_overlay != null:
            _shape_overlay.shape_infos = _shape_infos
            _shape_overlay.queue_redraw()
        if _current_index >= 0 and _current_index < ImgDebug._HITBOX_ENTITIES.size():
            _set_meta(ImgDebug._HITBOX_ENTITIES[_current_index], _shape_infos)
        _refresh_projectile_row()

    func _apply_selected_frame() -> void:
        if _current_instance == null:
            return
        var sprite := _find_sprite2d(_current_instance)
        if sprite != null:
            sprite.frame = clampi(_selected_frame, 0, max(0, sprite.hframes * sprite.vframes - 1))
        var animated := _find_animated_sprite2d(_current_instance)
        if animated != null:
            animated.frame = clampi(_selected_frame, 0, max(0, _detect_frame_count(_current_instance) - 1))
        _apply_hitbox_frame_state()

    func _apply_hitbox_frame_state() -> void:
        if _current_instance == null:
            return
        # Inimigos com hitbox por frame expõem _apply_hitbox_frame (EnemyBase).
        if _current_instance.has_method("_apply_hitbox_frame"):
            _current_instance.call("_apply_hitbox_frame", _selected_frame)
        if _current_instance.name == "EnemyGlacierShield":
            var barrier := _current_instance.get_node_or_null("ShieldBarrier") as Area2D
            if barrier != null:
                match _selected_frame:
                    1:
                        barrier.position = Vector2(38.0, -52.0)
                    2:
                        barrier.position = Vector2(38.0, -40.0)
                    _:
                        barrier.position = Vector2(38.0, -56.0)

    func _refresh_projectile_row() -> void:
        _clear_container(_projectile_row)
        _current_projectile_info = {}
        if _shape_overlay != null:
            _shape_overlay.projectile_preview = {}
            _shape_overlay.queue_redraw()
        if _current_index < 0 or _current_index >= ImgDebug._HITBOX_ENTITIES.size():
            return
        var entry: Dictionary = ImgDebug._HITBOX_ENTITIES[_current_index]
        var def_value = _PROJECTILE_DEFS.get(String(entry.name))
        if not (def_value is Dictionary):
            if _projectile_row != null:
                _projectile_row.visible = false
            return
        var projectile_def := (def_value as Dictionary).duplicate()
        var release_frame := int(projectile_def.release_frame)
        var is_release := _selected_frame == release_frame
        projectile_def["visible"] = is_release
        projectile_def["position"] = _projectile_spawn_position(projectile_def.get("offset", Vector2.ZERO) as Vector2)
        _current_projectile_info = projectile_def
        if _projectile_row != null:
            _projectile_row.visible = true
            var title := Label.new()
            title.text = "Projetil:"
            title.add_theme_font_size_override("font_size", 24)
            _projectile_row.add_child(title)
            _projectile_label = Label.new()
            _projectile_label.text = "%s no Frame %d%s" % [
                String(projectile_def.label),
                release_frame + 1,
                " (visivel)" if is_release else "",
            ]
            _projectile_label.add_theme_font_size_override("font_size", 24)
            _projectile_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.32) if is_release else Color(0.82, 0.82, 0.86))
            _projectile_row.add_child(_projectile_label)
        if _shape_overlay != null:
            _shape_overlay.projectile_preview = projectile_def
            _shape_overlay.queue_redraw()

    func _projectile_spawn_position(offset: Vector2) -> Vector2:
        if _current_instance == null:
            return _ENTITY_POS + offset
        return _current_instance.global_position + offset

    # ── Editor por mouse: estado / helpers ────────────────────────────────────

    func _entity_hitbox_id() -> String:
        if _current_instance == null:
            return ""
        var scr := _current_instance.get_script() as Script
        return scr.resource_path.get_file().get_basename() if scr != null else ""

    func _load_edit_state() -> void:
        _edit_id = _entity_hitbox_id()
        _edit = HitboxData.entry(_edit_id).duplicate(true)
        if not _edit.has("shapes"):
            _edit["shapes"] = []
        _sel_shape = (_edit["shapes"].size() - 1) if _edit["shapes"].size() > 0 else -1
        _push_overlay_edit()

    func _sprite_node() -> Sprite2D:
        return _current_instance.get_node_or_null("Sprite2D") as Sprite2D if _current_instance != null else null

    func _sprite_center_world() -> Vector2:
        var sp := _sprite_node()
        if sp == null: return _origin_world()
        return _origin_world() + sp.position

    func _sprite_half_frame() -> Vector2:
        var sp := _sprite_node()
        if sp == null or sp.texture == null: return Vector2(32, 32)
        var fw := sp.texture.get_width() / maxi(1, sp.hframes)
        var fh := sp.texture.get_height() / maxi(1, sp.vframes)
        return Vector2(fw, fh) * 0.5

    func _sprite_scale_handle_world() -> Vector2:
        var sp := _sprite_node()
        var sc := sp.scale if sp != null else Vector2.ONE
        return _sprite_center_world() + Vector2(_sprite_half_frame().x * sc.x, -_sprite_half_frame().y * sc.y)

    func _push_overlay_edit() -> void:
        if _shape_overlay == null:
            return
        _shape_overlay.edit_shapes = _edit.get("shapes", [])
        _shape_overlay.sel_shape = _sel_shape
        _shape_overlay.edit_proj = _edit.get("projectile", {})
        _shape_overlay.sprite_handle = _sprite_scale_handle_world() if _shape_overlay.editing else Vector2.INF
        _shape_overlay.queue_redraw()

    func _frame_scope() -> Variant:
        return [_selected_frame] if _edit_this_frame else "all"

    # ── Coordenadas tela → mundo ──────────────────────────────────────────────

    func _screen_to_world(p: Vector2) -> Vector2:
        # p é relativo ao canto superior esquerdo do SubViewportContainer
        # sem stretch: 1 px container = 1 px viewport
        # câmera zoom 2.0: 1 world-px = 2 viewport-px
        var vp_center := Vector2(_viewport.size) * 0.5
        return _camera.global_position + (p - vp_center) / _camera.zoom

    func _origin_world() -> Vector2:
        return _current_instance.global_position if _current_instance != null else _ENTITY_POS

    # ── Drag: hittest e processamento ─────────────────────────────────────────

    func _handle_radius() -> float:
        return 8.0 / _camera.zoom.x   # 8 px tela → world-px

    func _on_viewport_gui_input(event: InputEvent) -> void:
        if _current_instance == null:
            return
        if not _shape_overlay.editing:
            return
        if event is InputEventMouseButton:
            var mb := event as InputEventMouseButton
            if mb.button_index == MOUSE_BUTTON_LEFT:
                if mb.pressed:
                    _start_drag(mb.position)
                else:
                    _drag_mode = ""
        elif event is InputEventMouseMotion:
            if _drag_mode != "":
                _continue_drag((event as InputEventMouseMotion).position)

    func _start_drag(screen_pos: Vector2) -> void:
        var world := _screen_to_world(screen_pos)
        var origin := _origin_world()
        var local := world - origin      # coords relativas à entidade
        var hr := _handle_radius()

        # Testa projétil primeiro
        if _edit.has("projectile") and _edit["projectile"].has("offset"):
            var po: Array = _edit["projectile"]["offset"] as Array
            var pp := Vector2(float(po[0]), float(po[1]))
            if local.distance_to(pp) <= hr * 1.5:
                _drag_mode = "move_proj"
                _drag_last_world = world
                return

        # Testa handles do shape selecionado
        if _sel_shape >= 0 and _sel_shape < _edit["shapes"].size():
            var s: Dictionary = _edit["shapes"][_sel_shape]
            var sp := Vector2(float(s["pos"][0]), float(s["pos"][1]))
            var half := Vector2(float(s["size"][0]), float(s["size"][1])) * 0.5
            for hxi in 3:
                for hyi in 3:
                    var hx: float = float(hxi) - 1.0
                    var hy: float = float(hyi) - 1.0
                    if hx == 0.0 and hy == 0.0:
                        continue
                    var hp := sp + Vector2(half.x * hx, half.y * hy)
                    if local.distance_to(hp) <= hr:
                        var dir := ""
                        if hy < 0.0: dir += "t"
                        elif hy > 0.0: dir += "b"
                        if hx < 0.0: dir += "l"
                        elif hx > 0.0: dir += "r"
                        _drag_mode = "resize_" + dir
                        _drag_last_world = world
                        return

        # Testa corpo de cada shape (hit-test → seleciona e inicia move)
        for si in _edit["shapes"].size():
            var s: Dictionary = _edit["shapes"][si]
            var sp := Vector2(float(s["pos"][0]), float(s["pos"][1]))
            var half := Vector2(float(s["size"][0]), float(s["size"][1])) * 0.5
            var rect := Rect2(sp - half, half * 2.0)
            if rect.has_point(local):
                _sel_shape = si
                _drag_mode = "move_shape"
                _drag_last_world = world
                _push_overlay_edit()
                return

        # Sem hit → testa alça de escala do sprite (canto superior-direito)
        if world.distance_to(_sprite_scale_handle_world()) <= 10.0:
            _drag_mode = "scale_sprite"
            _drag_last_world = world
            return

        # Sem hit → tenta mover sprite
        _drag_mode = "move_sprite"
        _drag_last_world = world

    func _continue_drag(screen_pos: Vector2) -> void:
        var world := _screen_to_world(screen_pos)

        # scale_sprite usa posição absoluta (não delta); tratado antes do snap guard
        if _drag_mode == "scale_sprite":
            var half := _sprite_half_frame()
            if half.x > 0.0:
                var s: float = maxf(0.1, absf(world.x - _sprite_center_world().x) / half.x)
                s = snappedf(s, 0.05)
                if not _edit.has("sprite"): _edit["sprite"] = {}
                _edit["sprite"]["scale"] = [s, s]
                _apply_edit_to_instance()
            return

        var raw_delta := world - _drag_last_world
        # Snap a 1 game-px inteiro
        var delta := Vector2(roundi(raw_delta.x), roundi(raw_delta.y))
        if delta == Vector2.ZERO:
            return
        _drag_last_world += delta   # acumula apenas o snap consumido

        if _drag_mode == "move_shape" and _sel_shape >= 0 and _sel_shape < _edit["shapes"].size():
            var s: Dictionary = _edit["shapes"][_sel_shape]
            s["pos"] = [int(s["pos"][0]) + int(delta.x), int(s["pos"][1]) + int(delta.y)]
            _edit["shapes"][_sel_shape] = s
            _apply_edit_to_instance()
        elif _drag_mode == "move_proj":
            if not _edit.has("projectile"):
                _edit["projectile"] = {}
            var cur_off: Array = (_edit["projectile"].get("offset", [0, 0])) as Array
            _edit["projectile"]["offset"] = [int(cur_off[0]) + int(delta.x), int(cur_off[1]) + int(delta.y)]
            _apply_edit_to_instance()
        elif _drag_mode == "move_sprite":
            if not _edit.has("sprite"):
                _edit["sprite"] = {"pos": [0, 0], "scale": [1.0, 1.0]}
            var sp: Array = (_edit["sprite"].get("pos", [0, 0])) as Array
            _edit["sprite"]["pos"] = [int(sp[0]) + int(delta.x), int(sp[1]) + int(delta.y)]
            _apply_edit_to_instance()
        elif _drag_mode.begins_with("resize_") and _sel_shape >= 0 and _sel_shape < _edit["shapes"].size():
            _apply_resize(delta)

    func _apply_resize(delta: Vector2) -> void:
        if _sel_shape < 0 or _sel_shape >= _edit["shapes"].size():
            return
        var s: Dictionary = _edit["shapes"][_sel_shape]
        var pos := Vector2(float(s["pos"][0]), float(s["pos"][1]))
        var sz  := Vector2(float(s["size"][0]), float(s["size"][1]))
        var dir := _drag_mode.substr(7)   # after "resize_"
        var min_sz := 4.0
        if dir.contains("l"):
            var new_w := maxf(min_sz, sz.x - delta.x)
            pos.x += (sz.x - new_w) * 0.5
            sz.x = new_w
        if dir.contains("r"):
            var new_w := maxf(min_sz, sz.x + delta.x)
            pos.x += (new_w - sz.x) * 0.5
            sz.x = new_w
        if dir.contains("t"):
            var new_h := maxf(min_sz, sz.y - delta.y)
            pos.y += (sz.y - new_h) * 0.5
            sz.y = new_h
        if dir.contains("b"):
            var new_h := maxf(min_sz, sz.y + delta.y)
            pos.y += (new_h - sz.y) * 0.5
            sz.y = new_h
        s["pos"] = [roundi(pos.x), roundi(pos.y)]
        s["size"] = [roundi(sz.x), roundi(sz.y)]
        _edit["shapes"][_sel_shape] = s
        _apply_edit_to_instance()

    func _apply_edit_to_instance() -> void:
        if _current_instance == null:
            return
        if _edit_id != "":
            HitboxData._data[_edit_id] = _edit
        if _current_instance.has_method("_apply_hitbox_data"):
            _current_instance._apply_hitbox_data()
        _push_overlay_edit()

    # ── CRUD toolbar ──────────────────────────────────────────────────────────

    func _on_toggle_edit() -> void:
        if _shape_overlay == null:
            return
        _shape_overlay.editing = not _shape_overlay.editing
        if _edit_toggle_btn != null:
            _edit_toggle_btn.text = "Editar ON" if _shape_overlay.editing else "Editar OFF"
        _shape_overlay.queue_redraw()

    func _on_add_shape() -> void:
        if not _edit.has("shapes"):
            _edit["shapes"] = []
        _edit["shapes"].append({
            "target": _edit_target,
            "kind": "rect",
            "pos": [0, 0],
            "size": [40, 40],
            "frames": _frame_scope()
        })
        _sel_shape = _edit["shapes"].size() - 1
        _apply_edit_to_instance()

    func _on_delete_shape() -> void:
        if _sel_shape < 0 or not _edit.has("shapes"):
            return
        if _sel_shape >= _edit["shapes"].size():
            return
        _edit["shapes"].remove_at(_sel_shape)
        _sel_shape = clampi(_sel_shape, 0, _edit["shapes"].size() - 1)
        if _edit["shapes"].is_empty():
            _sel_shape = -1
        _apply_edit_to_instance()

    func _on_toggle_frame_scope() -> void:
        _edit_this_frame = not _edit_this_frame
        if _frame_scope_btn != null:
            _frame_scope_btn.text = "Frame: Este" if _edit_this_frame else "Frame: Todos"

    # ── Save (POST para o servidor de hitbox) ─────────────────────────────────

    func _on_save() -> void:
        if _edit_id.is_empty():
            return
        var req := HTTPRequest.new()
        add_child(req)
        req.request_completed.connect(func(_r, _c, _h, _b): req.queue_free())
        var payload := JSON.stringify({"id": _edit_id, "data": _edit})
        req.request("/save-hitbox",
            PackedStringArray(["Content-Type: application/json"]),
            HTTPClient.METHOD_POST,
            payload)

    func _find_sprite2d(node: Node) -> Sprite2D:
        if node is Sprite2D:
            return node as Sprite2D
        if node == null:
            return null
        for child in node.get_children():
            var found := _find_sprite2d(child)
            if found != null:
                return found
        return null

    func _find_animated_sprite2d(node: Node) -> AnimatedSprite2D:
        if node is AnimatedSprite2D:
            return node as AnimatedSprite2D
        if node == null:
            return null
        for child in node.get_children():
            var found := _find_animated_sprite2d(child)
            if found != null:
                return found
        return null

# Arena jogável: SubViewport com Zael, inimigo, física e câmera
class _MovView extends Control:
    const _PLAYER_PATHS := [
        "res://characters/ranged/zael.tscn",
        "res://characters/ranged/kawagael/kawagael.tscn",
    ]
    const _PLAYER_NAMES := ["Zael", "Kawagael"]
    const _ENEMY_PATHS := [
        "res://characters/enemies/enemy_base.tscn",
        "res://characters/enemies/enemy_flyer.tscn",
        "res://characters/enemies/stage_02/enemy_ice_grunt.tscn",
        "res://characters/enemies/stage_02/enemy_ice_flyer.tscn",
        "res://characters/enemies/stage_02/enemy_ice_archer.tscn",
        "res://characters/enemies/stage_02/enemy_frost_turret.tscn",
        "res://characters/enemies/stage_02/enemy_cryo_bomber.tscn",
        "res://characters/enemies/stage_02/enemy_glacier_shield.tscn",
        "res://characters/enemies/stage_02/enemy_ice_wisp.tscn",
        "res://characters/enemies/stage_02/enemy_ice_miniboss.tscn",
        "res://characters/enemies/enemy_miniboss.tscn",
        "res://characters/bosses/intro_boss.tscn",
    ]
    const _ENEMY_NAMES := [
        "Grunt", "Flyer",
        "Ice Grunt", "Ice Flyer", "Ice Archer", "Frost Turret", "Cryo Bomber", "Glacier Shield", "Ice Wisp", "Ice MiniBoss",
        "MiniBoss", "IntroBoss",
    ]
    const _GROUND_Y    := 16.0
    const _PLAYER_X    := 280.0
    const _ENEMY_X     := 680.0
    const _ENEMY_Y     := [-40.0, -100.0, -40.0, -100.0, -40.0, -40.0, -42.0, -42.0, -125.0, 3.0, 3.0, -24.0]
    const _WALL_L      := 100.0
    const _WALL_R      := 1820.0
    const _GWL         := 480.0
    const _GWR         := 900.0
    const _GLASS_ROWS  := 4
    const _TW          := 64.0

    var _player: CharacterBase = null
    var _enemy: Node2D = null
    var _enemy_index: int = 0
    var _player_index: int = 0
    var _camera: Camera2D = null
    var _world: Node2D = null
    var label_player: Label = null     # definido externamente antes de add_child
    var label_enemy: Label = null      # definido externamente antes de add_child
    var label_move_btn: Button = null  # botão de toggle de movimento
    var attack_row: Control = null     # linha de botões de ataque do MiniBoss
    var boss_attack_row: Control = null  # linha de botões do IntroBoss
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
        if ResourceLoader.exists("res://stages/stage_00/stage_00_glass.png"):
            mw.glass_tex = load("res://stages/stage_00/stage_00_glass.png") as Texture2D
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
        _camera.zoom = Vector2(2.0, 2.0)   # mesmo zoom do jogo e da aba Hitbox
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
        # Paredes de vidro (no_wall_grab) — face interna do tile lateral (tile_left + 32)
        for gx: float in [_GWL, _GWR]:
            var gwall := StaticBody2D.new()
            gwall.collision_layer = 1
            gwall.add_to_group("no_wall_grab")
            _world.add_child(gwall)
            var gwcs := CollisionShape2D.new()
            var gwseg := SegmentShape2D.new()
            var wx := gx - 32.0 if gx == _GWL else gx + 32.0
            gwseg.a = Vector2(wx, _GROUND_Y - float(_GLASS_ROWS) * _TW)
            gwseg.b = Vector2(wx, _GROUND_Y)
            gwcs.shape = gwseg
            gwall.add_child(gwcs)

    func _spawn_player() -> void:
        if is_instance_valid(_player):
            _player.queue_free()
        var scene := load(_PLAYER_PATHS[_player_index]) as PackedScene
        if not scene:
            return
        _player = scene.instantiate() as CharacterBase
        _world.add_child(_player)
        _player.global_position = Vector2(_PLAYER_X, _GROUND_Y - 90.0)
        _player.died.connect(func(): call_deferred("_spawn_player"))
        (_world as ImgDebug._MovWorld).player_ref = _player
        if _ENEMY_NAMES[_enemy_index] == "IntroBoss" and is_instance_valid(_enemy):
            (_enemy as BossBase).player = _player

    func _spawn_enemy() -> void:
        if is_instance_valid(_enemy):
            _enemy.queue_free()
        var scene := load(_ENEMY_PATHS[_enemy_index]) as PackedScene
        if not scene:
            return
        _enemy = scene.instantiate() as Node2D
        _world.add_child(_enemy)
        _enemy.global_position = Vector2(_ENEMY_X, _GROUND_Y + _ENEMY_Y[_enemy_index])
        if _ENEMY_NAMES[_enemy_index] == "IntroBoss":
            var boss := _enemy as BossBase
            boss.player      = _player
            boss.arena_left  = _WALL_L - 32.0
            boss.arena_right = _WALL_R + 32.0
            boss.arena_floor = _GROUND_Y
            boss.max_hp      = 99999
            boss.current_hp  = 99999
            boss.state       = BossBase.State.COMBAT
        else:
            var enemy := _enemy as EnemyBase
            enemy.set_physics_process(false)
            enemy.show_hitbox = true
            enemy.max_hp      = 99999
            enemy.current_hp  = 99999
            var spr := enemy.get_node_or_null("Sprite2D") as Sprite2D
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

    func on_player_prev() -> void:
        _player_index = (_player_index - 1 + _PLAYER_PATHS.size()) % _PLAYER_PATHS.size()
        _spawn_player()
        _update_player_label()

    func on_player_next() -> void:
        _player_index = (_player_index + 1) % _PLAYER_PATHS.size()
        _spawn_player()
        _update_player_label()

    func _update_player_label() -> void:
        if is_instance_valid(label_player):
            label_player.text = _PLAYER_NAMES[_player_index]

    func on_toggle_movement() -> void:
        if not is_instance_valid(_enemy):
            return
        if _ENEMY_NAMES[_enemy_index] == "IntroBoss":
            var boss := _enemy as BossBase
            if boss.state == BossBase.State.COMBAT:
                boss.state    = BossBase.State.IDLE
                boss.velocity = Vector2.ZERO
            else:
                boss.state = BossBase.State.COMBAT
        else:
            var moving := not _enemy.is_physics_processing()
            _enemy.set_physics_process(moving)
        _update_move_btn()

    func on_attack(method_name: String) -> void:
        if not is_instance_valid(_enemy):
            return
        if _enemy.has_method(method_name):
            _enemy.call(method_name)

    func _update_move_btn() -> void:
        if not is_instance_valid(label_move_btn):
            return
        var moving: bool
        if _ENEMY_NAMES[_enemy_index] == "IntroBoss" and is_instance_valid(_enemy):
            moving = (_enemy as BossBase).state == BossBase.State.COMBAT
        else:
            moving = is_instance_valid(_enemy) and _enemy.is_physics_processing()
        label_move_btn.text = "Parar" if moving else "Mover"

    func _update_attack_row() -> void:
        if is_instance_valid(attack_row):
            attack_row.visible = (_ENEMY_NAMES[_enemy_index] == "MiniBoss")
        if is_instance_valid(boss_attack_row):
            boss_attack_row.visible = (_ENEMY_NAMES[_enemy_index] == "IntroBoss")

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
            if _ENEMY_NAMES[_enemy_index] in ["MiniBoss", "IntroBoss"] and is_instance_valid(_enemy):
                var y_offset := 146.0 if _ENEMY_NAMES[_enemy_index] == "MiniBoss" else 80.0
                # Target: centro do sprite do inimigo
                var tx := _enemy.global_position.x
                var ty := clampf(_enemy.global_position.y - y_offset, _GROUND_Y - 220.0, _GROUND_Y + 100.0)
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

# Vista interativa para testar colisão do teto de fill (Abordagem B)
class _FillCeilView extends Control:
    const _PLAYER_PATH := "res://characters/ranged/zael.tscn"
    const _TW          := 64.0
    const _GROUND_Y    := 60.0
    const _CEIL_Y      := -68.0
    const _LAT_X       := 60.0
    const _FILL_X      := 124.0
    const _FILL_COLS   := 14
    const _WALL_L      := -4.0
    const _WALL_R      := 1020.0
    const _GLASS_ROWS  := 4

    var _player: CharacterBase = null
    var _camera: Camera2D      = null
    var _world: Node2D         = null
    var _fixed_mode: bool      = false
    var lbl_mode:  Label       = null
    var lbl_state: Label       = null

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
        var mw := ImgDebug._FillCeilWorld.new()
        mw.tile_tex   = load("res://stages/stage_00/Stage_00T.png") as Texture2D
        if ResourceLoader.exists("res://stages/stage_00/stage_00_glass.png"):
            mw.glass_tex = load("res://stages/stage_00/stage_00_glass.png") as Texture2D
        mw.fixed_mode = _fixed_mode
        mw.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        svp.add_child(mw)
        _world = mw
        _camera = Camera2D.new()
        _world.add_child(_camera)
        _camera.global_position = Vector2(_FILL_X + _FILL_COLS * _TW * 0.5, (_GROUND_Y + _CEIL_Y) * 0.5 - 20.0)
        _build_physics()
        _spawn_player()

    func _build_physics() -> void:
        var ground := StaticBody2D.new()
        ground.collision_layer = 1
        _world.add_child(ground)
        var gcs := CollisionShape2D.new()
        var gseg := SegmentShape2D.new()
        gseg.a = Vector2(-8000.0, _GROUND_Y)
        gseg.b = Vector2(8000.0, _GROUND_Y)
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
        _rebuild_glass_physics()

    func _rebuild_glass_physics() -> void:
        for c: Node in _world.get_children():
            if c.is_in_group("_glass_ceil"):
                c.queue_free()
        var col_top := _CEIL_Y - float(_GLASS_ROWS) * _TW
        var height  := _CEIL_Y - col_top
        # Body1: lateral + 1st fill (2 tiles wide, como comportamento atual)
        _world.add_child(_make_glass_body(
            Vector2(_LAT_X + _TW, (col_top + _CEIL_Y) * 0.5),
            Vector2(_TW * 2.0, height)))
        if _fixed_mode:
            # Body2: todos os fills (Abordagem B)
            var fill_w := float(_FILL_COLS) * _TW
            _world.add_child(_make_glass_body(
                Vector2(_FILL_X + fill_w * 0.5, (col_top + _CEIL_Y) * 0.5),
                Vector2(fill_w, height)))

    func _make_glass_body(center: Vector2, size: Vector2) -> StaticBody2D:
        var body := StaticBody2D.new()
        body.collision_layer = 1
        body.collision_mask  = 0
        body.add_to_group("no_wall_grab")
        body.add_to_group("_glass_ceil")
        body.global_position = center
        var cs    := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = size
        cs.shape = shape
        body.add_child(cs)
        return body

    func _spawn_player() -> void:
        if is_instance_valid(_player):
            _player.queue_free()
        var scene := load(_PLAYER_PATH) as PackedScene
        if not scene:
            return
        _player = scene.instantiate() as CharacterBase
        _world.add_child(_player)
        _player.global_position = Vector2(_FILL_X + _FILL_COLS * _TW * 0.5, _GROUND_Y - 90.0)
        _player.died.connect(func(): call_deferred("_spawn_player"))
        (_world as ImgDebug._FillCeilWorld).player_ref = _player

    func toggle_mode() -> void:
        _fixed_mode = not _fixed_mode
        (_world as ImgDebug._FillCeilWorld).fixed_mode = _fixed_mode
        _world.queue_redraw()
        _rebuild_glass_physics()
        if is_instance_valid(lbl_mode):
            if _fixed_mode:
                lbl_mode.text = "✓ Corrigido — Body1 (2t) + Body2 (14 fills)"
                lbl_mode.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
            else:
                lbl_mode.text = "✗ Atual — só Body1 (2 tiles, 12 fills sem colisão)"
                lbl_mode.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

    func _process(_delta: float) -> void:
        if is_instance_valid(_player) and is_instance_valid(_camera):
            var cam_y := clampf(_player.global_position.y + 40.0, _CEIL_Y - 160.0, _GROUND_Y + 80.0)
            _camera.global_position = Vector2(_player.global_position.x, cam_y)
            _world.queue_redraw()
        if is_instance_valid(_player) and is_instance_valid(lbl_state):
            if _player.is_on_ceiling():
                lbl_state.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
                lbl_state.text = "✓ Bloqueado pelo teto"
            elif _player.is_on_floor():
                lbl_state.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
                lbl_state.text = "No chão"
            else:
                lbl_state.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
                lbl_state.text = "No ar"

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
var _hitboxes_box: VBoxContainer
var _battle_box: VBoxContainer
var _battle_view: _BossBattleView
var _hitbox_view: _HitboxView
var _anim_tabs_box: HBoxContainer
var _preview_rect: TextureRect
var _info_label: Label
var _strip_box: HBoxContainer
var _tile_info_label: Label
var _tile_preview_rect: TextureRect
var _tile_desc_label: Label
var _tile_displays: Dictionary = {}
# Membros (não locais): a lambda show_section os lê por self em call-time.
# Como locais, seriam capturados por valor (null) antes da atribuição → painel nunca aparece.
var _col_panel_ref: VBoxContainer
var _plat_panel_ref: VBoxContainer

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
    _hitboxes_box.visible = (section == "HITBOXES")
    _battle_box.visible  = (section == "BATALHA")
    if _battle_view != null:
        _battle_view.show_selection()  # reseta p/ o hub e libera ESC/Enter fora da BATALHA
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
        btn.add_theme_font_size_override("font_size", 34)
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
    title_lbl.add_theme_font_size_override("font_size", 40)
    title_lbl.add_theme_color_override("font_color", Color(0.8, 0.75, 1.0))
    title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_lbl)

    if OS.get_name() == "Web":
        var reload_btn := Button.new()
        reload_btn.text = "Hard Refresh"
        reload_btn.add_theme_font_size_override("font_size", 36)
        reload_btn.pressed.connect(func(): JavaScriptBridge.eval("location.reload(true)"))
        header.add_child(reload_btn)

    var close_btn := Button.new()
    close_btn.text = "X Fechar"
    close_btn.add_theme_font_size_override("font_size", 36)
    close_btn.pressed.connect(queue_free)
    header.add_child(close_btn)

    # Section row: SPRITES | TILES
    var section_row := HBoxContainer.new()
    section_row.add_theme_constant_override("separation", 6)
    main.add_child(section_row)

    for s in ["SPRITES", "TILES"]:
        var btn := Button.new()
        btn.text = s
        btn.add_theme_font_size_override("font_size", 36)
        btn.pressed.connect(_show_section.bind(s))
        section_row.add_child(btn)
        _section_btns[s] = btn

    var mov_btn := Button.new()
    mov_btn.text = "MOVIMENTOS"
    mov_btn.add_theme_font_size_override("font_size", 36)
    mov_btn.pressed.connect(_show_section.bind("MOVIMENTOS"))
    section_row.add_child(mov_btn)
    _section_btns["MOVIMENTOS"] = mov_btn

    var hitbox_btn := Button.new()
    hitbox_btn.text = "HITBOXES"
    hitbox_btn.add_theme_font_size_override("font_size", 36)
    hitbox_btn.pressed.connect(_show_section.bind("HITBOXES"))
    section_row.add_child(hitbox_btn)
    _section_btns["HITBOXES"] = hitbox_btn

    var battle_btn := Button.new()
    battle_btn.text = "BATALHA"
    battle_btn.add_theme_font_size_override("font_size", 36)
    battle_btn.pressed.connect(_show_section.bind("BATALHA"))
    section_row.add_child(battle_btn)
    _section_btns["BATALHA"] = battle_btn

    # SPRITES BOX
    _sprites_box = VBoxContainer.new()
    _sprites_box.add_theme_constant_override("separation", 8)
    main.add_child(_sprites_box)

    var char_row := HBoxContainer.new()
    char_row.add_theme_constant_override("separation", 6)
    _sprites_box.add_child(char_row)

    for c in ["ZAEL", "KAWAGAEL", "ZARA", "MINIBOSS"]:
        var btn := Button.new()
        btn.text = c
        btn.add_theme_font_size_override("font_size", 36)
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
    _info_label.add_theme_font_size_override("font_size", 26)
    _info_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
    right_col.add_child(_info_label)

    _strip_box = HBoxContainer.new()
    _strip_box.add_theme_constant_override("separation", 4)
    right_col.add_child(_strip_box)

    var hint_lbl := Label.new()
    hint_lbl.text = "strip: clicar pausa  ·  preview: clicar retoma"
    hint_lbl.add_theme_font_size_override("font_size", 21)
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

    # HITBOXES BOX
    _hitboxes_box = VBoxContainer.new()
    _hitboxes_box.add_theme_constant_override("separation", 8)
    main.add_child(_hitboxes_box)
    _hitbox_view = _HitboxView.new()
    _hitbox_view.custom_minimum_size = Vector2(0.0, 720.0)
    _hitbox_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _hitbox_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _hitboxes_box.add_child(_hitbox_view)

    # BATALHA BOX
    _battle_box = VBoxContainer.new()
    _battle_box.add_theme_constant_override("separation", 8)
    _battle_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
    main.add_child(_battle_box)
    _battle_view = _BossBattleView.new()
    _battle_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _battle_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _battle_view.custom_minimum_size = Vector2(0.0, 560.0)
    _battle_view.exit_requested.connect(func(): _show_section("SPRITES"))
    _battle_box.add_child(_battle_view)

func _build_moves_box() -> void:
    # ── Tab row ──────────────────────────────────────────────────────────────
    var tab_row := HBoxContainer.new()
    tab_row.add_theme_constant_override("separation", 6)
    _moves_box.add_child(tab_row)

    var mov_panel := VBoxContainer.new()
    mov_panel.add_theme_constant_override("separation", 6)
    var fill_ceil_panel := VBoxContainer.new()
    fill_ceil_panel.add_theme_constant_override("separation", 4)
    fill_ceil_panel.visible = false

    # ── Painel Movimentos ────────────────────────────────────────────────────
    var top_bar := HBoxContainer.new()
    top_bar.add_theme_constant_override("separation", 8)
    mov_panel.add_child(top_bar)

    var mview := _MovView.new()
    mview.custom_minimum_size   = Vector2(0.0, 480.0)
    mview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    mview.size_flags_vertical   = Control.SIZE_EXPAND_FILL

    # ── Seletor de personagem do player (Zael / Kawagael) ──
    var player_lbl := Label.new()
    player_lbl.text = "Player:"
    player_lbl.add_theme_font_size_override("font_size", 32)
    player_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    top_bar.add_child(player_lbl)

    var btn_pprev := Button.new()
    btn_pprev.text = "<"
    btn_pprev.add_theme_font_size_override("font_size", 32)
    btn_pprev.pressed.connect(mview.on_player_prev)
    top_bar.add_child(btn_pprev)

    var lbl_pname := Label.new()
    lbl_pname.custom_minimum_size.x = 120.0
    lbl_pname.add_theme_font_size_override("font_size", 32)
    lbl_pname.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
    lbl_pname.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_pname.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
    lbl_pname.text = "Zael"
    top_bar.add_child(lbl_pname)
    mview.label_player = lbl_pname

    var btn_pnext := Button.new()
    btn_pnext.text = ">"
    btn_pnext.add_theme_font_size_override("font_size", 32)
    btn_pnext.pressed.connect(mview.on_player_next)
    top_bar.add_child(btn_pnext)

    var hint := Label.new()
    hint.text = "A/D: mover - Z: pular - X: dash - J: atirar"
    hint.add_theme_font_size_override("font_size", 24)
    hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
    hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hint.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
    top_bar.add_child(hint)

    var enemy_lbl := Label.new()
    enemy_lbl.text = "Inimigo:"
    enemy_lbl.add_theme_font_size_override("font_size", 32)
    enemy_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    top_bar.add_child(enemy_lbl)

    var btn_prev := Button.new()
    btn_prev.text = "<"
    btn_prev.add_theme_font_size_override("font_size", 32)
    btn_prev.pressed.connect(mview.on_prev)
    top_bar.add_child(btn_prev)

    var lbl_name := Label.new()
    lbl_name.custom_minimum_size.x = 80.0
    lbl_name.add_theme_font_size_override("font_size", 32)
    lbl_name.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
    lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_name.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
    lbl_name.text = "Grunt"
    top_bar.add_child(lbl_name)

    var btn_next := Button.new()
    btn_next.text = ">"
    btn_next.add_theme_font_size_override("font_size", 32)
    btn_next.pressed.connect(mview.on_next)
    top_bar.add_child(btn_next)

    var btn_move := Button.new()
    btn_move.text = "Mover"
    btn_move.add_theme_font_size_override("font_size", 32)
    btn_move.pressed.connect(mview.on_toggle_movement)
    top_bar.add_child(btn_move)

    mview.label_enemy    = lbl_name
    mview.label_move_btn = btn_move

    var state_lbl := Label.new()
    state_lbl.add_theme_font_size_override("font_size", 21)
    state_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
    state_lbl.text = "No chão"
    mov_panel.add_child(state_lbl)
    mview.lbl_state = state_lbl

    var atk_row := HBoxContainer.new()
    atk_row.add_theme_constant_override("separation", 8)
    atk_row.visible = false
    mov_panel.add_child(atk_row)
    mview.attack_row = atk_row

    var atk_lbl := Label.new()
    atk_lbl.text = "Estado:"
    atk_lbl.add_theme_font_size_override("font_size", 24)
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
        abtn.add_theme_font_size_override("font_size", 32)
        abtn.modulate = atk[2]
        var mname: String = atk[1]
        abtn.pressed.connect(mview.on_attack.bind(mname))
        atk_row.add_child(abtn)

    # IntroBoss attack row
    var boss_atk_row := HBoxContainer.new()
    boss_atk_row.add_theme_constant_override("separation", 8)
    boss_atk_row.visible = false
    mov_panel.add_child(boss_atk_row)
    mview.boss_attack_row = boss_atk_row

    var boss_atk_lbl := Label.new()
    boss_atk_lbl.text = "Ataques:"
    boss_atk_lbl.add_theme_font_size_override("font_size", 24)
    boss_atk_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    boss_atk_row.add_child(boss_atk_lbl)

    for batk: Array in [
        ["Idle",   "debug_set_idle",      Color(0.5, 0.75, 1.0)],
        ["Combat", "debug_set_combat",    Color(0.4, 0.9, 0.4)],
        ["Dash",   "debug_trigger_dash",  Color(1.0, 0.7, 0.2)],
        ["Shoot",  "debug_trigger_shoot", Color(1.0, 0.35, 0.35)],
        ["Burst",  "debug_trigger_burst", Color(0.6, 0.2, 1.0)],
        ["Fase 2", "debug_enter_phase2",  Color(1.3, 0.5, 1.3)],
    ]:
        var babtn := Button.new()
        babtn.text = batk[0]
        babtn.add_theme_font_size_override("font_size", 32)
        babtn.modulate = batk[2]
        var bname: String = batk[1]
        babtn.pressed.connect(mview.on_attack.bind(bname))
        boss_atk_row.add_child(babtn)

    mov_panel.add_child(mview)

    # ── Painel Fill Teto ─────────────────────────────────────────────────────
    var fcview := _FillCeilView.new()
    fcview.custom_minimum_size   = Vector2(0.0, 480.0)
    fcview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    fcview.size_flags_vertical   = Control.SIZE_EXPAND_FILL

    var fc_bar := HBoxContainer.new()
    fc_bar.add_theme_constant_override("separation", 8)
    fill_ceil_panel.add_child(fc_bar)

    var fc_hint := Label.new()
    fc_hint.text = "A/D: mover  ·  Z: pular sob os fills — verifica se é bloqueado"
    fc_hint.add_theme_font_size_override("font_size", 22)
    fc_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
    fc_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    fc_bar.add_child(fc_hint)

    var fc_toggle := Button.new()
    fc_toggle.text = "Alternar Modo"
    fc_toggle.add_theme_font_size_override("font_size", 32)
    fc_toggle.pressed.connect(fcview.toggle_mode)
    fc_bar.add_child(fc_toggle)

    var fc_mode_lbl := Label.new()
    fc_mode_lbl.add_theme_font_size_override("font_size", 21)
    fc_mode_lbl.text = "✗ Atual — só Body1 (2 tiles, 12 fills sem colisão)"
    fc_mode_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
    fill_ceil_panel.add_child(fc_mode_lbl)
    fcview.lbl_mode = fc_mode_lbl

    var fc_state_lbl := Label.new()
    fc_state_lbl.add_theme_font_size_override("font_size", 21)
    fc_state_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
    fc_state_lbl.text = "No chão"
    fill_ceil_panel.add_child(fc_state_lbl)
    fcview.lbl_state = fc_state_lbl

    fill_ceil_panel.add_child(fcview)

    # ── Montar e conectar tabs ────────────────────────────────────────────────
    _moves_box.add_child(mov_panel)
    _moves_box.add_child(fill_ceil_panel)

    var btn_mov_tab := Button.new()
    btn_mov_tab.text = "Movimentos"
    btn_mov_tab.add_theme_font_size_override("font_size", 34)
    btn_mov_tab.modulate = Color(1.0, 1.0, 0.0)
    tab_row.add_child(btn_mov_tab)

    var btn_fill_tab := Button.new()
    btn_fill_tab.text = "Fill Teto"
    btn_fill_tab.add_theme_font_size_override("font_size", 34)
    btn_fill_tab.modulate = Color(0.6, 0.6, 0.6)
    tab_row.add_child(btn_fill_tab)

    btn_mov_tab.pressed.connect(func():
        mov_panel.visible = true
        fill_ceil_panel.visible = false
        btn_mov_tab.modulate = Color(1.0, 1.0, 0.0)
        btn_fill_tab.modulate = Color(0.6, 0.6, 0.6))
    btn_fill_tab.pressed.connect(func():
        mov_panel.visible = false
        fill_ceil_panel.visible = true
        btn_mov_tab.modulate = Color(0.6, 0.6, 0.6)
        btn_fill_tab.modulate = Color(1.0, 1.0, 0.0))

func _refresh_tiles() -> void:
    _tile_displays.clear()
    for child in _tiles_box.get_children():
        child.queue_free()

    # ── Agrupar tilesets por stage ───────────────────────────────────────────
    var stage_order: Array[String] = []
    var stage_groups: Dictionary = {}
    for ts_data: Dictionary in _TILESETS:
        var sk: String = ts_data.name.substr(0, 8)
        if not stage_groups.has(sk):
            stage_groups[sk] = []
            stage_order.append(sk)
        stage_groups[sk].append(ts_data)

    # ── Seletor de stage (nível 1) ────────────────────────────────────────────
    var stage_row := HBoxContainer.new()
    stage_row.add_theme_constant_override("separation", 4)
    _tiles_box.add_child(stage_row)

    var ts_area := VBoxContainer.new()
    ts_area.add_theme_constant_override("separation", 4)
    _tiles_box.add_child(ts_area)

    # _col_panel_ref / _plat_panel_ref são membros da classe (ver topo): a lambda
    # show_section precisa lê-los em call-time, não capturá-los como null por valor.
    var stage_conts: Array = []

    var show_section := func(sec: int, sub: int) -> void:
        ts_area.visible = (sec == 0)
        if is_instance_valid(_col_panel_ref):
            _col_panel_ref.visible = (sec == 1)
        if is_instance_valid(_plat_panel_ref):
            _plat_panel_ref.visible = (sec == 2)
        if sec == 0:
            for i in stage_conts.size():
                stage_conts[i].visible = (i == sub)
        var n: int = stage_order.size()
        for i in stage_row.get_child_count():
            var active: bool
            if sec == 0:
                active = (i == sub)
            else:
                active = (i == n + sec - 1)
            stage_row.get_child(i).modulate = Color(1, 1, 0) if active else Color(0.6, 0.6, 0.6)

    # ── Build por stage (nível 2: tileset tabs) ───────────────────────────────
    for st_idx in stage_order.size():
        var sk: String = stage_order[st_idx]
        var ts_list: Array = stage_groups[sk]

        var stage_btn := Button.new()
        stage_btn.text = sk.trim_prefix("Stage_")
        stage_btn.add_theme_font_size_override("font_size", 34)
        var _st: int = st_idx
        stage_btn.pressed.connect(func(): show_section.call(0, _st))
        stage_row.add_child(stage_btn)

        var sc := VBoxContainer.new()
        sc.add_theme_constant_override("separation", 4)
        sc.visible = (st_idx == 0)
        ts_area.add_child(sc)
        stage_conts.append(sc)

        var ts_tab_row := HBoxContainer.new()
        ts_tab_row.add_theme_constant_override("separation", 4)
        sc.add_child(ts_tab_row)

        var ts_panels: Array = []

        var show_ts := func(tidx: int, tp: Array, tr: HBoxContainer) -> void:
            for i in tp.size():
                tp[i].visible = (i == tidx)
            for i in tr.get_child_count():
                tr.get_child(i).modulate = Color(1, 1, 0) if i == tidx else Color(0.6, 0.6, 0.6)

        for ts_idx in ts_list.size():
            var ts_data: Dictionary = ts_list[ts_idx]

            var short: String = ts_data.name.substr(9).trim_prefix("T_").trim_prefix("_").trim_prefix("T")
            if short.is_empty():
                short = "Principal"

            var ts_btn := Button.new()
            ts_btn.text = short
            ts_btn.add_theme_font_size_override("font_size", 32)
            ts_btn.pressed.connect(show_ts.bind(ts_idx, ts_panels, ts_tab_row))
            ts_tab_row.add_child(ts_btn)

            var panel := VBoxContainer.new()
            panel.add_theme_constant_override("separation", 8)
            panel.visible = (ts_idx == 0)
            sc.add_child(panel)
            ts_panels.append(panel)

            var info_lbl := Label.new()
            info_lbl.text = "clique num tile para zoom  ·  %dx%d, %dpx cada" % [ts_data.cols, ts_data.rows, ts_data.tile_size]
            info_lbl.add_theme_font_size_override("font_size", 22)
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
            desc_lbl.add_theme_font_size_override("font_size", 24)
            desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.6))
            desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            panel.add_child(desc_lbl)

            _tile_displays[ts_data.name] = {
                "info":    info_lbl,
                "preview": preview_rect,
                "desc":    desc_lbl,
                "data":    ts_data,
            }

            var tex: Texture2D = null
            if ResourceLoader.exists(ts_data.path):
                tex = load(ts_data.path) as Texture2D
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

                    var _bkey := "%s:%d,%d" % [ts_data.name, col, row]
                    var _bdesc: String = _TILE_DESCS.get(_bkey, _ZONE_TILE_DESCS.get("%d,%d" % [col, row], ""))
                    var is_blank: bool = _bdesc.begins_with("Transparente")
                    var coord_lbl := Label.new()
                    coord_lbl.text = "—" if is_blank else "%d,%d" % [col, row]
                    coord_lbl.add_theme_font_size_override("font_size", 20)
                    coord_lbl.add_theme_color_override(
                        "font_color",
                        Color(0.3, 0.3, 0.3) if is_blank else Color(0.6, 0.6, 0.6)
                    )
                    coord_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                    cell.add_child(coord_lbl)

    # Colisões tab
    # Highlight do primeiro stage por padrão
    if stage_row.get_child_count() > 0:
        stage_row.get_child(0).modulate = Color(1, 1, 0)

    var col_tab_btn := Button.new()
    col_tab_btn.text = "Colisões"
    col_tab_btn.add_theme_font_size_override("font_size", 34)
    col_tab_btn.pressed.connect(func(): show_section.call(1, -1))
    stage_row.add_child(col_tab_btn)

    var col_panel := VBoxContainer.new()
    col_panel.add_theme_constant_override("separation", 8)
    col_panel.visible = false
    _tiles_box.add_child(col_panel)
    _col_panel_ref = col_panel

    var col_mode_row := HBoxContainer.new()
    col_mode_row.add_theme_constant_override("separation", 6)
    col_panel.add_child(col_mode_row)
    var col_mode_lbl := Label.new()
    col_mode_lbl.text = "Modo:"
    col_mode_lbl.add_theme_font_size_override("font_size", 24)
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
        il.add_theme_font_size_override("font_size", 24)
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
    col_corner_lbl.add_theme_font_size_override("font_size", 24)
    col_corner_row.add_child(col_corner_lbl)
    for ci: Array in [["↗ topo-dir", 0], ["↖ topo-esq", 1], ["↘ base-dir", 2], ["↙ base-esq", 3]]:
        var cbtn := Button.new()
        cbtn.text = ci[0]
        cbtn.add_theme_font_size_override("font_size", 32)
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
        mbtn.add_theme_font_size_override("font_size", 32)
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
    glass_hdr.add_theme_font_size_override("font_size", 26)
    glass_hdr.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
    col_panel.add_child(glass_hdr)

    var glass_mode_row := HBoxContainer.new()
    glass_mode_row.add_theme_constant_override("separation", 6)
    col_panel.add_child(glass_mode_row)
    var glass_mode_lbl := Label.new()
    glass_mode_lbl.text = "Modo:"
    glass_mode_lbl.add_theme_font_size_override("font_size", 24)
    glass_mode_row.add_child(glass_mode_lbl)

    var gl_tex: Texture2D = null
    if ResourceLoader.exists("res://stages/stage_00/stage_00_glass.png"):
        gl_tex = load("res://stages/stage_00/stage_00_glass.png") as Texture2D
    var tile_t  := load("res://stages/stage_00/Stage_00T.png")      as Texture2D
    var spr_t   := load("res://characters/ranged/ZaelIdle.png")     as Texture2D

    # ── Boxes por modo ───────────────────────────────────────────────────────
    var gbox_lat  := VBoxContainer.new()
    var gbox_cor  := VBoxContainer.new()
    var gbox_gap  := VBoxContainer.new()
    var gbox_cmp  := VBoxContainer.new()
    var gbox_pan  := VBoxContainer.new()
    var gbox_fill := VBoxContainer.new()

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
    gcor_lbl.add_theme_font_size_override("font_size", 24)
    gcor_btn_row.add_child(gcor_lbl)
    for gci: Array in [["↗ topo-dir", 0], ["↖ topo-esq", 1], ["↘ base-dir", 2], ["↙ base-esq", 3]]:
        var gcbtn := Button.new()
        gcbtn.text = gci[0]
        gcbtn.add_theme_font_size_override("font_size", 32)
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
    gpan_norm_btn.add_theme_font_size_override("font_size", 28)
    gpan_norm_btn.modulate = Color(1.0, 1.0, 0.0)
    var gpan_mirr_btn := Button.new()
    gpan_mirr_btn.text = "Espelho"
    gpan_mirr_btn.add_theme_font_size_override("font_size", 28)
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

    # Centro (2,1)
    var gfill := _FillTileView.new()
    gfill.tile_tex  = tile_t
    gfill.glass_tex = gl_tex
    gfill.custom_minimum_size = Vector2(728.0, 252.0)
    gfill.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    gbox_fill.add_child(gfill)

    # Adicionar boxes ao col_panel (lateral visível por padrão)
    var glass_boxes: Array = [gbox_lat, gbox_cor, gbox_gap, gbox_cmp, gbox_pan, gbox_fill]
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
    for gml: Array in [["Lateral", 0], ["Cantos", 1], ["Gap", 2], ["Comparação", 3], ["Painel", 4], ["Centro (2,1)", 5]]:
        var gmbtn := Button.new()
        gmbtn.text = gml[0]
        gmbtn.add_theme_font_size_override("font_size", 32)
        var gidx: int = gml[1]
        gmbtn.pressed.connect(func(): _glass_sw.call(gidx))
        glass_mode_row.add_child(gmbtn)
        glass_mode_btns.append(gmbtn)
    glass_mode_btns[0].modulate = Color(1.0, 1.0, 0.0)

    # Plataformas tab
    var plat_tab_btn := Button.new()
    plat_tab_btn.text = "Plataformas"
    plat_tab_btn.add_theme_font_size_override("font_size", 34)
    plat_tab_btn.pressed.connect(func(): show_section.call(2, -1))
    stage_row.add_child(plat_tab_btn)

    var plat_panel := VBoxContainer.new()
    plat_panel.add_theme_constant_override("separation", 8)
    plat_panel.visible = false
    _tiles_box.add_child(plat_panel)
    _plat_panel_ref = plat_panel

    var pview := _PlatformView.new()
    pview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    pview.tile_tex = load(_TILESETS[0].path) as Texture2D

    var plat_ts_row := HBoxContainer.new()
    plat_ts_row.add_theme_constant_override("separation", 6)
    plat_panel.add_child(plat_ts_row)

    var plat_ts_lbl := Label.new()
    plat_ts_lbl.text = "Tileset:"
    plat_ts_lbl.add_theme_font_size_override("font_size", 24)
    plat_ts_row.add_child(plat_ts_lbl)

    for ts_data2 in _TILESETS:
        var ts_btn := Button.new()
        ts_btn.text = ts_data2.name.trim_suffix("T")
        ts_btn.add_theme_font_size_override("font_size", 32)
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
    mode_lbl.add_theme_font_size_override("font_size", 24)
    mode_row.add_child(mode_lbl)

    var ctrl_row := HBoxContainer.new()
    ctrl_row.add_theme_constant_override("separation", 20)

    var ceil_sub_visible: Array = []   # Array[Control] — preenchido após criação da sub-row
    var ceil_sub_btns: Array = []      # Array[Button]  — preenchido após criação dos sub-botões

    var mode_btns: Array = []
    var _sw := func(mkey: String, mlbl: String) -> void:
        pview.mode = mkey
        pview.set_dims(pview.rows, pview.cols)
        for b: Button in mode_btns:
            b.modulate = Color(1.0, 1.0, 0.0) if b.text == mlbl else Color(0.6, 0.6, 0.6)
        if ceil_sub_visible.size() > 0 and is_instance_valid(ceil_sub_visible[0]):
            (ceil_sub_visible[0] as Control).visible = mkey.begins_with("ceil_")

    for me: Array in [["Plataforma", "platform"], ["Sala", "room"], ["Piso+Plat", "floor_platform"], ["Piso+Abismo", "floor_platform_hole"], ["Buraco no Piso", "floor_hole"], ["Saliência", "foothold"], ["Teto", "ceil_flat"]]:
        var mbtn := Button.new()
        mbtn.text = me[0]
        mbtn.add_theme_font_size_override("font_size", 32)
        var mk: String = me[1]
        var ml: String = me[0]
        mbtn.pressed.connect(func():
            _sw.call(mk, ml)
            if mk.begins_with("ceil_"):
                for sb: Button in ceil_sub_btns:
                    sb.modulate = Color(1.0, 1.0, 0.0) if sb.text == "Reto" else Color(0.6, 0.6, 0.6))
        mode_row.add_child(mbtn)
        mode_btns.append(mbtn)
    mode_btns[0].modulate = Color(1.0, 1.0, 0.0)

    # Sub-row de teto (escondida até o modo "Teto" ser activado)
    var ceil_sub_row := HBoxContainer.new()
    ceil_sub_row.add_theme_constant_override("separation", 6)
    ceil_sub_row.visible = false
    var ceil_tipo_lbl := Label.new()
    ceil_tipo_lbl.text = "Tipo:"
    ceil_tipo_lbl.add_theme_font_size_override("font_size", 24)
    ceil_sub_row.add_child(ceil_tipo_lbl)
    var _sw_sub := func(sk: String, sl: String) -> void:
        _sw.call(sk, "Teto")
        for sb: Button in ceil_sub_btns:
            sb.modulate = Color(1.0, 1.0, 0.0) if sb.text == sl else Color(0.6, 0.6, 0.6)
    for sub: Array in [["Reto", "ceil_flat"], ["Escada", "ceil_step"], ["Buraco", "ceil_hole"], ["Plat", "ceil_platform"], ["Pit+Plat", "ceil_plat_pit"]]:
        var sbtn := Button.new()
        sbtn.text = sub[0]
        sbtn.add_theme_font_size_override("font_size", 32)
        var sk: String = sub[1]; var sl: String = sub[0]
        sbtn.pressed.connect(func(): _sw_sub.call(sk, sl))
        ceil_sub_row.add_child(sbtn)
        ceil_sub_btns.append(sbtn)
    ceil_sub_btns[0].modulate = Color(1.0, 1.0, 0.0)
    ceil_sub_visible.append(ceil_sub_row)
    plat_panel.add_child(ceil_sub_row)

    plat_panel.add_child(ctrl_row)

    var cols_lbl := Label.new()
    cols_lbl.text = "Cols: 3"
    cols_lbl.add_theme_font_size_override("font_size", 24)
    cols_lbl.custom_minimum_size = Vector2(80.0, 0.0)
    var cols_hb := HBoxContainer.new()
    cols_hb.add_theme_constant_override("separation", 4)
    var cols_m := Button.new()
    cols_m.text = "−"
    cols_m.add_theme_font_size_override("font_size", 24)
    cols_m.pressed.connect(func():
        if pview.cols > 1:
            pview.set_dims(pview.rows, pview.cols - 1)
            cols_lbl.text = "Cols: %d" % pview.cols)
    var cols_p := Button.new()
    cols_p.text = "+"
    cols_p.add_theme_font_size_override("font_size", 24)
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
    rows_lbl.add_theme_font_size_override("font_size", 24)
    rows_lbl.custom_minimum_size = Vector2(80.0, 0.0)
    var rows_hb := HBoxContainer.new()
    rows_hb.add_theme_constant_override("separation", 4)
    var rows_m := Button.new()
    rows_m.text = "−"
    rows_m.add_theme_font_size_override("font_size", 24)
    rows_m.pressed.connect(func():
        if pview.rows > 1:
            pview.set_dims(pview.rows - 1, pview.cols)
            rows_lbl.text = "Rows: %d" % pview.rows)
    var rows_p := Button.new()
    rows_p.text = "+"
    rows_p.add_theme_font_size_override("font_size", 24)
    rows_p.pressed.connect(func():
        if pview.rows < 8:
            pview.set_dims(pview.rows + 1, pview.cols)
            rows_lbl.text = "Rows: %d" % pview.rows)
    rows_hb.add_child(rows_m)
    rows_hb.add_child(rows_lbl)
    rows_hb.add_child(rows_p)
    ctrl_row.add_child(rows_hb)

    var mirror_btn := Button.new()
    mirror_btn.text = "Espelhar"
    mirror_btn.add_theme_font_size_override("font_size", 24)
    mirror_btn.pressed.connect(func():
        pview.mirror_hole = not pview.mirror_hole
        pview.queue_redraw())
    ctrl_row.add_child(mirror_btn)

    plat_panel.add_child(pview)
    pview.set_dims(2, 3)

    show_section.call(0, 0)

func _on_tile_input(event: InputEvent, col: int, row: int, ts_name: String) -> void:
    if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
        return
    if not _tile_displays.has(ts_name):
        return
    var d: Dictionary = _tile_displays[ts_name]
    var ts_data: Dictionary = d.data
    var _tile_key := "%s:%d,%d" % [ts_name, col, row]
    var _coord_key := "%d,%d" % [col, row]
    var _desc: String = _TILE_DESCS.get(_tile_key, _ZONE_TILE_DESCS.get(_coord_key, ""))
    var is_empty: bool = _desc.begins_with("Transparente")
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
        d.desc.text = _desc


# ── Sala de teste de batalha (seção BATALHA) ─────────────────────────────────
# Caixa fechada nas dimensões reais da sala do boss do Stage 00 (15×8 tiles de
# 64px; interior 832×384). Espelha o padrão de _MovWorld. Treino: player e boss
# com HP 99999. tile_tex deve ser setado ANTES do add_child (usado em _draw).
class _BossBattleWorld extends Node2D:
    const _TS      := 64.0
    const _SRC     := 32.0
    const _COLS    := 15
    const _ROWS    := 8
    const _FLOOR_Y := 448.0   # superfície do chão (topo) — coords locais
    const _WALL_L  := 64.0     # face interna parede esquerda
    const _WALL_R  := 896.0    # face interna parede direita
    const _MARGIN  := 80.0     # margem lateral da arena do boss

    var tile_tex: Texture2D = null
    var _player: CharacterBase = null
    var _boss: Node2D = null

    func _ready() -> void:
        texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        GameManager.active_character = "zael"
        GameManager.zael_selected_shot = "single"
        _build_room()
        _spawn_player()
        var cam := Camera2D.new()
        cam.global_position = Vector2(480.0, 256.0)  # centro da sala
        cam.zoom = Vector2(2.0, 2.0)                 # zoom 2.0 (igual ao jogo); SubViewport 1920×1080 → mostra 960×540 = sala inteira
        add_child(cam)

    func _build_room() -> void:
        _add_wall(Vector2(480.0, 480.0), Vector2(960.0, 64.0))  # chão
        _add_wall(Vector2(480.0, 32.0),  Vector2(960.0, 64.0))  # teto
        _add_wall(Vector2(32.0, 256.0),  Vector2(64.0, 512.0))  # parede esq
        _add_wall(Vector2(928.0, 256.0), Vector2(64.0, 512.0))  # parede dir

    func _add_wall(center: Vector2, size: Vector2) -> void:
        var body := StaticBody2D.new()
        body.collision_layer = 1
        body.collision_mask = 0
        var cs := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = size
        cs.shape = shape
        cs.position = center
        body.add_child(cs)
        add_child(body)

    func _spawn_player() -> void:
        if is_instance_valid(_player):
            _player.queue_free()
        var scene := load("res://characters/ranged/zael.tscn") as PackedScene
        if scene == null:
            return
        _player = scene.instantiate() as CharacterBase
        _player.add_to_group("player")
        add_child(_player)
        _player.global_position = Vector2(220.0, _FLOOR_Y - 90.0)
        _player.max_hp = 99999
        _player.current_hp = 99999
        _player.died.connect(func(): call_deferred("_spawn_player"))
        if is_instance_valid(_boss):
            (_boss as BossBase).player = _player

    func load_boss(idx: int) -> void:
        if is_instance_valid(_boss):
            _boss.queue_free()
            _boss = null
        if idx < 0 or idx >= ImgDebug._BOSS_BATTLE.size():
            return
        var scene := load(ImgDebug._BOSS_BATTLE[idx].path) as PackedScene
        if scene == null:
            return
        var boss := scene.instantiate() as BossBase
        if boss == null:
            push_error("_BossBattleWorld: cena no índice %d não é BossBase" % idx)
            return
        add_child(boss)
        boss.global_position = Vector2(680.0, _FLOOR_Y - 120.0)
        boss.player      = _player
        boss.arena_left  = _WALL_L + _MARGIN
        boss.arena_right = _WALL_R - _MARGIN
        boss.arena_floor = _FLOOR_Y
        boss.max_hp      = 99999
        boss.current_hp  = 99999
        boss.state       = BossBase.State.COMBAT
        _boss = boss

    func _draw() -> void:
        # Fundo escuro (igual ao boss room background do stage) — sempre desenhado
        draw_rect(Rect2(0.0, 0.0, _COLS * _TS, _ROWS * _TS), Color(0.05, 0.05, 0.12))
        if tile_tex == null:
            return
        # Caixa fechada — mapeamento canônico de _draw_boss_room (sem abertura de porta)
        var ts := _TS
        var src := _SRC
        for row in _ROWS:
            for col in _COLS:
                var is_l := col == 0
                var is_r := col == _COLS - 1
                var is_t := row == 0
                var is_b := row == _ROWS - 1
                if not (is_l or is_r or is_t or is_b):
                    continue
                var tile: Vector2i
                var tx := 0.0
                var ty := 0.0
                if   is_t and is_l: tile = Vector2i(3, 1); tx =  src; ty =  src
                elif is_t and is_r: tile = Vector2i(2, 2); tx = -src; ty =  src
                elif is_b and is_l: tile = Vector2i(2, 0); tx =  src; ty = -src
                elif is_b and is_r: tile = Vector2i(1, 1); tx = -src; ty = -src
                elif is_t:          tile = Vector2i(1, 2);            ty =  src
                elif is_b:          tile = Vector2i(3, 0);            ty = -src
                elif is_l:          tile = Vector2i(3, 2); tx =  src
                else:               tile = Vector2i(1, 0); tx = -src
                var dx := col * ts + tx
                var dy := row * ts + ty
                draw_texture_rect_region(tile_tex,
                    Rect2(dx, dy, ts, ts),
                    Rect2(tile.x * src, tile.y * src, src, src))


# ── View da seção BATALHA: tela de seleção (hub) + SubViewport da sala ────────
class _BossBattleView extends Control:
    signal exit_requested

    var _grid_box: VBoxContainer = null
    var _svc: SubViewportContainer = null
    var _world: ImgDebug._BossBattleWorld = null
    var _in_battle := false

    func _ready() -> void:
        set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        _build_selection()
        show_selection()

    func _build_selection() -> void:
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 12)
        add_child(box)
        box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        _grid_box = box

        var title := Label.new()
        title.text = "Escolha o boss  (ESC/Enter na sala = voltar aqui)"
        title.add_theme_font_size_override("font_size", 34)
        title.add_theme_color_override("font_color", Color(0.85, 0.8, 1.0))
        box.add_child(title)

        var grid := GridContainer.new()
        grid.columns = 4
        grid.add_theme_constant_override("h_separation", 8)
        grid.add_theme_constant_override("v_separation", 8)
        box.add_child(grid)
        for i in ImgDebug._BOSS_BATTLE.size():
            var btn := Button.new()
            btn.text = ImgDebug._BOSS_BATTLE[i].name
            btn.add_theme_font_size_override("font_size", 32)
            btn.custom_minimum_size = Vector2(240.0, 56.0)
            btn.pressed.connect(_enter_battle.bind(i))
            grid.add_child(btn)

        var exit_btn := Button.new()
        exit_btn.text = "Sair"
        exit_btn.add_theme_font_size_override("font_size", 32)
        exit_btn.custom_minimum_size = Vector2(160.0, 48.0)
        exit_btn.pressed.connect(func(): exit_requested.emit())
        box.add_child(exit_btn)

    func _ensure_world() -> void:
        if _svc != null:
            return
        _svc = SubViewportContainer.new()
        _svc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        _svc.stretch = true
        add_child(_svc)
        var svp := SubViewport.new()
        svp.size = Vector2i(1920, 1080)  # com zoom 2.0 da câmera, mostra 960×540 = sala inteira
        svp.handle_input_locally = false
        _svc.add_child(svp)
        var w := ImgDebug._BossBattleWorld.new()
        w.tile_tex = load("res://stages/stage_00/Stage_00T.png") as Texture2D
        svp.add_child(w)
        _world = w

    func _enter_battle(idx: int) -> void:
        _ensure_world()
        _world.load_boss(idx)
        _grid_box.visible = false
        _svc.visible = true
        _in_battle = true
        get_viewport().gui_release_focus()

    func show_selection() -> void:
        _in_battle = false
        if _svc != null:
            _svc.visible = false
        if _grid_box != null:
            _grid_box.visible = true

    func _unhandled_key_input(event: InputEvent) -> void:
        if not _in_battle:
            return
        if event is InputEventKey and event.pressed and not event.echo:
            var kc: int = (event as InputEventKey).keycode
            if kc == KEY_ESCAPE or kc == KEY_ENTER or kc == KEY_KP_ENTER:
                show_selection()
                get_viewport().set_input_as_handled()
