extends Node

const EXPECTED_ANIMS := [
	"idle", "run_start", "run", "run_stop", "jump",
	"shoot_1", "shoot_2", "shoot_3", "dash", "wall_slide",
	"hurt", "death", "run_shoot", "jump_shoot", "dash_shoot",
]

# Contagens finais esperadas após Task 9 (loader completo) — conferir
# com o que o PixelLab devolveu. Se anim vier com 1 frame a mais/menos,
# ajustar aqui, não no loader (loader carrega o que existe).
const EXPECTED_FRAMES := {
	# run = 6 (run gen) + 6 (run_b continuation) = 12 frames pra loop suave
	"idle": 8, "run_start": 4, "run": 12, "run_stop": 4, "jump": 4,
	"shoot_1": 4, "shoot_2": 4, "shoot_3": 4, "dash": 1, "wall_slide": 4,
	"hurt": 4, "death": 6, "run_shoot": 6, "jump_shoot": 4, "dash_shoot": 1,
}

func _ready() -> void:
	await test_kawagael_instantiates()
	await test_kawagael_is_zael_subclass()
	await test_kawagael_has_all_animations()
	await test_kawagael_frame_counts()
	print("=== All Kawagael tests passed ===")
	get_tree().quit()

func _new_kawagael() -> Node:
	var scene := load("res://characters/ranged/kawagael/kawagael.tscn") as PackedScene
	var k = scene.instantiate()
	add_child(k)
	await get_tree().process_frame  # let _ready() run
	return k

func test_kawagael_instantiates() -> void:
	var scene := load("res://characters/ranged/kawagael/kawagael.tscn") as PackedScene
	assert(scene != null, "kawagael.tscn missing")
	var kawa = scene.instantiate()
	assert(kawa != null, "instantiate() failed")
	kawa.free()
	print("PASS: test_kawagael_instantiates")

func test_kawagael_is_zael_subclass() -> void:
	var k = await _new_kawagael()
	assert(k is Zael, "Kawagael must inherit Zael (needed for is-checks across the code)")
	k.queue_free()
	print("PASS: test_kawagael_is_zael_subclass")

func test_kawagael_has_all_animations() -> void:
	var k = await _new_kawagael()
	var sprite: AnimatedSprite2D = k.get_node("AnimatedSprite2D")
	var got: PackedStringArray = sprite.sprite_frames.get_animation_names()
	for anim in EXPECTED_ANIMS:
		assert(anim in got, "missing animation: %s (got %s)" % [anim, got])
	k.queue_free()
	print("PASS: test_kawagael_has_all_animations")

func test_kawagael_frame_counts() -> void:
	var k = await _new_kawagael()
	var sprite: AnimatedSprite2D = k.get_node("AnimatedSprite2D")
	for anim in EXPECTED_ANIMS:
		var got: int = sprite.sprite_frames.get_frame_count(anim)
		var want: int = EXPECTED_FRAMES[anim]
		assert(got == want, "anim %s: expected %d frames, got %d" % [anim, want, got])
	k.queue_free()
	print("PASS: test_kawagael_frame_counts")
