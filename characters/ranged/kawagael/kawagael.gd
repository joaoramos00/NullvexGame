extends Zael
class_name Kawagael

const _ANIMS_DIR := "res://characters/ranged/kawagael/anims/"

# (anim_name, speed_fps, loop, frame_count) — configuração de todas as anims.
# frame_count é EXPLÍCITO (não descoberto via DirAccess) porque em builds
# exportadas o Godot não expõe get_files() em res:// — retorna vazio no PCK.
# Ordem dos frames: f00.png, f01.png, ..., f{count-1:02d}.png.
const _ANIM_SPECS := [
    ["idle",        8.0,  true,   8],
    # run_start em 20fps: 4f / 20 = 200ms — pernas engatam junto com movimento.
    ["run_start",  20.0, false,   4],
    # run em 16fps: leg cycle mais rápido, sensação de pé firme no chão.
    ["run",        16.0,  true,  12],
    # run_stop em 18fps: freada rápida, sem enrolar.
    ["run_stop",   18.0, false,   4],
    ["jump",       10.0, false,   4],
    ["shoot_1",    12.0, false,   4],
    ["shoot_2",    12.0, false,   4],
    ["shoot_3",    12.0, false,   4],
    ["dash",       12.0, false,   1],
    ["wall_slide",  6.0,  true,   4],
    ["hurt",       15.0, false,   4],
    ["death",      10.0, false,   6],
    ["run_shoot",  16.0,  true,   6],
    ["jump_shoot", 10.0,  true,   4],
    ["dash_shoot", 12.0,  true,   1],
]

# FSM de run: idle → starting → cycle → stopping → idle
# - idle:     parado, sem input horizontal
# - starting: tocando run_start (transição idle→run)
# - cycle:    tocando run (loop principal)
# - stopping: tocando run_stop (freada, volta pra idle)
var _run_phase: String = "idle"

## Testing helper: replica o passo da FSM que _update_animation faria,
## sem exigir mundo físico. `on_floor` e `moving` substituem is_on_floor()
## e (velocity.x != 0.0) respectivamente.
func _advance_run_fsm_for_testing(on_floor: bool, moving: bool) -> void:
    _advance_run_fsm(on_floor, moving)

## Chamado por _on_animation_finished quando "run_start" acaba.
func _notify_run_start_finished() -> void:
    if _run_phase == "starting":
        _run_phase = "cycle"

## Chamado por _on_animation_finished quando "run_stop" acaba.
func _notify_run_stop_finished() -> void:
    if _run_phase == "stopping":
        _run_phase = "idle"

func _advance_run_fsm(on_floor: bool, moving: bool) -> void:
    if not on_floor:
        return  # ar → outras rotinas de anim tomam conta
    match _run_phase:
        "idle":
            if moving:
                _run_phase = "starting"
        "starting":
            pass  # aguarda _notify_run_start_finished
        "cycle":
            if not moving:
                _run_phase = "stopping"
        "stopping":
            if moving:
                _run_phase = "starting"

func _on_animation_finished() -> void:
    super._on_animation_finished()
    # FSM de run: transiciona quando as anims não-loop terminam.
    match _sprite.animation:
        "run_start":
            _notify_run_start_finished()
        "run_stop":
            _notify_run_stop_finished()

## Override do Zael. Delegamos ao super para todos os estados de exceção
## (dead/hurt/jump_squat/dashing/no-chão/shooting). Só o bloco "no chão,
## andando/parado, sem tiro" é a FSM nova de run.
func _update_animation() -> void:
    # Reset da FSM quando saímos do chão ou entramos num estado que não
    # tem run: no próximo pouso sem input começamos em "idle" naturalmente.
    if not is_on_floor() or _is_shooting or _is_dashing \
            or is_dead or _is_hurt or _jump_squat_timer >= 0.0:
        _run_phase = "idle"
        super._update_animation()
        return

    # A partir daqui: no chão, sem hurt/dead, sem jump_squat, sem dash, sem tiro.
    # Cuidamos manualmente da orientação (facing_right ↔ flip_h) e da FSM.
    _sprite.flip_h = not facing_right

    var moving := velocity.x != 0.0
    _advance_run_fsm(true, moving)

    match _run_phase:
        "starting":
            if _sprite.animation != "run_start":
                _sprite.play("run_start")
        "cycle":
            if _sprite.animation != "run":
                _sprite.play("run")
        "stopping":
            if _sprite.animation != "run_stop":
                _sprite.play("run_stop")
        "idle":
            if _sprite.animation != "idle":
                _sprite.play("idle")

## Carrega N frames de `dir` como `dir/f{i:02d}.png` — usado em produção.
## Explicit-count porque DirAccess.get_files() em res:// retorna vazio em
## builds exportadas do Godot (o PCK não expõe listagem de arquivos).
func _add_anim_by_count(frames: SpriteFrames, anim_name: String,
        dir: String, count: int, speed: float, loop: bool) -> void:
    frames.add_animation(anim_name)
    frames.set_animation_loop(anim_name, loop)
    frames.set_animation_speed(anim_name, speed)
    for i in count:
        var path := dir + "f%02d.png" % i
        var tex := _load_frame_texture(path)
        if tex:
            frames.add_frame(anim_name, tex)
        else:
            push_warning("kawagael: frame missing %s" % path)

## Carrega todos os *.png de `dir` (ordem alfabética) como frames de `anim_name`
## em `frames`. Formato PixelLab: um Texture2D completo por frame (sem stitching).
## Usado só em TESTES com fixtures em user:// (onde DirAccess funciona).
## Em produção, prefira _add_anim_by_count — DirAccess retorna vazio no PCK.
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

func _setup_sprite_frames() -> void:
    var frames := SpriteFrames.new()
    # A anim padrão "default" precisa sair — se sobrar, aparece em get_animation_names
    # e o AnimatedSprite2D pode cair nela quando trocamos. Zael base já não a tem.
    if frames.has_animation("default"):
        frames.remove_animation("default")
    for spec in _ANIM_SPECS:
        var anim_name: String = spec[0]
        var speed: float      = spec[1]
        var loop: bool        = spec[2]
        var count: int        = spec[3]
        _add_anim_by_count(frames, anim_name, _ANIMS_DIR + anim_name + "/",
                count, speed, loop)
    _sprite.sprite_frames = frames
    _sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _sprite.play("idle")
