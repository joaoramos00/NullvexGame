# Portal de sombra: par de Area2D que reposiciona o corpo que entrar numa
# delas pra posição da outra, preservando velocity (CharacterBody2D.velocity
# não é tocado, só global_position muda). Cooldown por corpo em AMBOS os
# portais evita re-teleporte imediato quando as duas áreas ficam próximas
# (o corpo chega na saída já sobrepondo a área dela).
extends Area2D
class_name ShadowPortal

@export var reentry_cooldown: float = 0.3

var _partner: ShadowPortal = null
var _cooldown: Dictionary = {}   # Node -> float (tempo restante)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func link_partner(other: Node2D) -> void:
	_partner = other as ShadowPortal

func mark_cooldown(body: Node) -> void:
	_cooldown[body] = reentry_cooldown

func _on_body_entered(body: Node) -> void:
	if _partner == null:
		return
	if _cooldown.has(body):
		return
	if not (body is Node2D):
		return
	(body as Node2D).global_position = _partner.global_position
	mark_cooldown(body)
	_partner.mark_cooldown(body)

func _physics_process(delta: float) -> void:
	if _cooldown.is_empty():
		return
	for b in _cooldown.keys().duplicate():
		_cooldown[b] -= delta
		if _cooldown[b] <= 0.0:
			_cooldown.erase(b)
