extends Control

const UNIT_DEFS := [
	{"name":"Bramble Bun","element":"Nature","role":"Damage","damage":13.0,"rate":0.75,"color":Color("#63c174")},
	{"name":"Cinder Fox","element":"Fire","role":"Area","damage":18.0,"rate":1.1,"color":Color("#f47b54")},
	{"name":"Brook Otter","element":"Water","role":"Support","damage":9.0,"rate":0.65,"color":Color("#55b9db")},
	{"name":"Gale Finch","element":"Storm","role":"Control","damage":11.0,"rate":0.55,"color":Color("#e6d85c")},
	{"name":"Moss Guardian","element":"Guardian","role":"Tank","damage":8.0,"rate":0.9,"color":Color("#789d65")},
	{"name":"Fizzlepaw","element":"Alchemist","role":"Debuffer","damage":15.0,"rate":0.8,"color":Color("#bf75da")}
]
const PATH := [Vector2(0,170),Vector2(210,170),Vector2(210,365),Vector2(520,365),Vector2(520,150),Vector2(790,150),Vector2(790,420),Vector2(1100,420)]
var rng := RandomNumberGenerator.new()
var units:Array[Dictionary] = []
var enemies:Array[Dictionary] = []
var projectiles:Array[Dictionary] = []
var essence := 120
var lives := 20
var wave := 0
var selected := -1
var spawn_left := 0
var spawn_clock := 0.0
var wave_running := false
var boss_wave := false
var game_over := false
var message := "Beschwöre deine ersten Hüter!"
var message_time := 4.0
var summon_rect := Rect2()
var wave_rect := Rect2()
var merge_rect := Rect2()
var speed := 1.0

func _ready() -> void:
	rng.seed = int(Time.get_unix_time_from_system())
	load_progress()
	queue_redraw()

func _process(delta:float) -> void:
	if game_over: queue_redraw(); return
	var dt := delta * speed
	message_time = maxf(0.0, message_time-delta)
	if wave_running:
		spawn_clock -= dt
		if spawn_left > 0 and spawn_clock <= 0:
			spawn_enemy()
			spawn_left -= 1
			spawn_clock = 0.65
	update_units(dt)
	update_enemies(dt)
	update_projectiles(dt)
	if wave_running and spawn_left == 0 and enemies.is_empty():
		wave_running = false
		essence += 25 + wave * 3
		message = "Welle geschafft! +%d Essence" % (25 + wave*3)
		message_time = 3.0
		save_progress()
	queue_redraw()

func start_wave() -> void:
	if wave_running or game_over: return
	wave += 1
	boss_wave = wave % 5 == 0
	spawn_left = 1 if boss_wave else 6 + wave * 2
	wave_running = true
	message = "BOSS: Der Verderbnis-Koloss!" if boss_wave else "Welle %d beginnt" % wave
	message_time = 2.5

func spawn_enemy() -> void:
	var kind := rng.randi_range(0,3)
	var hp := 38.0 + wave * 14.0
	var speed_value := 48.0 + kind*7.0
	var color:Color = [Color("#d34d6d"),Color("#9b6b55"),Color("#7d65c1"),Color("#d98b42")][kind]
	var radius := 15.0 + kind
	if boss_wave:
		hp *= 12.0; speed_value = 30.0; radius = 34.0; color = Color("#6f315c")
	enemies.append({"pos":PATH[0],"segment":0,"hp":hp,"max_hp":hp,"speed":speed_value,"color":color,"radius":radius,"boss":boss_wave})

func update_enemies(dt:float) -> void:
	for i in range(enemies.size()-1,-1,-1):
		var e := enemies[i]
		var target:Vector2 = PATH[e.segment+1]
		e.pos = e.pos.move_toward(target, e.speed*dt)
		if e.pos.distance_to(target) < 1.0:
			e.segment += 1
			if e.segment >= PATH.size()-1:
				lives -= 5 if e.boss else 1
				enemies.remove_at(i)
				if lives <= 0: game_over=true; message="Die Verderbnis brach durch"

func update_units(dt:float) -> void:
	for u in units:
		u.cooldown -= dt
		if u.cooldown > 0: continue
		var best := -1
		var progress := -1
		for i in enemies.size():
			if u.pos.distance_to(enemies[i].pos) <= 175.0 and enemies[i].segment >= progress:
				best=i; progress=enemies[i].segment
		if best >= 0:
			var d:Dictionary = UNIT_DEFS[u.type]
			var covenant_bonus := 1.25 if active_covenants().size() > 0 else 1.0
			projectiles.append({"pos":u.pos,"target":enemies[best],"damage":d.damage*u.level*covenant_bonus,"color":d.color})
			u.cooldown = d.rate / (1.0 + (u.level-1)*0.12)

func update_projectiles(dt:float) -> void:
	for i in range(projectiles.size()-1,-1,-1):
		var p := projectiles[i]
		if not enemies.has(p.target): projectiles.remove_at(i); continue
		p.pos = p.pos.move_toward(p.target.pos, 520.0*dt)
		if p.pos.distance_to(p.target.pos) < 10:
			p.target.hp -= p.damage
			if p.target.hp <= 0:
				var reward := 18 if p.target.boss else 3
				essence += reward
				enemies.erase(p.target)
			projectiles.remove_at(i)

func summon() -> void:
	if essence < 25 or units.size() >= 12: message="Nicht genug Essence oder Brett voll"; message_time=2; return
	essence -= 25
	var type := rng.randi_range(0,UNIT_DEFS.size()-1)
	var slot := units.size()
	var col := slot % 6
	var row := slot / 6
	units.append({"type":type,"level":1,"pos":Vector2(120+col*160,555+row*80),"cooldown":rng.randf_range(0,0.5)})
	message = "%s schließt sich dem Pakt an!" % UNIT_DEFS[type].name
	message_time=2

func merge_selected() -> void:
	if selected < 0 or selected >= units.size(): return
	var chosen := units[selected]
	var matches:Array[int]=[]
	for i in units.size():
		if units[i].type==chosen.type and units[i].level==chosen.level: matches.append(i)
	if matches.size()<3: message="Du brauchst 3 gleiche Hüter derselben Stufe"; message_time=2; return
	var keep := matches[0]
	for j in range(2,0,-1): units.remove_at(matches[j])
	units[keep].level += 1
	selected=-1; message="MERGE! Fähigkeit verstärkt"; message_time=2
	reflow_units()

func reflow_units() -> void:
	for i in units.size(): units[i].pos=Vector2(120+(i%6)*160,555+(i/6)*80)

func active_covenants() -> Array[String]:
	var elements:Dictionary={}
	for u in units: elements[UNIT_DEFS[u.type].element]=elements.get(UNIT_DEFS[u.type].element,0)+1
	var result:Array[String]=[]
	if elements.get("Nature",0)>=2: result.append("Dornenbund")
	if elements.get("Fire",0)>=1 and elements.get("Storm",0)>=1: result.append("Flammenwirbel")
	return result

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		handle_press(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		handle_press(event.position)

func handle_press(p:Vector2) -> void:
	if game_over: get_tree().reload_current_scene(); return
	if summon_rect.has_point(p): summon(); return
	if wave_rect.has_point(p): start_wave(); return
	if merge_rect.has_point(p): merge_selected(); return
	for i in units.size():
		if units[i].pos.distance_to(p)<32: selected=i; return

func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO,size),Color("#15283a"))
	draw_rect(Rect2(0,105,size.x,390),Color("#294b4b"))
	for i in PATH.size()-1: draw_line(PATH[i],PATH[i+1],Color("#b89568"),46,true)
	draw_string(ThemeDB.fallback_font,Vector2(28,42),"CRITTER COVENANT",HORIZONTAL_ALIGNMENT_LEFT,400,30,Color("#f4e8bf"))
	draw_string(ThemeDB.fallback_font,Vector2(28,78),"❤ %d    ✦ %d Essence    Welle %d    Gegner %d" %[lives,essence,wave,enemies.size()+spawn_left],0,-1,21,Color.WHITE)
	var cov := active_covenants()
	draw_string(ThemeDB.fallback_font,Vector2(size.x-390,42),"Covenants: "+(", ".join(cov) if cov else "—"),0,360,18,Color("#f0d96c"))
	for e in enemies:
		var ep:Vector2=e.pos
		draw_circle(ep,e.radius,e.color)
		draw_circle(ep-Vector2(5,4),3,Color.WHITE); draw_circle(ep+Vector2(5,-4),3,Color.WHITE)
		draw_rect(Rect2(ep.x-e.radius,ep.y-e.radius-9,e.radius*2,4),Color("#401b32"))
		draw_rect(Rect2(ep.x-e.radius,ep.y-e.radius-9,e.radius*2*maxf(0,e.hp/e.max_hp),4),Color("#72e082"))
	for p in projectiles: draw_circle(p.pos+Vector2(0,0),5,p.color)
	for i in units.size():
		var u:=units[i]; var d:Dictionary=UNIT_DEFS[u.type]
		if i==selected: draw_circle(u.pos,38,Color("#fff0a6")); draw_arc(u.pos,175,0,TAU,64,Color(1,1,1,0.1),2)
		draw_circle(u.pos,29,d.color); draw_circle(u.pos-Vector2(8,3),4,Color.WHITE); draw_circle(u.pos+Vector2(8,-3),4,Color.WHITE)
		draw_string(ThemeDB.fallback_font,u.pos+Vector2(-55,47),d.name,1,110,13,Color.WHITE)
		draw_string(ThemeDB.fallback_font,u.pos+Vector2(-10,6),str(u.level),1,20,16,Color("#17202a"))
	summon_rect=Rect2(size.x-245,size.y-72,215,50); wave_rect=Rect2(30,size.y-72,190,50); merge_rect=Rect2(size.x/2-95,size.y-72,190,50)
	draw_button(wave_rect,"NÄCHSTE WELLE",not wave_running); draw_button(summon_rect,"BESCHWÖREN 25",essence>=25); draw_button(merge_rect,"3× MERGE",selected>=0)
	if message_time>0 or game_over:
		draw_rect(Rect2(size.x/2-260,112,520,48),Color(0.05,0.08,0.12,0.9))
		draw_string(ThemeDB.fallback_font,Vector2(size.x/2-245,145),message,1,490,20,Color.WHITE)

func draw_button(rect:Rect2,label:String,enabled:bool) -> void:
	draw_rect(rect,Color("#d89445") if enabled else Color("#56616b"))
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(8,33),label,1,rect.size.x-16,18,Color.WHITE)

func save_progress() -> void:
	var f:=FileAccess.open("user://save.json",FileAccess.WRITE)
	if f: f.store_string(JSON.stringify({"best_wave":wave}))

func load_progress() -> void:
	if FileAccess.file_exists("user://save.json"):
		var data=JSON.parse_string(FileAccess.get_file_as_string("user://save.json"))
		if data is Dictionary: message="Willkommen zurück – Bestwelle %d" % int(data.get("best_wave",0))
