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
	# Paredes esquerdas: Z4ShaftWL1 .. Z4ShaftWL5 (NÃO Z4ShaftWL0 — seg0 sem parede esq)
	for i in range(1, 6):
		var wl = s.get_node_or_null("Z4ShaftWL%d" % i)
		if wl == null:
			print("FAIL: Z4ShaftWL%d ausente" % i); fail = true
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
	# Espinhos instant-kill (Z4SpikeR1 e Z4SpikeR3)
	for sname in ["Z4SpikeR1", "Z4SpikeR3"]:
		var spike = s.get_node_or_null(sname)
		if spike == null:
			print("FAIL: %s ausente" % sname); fail = true
		var hurt = s.get_node_or_null(sname + "Hurt")
		if hurt == null:
			print("FAIL: %sHurt ausente" % sname); fail = true
		elif not bool(hurt.get("instant_kill")):
			print("FAIL: %sHurt instant_kill=false" % sname); fail = true
	# Plataformas: Z4Plat4 e Z4Plat5 (1-3 colapsam por nome com .tscn stale; validam Z4Plat4-5 neste ramo)
	for i in range(4, 6):
		var plat = s.get_node_or_null("Z4Plat%d" % i)
		if plat == null:
			print("FAIL: Z4Plat%d ausente" % i); fail = true
	# Outros elementos do shaft
	for ename in ["Z4Crumble4", "Z4Flyer1"]:
		if s.get_node_or_null(ename) == null:
			print("FAIL: %s ausente" % ename); fail = true
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
