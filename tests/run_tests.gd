extends SceneTree

var failures:=0

func _init() -> void:
	check(GameContent.UNITS.size()==12,"12 distinct guardian definitions")
	check(GameContent.ENEMIES.size()==4,"four enemy archetypes")
	check(GameContent.MAPS.size()==3,"three playable map definitions")
	for unit in GameContent.UNITS:
		check(unit.has_all(["name","element","role","rarity","damage","rate","range","ability","color","accent"]),"unit schema: "+str(unit.get("name","unknown")))
		check(float(unit.damage)>0 and float(unit.rate)>0 and float(unit.range)>=140,"valid combat stats: "+str(unit.name))
	var total:=0
	for i in GameContent.UNITS.size(): total+=GameContent.rarity_weight(i)
	check(total>0,"summon table has positive weight")
	check(MatchRules.is_boss_wave(5) and MatchRules.is_boss_wave(30),"boss cadence")
	check(MatchRules.is_elite_wave(4) and not MatchRules.is_elite_wave(20),"elite cadence excludes boss waves")
	check(MatchRules.enemy_count(5)==1 and MatchRules.enemy_count(3)==13,"wave enemy counts")
	check(MatchRules.wave_reward(4)>MatchRules.wave_reward(3),"elite reward premium")
	check(MatchRules.result_reward(30,true)==120,"final victory reward")
	check(SummonRules.adjusted_weight(10,"Rare","Storm",7,false,"")==80,"pity boosts rare weight")
	check(SummonRules.adjusted_weight(10,"Common","Storm",7,false,"")==10,"pity leaves common weight unchanged")
	check(SummonRules.adjusted_weight(10,"Rare","Storm",0,true,"Storm")==50,"focused summon boosts matching element")
	check(SummonRules.resets_pity("Legendary") and not SummonRules.resets_pity("Common"),"pity reset rarities")
	if failures==0: print("PASS: content, combat stats and summon table validated")
	quit(failures)

func check(condition:bool,label:String) -> void:
	if not condition: failures+=1; push_error("FAIL: "+label)
