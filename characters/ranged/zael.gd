extends CharacterBase
class_name Zael

const CHARGE_L2_THRESHOLD := 0.4
const CHARGE_L3_THRESHOLD := 1.2

const BULLET_DAMAGE := [0, 1, 2, 3]
const BULLET_SCALE := [
    Vector2.ZERO,
    Vector2(1.0, 1.0),
    Vector2(1.6, 1.6),
    Vector2(2.5, 2.5),
]

const _BULLET_SCENE := preload("res://characters/ranged/zael_bullet.tscn")
const _FIRE_WAVE    := preload("res://characters/ranged/player_fire_wave.gd")
const _WIND_GUST    := preload("res://characters/ranged/player_wind_gust.gd")
const _ICE_ARROW    := preload("res://characters/ranged/player_ice_arrow.gd")
const _SHADOW_KUNAI := preload("res://characters/ranged/player_shadow_kunai.gd")
const _STONE_SHARD  := preload("res://characters/ranged/player_stone_shard.gd")
const _SOLAR_CORONA := preload("res://characters/ranged/player_solar_corona.gd")

const _FRAME_W := 68
const _FRAME_H := 68
const _ROW_RIGHT := 0

const _SPAWN_OFFSET_Y := 24.0
const _SPAWN_OFFSET_X := [0.0, 60.0, 65.0, 85.0]  # por nível: L1/L2/L3

# Absorção: bolinhas partem do círculo externo e espiralam para o centro
const _CHARGE_SPEED    := 0.6
const _CHARGE_TURNS    := 1.2
const _CHARGE_CENTER_Y := 35.0

const _CHARGE_COUNT_L2     := 6
const _CHARGE_OUTER_L2     := 60.0
const _CHARGE_SIZE_L2      := 5.0
const _CHARGE_BIG_COUNT_L2 := 3
const _CHARGE_BIG_SIZE_L2  := 11.0
const _CHARGE_COLOR_L2     := Color(1.0, 0.88, 0.2, 0.85)

const _CHARGE_COUNT_L3     := 8
const _CHARGE_OUTER_L3     := 72.0
const _CHARGE_SIZE_L3      := 7.0
const _CHARGE_BIG_COUNT_L3 := 4
const _CHARGE_BIG_SIZE_L3  := 14.0
const _CHARGE_COLOR_L3     := Color(1.0, 0.22, 0.18, 0.85)

const _CHARGE_BIG_SPEED := 0.4  # bolinhas grandes mais lentas

const HURT_DURATION       := 0.3
const _SHOOT_DURATIONS    := [0.1, 0.2, 0.3]  # duração de shoot_1/2/3 a 10fps
const _SQUAT_DURATION     := 0.1
const _DASH_JUMP_BUFFER   := 0.35  # janela após o dash terminar para ainda fazer dash-jump
const _DASH_JUMP_SPEED    := 460.0 # velocidade horizontal do dash-jump (reduzida; < DASH_SPEED=720)
const _JUMP_BUFFER_TIME   := 0.25  # buffer de input: pulo pressionado antes do dash ainda dispara

var _charge_timer: float = 0.0
var _is_charging: bool = false
var _last_charge_level: int = 1   # p/ tocar o "ping" ao subir de nível de carga
var _is_shooting: bool = false
var _jump_squat_timer: float = -1.0
var _dash_jump: bool = false
var _dash_jump_dir: float = 0.0
var _was_dashing_timer: float = 0.0
var _landing_timer: float = 0.0
var _is_hurt: bool = false
var _hurt_timer: float = 0.0
var _shoot_timer: float = -1.0
var _was_on_floor: bool = true
var _spiral_phases: Array = []
var _spiral_phases_big: Array = []
var _draw_orbs: Array = []  # [{pos, color, radius}]
var _orb_canvas: Node2D    # filho com z_index alto para desenhar por cima

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    super._ready()
    _setup_sprite_frames()
    _sprite.animation_finished.connect(_on_animation_finished)
    damaged.connect(_on_damaged)
    for i in _CHARGE_COUNT_L3:
        _spiral_phases.append(randf())
    for i in _CHARGE_BIG_COUNT_L3:
        _spiral_phases_big.append(randf())
    _orb_canvas = Node2D.new()
    _orb_canvas.z_index = 10
    add_child(_orb_canvas)
    _orb_canvas.draw.connect(_on_orb_canvas_draw)

func _on_orb_canvas_draw() -> void:
    for d in _draw_orbs:
        _orb_canvas.draw_circle(d.pos, d.radius, d.color)

func _setup_sprite_frames() -> void:
    var frames := SpriteFrames.new()
    var idle_tex      := load("res://characters/ranged/ZaelIdle.png")      as Texture2D
    var run_tex       := load("res://characters/ranged/ZaelCorrendo.png")  as Texture2D
    var jump_tex      := load("res://characters/ranged/ZaelJump_new.png")  as Texture2D
    var shoot_tex     := load("res://characters/ranged/ZaelAtirando.png")  as Texture2D
    var dash_tex      := load("res://characters/ranged/ZaelDash.png")      as Texture2D
    var wall_tex      := load("res://characters/ranged/ZaelWallSlide.png") as Texture2D
    var hurt_tex      := load("res://characters/ranged/ZaelHurt.png")      as Texture2D
    var death_tex     := load("res://characters/ranged/ZaelDeath.png")     as Texture2D
    var run_shoot_tex := load("res://characters/ranged/ZaelRunShoot.png")  as Texture2D
    var fw := _FRAME_W
    var fh := _FRAME_H

    frames.add_animation("idle")
    frames.set_animation_loop("idle", true)
    frames.set_animation_speed("idle", 8.0)
    for i in 8:
        var at := AtlasTexture.new()
        at.atlas = idle_tex
        at.filter_clip = true
        at.region = Rect2(i * fw, 0, fw, fh)
        frames.add_frame("idle", at)

    frames.add_animation("run")
    frames.set_animation_loop("run", true)
    frames.set_animation_speed("run", 10.0)
    for i in 6:
        var at := AtlasTexture.new()
        at.atlas = run_tex
        at.filter_clip = true
        at.region = Rect2(i * fw, 0, fw, fh)
        frames.add_frame("run", at)

    frames.add_animation("jump")
    frames.set_animation_loop("jump", false)
    frames.set_animation_speed("jump", 10.0)
    for i in 4:
        var at := AtlasTexture.new()
        at.atlas = jump_tex
        at.filter_clip = true
        at.region = Rect2(i * fw, 0, fw, fh)
        frames.add_frame("jump", at)

    var shoot_ranges := [[4, 4], [4, 5], [4, 6]]
    for lvl in 3:
        var anim := "shoot_%d" % (lvl + 1)
        frames.add_animation(anim)
        frames.set_animation_loop(anim, false)
        frames.set_animation_speed(anim, 10.0)
        for i in range(shoot_ranges[lvl][0], shoot_ranges[lvl][1] + 1):
            var at := AtlasTexture.new()
            at.atlas = shoot_tex
            at.filter_clip = true
            at.region = Rect2(i * fw, 0, fw, fh)
            frames.add_frame(anim, at)

    frames.add_animation("dash")
    frames.set_animation_loop("dash", false)
    frames.set_animation_speed("dash", 12.0)
    for i in 2:
        var at := AtlasTexture.new()
        at.atlas = dash_tex
        at.filter_clip = true
        at.region = Rect2(i * fw, 0, fw, fh)
        frames.add_frame("dash", at)

    frames.add_animation("wall_slide")
    frames.set_animation_loop("wall_slide", true)
    frames.set_animation_speed("wall_slide", 6.0)
    for i in 2:
        var at := AtlasTexture.new()
        at.atlas = wall_tex
        at.filter_clip = true
        at.region = Rect2(i * fw, 0, fw, fh)
        frames.add_frame("wall_slide", at)

    frames.add_animation("hurt")
    frames.set_animation_loop("hurt", false)
    frames.set_animation_speed("hurt", 15.0)
    for i in 3:
        var at := AtlasTexture.new()
        at.atlas = hurt_tex
        at.filter_clip = true
        at.region = Rect2(i * fw, 0, fw, fh)
        frames.add_frame("hurt", at)

    frames.add_animation("death")
    frames.set_animation_loop("death", false)
    frames.set_animation_speed("death", 10.0)
    for i in 6:
        var at := AtlasTexture.new()
        at.atlas = death_tex
        at.filter_clip = true
        at.region = Rect2(i * fw, 0, fw, fh)
        frames.add_frame("death", at)

    frames.add_animation("run_shoot")
    frames.set_animation_loop("run_shoot", true)
    frames.set_animation_speed("run_shoot", 10.0)
    for i in 9:
        var at := AtlasTexture.new()
        at.atlas = run_shoot_tex
        at.filter_clip = true
        at.region = Rect2(i * fw, 0, fw, fh)
        frames.add_frame("run_shoot", at)

    var jump_shoot_tex := load("res://characters/ranged/ZaelJumpShoot.png") as Texture2D
    frames.add_animation("jump_shoot")
    frames.set_animation_loop("jump_shoot", true)
    frames.set_animation_speed("jump_shoot", 10.0)
    for i in 2:
        var at := AtlasTexture.new()
        at.atlas = jump_shoot_tex
        at.filter_clip = true
        at.region = Rect2(i * fw, 0, fw, fh)
        frames.add_frame("jump_shoot", at)

    var dash_shoot_tex := load("res://characters/ranged/ZaelDashShoot.png") as Texture2D
    frames.add_animation("dash_shoot")
    frames.set_animation_loop("dash_shoot", true)
    frames.set_animation_speed("dash_shoot", 12.0)
    for i in 2:
        var at := AtlasTexture.new()
        at.atlas = dash_shoot_tex
        at.filter_clip = true
        at.region = Rect2(i * fw, 0, fw, fh)
        frames.add_frame("dash_shoot", at)

    _sprite.sprite_frames = frames
    _sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _sprite.play("idle")

func _handle_jump() -> void:
    # Wall-jump tem PRIORIDADE: funciona mesmo durante o dash-jump (encerra o dash-jump).
    if Input.is_action_just_pressed("jump") and _can_wall_jump():
        _dash_jump = false
        _apply_wall_jump()
        return
    if _jump_squat_timer >= 0.0 or _dash_jump:
        return
    if Input.is_action_just_pressed("jump"):
        if is_on_floor() or _coyote_timer > 0.0:
            _jump_squat_timer = 0.0
            if not _is_dashing:
                _jump_buffer_timer = 0.0
            _coyote_timer = 0.0

func _handle_movement(delta: float) -> void:
    if _dash_jump:
        if is_on_floor():
            velocity.x = _DASH_JUMP_SPEED * _dash_jump_dir
        else:
            var dir := Input.get_axis("move_left", "move_right")
            if dir != 0.0:
                velocity.x = dir * _DASH_JUMP_SPEED
        return
    super._handle_movement(delta)

func _physics_process(delta: float) -> void:
    if _jump_squat_timer >= 0.0:
        _jump_squat_timer += delta
        if _jump_squat_timer >= _SQUAT_DURATION:
            velocity.y = JUMP_VELOCITY
            _jump_squat_timer = -1.0
            AudioManager.play_sfx(AudioLibrary.sfx_jump)
    # Buffer de input: registra que pulo foi pressionado recentemente
    if Input.is_action_just_pressed("jump"):
        _jump_buffer_timer = _JUMP_BUFFER_TIME
    elif _jump_buffer_timer > 0.0:
        _jump_buffer_timer = max(0.0, _jump_buffer_timer - delta)
    # Dispara dash-jump se pulo foi pressionado (agora ou no buffer) com dash ativo/recente
    # _jump_squat_timer pode estar ativo (press simultâneo): cancelamos o squat normal
    if _jump_buffer_timer > 0.0 and not _dash_jump:
        if _is_dashing or (_was_dashing_timer > 0.0 and (is_on_floor() or _coyote_timer > 0.0)):
            _jump_squat_timer = -1.0
            _dash_jump = true
            _dash_jump_dir = _dash_direction
            _is_dashing = false
            _was_dashing_timer = 0.0
            _jump_buffer_timer = 0.0
            velocity.y = JUMP_VELOCITY
            AudioManager.play_sfx(AudioLibrary.sfx_jump)
    if _is_dashing:
        _was_dashing_timer = _DASH_JUMP_BUFFER
    elif _was_dashing_timer > 0.0:
        if is_on_floor() or _coyote_timer > 0.0:
            _was_dashing_timer = max(0.0, _was_dashing_timer - delta)
        else:
            _was_dashing_timer = 0.0
    super._physics_process(delta)
    if is_dead:
        return
    var just_landed: bool = is_on_floor() and not _was_on_floor
    _was_on_floor = is_on_floor()
    if just_landed:
        _landing_timer = 0.15
        _dash_jump = false
    elif is_on_floor():
        _dash_jump = false
    elif is_on_wall():
        _dash_jump = false  # encostou na parede no ar → encerra o dash-jump (libera wall-slide/wall-jump)
    if _landing_timer > 0.0:
        _landing_timer = max(0.0, _landing_timer - delta)
    _handle_shooting(delta)
    if _shoot_timer > 0.0:
        _shoot_timer -= delta
        if _shoot_timer <= 0.0:
            _shoot_timer = -1.0
            _is_shooting = false
    if _is_hurt:
        _hurt_timer += delta
        if _hurt_timer >= HURT_DURATION:
            _is_hurt = false
    _update_charge_effect(delta)
    _update_animation()

func _handle_shooting(delta: float) -> void:
    if is_dead:
        return
    if GameManager.selected_boss_ability != "" \
            and Input.is_action_just_pressed("attack"):
        if _use_special_ability():
            _is_shooting = true
            _shoot_timer = _SHOOT_DURATIONS[0]
            _sprite.play("shoot_1")
        return
    if Input.is_action_just_pressed("attack"):
        _is_charging = true
        _last_charge_level = 1
    if _is_charging:
        _charge_timer += delta
        var lvl := _charge_level()
        if lvl > _last_charge_level:
            _last_charge_level = lvl
            AudioManager.play_sfx(AudioLibrary.sfx_charge_ready)
    if Input.is_action_just_released("attack") and _is_charging:
        _fire(_charge_level())
        _is_charging = false
        _charge_timer = 0.0

func _charge_level() -> int:
    var level := get_charge_level(_charge_timer)
    if not GameManager.zael_armor.get("arms", false):
        level = mini(level, 2)
    return level

func _update_charge_effect(delta: float) -> void:
    _draw_orbs.clear()
    var level := _charge_level()
    if not _is_charging or level < 2:
        _orb_canvas.queue_redraw()
        return

    var count   := _CHARGE_COUNT_L2 if level == 2 else _CHARGE_COUNT_L3
    var outer_r := _CHARGE_OUTER_L2 if level == 2 else _CHARGE_OUTER_L3
    var size    := _CHARGE_SIZE_L2  if level == 2 else _CHARGE_SIZE_L3
    var col     := _CHARGE_COLOR_L2 if level == 2 else _CHARGE_COLOR_L3

    for i in count:
        _spiral_phases[i] = fmod(_spiral_phases[i] + _CHARGE_SPEED * delta, 1.0)
        var t: float = _spiral_phases[i]
        var angle := (TAU / count) * i + t * TAU * _CHARGE_TURNS
        var r := lerpf(outer_r, 0.0, t)
        _draw_orbs.append({
            "pos":    Vector2(cos(angle) * r, sin(angle) * r + _CHARGE_CENTER_Y),
            "color":  Color(col.r, col.g, col.b, col.a * (1.0 - t * t)),
            "radius": size,
        })

    var big_count := _CHARGE_BIG_COUNT_L2 if level == 2 else _CHARGE_BIG_COUNT_L3
    var big_size  := _CHARGE_BIG_SIZE_L2  if level == 2 else _CHARGE_BIG_SIZE_L3
    for i in big_count:
        _spiral_phases_big[i] = fmod(_spiral_phases_big[i] + _CHARGE_BIG_SPEED * delta, 1.0)
        var t: float = _spiral_phases_big[i]
        var angle := (TAU / big_count) * i + t * TAU * _CHARGE_TURNS
        var r := lerpf(outer_r * 1.1, 0.0, t)
        _draw_orbs.append({
            "pos":    Vector2(cos(angle) * r, sin(angle) * r + _CHARGE_CENTER_Y),
            "color":  Color(col.r, col.g, col.b, col.a * 0.7 * (1.0 - t * t)),
            "radius": big_size,
        })

    _orb_canvas.queue_redraw()

func _on_animation_finished() -> void:
    match _sprite.animation:
        "shoot_1", "shoot_2", "shoot_3":
            _is_shooting = false
            _shoot_timer = -1.0
        "hurt":
            _is_hurt = false
        "death":
            died.emit()

func _on_damaged(_amount: int) -> void:
    if is_dead:
        return
    _is_hurt = true
    _hurt_timer = 0.0
    _sprite.play("hurt")

func _play_death_animation() -> void:
    _sprite.play("death")

func _update_animation() -> void:
    if not _is_shooting and not is_dead and not _is_hurt:
        _sprite.flip_h = not facing_right

    if is_dead:
        pass  # animação death não deve ser interrompida
    elif _is_hurt:
        pass  # animação hurt não deve ser interrompida
    elif _jump_squat_timer >= 0.0:
        if not _is_shooting:
            _sprite.stop()
            _sprite.animation = "jump"
            _sprite.frame = 0 if _jump_squat_timer < _SQUAT_DURATION * 0.5 else 1
    elif _is_dashing:
        if _is_shooting:
            _sprite.play("dash_shoot")
        else:
            _sprite.play("dash")
    elif not is_on_floor():
        if _is_wall_sliding:
            # Sprite único (frame 1) + encarando o lado OPOSTO à parede (estilo MMX).
            _sprite.stop()
            _sprite.animation = "wall_slide"
            _sprite.frame = 0
            _sprite.flip_h = _wall_normal.x < 0.0
        elif _is_shooting:
            if _sprite.animation not in ["shoot_1", "shoot_2", "shoot_3"]:
                _sprite.play("jump_shoot")
        else:
            _sprite.stop()
            _sprite.animation = "jump"
            _sprite.frame = 2
    elif _landing_timer > 0.0:
        if not _is_shooting:
            _sprite.stop()
            _sprite.animation = "jump"
            _sprite.frame = 3
    elif _is_shooting and velocity.x != 0.0:
        _sprite.play("run_shoot")
    elif _is_shooting:
        pass  # shoot_1/2/3 já está tocando
    elif velocity.x != 0.0:
        _sprite.play("run")
    else:
        _sprite.play("idle")

static func get_charge_level(timer: float) -> int:
    if timer >= CHARGE_L3_THRESHOLD:
        return 3
    if timer >= CHARGE_L2_THRESHOLD:
        return 2
    return 1

func _use_special_ability() -> bool:
    var bid: String = GameManager.selected_boss_ability
    if bid == "ignarath" and GameManager.use_ability_ammo("ignarath"):
        _fire_walk()
        return true
    if bid == "galerix" and GameManager.use_ability_ammo("galerix"):
        _fire_wind_gust()
        return true
    if bid == "cryovex" and GameManager.use_ability_ammo("cryovex"):
        _fire_ice_arrow()
        return true
    if bid == "umbraex" and GameManager.use_ability_ammo("umbraex"):
        _fire_shadow_kunai()
        return true
    if bid == "terragor" and GameManager.use_ability_ammo("terragor"):
        _fire_stone_shard()
        return true
    if bid == "luxar" and GameManager.use_ability_ammo("luxar"):
        _fire_solar_corona()
        return true
    return false

func _fire_wind_gust() -> void:
    var dir_f: float = 1.0 if facing_right else -1.0
    var gust: Area2D = _WIND_GUST.new()
    gust.set("dir", dir_f)
    # Mesma altura de braço dos tiros normais (_SPAWN_OFFSET_Y) — sem isso
    # a rajada saía perto do centro do corpo em vez de na altura do braço.
    gust.global_position = global_position + Vector2(dir_f * _SPAWN_OFFSET_X[1], _SPAWN_OFFSET_Y)
    get_parent().add_child(gust)

func _fire_ice_arrow() -> void:
    var dir_f: float = 1.0 if facing_right else -1.0
    var arrow: Area2D = _ICE_ARROW.new()
    arrow.set("dir", dir_f)
    arrow.global_position = global_position + Vector2(dir_f * _SPAWN_OFFSET_X[1], _SPAWN_OFFSET_Y)
    get_parent().add_child(arrow)

func _fire_shadow_kunai() -> void:
    var dir_f: float = 1.0 if facing_right else -1.0
    var kunai: Area2D = _SHADOW_KUNAI.new()
    kunai.set("dir", dir_f)
    kunai.global_position = global_position + Vector2(dir_f * _SPAWN_OFFSET_X[1], _SPAWN_OFFSET_Y)
    get_parent().add_child(kunai)

func _fire_stone_shard() -> void:
    var dir_f: float = 1.0 if facing_right else -1.0
    var shard: Area2D = _STONE_SHARD.new()
    shard.set("dir", dir_f)
    shard.global_position = global_position + Vector2(dir_f * _SPAWN_OFFSET_X[1], _SPAWN_OFFSET_Y)
    get_parent().add_child(shard)

func _fire_solar_corona() -> void:
    var dir_f: float = 1.0 if facing_right else -1.0
    var orb: Area2D = _SOLAR_CORONA.new()
    orb.set("dir", dir_f)
    orb.global_position = global_position + Vector2(dir_f * _SPAWN_OFFSET_X[1], _SPAWN_OFFSET_Y)
    get_parent().add_child(orb)

func _fire_walk() -> void:
    var dir_f: float = 1.0 if facing_right else -1.0
    const WAVE_H_HALF := 28.0   # player_fire_wave._WAVE_H * 0.5
    const WAVE_W_HALF := 45.0   # player_fire_wave._WAVE_W * 0.5
    var wave_center_y: float = global_position.y + 82.0 - WAVE_H_HALF

    # Raycast horizontal para não spawnar além de uma parede próxima
    var space := get_world_2d().direct_space_state
    var query := PhysicsRayQueryParameters2D.create(
        Vector2(global_position.x, wave_center_y),
        Vector2(global_position.x + dir_f * 120.0, wave_center_y),
        1)  # world layer
    var hit := space.intersect_ray(query)

    var spawn_x: float
    if hit:
        # Coloca o centro da onda encostado na parede (frente da wave toca a parede)
        spawn_x = hit.position.x - dir_f * (WAVE_W_HALF + 4.0)
    else:
        spawn_x = global_position.x + dir_f * _SPAWN_OFFSET_X[1]

    var wave: Area2D = _FIRE_WAVE.new()
    wave.set("dir", dir_f)
    wave.global_position = Vector2(spawn_x, wave_center_y)
    get_parent().add_child(wave)

func _fire(level: int) -> void:
    assert(level >= 1 and level <= 3, "charge level deve ser 1, 2 ou 3")
    match level:
        1: AudioManager.play_sfx(AudioLibrary.sfx_shot_l1)
        2: AudioManager.play_sfx(AudioLibrary.sfx_shot_l2)
        3: AudioManager.play_sfx(AudioLibrary.sfx_shot_l3)
    _is_shooting = true
    _shoot_timer = _SHOOT_DURATIONS[level - 1]
    _sprite.play("shoot_%d" % level)
    var bullet: ZaelBullet = _BULLET_SCENE.instantiate()
    bullet.damage = BULLET_DAMAGE[level]
    bullet.level = level
    # Durante wall grab, facing_right reflete a direção de avanço (em direção à parede),
    # não a direção visual. Usa _wall_normal para disparar para fora da parede.
    var fire_right: bool = (_wall_normal.x > 0.0) if _is_wall_sliding else facing_right
    bullet.direction = 1.0 if fire_right else -1.0
    bullet.scale = BULLET_SCALE[level]
    bullet.source_id = GameManager.zael_selected_shot
    get_parent().add_child(bullet)
    var offset_x: float = _SPAWN_OFFSET_X[level] if fire_right else -_SPAWN_OFFSET_X[level]
    bullet.global_position = global_position + Vector2(offset_x, _SPAWN_OFFSET_Y)

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        _is_charging = false
        _charge_timer = 0.0
