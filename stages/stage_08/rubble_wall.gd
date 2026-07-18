# Parede de entulho que bloqueia o caminho principal da Zona 3 até levar
# hits_required golpes de qualquer ataque do jogador. Diferente de
# cracked_wall.gd (stage_01, que exige a habilidade do Galerix pra abrir um
# SEGREDO opcional): esta parede está no caminho OBRIGATÓRIO, e Stage 08
# pode ser a primeira fase jogada (stage select em qualquer ordem) — travar
# atrás de uma habilidade de outro boss deixaria a fase impossível de
# terminar em certas ordens de jogo. Por isso quebra com qualquer hit, sem
# checagem de habilidade.
extends StaticBody2D

signal wall_destroyed

@export var hits_required: int = 3

var _hits: int = 0

const _TINT := Color(0.55, 0.4, 0.25, 0.45)

func _draw() -> void:
	for c in get_children():
		if c is CollisionShape2D and (c as CollisionShape2D).shape is RectangleShape2D:
			var sz: Vector2 = ((c as CollisionShape2D).shape as RectangleShape2D).size
			var pos: Vector2 = (c as Node2D).position
			draw_rect(Rect2(pos - sz * 0.5, sz), _TINT)

func _ready() -> void:
	add_to_group("rubble_wall")
	if DebugBoot.bot_enabled:
		# stage_bot.gd (tests/bot/stage_bot.gd) só simula move_left/move_right/jump/dash —
		# não existe segmento ou input de "attack" em lugar nenhum do autopilot. Ao contrário
		# de cracked_wall/ice_gate (onde o bot poderia teoricamente ter a habilidade mas não
		# tem), aqui o bot é estruturalmente incapaz de gerar UM hit sequer, não só "N hits de
		# forma confiável". Como a parede está no caminho OBRIGATÓRIO (não numa secret area),
		# sem esse bypass o bot travaria 100% das vezes na Zona 3. Mesma saída de ice_gate.gd
		# (queue_free em _ready), mas por um motivo ainda mais forte.
		call_deferred("queue_free")
		return
	queue_redraw()
	var detector := get_node_or_null("HitDetector") as Area2D
	if detector != null:
		detector.area_entered.connect(_on_hit)

func _on_hit(_area: Area2D) -> void:
	if is_queued_for_deletion():
		return
	_hits += 1
	if _hits >= hits_required:
		wall_destroyed.emit()
		queue_free()
