extends Node
func _ready() -> void:
	var s: Node = load("res://stages/stage_01/stage_01.tscn").instantiate()
	add_child(s)
	for i in 10: await get_tree().physics_frame
	var fail := false
	# Envelope: parede direita única do corpo + boca (parede + teto) + Z4SecretWR
	# à esquerda (sela o segredo E é a parede de escalada esquerda).
	for wn in ["Z4ShaftWR", "Z4MouthWR", "Z4TopCap", "Z4SecretWR"]:
		if s.get_node_or_null(wn) == null:
			print("FAIL: %s ausente" % wn); fail = true
	var cap = s.get_node_or_null("Z4TopCap")
	if cap != null and not cap.is_in_group("no_wall_grab"):
		print("FAIL: Z4TopCap deveria ser no_wall_grab"); fail = true
	# Lava do shaft (chase)
	if s.get_node_or_null("Z4ShaftLava") == null:
		print("FAIL: Z4ShaftLava ausente"); fail = true
	# Parede+plats do zigue-zague (pisos de switchback); espinhos sob 1, 2 e 4
	for i in 5:
		if s.get_node_or_null("Z4WallPlat%d" % (i + 1)) == null:
			print("FAIL: Z4WallPlat%d ausente" % (i + 1)); fail = true
	for bn in ["Z4WallPlat1", "Z4WallPlat2", "Z4WallPlat4"]:
		var hurt = s.get_node_or_null(bn + "SpikesHurt")
		if hurt == null:
			print("FAIL: %sSpikesHurt ausente" % bn); fail = true
		elif not bool(hurt.get("instant_kill")):
			print("FAIL: %sSpikesHurt instant_kill=false" % bn); fail = true
	# Footholds (agarráveis — não devem estar em no_wall_grab); 3/4/5 = topo dos
	# compostos plat→espinho→saliência das wall plats 2/3/4
	for fname in ["Z4Foot1", "Z4Foot2", "Z4Foot3", "Z4Foot4", "Z4Foot5"]:
		var foot = s.get_node_or_null(fname)
		if foot == null:
			print("FAIL: %s ausente" % fname); fail = true
		elif foot.is_in_group("no_wall_grab"):
			print("FAIL: %s está em grupo no_wall_grab (deve ser agarrável)" % fname); fail = true
	# Espinhos de parede instant-kill — ver _Z4_SPIKES em stage_01_scene.gd
	for sname in ["Z4SpikeR2", "Z4SpikeL3", "Z4SpikeR3", "Z4SpikeL4", "Z4SpikeR4"]:
		var spike = s.get_node_or_null(sname)
		if spike == null:
			print("FAIL: %s ausente" % sname); fail = true
		var hurt2 = s.get_node_or_null(sname + "Hurt")
		if hurt2 == null:
			print("FAIL: %sHurt ausente" % sname); fail = true
		elif not bool(hurt2.get("instant_kill")):
			print("FAIL: %sHurt instant_kill=false" % sname); fail = true
	# Crumbles (estreia isolada + pivô do clímax) — Z4Plat5 (apoio da boca) foi
	# removido por playtest (redundante, os rests já viraram baffles).
	for ename in ["Z4Crumble1", "Z4Crumble2"]:
		if s.get_node_or_null(ename) == null:
			print("FAIL: %s ausente" % ename); fail = true
	# Checkpoint da base da Z4 (índice 4, entre Corridor1=1 e pré-boss=5)
	var z4cp = s.get_node_or_null("Z4BaseCheckpoint")
	if z4cp == null:
		print("FAIL: Z4BaseCheckpoint ausente"); fail = true
	elif int(z4cp.get("checkpoint_index")) != 4:
		print("FAIL: Z4BaseCheckpoint checkpoint_index != 4"); fail = true
	# Câmara pré-chefe
	for pname in ["Z4PreL", "Z4PreR"]:
		if s.get_node_or_null(pname) == null:
			print("FAIL: %s ausente" % pname); fail = true
	# Segredo: crackeadas + elevador + coletável
	for sname2 in ["Z4Crack1", "Z4Crack2", "Z4SecretElevator", "Z4DualBlades"]:
		if s.get_node_or_null(sname2) == null:
			print("FAIL: %s ausente" % sname2); fail = true
	if fail: get_tree().quit(1)
	else: print("PASS: shaft geometry (zigue-zague por parede+plats)"); get_tree().quit(0)
