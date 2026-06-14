# tests/test_boss_battle.gd
# Valida a sala de batalha do ImgDebug: instancia _BossBattleWorld e percorre
# todos os bosses de _BOSS_BATTLE via load_boss, conferindo instância/estado.
# assert() NÃO aborta em headless — usamos _check + quit(code).
extends Node

func _ready() -> void:
    var ok := true
    var world := ImgDebug._BossBattleWorld.new()
    world.tile_tex = load("res://stages/stage_00/Stage_00T.png") as Texture2D
    add_child(world)
    await get_tree().process_frame
    ok = _check(is_instance_valid(world._player), "player Zael spawnado") and ok
    ok = _check(world._player.current_hp == 99999, "player invencível (HP 99999)") and ok

    for i in ImgDebug._BOSS_BATTLE.size():
        var boss_name: String = ImgDebug._BOSS_BATTLE[i].name
        world.load_boss(i)
        await get_tree().process_frame
        var b = world._boss
        ok = _check(is_instance_valid(b), "boss %d instanciado (%s)" % [i, boss_name]) and ok
        if is_instance_valid(b):
            ok = _check(b is BossBase, "boss %d é BossBase (%s)" % [i, boss_name]) and ok
            ok = _check(b.state == BossBase.State.COMBAT, "boss %d em COMBAT (%s)" % [i, boss_name]) and ok
            ok = _check(b.player == world._player, "boss %d tem player (%s)" % [i, boss_name]) and ok
            ok = _check(b.current_hp == 99999, "boss %d dummy invencível (HP 99999)" % i) and ok

    if ok:
        print("ALL BATTLE TESTS PASSED")
        get_tree().quit(0)
    else:
        printerr("BATTLE TESTS FAILED")
        get_tree().quit(1)

func _check(cond: bool, msg: String) -> bool:
    if cond:
        print("  PASS: ", msg)
    else:
        printerr("  FAIL: ", msg)
    return cond
