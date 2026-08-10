extends Zael
class_name Kawagael

const _ZAEL_DIR := "res://characters/ranged/"
const _KAWA_DIR := "res://characters/ranged/kawagael/"

## Carrega todos os *.png de `dir` (ordem alfabética) como frames de `anim_name`
## em `frames`. Formato PixelLab: um Texture2D completo por frame (sem stitching).
## Se `dir` não existir, emite push_warning e retorna anim vazia (0 frames).
func _add_anim_from_frames(frames: SpriteFrames, anim_name: String,
        dir: String, speed: float, loop: bool) -> void:
    frames.add_animation(anim_name)
    frames.set_animation_loop(anim_name, loop)
    frames.set_animation_speed(anim_name, speed)
    var da := DirAccess.open(dir)
    if da == null:
        push_warning("kawagael: missing anim dir %s" % dir)
        return
    var files: Array[String] = []
    for f in da.get_files():
        if f.ends_with(".png"):
            files.append(f)
    files.sort()  # f00.png, f01.png, ..., fNN.png ordenam alfabeticamente
    for f in files:
        var tex := _load_frame_texture(dir + f)
        if tex:
            frames.add_frame(anim_name, tex)

## `load()` requer asset importado (res://). Este helper aceita res:// e user://,
## caindo em Image.load para paths runtime — necessário pra testes com fixtures
## geradas em user://.
static func _load_frame_texture(path: String) -> Texture2D:
    if path.begins_with("res://"):
        var t := load(path) as Texture2D
        if t: return t
    var img := Image.new()
    if img.load(path) == OK:
        return ImageTexture.create_from_image(img)
    return null

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
