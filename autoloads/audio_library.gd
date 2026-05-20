extends Node

@export var bgm_intro: AudioStream = null
@export var bgm_stage_01: AudioStream = null
@export var bgm_stage_02: AudioStream = null
@export var bgm_stage_03: AudioStream = null
@export var bgm_stage_04: AudioStream = null
@export var bgm_stage_05: AudioStream = null
@export var bgm_stage_06: AudioStream = null
@export var bgm_stage_07: AudioStream = null
@export var bgm_stage_08: AudioStream = null
@export var bgm_gauntlet: AudioStream = null
@export var bgm_nullvex: AudioStream = null
@export var bgm_nullvex_true: AudioStream = null

@export var sfx_jump: AudioStream = null
@export var sfx_shoot: AudioStream = null
@export var sfx_attack: AudioStream = null
@export var sfx_player_damage: AudioStream = null
@export var sfx_player_death: AudioStream = null
@export var sfx_enemy_death: AudioStream = null
@export var sfx_boss_damage: AudioStream = null
@export var sfx_boss_death: AudioStream = null
@export var sfx_collectible: AudioStream = null

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
