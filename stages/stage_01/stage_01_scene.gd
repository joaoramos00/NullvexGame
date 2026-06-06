# stages/stage_01/stage_01_scene.gd
extends "res://stages/stage_scene.gd"

func _ready() -> void:
	if StageManager.current_stage_id < 0:
		StageManager.current_stage_id = 1
	super._ready()
	# Paredes do shaft de DESCIDA: lisas (no_wall_grab) — desce pulando nas ShaftP,
	# não escalando. Sem isso o player agarra a parede e fica pendurado.
	for wn in ["ShaftWallL", "ShaftWallR"]:
		var w := get_node_or_null(wn)
		if w:
			w.add_to_group("no_wall_grab")
	for corr in get_children():
		if corr is CorridorSection:
			corr.setup(_player)
			corr.camera_lock_requested.connect(_on_camera_lock)

func _on_camera_lock(center: Vector2, zoom: float) -> void:
	$Camera2D.zoom = Vector2(zoom, zoom)
	# câmera volta a seguir o player automaticamente pelo _process herdado

# Debug ?zone=N: pontos de spawn no início de cada zona (calibração do bot).
func _zone_spawn(zone: int) -> Vector2:
	match zone:
		2: return Vector2(3760, 2480)    # zona 2 — sobre Z2Plat1 (pós shaft ↓)
		3: return Vector2(11300, 2480)   # zona 3 — sobre Z3Plat1
		4: return Vector2(16960, 816)    # zona 4 — sobre Z4Plat1 (pós shaft ↑)
		5: return Vector2(20160, 740)    # boss — sobre BossPlat1
		6: return Vector2(2640, 540)     # DEBUG: shaft ↓ — sobre a Z1Plat4 (testar descida)
		_: return Vector2.ZERO           # zona 1 = início normal
