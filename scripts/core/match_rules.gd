class_name MatchRules
extends RefCounted

const FINAL_WAVE:=30

static func is_boss_wave(wave:int) -> bool:
	return wave>0 and wave%5==0

static func is_elite_wave(wave:int) -> bool:
	return wave>0 and not is_boss_wave(wave) and wave%4==0

static func enemy_count(wave:int) -> int:
	return 1 if is_boss_wave(wave) else 7+wave*2

static func wave_reward(wave:int) -> int:
	return 25+wave*3+(12 if is_elite_wave(wave) else 0)

static func result_reward(wave:int,victory:bool) -> int:
	return maxi(5,wave*2)+(60 if victory else 0)
