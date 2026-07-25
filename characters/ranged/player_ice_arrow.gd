extends Area2D
class_name PlayerIceArrow

# Habilidade "Ice Arrow" do Zael, desbloqueada ao derrotar o Cryovex — mesma
# arte da ponta de flecha com rastro de pó de gelo usada no IcyBlast do boss
# (fx_ice_arrow_idle.png / fx_ice_arrow_shatter.png / dust_puff.tscn), agora
# atirada em linha reta na direção que o Zael está de frente.
const TEX_IDLE := preload("res://characters/bosses/cryovex/fx_ice_arrow_idle.png")
const TEX_SHATTER := preload("res://characters/bosses/cryovex/fx_ice_arrow_shatter.png")
const _DUST_PUFF_SCENE := preload("res://characters/bosses/dust_puff.tscn")
const _SHATTER_FRAMES := 11
const _SHATTER_FPS := 22.0
const _DUST_INTERVAL := 0.07

var dir: float = 1.0
var speed: float = 480.0
var damage: int = 2
var source_id: String = "zael_ice_arrow"
var _lifetime: float = 2.0
var _hit := false
var _shattering := false
var _dust_timer := 0.0
var _shatter_frame := 0
var _shatter_anim_timer := 0.0

var _sprite: Sprite2D

func _ready() -> void:
	collision_layer = 8   # projéteis do player
	collision_mask = 5    # enemy (4) + world (1) — estilhaça na parede também
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8.0
	cs.shape = shape
	add_child(cs)
	_sprite = Sprite2D.new()
	add_child(_sprite)
	body_entered.connect(_on_body_entered)
	_sprite.texture = TEX_IDLE
	_sprite.hframes = 1
	# A arte aponta pra cima (0 rad = "pra cima" na tela); +PI/2 alinha "pra
	# cima" com a direção real de voo (dir>0 == direita == 0 rad).
	rotation = Vector2(dir, 0.0).angle() + PI / 2.0

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
		_spawn_dust_puff()
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _spawn_dust_puff() -> void:
	var puff: Node2D = _DUST_PUFF_SCENE.instantiate()
	puff.global_position = global_position - Vector2(dir, 0.0) * 10.0
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
	rotation = 0.0  # a rotação de mira fica no nó raiz; zera pra a quebra não ficar torta
