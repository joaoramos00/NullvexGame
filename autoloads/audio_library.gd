extends Node

var bgm_intro: AudioStream
var bgm_stage_01: AudioStream
var bgm_stage_02: AudioStream
var bgm_stage_03: AudioStream
var bgm_stage_04: AudioStream
var bgm_stage_05: AudioStream
var bgm_stage_06: AudioStream
var bgm_stage_07: AudioStream
var bgm_stage_08: AudioStream
var bgm_gauntlet: AudioStream
var bgm_nullvex: AudioStream
var bgm_nullvex_true: AudioStream

var sfx_jump: AudioStream
var sfx_shoot: AudioStream
var sfx_attack: AudioStream
var sfx_player_damage: AudioStream
var sfx_player_death: AudioStream
var sfx_enemy_death: AudioStream
var sfx_boss_damage: AudioStream
var sfx_boss_death: AudioStream
var sfx_collectible: AudioStream
var sfx_shot_l1: AudioStream
var sfx_shot_l2: AudioStream
var sfx_shot_l3: AudioStream
var sfx_ignarath_fire: AudioStream
var sfx_ignarath_clawwave: AudioStream

func _ready() -> void:
	sfx_jump          = load("res://assets/audio/sfx/sfx_jump.mp3")
	sfx_shoot         = load("res://assets/audio/sfx/sfx_shoot.mp3")
	sfx_attack        = load("res://assets/audio/sfx/sfx_attack.mp3")
	sfx_player_damage = load("res://assets/audio/sfx/sfx_player_damage.mp3")
	sfx_player_death  = load("res://assets/audio/sfx/sfx_player_death.mp3")
	sfx_enemy_death   = load("res://assets/audio/sfx/sfx_enemy_death.mp3")
	sfx_boss_damage   = load("res://assets/audio/sfx/sfx_boss_damage.mp3")
	sfx_boss_death    = load("res://assets/audio/sfx/sfx_boss_death.mp3")
	sfx_collectible   = load("res://assets/audio/sfx/sfx_collectible.mp3")
	sfx_shot_l1       = load("res://assets/audio/sfx/sfx_shot_l1.mp3")
	sfx_shot_l2       = load("res://assets/audio/sfx/sfx_shot_l2.mp3")
	sfx_shot_l3       = load("res://assets/audio/sfx/sfx_shot_l3.mp3")
	sfx_ignarath_fire = load("res://assets/audio/sfx/sfx_ignarath_fire.mp3")
	sfx_ignarath_clawwave = load("res://assets/audio/sfx/sfx_ignarath_clawwave.mp3")
	bgm_intro        = load("res://assets/audio/bgm/bgm_intro.mp3")
	bgm_stage_01     = load("res://assets/audio/bgm/bgm_stage_01.mp3")
	bgm_stage_02     = load("res://assets/audio/bgm/bgm_stage_02.mp3")
	bgm_stage_03     = load("res://assets/audio/bgm/bgm_stage_03.mp3")
	bgm_stage_04     = load("res://assets/audio/bgm/bgm_stage_04.mp3")
	bgm_stage_05     = load("res://assets/audio/bgm/bgm_stage_05.mp3")
	bgm_stage_06     = load("res://assets/audio/bgm/bgm_stage_06.mp3")
	bgm_stage_07     = load("res://assets/audio/bgm/bgm_stage_07.mp3")
	bgm_stage_08     = load("res://assets/audio/bgm/bgm_stage_08.mp3")
	bgm_gauntlet     = load("res://assets/audio/bgm/bgm_gauntlet.mp3")
	bgm_nullvex      = load("res://assets/audio/bgm/bgm_nullvex.mp3")
	bgm_nullvex_true = load("res://assets/audio/bgm/bgm_nullvex_true.mp3")

func get_stage_bgm(stage_id: int) -> AudioStream:
	match stage_id:
		0: return bgm_intro
		1: return bgm_stage_01
		2: return bgm_stage_02
		3: return bgm_stage_03
		4: return bgm_stage_04
		5: return bgm_stage_05
		6: return bgm_stage_06
		7: return bgm_stage_07
		8: return bgm_stage_08
		9: return bgm_gauntlet
		10: return bgm_nullvex
		11: return bgm_nullvex_true
	return null
