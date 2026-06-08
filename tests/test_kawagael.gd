extends Node

const _EXPECTED := [
    "idle", "run", "jump", "shoot_1", "shoot_2", "shoot_3",
    "dash", "wall_slide", "hurt", "death", "run_shoot", "jump_shoot", "dash_shoot",
]

func _ready() -> void:
    var scene := load("res://characters/ranged/kawagael/kawagael.tscn") as PackedScene
    var k := scene.instantiate()
    add_child(k)
    await get_tree().process_frame

    var sprite := k.get_node("AnimatedSprite2D") as AnimatedSprite2D
    var sf := sprite.sprite_frames
    var ok := true

    # A run deve ter tantos frames quanto o sheet (largura / 68). Placeholder = 5, final = 8.
    var run_tex := load("res://characters/ranged/kawagael/KawagaelRun.png") as Texture2D
    var expected_run := int(run_tex.get_width() / 68)
    if sf.get_frame_count("run") != expected_run:
        push_error("run tem %d frames, esperado %d (sheet)" % [sf.get_frame_count("run"), expected_run])
        ok = false

    for anim in _EXPECTED:
        if not sf.has_animation(anim):
            push_error("faltando animação: " + anim)
            ok = false

    print("TEST_KAWAGAEL: ", "PASS" if ok else "FAIL", " (run=%d frames)" % sf.get_frame_count("run"))
    get_tree().quit(0 if ok else 1)
