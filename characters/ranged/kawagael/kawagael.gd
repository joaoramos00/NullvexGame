extends Zael
class_name Kawagael

const _ZAEL_DIR := "res://characters/ranged/"
const _KAWA_DIR := "res://characters/ranged/kawagael/"

func _add_anim(frames: SpriteFrames, anim: String, tex: Texture2D,
        start: int, count: int, speed: float, loop: bool) -> void:
    frames.add_animation(anim)
    frames.set_animation_loop(anim, loop)
    frames.set_animation_speed(anim, speed)
    for i in range(start, start + count):
        var at := AtlasTexture.new()
        at.atlas = tex
        at.filter_clip = true
        at.region = Rect2(i * _FRAME_W, 0, _FRAME_W, _FRAME_H)
        frames.add_frame(anim, at)

func _setup_sprite_frames() -> void:
    var idle_tex       := load(_ZAEL_DIR + "ZaelIdle.png")       as Texture2D
    var run_tex        := load(_KAWA_DIR + "KawagaelRun.png")    as Texture2D
    var jump_tex       := load(_ZAEL_DIR + "ZaelJump_new.png")   as Texture2D
    var shoot_tex      := load(_ZAEL_DIR + "ZaelAtirando.png")   as Texture2D
    var dash_tex       := load(_ZAEL_DIR + "ZaelDash.png")       as Texture2D
    var wall_tex       := load(_ZAEL_DIR + "ZaelWallSlide.png")  as Texture2D
    var hurt_tex       := load(_ZAEL_DIR + "ZaelHurt.png")       as Texture2D
    var death_tex      := load(_ZAEL_DIR + "ZaelDeath.png")      as Texture2D
    var run_shoot_tex  := load(_ZAEL_DIR + "ZaelRunShoot.png")   as Texture2D
    var jump_shoot_tex := load(_ZAEL_DIR + "ZaelJumpShoot.png")  as Texture2D
    var dash_shoot_tex := load(_ZAEL_DIR + "ZaelDashShoot.png")  as Texture2D

    # A corrida do Kawagael ainda é placeholder (5/8 frames). A contagem sai da
    # largura do sheet, então passa a 8 automaticamente quando regenerarmos.
    var run_count := int(run_tex.get_width() / _FRAME_W)

    var frames := SpriteFrames.new()
    _add_anim(frames, "idle",       idle_tex,       0, 8,         8.0, true)
    _add_anim(frames, "run",        run_tex,        0, run_count, 10.0, true)
    _add_anim(frames, "jump",       jump_tex,       0, 4,         10.0, false)
    _add_anim(frames, "shoot_1",    shoot_tex,      4, 1,         10.0, false)
    _add_anim(frames, "shoot_2",    shoot_tex,      4, 2,         10.0, false)
    _add_anim(frames, "shoot_3",    shoot_tex,      4, 3,         10.0, false)
    _add_anim(frames, "dash",       dash_tex,       0, 2,         12.0, false)
    _add_anim(frames, "wall_slide", wall_tex,       0, 2,          6.0, true)
    _add_anim(frames, "hurt",       hurt_tex,       0, 3,         15.0, false)
    _add_anim(frames, "death",      death_tex,      0, 6,         10.0, false)
    _add_anim(frames, "run_shoot",  run_shoot_tex,  0, 9,         10.0, true)
    _add_anim(frames, "jump_shoot", jump_shoot_tex, 0, 2,         10.0, true)
    _add_anim(frames, "dash_shoot", dash_shoot_tex, 0, 2,         12.0, true)

    _sprite.sprite_frames = frames
    _sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _sprite.play("idle")
