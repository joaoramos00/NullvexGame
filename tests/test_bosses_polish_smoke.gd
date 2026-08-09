extends Node

# Smoke: garante que os 4 bosses recem wirados (Cryovex/Gravitus/Umbraex/
# Terragor) instanciam sem erro e que as texturas de idle e death novas
# realmente resolvem (preload nao falha em parse, mas resource pode ser null
# se .import estiver quebrado).

func _ready() -> void:
	_check_boss("cryovex", "res://characters/bosses/cryovex.tscn",
		["res://characters/bosses/cryovex/cryovex_idle_east.png",
		 "res://characters/bosses/cryovex/cryovex_death_east.png"])
	_check_boss("gravitus", "res://characters/bosses/gravitus.tscn",
		["res://characters/bosses/gravitus/gravitus_idle_east.png",
		 "res://characters/bosses/gravitus/gravitus_death_east.png"])
	_check_boss("umbraex", "res://characters/bosses/umbraex.tscn",
		["res://characters/bosses/umbraex/umbraex_idle_east.png",
		 "res://characters/bosses/umbraex/umbraex_hurt_east.png",
		 "res://characters/bosses/umbraex/umbraex_death_east.png"])
	_check_boss("terragor", "res://characters/bosses/terragor.tscn",
		["res://characters/bosses/terragor/terragor_idle_east.png",
		 "res://characters/bosses/terragor/terragor_death_east.png"])
	print("ALL TESTS PASSED")
	get_tree().quit()

func _check_boss(name: String, scene_path: String, tex_paths: Array) -> void:
	var scene = load(scene_path)
	assert(scene != null, "%s scene load failed" % name)
	var boss = scene.instantiate()
	assert(boss != null, "%s instantiate failed" % name)
	# _dying_anim_done deve existir (state var nova)
	assert("_dying_anim_done" in boss, "%s missing _dying_anim_done" % name)
	for p in tex_paths:
		var tex = load(p)
		assert(tex != null, "%s tex load failed: %s" % [name, p])
	boss.queue_free()
	print("PASS: %s (instantiate + %d anim tex)" % [name, tex_paths.size()])
