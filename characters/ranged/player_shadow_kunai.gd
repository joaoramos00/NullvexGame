extends Area2D
class_name PlayerShadowKunai

# Habilidade "Shadow Kunai" do Zael, desbloqueada ao derrotar o Umbraex —
# mesma arte/kunai do próprio boss (fx_kunai.png), atirada reta na direção
# que o Zael está de frente. source_id = "umbraex" pra bater a checagem de
# fraqueza em boss_base.gd (Luxar é fraco a essa habilidade). Sem giro em
# voo; ao bater em algo que não seja o alvo, crava e gira no lugar (código,
# sem animação do PixelLab) — mesmo comportamento do kunai do Umbraex.
const TEX := preload("res://characters/bosses/umbraex/fx_kunai.png")
const _SPEED := 420.0
const _SPIN_SPEED := 18.0   # rad/s ao cravar
const _EMBED_DURATION := 0.5
const _LIFETIME := 2.0

var dir: float = 1.0
var damage: int = 10
var source_id: String = "umbraex"
var _embedded := false
var _embed_timer := 0.0
var _lifetime := _LIFETIME

var _sprite: Sprite2D

func _ready() -> void:
	collision_layer = 8   # projéteis do player
	collision_mask = 5    # enemy (4) + world (1) — crava na parede também
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	cs.shape = shape
	add_child(cs)
	_sprite = Sprite2D.new()
	_sprite.texture = TEX
	_sprite.scale = Vector2(0.5, 0.5)
	add_child(_sprite)
	body_entered.connect(_on_body_entered)
	# A arte aponta pra esquerda (PI rad); alinha com a direção real de voo.
	rotation = Vector2(dir, 0.0).angle() - PI

func _physics_process(delta: float) -> void:
	if _embedded:
		_sprite.rotation += _SPIN_SPEED * delta
		_embed_timer -= delta
		if _embed_timer <= 0.0:
			queue_free()
		return
	global_position.x += dir * _SPEED * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if _embedded:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
		queue_free()
		return
	_embedded = true
	_embed_timer = _EMBED_DURATION
