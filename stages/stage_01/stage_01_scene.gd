# stages/stage_01/stage_01_scene.gd
extends "res://stages/stage_scene.gd"

func _ready() -> void:
	super._ready()
	for corr in get_children():
		if corr is CorridorSection:
			corr.setup(_player)
			corr.camera_lock_requested.connect(_on_camera_lock)

func _on_camera_lock(center: Vector2, zoom: float) -> void:
	$Camera2D.zoom = Vector2(zoom, zoom)
	# câmera volta a seguir o player automaticamente pelo _process herdado
