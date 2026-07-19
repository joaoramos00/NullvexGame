extends Area2D
class_name IceShard

# Projétil do IcyBlast do Cryovex. Visual: ponta de flecha estática (girada
# conforme a direção do voo) + rastro de pó de gelo spawnado periodicamente
# atrás (dust_puff.tscn) + animação de estilhaçamento ao bater numa parede
# (fx_ice_arrow_shatter.png, 11 frames). Sprites gerados via PixelLab +
# skill pixellab-effect.
const TEX_IDLE := preload("res://characters/bosses/cryovex/fx_ice_arrow_idle.png")
const TEX_SHATTER := preload("res://characters/bosses/cryovex/fx_ice_arrow_shatter.png")
const _DUST_PUFF_SCENE := preload("res://characters/bosses/dust_puff.tscn")
const _SHATTER_FRAMES := 11
const _SHATTER_FPS := 22.0
const _DUST_INTERVAL := 0.07

var projectile_velocity: Vector2 = Vector2(240.0, 0.0)
var damage: int = 12
var source_id: String = "cryovex"
var _lifetime: float = 4.0
var _hit := false
var _shattering := false
var _dust_timer := 0.0
var _shatter_frame := 0
var _shatter_anim_timer := 0.0

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	AudioManager.play_sfx(AudioLibrary.sfx_boss_shoot)
	_sprite.texture = TEX_IDLE
	_sprite.hframes = 1
	# A arte aponta pra cima (0 rad = "pra cima" na tela); +PI/2 alinha "pra
	# cima" com a direção real de voo (velocity.angle()==0 é "pra direita").
	rotation = projectile_velocity.angle() + PI / 2.0

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
	global_position += projectile_velocity * delta
	_dust_timer += delta
	if _dust_timer >= _DUST_INTERVAL:
		_dust_timer -= _DUST_INTERVAL
		_spawn_dust_puff()
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _spawn_dust_puff() -> void:
	var puff: Node2D = _DUST_PUFF_SCENE.instantiate()
	puff.global_position = global_position - projectile_velocity.normalized() * 10.0
	get_parent().add_child(puff)

func _on_body_entered(body: Node) -> void:
	if _hit:
		return
	_hit = true
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
		queue_free()
		return
	# Bateu em terreno (sem take_damage): estilhaça em vez de simplesmente sumir.
	_shattering = true
	_shatter_frame = 0
	_shatter_anim_timer = 0.0
	_sprite.texture = TEX_SHATTER
	_sprite.hframes = _SHATTER_FRAMES
	_sprite.frame = 0
	rotation = 0.0  # a rotação de mira fica no nó raiz (Area2D); zera pra a quebra não ficar torta
