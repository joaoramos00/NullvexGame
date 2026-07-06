extends Node
# Verifica que o golpe de garra do Ignarath lança UMA onda de fogo só (não 3
# ondas no chão + 7 na parede como era antes) — a mesma onda transiciona de
# horizontal pra vertical ao alcançar a parede, e o total de "ground bursts"
# ao longo do trajeto inteiro (chão+subida) fica em torno de CLAW_WAVE_BURSTS
# (10), não um por onda separada.

const _FIRE_WAVE_SCRIPT := preload("res://characters/bosses/ignarath/fire_wave.gd")

func _ready() -> void:
	DebugBoot.zone = 5
	var s: Node = load("res://stages/stage_01/stage_01.tscn").instantiate()
	add_child(s)
	for i in 4: await get_tree().physics_frame
	DebugBoot.zone = -1

	var ign := s.get_node_or_null("Ignarath")
	if ign == null:
		print("FAIL: Ignarath não encontrado")
		get_tree().quit(1)
		return

	# Espera a intro terminar (State.INTRO por intro_duration) antes de golpear.
	await get_tree().create_timer(float(ign.get("intro_duration")) + 0.2).timeout

	# Array em vez de int: lambdas do GDScript capturam locais POR VALOR na
	# criação, então um "var burst_count:=0" incrementado dentro do lambda
	# nunca refletiria aqui fora — precisa de um tipo de referência (Array).
	var burst_count_box := [0]
	s.child_entered_tree.connect(func(n):
		if n is AnimatedSprite2D and n.sprite_frames != null and n.sprite_frames.has_animation("burst"):
			burst_count_box[0] += 1
	)

	ign.call("_do_claw")

	var max_wave_count := 0
	var saw_vertical := false
	var wave_appeared := false
	for i in 600:  # ~10s a 60fps — cobre windup + trajeto inteiro (chão+subida)
		await get_tree().physics_frame
		var waves: Array = []
		for c in s.get_children():
			if c.get_script() == _FIRE_WAVE_SCRIPT:
				waves.append(c)
		max_wave_count = maxi(max_wave_count, waves.size())
		if waves.size() == 1:
			wave_appeared = true
			if bool(waves[0].get("vertical")):
				saw_vertical = true
		if wave_appeared and waves.size() == 0:
			break   # onda já completou o trajeto e sumiu

	var fail := false
	if not wave_appeared:
		print("FAIL: nenhuma fire_wave chegou a existir")
		fail = true
	if max_wave_count > 1:
		print("FAIL: mais de 1 fire_wave existiu ao mesmo tempo (max=%d) — deveria ser uma onda só" % max_wave_count)
		fail = true
	if not saw_vertical:
		print("FAIL: a onda nunca transicionou pra vertical (não subiu a parede)")
		fail = true
	var burst_count: int = burst_count_box[0]
	if burst_count < 8 or burst_count > 12:
		print("FAIL: burst_count fora do esperado (~10), veio %d" % burst_count)
		fail = true

	if fail:
		get_tree().quit(1)
	else:
		print("PASS: golpe de garra = onda única (%d bursts, transição chão→parede ok)" % burst_count)
		get_tree().quit(0)
