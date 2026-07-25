extends Area2D
class_name RollingBoulder

# Ataque StoneShatter do Terragor: pedra grande empurrada em linha reta no
# chão até o player, com rastro de poeira (boulder_dust.tscn) mostrando o
# deslocamento. Ao bater no player, causa dano direto e some (igual ao
# ice_shard.gd). Ao bater numa parede, toca a animação de quebra e espalha
# fragmentos (rock_fragment.tscn) em várias direções. Sprites gerados via
# PixelLab + skill pixellab-effect.
const TEX_IDLE := preload("res://characters/bosses/terragor/fx_boulder_idle.png")
const TEX_SHATTER := preload("res://characters/bosses/terragor/fx_boulder_shatter.png")
const _DUST_SCENE := preload("res://characters/bosses/boulder_dust.tscn")
const _FRAGMENT_SCENE := preload("res://characters/bosses/rock_fragment.tscn")
const _SHATTER_FRAMES := 13
const _SHATTER_FPS := 18.0
const _DUST_INTERVAL := 0.15
const _FRAGMENT_COUNT := 6

var dir: float = 1.0
var speed: float = 160.0
var damage: int = 4
var source_id: String = "terragor"
# false = quebra "muda" sem espalhar estilhaços (usado no ThrowSoneLegal,
# que só quebra ao bater numa parede no meio do trajeto). true = usado no
# StoneShatter, onde a quebra É o ataque (explode fragmentos).
var spawn_fragments_on_shatter: bool = true
var _lifetime: float = 5.0
var _hit := false
var _shattering := false
var _dust_timer := 0.0
var _shatter_frame := 0
var _shatter_anim_timer := 0.0

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	collision_layer = 16
	collision_mask = 3
	body_entered.connect(_on_body_entered)
	_sprite.texture = TEX_IDLE
	_sprite.hframes = 1
	_sprite.flip_h = dir < 0.0

func _physics_process(delta: float) -> void:
	if _shattering:
		_shatter_anim_timer += delta
		if _shatter_anim_timer >= 1.0 / _SHATTER_FPS:
			_shatter_anim_timer -= 1.0 / _SHATTER_FPS
			_shatter_frame += 1
			if _shatter_frame >= _SHATTER_FRAMES:
				queue_free()
				return
			_sprite.frame = _shatter_frame
		return
	if _hit:
		return
	global_position.x += dir * speed * delta
	_dust_timer += delta
	if _dust_timer >= _DUST_INTERVAL:
		_dust_timer -= _DUST_INTERVAL
		_spawn_dust()
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _spawn_dust() -> void:
	var dust: Node2D = _DUST_SCENE.instantiate()
	dust.global_position = global_position + Vector2(-dir * 24.0, 34.0)
	get_parent().add_child(dust)

func _on_body_entered(body: Node) -> void:
	if _hit:
		return
	_hit = true
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
		queue_free()
		return
	# Bateu em terreno (sem take_damage): estilhaça (fragmentos opcionais).
	_start_shatter()

# Aciona a quebra imediatamente, sem esperar colisão — usado pelo
# StoneShatter, que esmaga a pedra contra o próprio corpo do boss.
func shatter_now() -> void:
	if _hit:
		return
	_hit = true
	_start_shatter()

func _start_shatter() -> void:
	_shattering = true
	_shatter_frame = 0
	_shatter_anim_timer = 0.0
	_sprite.texture = TEX_SHATTER
	_sprite.hframes = _SHATTER_FRAMES
	_sprite.frame = 0
	_sprite.flip_h = false
	if spawn_fragments_on_shatter:
		_spawn_fragments()

func _spawn_fragments() -> void:
	for i in _FRAGMENT_COUNT:
		var angle: float = (TAU / _FRAGMENT_COUNT) * i
		var vel := Vector2(150.0, 0.0).rotated(angle) + Vector2(0.0, -80.0)
		var frag: Area2D = _FRAGMENT_SCENE.instantiate()
		frag.global_position = global_position
		frag.velocity = vel
		frag.damage = 2
		frag.source_id = source_id
		get_parent().add_child(frag)
