extends Node
# SFX são pequenos (~400 KB no total) → carregados no boot e mantidos em RAM.
# BGM é grande (~54 MB nas 12 faixas) → carregado SOB DEMANDA via get_stage_bgm()
# e NÃO cacheado, pra não segurar todas as faixas na RAM ao mesmo tempo. Segurar
# as 12 estourava a memória do Edge no Xbox (SBOX_FATAL_MEMORY_EXCEEDED).

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
var sfx_dash: AudioStream
var sfx_wall_jump: AudioStream
var sfx_charge_ready: AudioStream
var sfx_boss_aggro: AudioStream
var sfx_boss_shoot: AudioStream
var sfx_enemy_shoot: AudioStream
var sfx_checkpoint: AudioStream
var sfx_stage_complete: AudioStream
var sfx_game_over: AudioStream
var sfx_enemy_hit: AudioStream
var sfx_shot_wall: AudioStream

const _BGM_BY_STAGE := {
	0: "bgm_intro", 1: "bgm_stage_01", 2: "bgm_stage_02", 3: "bgm_stage_03",
	4: "bgm_stage_04", 5: "bgm_stage_05", 6: "bgm_stage_06", 7: "bgm_stage_07",
	8: "bgm_stage_08", 9: "bgm_gauntlet", 10: "bgm_nullvex", 11: "bgm_nullvex_true",
}

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
	sfx_dash          = load("res://assets/audio/sfx/sfx_dash.mp3")
	sfx_wall_jump     = load("res://assets/audio/sfx/sfx_wall_jump.mp3")
	sfx_charge_ready  = load("res://assets/audio/sfx/sfx_charge_ready.mp3")
	sfx_boss_aggro    = load("res://assets/audio/sfx/sfx_boss_aggro.mp3")
	sfx_boss_shoot    = load("res://assets/audio/sfx/sfx_boss_shoot.mp3")
	sfx_enemy_shoot   = load("res://assets/audio/sfx/sfx_enemy_shoot.mp3")
	sfx_checkpoint    = load("res://assets/audio/sfx/sfx_checkpoint.mp3")
	sfx_stage_complete = load("res://assets/audio/sfx/sfx_stage_complete.mp3")
	sfx_game_over     = load("res://assets/audio/sfx/sfx_game_over.mp3")
	sfx_enemy_hit     = load("res://assets/audio/sfx/sfx_enemy_hit.mp3")
	sfx_shot_wall     = load("res://assets/audio/sfx/sfx_shot_wall.mp3")

# Carrega o BGM da fase SOB DEMANDA (não cacheia). O AudioManager troca o stream
# do player; a faixa anterior fica sem referência e é liberada da memória.
func get_stage_bgm(stage_id: int) -> AudioStream:
	var bgm_name: String = _BGM_BY_STAGE.get(stage_id, "")
	if bgm_name == "":
		return null
	return load("res://assets/audio/bgm/%s.mp3" % bgm_name)
