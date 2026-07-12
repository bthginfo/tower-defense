class_name GameContent
extends RefCounted

const UNITS:Array[Dictionary] = [
	{"name":"Bramble Bun","element":"Nature","role":"Sharpshooter","rarity":"Common","damage":15.0,"rate":0.72,"range":190.0,"ability":"Seedshot","color":Color("#65d17a"),"accent":Color("#d9f99d")},
	{"name":"Cinder Fox","element":"Fire","role":"Blaster","rarity":"Common","damage":20.0,"rate":1.05,"range":170.0,"ability":"Ember Burst","color":Color("#ff7657"),"accent":Color("#ffd166")},
	{"name":"Brook Otter","element":"Water","role":"Support","rarity":"Common","damage":10.0,"rate":0.62,"range":185.0,"ability":"Tidal Mend","color":Color("#51bde8"),"accent":Color("#bde8ff")},
	{"name":"Gale Finch","element":"Storm","role":"Controller","rarity":"Common","damage":12.0,"rate":0.55,"range":205.0,"ability":"Static Chain","color":Color("#f2d95c"),"accent":Color("#fff4ad")},
	{"name":"Moss Guardian","element":"Guardian","role":"Bulwark","rarity":"Uncommon","damage":11.0,"rate":0.88,"range":155.0,"ability":"Bark Ward","color":Color("#7fa66b"),"accent":Color("#cae8a9")},
	{"name":"Fizzlepaw","element":"Alchemist","role":"Debuffer","rarity":"Uncommon","damage":17.0,"rate":0.78,"range":180.0,"ability":"Volatile Flask","color":Color("#bf74dc"),"accent":Color("#efc2ff")},
	{"name":"Moon Moth","element":"Arcane","role":"Execute","rarity":"Uncommon","damage":25.0,"rate":1.18,"range":225.0,"ability":"Moonmark","color":Color("#8b7cf6"),"accent":Color("#d9d2ff")},
	{"name":"Pollen Pixie","element":"Nature","role":"Support","rarity":"Uncommon","damage":9.0,"rate":0.48,"range":175.0,"ability":"Bloom Pulse","color":Color("#99df62"),"accent":Color("#efffa8")},
	{"name":"Coal Badger","element":"Fire","role":"Bruiser","rarity":"Rare","damage":34.0,"rate":1.35,"range":145.0,"ability":"Magma Claw","color":Color("#c94f42"),"accent":Color("#ff9f68")},
	{"name":"Tempest Lynx","element":"Storm","role":"Carry","rarity":"Rare","damage":22.0,"rate":0.50,"range":215.0,"ability":"Thunderstep","color":Color("#62d5dd"),"accent":Color("#fcf06a")},
	{"name":"Tidecaller Toad","element":"Water","role":"Control","rarity":"Rare","damage":16.0,"rate":0.92,"range":195.0,"ability":"Undertow","color":Color("#347dc1"),"accent":Color("#88eeef")},
	{"name":"Starhorn Stag","element":"Arcane","role":"Mythic Carry","rarity":"Legendary","damage":46.0,"rate":1.15,"range":250.0,"ability":"Astral Volley","color":Color("#e98be9"),"accent":Color("#fff0ac")}
]

const ENEMIES:Array[Dictionary] = [
	{"name":"Gloomling","hp":1.0,"speed":1.0,"armor":0.0,"radius":15.0,"color":Color("#d95375")},
	{"name":"Shellsnout","hp":1.8,"speed":0.68,"armor":0.22,"radius":19.0,"color":Color("#9f765d")},
	{"name":"Wisp","hp":0.72,"speed":1.65,"armor":0.0,"radius":12.0,"color":Color("#9d83ec")},
	{"name":"Mender","hp":1.25,"speed":0.82,"armor":0.05,"radius":17.0,"color":Color("#db9847")}
]

const MAPS:Array[Dictionary] = [
	{"name":"Verdant Crossroads","subtitle":"Klassische Pfade · reiche Essence","ground":Color("#21494a"),"path":Color("#bc986b")},
	{"name":"Ember Hollow","subtitle":"Schnellere Gegner · höhere Belohnung","ground":Color("#503637"),"path":Color("#c77855")},
	{"name":"Moonlit Marsh","subtitle":"Zähe Gegner · langsamer Pfad","ground":Color("#273c58"),"path":Color("#6d8c91")}
]

static func rarity_weight(index:int) -> int:
	var rarity:String = UNITS[index].rarity
	return {"Common":42,"Uncommon":24,"Rare":10,"Legendary":2}.get(rarity,1)
