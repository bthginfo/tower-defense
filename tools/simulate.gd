extends SceneTree

func _init() -> void:
	var rng:=RandomNumberGenerator.new(); rng.seed=424242
	var picks:Array[int]=[]; picks.resize(GameContent.UNITS.size()); picks.fill(0)
	for run in 10000:
		var total:=0
		for i in GameContent.UNITS.size(): total+=GameContent.rarity_weight(i)
		var roll:=rng.randi_range(1,total)
		for i in GameContent.UNITS.size():
			roll-=GameContent.rarity_weight(i)
			if roll<=0: picks[i]+=1; break
	var report:={"seed":424242,"samples":10000,"summon_counts":{}}
	for i in picks.size(): report.summon_counts[GameContent.UNITS[i].name]=picks[i]
	print(JSON.stringify(report))
	quit()
