extends Node
func _ready() -> void:
	var s: Node = load("res://stages/stage_01/stage_01.tscn").instantiate()
	add_child(s)
	for i in 10: await get_tree().physics_frame
	var fail := false
	# Paredes direitas: Z4ShaftWR0 .. Z4ShaftWR5 (todas 6)
	for i in 6:
		var wr = s.get_node_or_null("Z4ShaftWR%d" % i)
		if wr == null:
			print("FAIL: Z4ShaftWR%d ausente" % i); fail = true
	# Parede ESQUERDA do shaft = Z4SecretWR (não há mais Z4ShaftWL — eram redundantes
	# c/ a coluna do segredo e foram removidas; o WR sela o segredo E é a parede de wall-jump esq).
	if s.get_node_or_null("Z4SecretWR") == null:
		print("FAIL: Z4SecretWR ausente (parede esquerda do shaft)"); fail = true
	# Lava do shaft (chase)
	var lava = s.get_node_or_null("Z4ShaftLava")
	if lava == null:
		print("FAIL: Z4ShaftLava ausente"); fail = true
	# Footholds (agarráveis — não devem estar em no_wall_grab)
	for fname in ["Z4Foot1", "Z4Foot2", "Z4Foot3", "Z4Foot4"]:
		var foot = s.get_node_or_null(fname)
		if foot == null:
			print("FAIL: %s ausente" % fname); fail = true
		elif foot.is_in_group("no_wall_grab"):
			print("FAIL: %s está em grupo no_wall_grab (deve ser agarrável)" % fname); fail = true
	# Espinhos instant-kill: lados alternados (segs 1-2), escalonados (seg3) e
	# com banda sobreposta (seg4) — ver _Z4_SPIKES em stage_01_scene.gd
	for sname in ["Z4SpikeL1", "Z4SpikeR2", "Z4SpikeL3", "Z4SpikeR3", "Z4SpikeL4", "Z4SpikeR4"]:
		var spike = s.get_node_or_null(sname)
		if spike == null:
			print("FAIL: %s ausente" % sname); fail = true
		var hurt = s.get_node_or_null(sname + "Hurt")
		if hurt == null:
			print("FAIL: %sHurt ausente" % sname); fail = true
		elif not bool(hurt.get("instant_kill")):
			print("FAIL: %sHurt instant_kill=false" % sname); fail = true
	# Plataformas sólidas: 1, 2, 4 e 5 (o rest do seg3 virou o crumble Z4Crumble3)
	for i in [1, 2, 4, 5]:
		var plat = s.get_node_or_null("Z4Plat%d" % i)
		if plat == null:
			print("FAIL: Z4Plat%d ausente" % i); fail = true
	# Rests que desmoronam (terço superior)
	for ename in ["Z4Crumble3", "Z4Crumble4"]:
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
	for sname in ["Z4Crack1", "Z4Crack2", "Z4SecretElevator", "Z4DualBlades"]:
		if s.get_node_or_null(sname) == null:
			print("FAIL: %s ausente" % sname); fail = true
	if fail: get_tree().quit(1)
	else: print("PASS: shaft geometry (novo layout)"); get_tree().quit(0)
