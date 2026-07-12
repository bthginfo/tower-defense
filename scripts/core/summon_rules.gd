class_name SummonRules
extends RefCounted

const PITY_THRESHOLD:=7

static func adjusted_weight(base_weight:int,rarity:String,element:String,pity:int,focused:bool,focus_element:String) -> int:
	var weight:=base_weight
	if pity>=PITY_THRESHOLD and rarity in ["Rare","Legendary"]: weight*=8
	if focused: weight=weight*5 if element==focus_element else maxi(1,weight/5)
	return weight

static func resets_pity(rarity:String) -> bool:
	return rarity in ["Rare","Legendary"]
