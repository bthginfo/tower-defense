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
	if failures==0: print("PASS: content, combat stats and summon table validated")
	quit(failures)

func check(condition:bool,label:String) -> void:
	if not condition: failures+=1; push_error("FAIL: "+label)
