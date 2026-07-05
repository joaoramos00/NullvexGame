extends Node
# Reproduz floor1 -> wall -> floor2 (corner de subida) e verifica se o
# Fire Walk consegue voltar ao modo chão depois de subir a parede.

const _FIRE_WAVE := preload("res://characters/ranged/player_fire_wave.gd")

func _make_body(pos: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	cs.shape = rect
	body.add_child(cs)
	return body

func _ready() -> void:
	# floor1: topo em y=500, de x=0 a x=300
	add_child(_make_body(Vector2(150, 550), Vector2(300, 100)))
	# wall: x=300..364, topo em y=308 (corner de subida, 192px = 3 tiles)
	add_child(_make_body(Vector2(332, 454), Vector2(64, 292)))
	# floor2: topo em y=308, de x=300 a x=700
	add_child(_make_body(Vector2(500, 328), Vector2(400, 40)))

	var wave: Area2D = _FIRE_WAVE.new()
	wave.dir = 1.0
	wave.speed = 300.0
	wave.global_position = Vector2(251.0, 472.0)  # colado na parede, pés em y=500
	add_child(wave)

	await get_tree().physics_frame
	if not wave._vertical:
		print("FAIL: nao iniciou em modo parede ao spawnar colado")
		get_tree().quit(1)
		return
	print("OK: iniciou em modo parede, pos=%s" % [wave.global_position])

	var frame := 0
	var settled := false
	var switch_frame := -1
	var floating_gap_frames := 0
	while frame < 90:
		await get_tree().physics_frame
		frame += 1
		if not is_instance_valid(wave):
			print("[f%02d] wave freed (burst despawn)" % frame)
			break
		var wf_colliding: bool = wave._ray_wall.is_colliding() if wave._ray_wall else false
		var fl_colliding: bool = wave._ray_floor.is_colliding() if wave._ray_floor else false
		print("[f%02d] vert=%s pos=(%.1f,%.1f) ray_wall=%s ray_floor=%s" % [
			frame, wave._vertical, wave.global_position.x, wave.global_position.y,
			wf_colliding, fl_colliding])
		if not wave._vertical:
			if switch_frame < 0:
				switch_frame = frame
			if not fl_colliding:
				floating_gap_frames += 1
		if not wave._vertical and wave.global_position.x >= 300.0 and absf(wave.global_position.y - 280.0) < 5.0:
			settled = true
			print("-> assentou corretamente no floor2 no frame %d" % frame)
			break

	# Regressao especifica: apos virar pro modo chao, nao pode flutuar sem
	# encontrar piso por mais de 1 frame (RayCast2D pode atrasar 1 frame).
	if floating_gap_frames > 1:
		print("FAIL: flutuou %d frames sem detectar piso apos sair do modo parede (gap entre X da parede e X do novo piso)" % floating_gap_frames)
		get_tree().quit(1)
		return

	if settled:
		print("PASS: fire wave sobe a parede e assenta no floor2 sem flutuar")
		get_tree().quit(0)
	else:
		print("FAIL: fire wave nunca assentou corretamente no floor2")
		get_tree().quit(1)
