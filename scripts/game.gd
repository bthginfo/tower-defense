extends Control

const UNIT_DEFS := GameContent.UNITS
const PORTRAITS:Array[Texture2D] = [
	preload("res://assets/generated/units/bramble_bun.png"),preload("res://assets/generated/units/cinder_fox.png"),preload("res://assets/generated/units/brook_otter.png"),preload("res://assets/generated/units/gale_finch.png"),preload("res://assets/generated/units/moss_guardian.png"),preload("res://assets/generated/units/fizzlepaw.png"),
	preload("res://assets/generated/units/moon_moth.png"),preload("res://assets/generated/units/pollen_pixie.png"),preload("res://assets/generated/units/coal_badger.png"),preload("res://assets/generated/units/tempest_lynx.png"),preload("res://assets/generated/units/tidecaller_toad.png"),preload("res://assets/generated/units/starhorn_stag.png")
]
const ENEMY_SPRITES:Array[Texture2D] = [preload("res://assets/generated/enemies/gloomling.png"),preload("res://assets/generated/enemies/shellsnout.png"),preload("res://assets/generated/enemies/wisp.png"),preload("res://assets/generated/enemies/mender.png"),preload("res://assets/generated/enemies/corruption_colossus.png")]
const BUTTON_TEX:Texture2D=preload("res://assets/third_party/kenney/ui/button_rectangle_depth_gradient.png")
const ARENA_TEX:Texture2D=preload("res://assets/generated/verdant_crossroads_premium.png")
const PATH := [Vector2(74,250),Vector2(260,200),Vector2(430,330),Vector2(260,490),Vector2(510,470),Vector2(660,260),Vector2(850,455),Vector2(1160,385)]
const SLOTS:Array[Vector2] = [Vector2(300,132),Vector2(530,225),Vector2(372,337),Vector2(245,455),Vector2(465,455),Vector2(625,380),Vector2(620,545),Vector2(800,135),Vector2(940,180),Vector2(830,318),Vector2(760,480),Vector2(930,520)]
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
var screen := "menu"
var map_index := 0
var best_wave := 0
var star_dust := 0
var tutorial_step := 0
var menu_play_rect := Rect2()
var menu_map_rect := Rect2()
var tutorial_rect := Rect2()
var particles:Array[Dictionary] = []
var combo := 0
var combo_clock := 0.0
var dragging := false

func _ready() -> void:
	rng.seed = int(Time.get_unix_time_from_system())
	load_progress()
	queue_redraw()

func _process(delta:float) -> void:
	if screen != "match": queue_redraw(); return
	if game_over: queue_redraw(); return
	var dt := delta * speed
	message_time = maxf(0.0, message_time-delta)
	combo_clock = maxf(0.0, combo_clock-delta)
	if combo_clock <= 0: combo = 0
	if wave_running:
		spawn_clock -= dt
		if spawn_left > 0 and spawn_clock <= 0:
			spawn_enemy()
			spawn_left -= 1
			spawn_clock = 0.65
	update_units(dt)
	update_enemies(dt)
	update_projectiles(dt)
	update_particles(dt)
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
	if tutorial_step==2: tutorial_step=3

func spawn_enemy() -> void:
	var kind := rng.randi_range(0,3)
	var ed:Dictionary = GameContent.ENEMIES[kind]
	var hp:float = (38.0 + wave * 14.0) * float(ed.hp) * [1.0,0.92,1.28][map_index]
	var speed_value:float = (48.0 + wave*0.8) * float(ed.speed) * [1.0,1.18,0.82][map_index]
	var color:Color = ed.color
	var radius:float = ed.radius
	if boss_wave:
		hp *= 12.0; speed_value = 30.0; radius = 34.0; color = Color("#6f315c")
	enemies.append({"pos":PATH[0],"segment":0,"hp":hp,"max_hp":hp,"speed":speed_value,"base_speed":speed_value,"color":color,"radius":radius,"boss":boss_wave,"armor":ed.armor,"slow":0.0,"kind":kind})

func update_enemies(dt:float) -> void:
	for i in range(enemies.size()-1,-1,-1):
		var e := enemies[i]
		e.slow = maxf(0.0,e.slow-dt)
		e.speed = e.base_speed * (0.55 if e.slow>0 else 1.0)
		if e.boss and e.hp/e.max_hp<0.5: e.speed=e.base_speed*1.55; e.color=Color("#e34f74")
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
			if u.pos.distance_to(enemies[i].pos) <= float(UNIT_DEFS[u.type].range) and enemies[i].segment >= progress:
				best=i; progress=enemies[i].segment
		if best >= 0:
			var d:Dictionary = UNIT_DEFS[u.type]
			var covenant_bonus := 1.25 if active_covenants().size() > 0 else 1.0
			projectiles.append({"pos":u.pos,"target":enemies[best],"damage":d.damage*u.level*covenant_bonus,"color":d.accent,"type":u.type,"level":u.level})
			u.cooldown = d.rate / (1.0 + (u.level-1)*0.12)

func update_projectiles(dt:float) -> void:
	for i in range(projectiles.size()-1,-1,-1):
		var p := projectiles[i]
		if not enemies.has(p.target): projectiles.remove_at(i); continue
		p.pos = p.pos.move_toward(p.target.pos, 520.0*dt)
		if p.pos.distance_to(p.target.pos) < 10:
			var d:Dictionary=UNIT_DEFS[p.type]
			var dealt:float=p.damage*(1.0-float(p.target.armor))
			if d.element=="Arcane" and p.target.hp/p.target.max_hp<0.3: dealt*=1.5
			p.target.hp -= dealt
			if d.element=="Water": p.target.slow=1.2+0.2*p.level
			if d.element=="Fire": splash_damage(p.target,dealt*0.38)
			if d.element=="Storm": chain_damage(p.target,dealt*0.50)
			burst(p.target.pos,d.color,5+p.level)
			if p.target.hp <= 0:
				var reward := 18 if p.target.boss else 3
				essence += reward
				combo += 1; combo_clock=2.2
				enemies.erase(p.target)
			projectiles.remove_at(i)

func splash_damage(origin:Dictionary,amount:float) -> void:
	for e in enemies:
		if e != origin and e.pos.distance_to(origin.pos)<75: e.hp-=amount

func chain_damage(origin:Dictionary,amount:float) -> void:
	var nearest:Dictionary={}; var distance:=120.0
	for e in enemies:
		if e != origin and e.pos.distance_to(origin.pos)<distance: nearest=e; distance=e.pos.distance_to(origin.pos)
	if not nearest.is_empty(): nearest.hp-=amount; burst(nearest.pos,Color("#fff06a"),4)

func burst(pos:Vector2,color:Color,count:int) -> void:
	for i in count:
		var angle:=rng.randf_range(0,TAU)
		particles.append({"pos":pos,"vel":Vector2.from_angle(angle)*rng.randf_range(30,95),"life":rng.randf_range(0.25,0.55),"color":color})

func update_particles(dt:float) -> void:
	for i in range(particles.size()-1,-1,-1):
		particles[i].life-=dt; particles[i].pos+=particles[i].vel*dt; particles[i].vel*=0.9
		if particles[i].life<=0: particles.remove_at(i)

func summon() -> void:
	if essence < 25 or units.size() >= 12: message="Nicht genug Essence oder Brett voll"; message_time=2; return
	essence -= 25
	var total:=0
	for i in UNIT_DEFS.size(): total+=GameContent.rarity_weight(i)
	var roll:=rng.randi_range(1,total); var type:=0
	for i in UNIT_DEFS.size():
		roll-=GameContent.rarity_weight(i)
		if roll<=0: type=i; break
	var slot:=first_free_slot()
	units.append({"type":type,"level":1,"pos":SLOTS[slot],"slot":slot,"cooldown":rng.randf_range(0,0.5)})
	message = "%s schließt sich dem Pakt an!" % UNIT_DEFS[type].name
	message_time=2
	if tutorial_step==0: tutorial_step=1

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
	if tutorial_step==1: tutorial_step=2
	reflow_units()

func reflow_units() -> void:
	pass

func first_free_slot() -> int:
	for slot in SLOTS.size():
		var free:=true
		for u in units:
			if int(u.slot)==slot: free=false; break
		if free: return slot
	return 0

func move_selected_to(point:Vector2) -> void:
	if selected<0 or selected>=units.size(): return
	var best:=-1; var distance:=55.0
	for i in SLOTS.size():
		var d:=SLOTS[i].distance_to(point)
		if d<distance: best=i; distance=d
	if best<0: return
	for u in units:
		if int(u.slot)==best: return
	units[selected].slot=best; units[selected].pos=SLOTS[best]
	message="Hüter neu positioniert"; message_time=1.2

func active_covenants() -> Array[String]:
	var elements:Dictionary={}
	for u in units: elements[UNIT_DEFS[u.type].element]=elements.get(UNIT_DEFS[u.type].element,0)+1
	var result:Array[String]=[]
	if elements.get("Nature",0)>=2: result.append("Dornenbund")
	if elements.get("Fire",0)>=1 and elements.get("Storm",0)>=1: result.append("Flammenwirbel")
	if elements.get("Water",0)>=1 and elements.get("Storm",0)>=1: result.append("Gezeitenblitz")
	if elements.get("Guardian",0)>=1 and elements.get("Water",0)>=1: result.append("Schutzquell")
	if elements.get("Arcane",0)>=2: result.append("Sterneneid")
	return result

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		dragging=true
		handle_press(event.position)
	elif event is InputEventMouseButton and not event.pressed:
		if dragging: move_selected_to(event.position)
		dragging=false
	elif event is InputEventScreenTouch and event.pressed:
		dragging=true
		handle_press(event.position)
	elif event is InputEventScreenTouch and not event.pressed:
		if dragging: move_selected_to(event.position)
		dragging=false

func handle_press(p:Vector2) -> void:
	if screen=="menu":
		if menu_play_rect.has_point(p): begin_match(); return
		if menu_map_rect.has_point(p): map_index=(map_index+1)%GameContent.MAPS.size(); return
		if tutorial_rect.has_point(p): tutorial_step=0; begin_match(); return
		return
	if game_over: get_tree().reload_current_scene(); return
	if summon_rect.has_point(p): summon(); return
	if wave_rect.has_point(p): start_wave(); return
	if merge_rect.has_point(p): merge_selected(); return
	for i in units.size():
		if units[i].pos.distance_to(p)<32: selected=i; return
	if selected>=0: move_selected_to(p)

func _draw() -> void:
	var size := get_viewport_rect().size
	if screen=="menu": draw_menu(size); return
	var map:Dictionary=GameContent.MAPS[map_index]
	draw_texture_rect(ARENA_TEX,Rect2(Vector2.ZERO,size),false)
	draw_rect(Rect2(0,0,size.x,92),Color(0.025,0.06,0.1,0.92))
	draw_rect(Rect2(0,size.y-96,size.x,96),Color(0.025,0.06,0.1,0.92))
	if map_index>0: draw_rect(Rect2(Vector2.ZERO,size),Color(map.ground,0.08))
	for slot in SLOTS:
		draw_circle(slot,31,Color(0.05,0.2,0.24,0.20)); draw_arc(slot,34,0,TAU,40,Color(0.35,0.95,0.88,0.48),2)
	draw_string(ThemeDB.fallback_font,Vector2(28,42),"CRITTER COVENANT",HORIZONTAL_ALIGNMENT_LEFT,400,30,Color("#f4e8bf"))
	draw_string(ThemeDB.fallback_font,Vector2(28,78),"❤ %d    ✦ %d Essence    Welle %d    Gegner %d" %[lives,essence,wave,enemies.size()+spawn_left],0,-1,21,Color.WHITE)
	var cov := active_covenants()
	draw_string(ThemeDB.fallback_font,Vector2(size.x-390,42),"Covenants: "+(", ".join(cov) if cov else "—"),0,360,18,Color("#f0d96c"))
	for e in enemies:
		var ep:Vector2=e.pos
		var sprite_size:=92.0 if e.boss else 54.0
		var sprite:Texture2D=ENEMY_SPRITES[4 if e.boss else int(e.kind)]
		draw_texture_rect(sprite,Rect2(ep-Vector2(sprite_size/2,sprite_size*0.68),Vector2(sprite_size,sprite_size)),false)
		if e.boss: draw_arc(ep,e.radius+9,0,TAU,48,Color("#ffdb70"),3)
		draw_rect(Rect2(ep.x-e.radius,ep.y-e.radius-9,e.radius*2,4),Color("#401b32"))
		draw_rect(Rect2(ep.x-e.radius,ep.y-e.radius-9,e.radius*2*maxf(0,e.hp/e.max_hp),4),Color("#72e082"))
	for p in projectiles: draw_circle(p.pos,5,p.color)
	for p in particles: draw_circle(p.pos,maxf(1,p.life*9),Color(p.color,p.life*1.8))
	for i in units.size():
		var u:=units[i]; var d:Dictionary=UNIT_DEFS[u.type]
		if i==selected: draw_circle(u.pos,43,Color(1,0.88,0.35,0.28)); draw_arc(u.pos,float(d.range),0,TAU,64,Color(0.4,1,0.85,0.18),2)
		draw_texture_rect(PORTRAITS[u.type],Rect2(u.pos-Vector2(43,62),Vector2(86,86)),false)
		draw_string(ThemeDB.fallback_font,u.pos+Vector2(-55,38),d.name,1,110,12,Color.WHITE)
		draw_circle(u.pos+Vector2(28,-30),12,Color("#18243c")); draw_string(ThemeDB.fallback_font,u.pos+Vector2(20,-24),str(u.level),1,16,13,Color("#ffe27a"))
	summon_rect=Rect2(size.x-245,size.y-72,215,50); wave_rect=Rect2(30,size.y-72,190,50); merge_rect=Rect2(size.x/2-95,size.y-72,190,50)
	draw_button(wave_rect,"NÄCHSTE WELLE",not wave_running); draw_button(summon_rect,"BESCHWÖREN 25",essence>=25); draw_button(merge_rect,"3× MERGE",selected>=0)
	if selected>=0 and selected<units.size(): draw_unit_card(size,units[selected])
	if combo>=2: draw_string(ThemeDB.fallback_font,Vector2(size.x-175,83),"%d× COMBO"%combo,1,150,18,Color("#ffe36d"))
	if message_time>0 or game_over:
		draw_rect(Rect2(size.x/2-260,112,520,48),Color(0.05,0.08,0.12,0.9))
		draw_string(ThemeDB.fallback_font,Vector2(size.x/2-245,145),message,1,490,20,Color.WHITE)
	if tutorial_step<3:
		var tips:=["Beschwöre einen zufälligen Hüter.","Wähle gleiche Hüter und merge drei davon.","Starte die Welle und verteidige den Pfad."]
		draw_rect(Rect2(330,size.y-126,620,42),Color(0.02,0.05,0.08,0.94))
		draw_string(ThemeDB.fallback_font,Vector2(345,size.y-98),"TUTORIAL %d/3  %s"%[tutorial_step+1,tips[tutorial_step]],1,590,16,Color("#fff0a6"))

func draw_button(rect:Rect2,label:String,enabled:bool) -> void:
	draw_texture_rect(BUTTON_TEX,rect,false,Color("#ef9e3f") if enabled else Color("#65717c"))
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(8,33),label,1,rect.size.x-16,18,Color.WHITE)

func draw_menu(size:Vector2) -> void:
	draw_texture_rect(ARENA_TEX,Rect2(Vector2.ZERO,size),false)
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.015,0.04,0.08,0.72))
	draw_rect(Rect2(size.x/2-390,58,780,605),Color(0.02,0.065,0.105,0.82))
	draw_string(ThemeDB.fallback_font,Vector2(size.x/2-360,145),"CRITTER COVENANT",1,720,48,Color("#ffe6a0"))
	draw_string(ThemeDB.fallback_font,Vector2(size.x/2-300,190),"SCHMIEDE PAKTE. BESIEGE DIE VERDERBNIS.",1,600,17,Color("#a9cad0"))
	for i in 6: draw_texture_rect(PORTRAITS[i],Rect2(size.x/2-275+i*90,218+sin(i)*10,86,86),false)
	var map:Dictionary=GameContent.MAPS[map_index]
	menu_map_rect=Rect2(size.x/2-240,345,480,70); draw_texture_rect(BUTTON_TEX,menu_map_rect,false,Color("#387f83"))
	draw_string(ThemeDB.fallback_font,Vector2(size.x/2-225,375),map.name,1,450,23,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(size.x/2-225,400),map.subtitle,1,450,14,Color("#c9e7e2"))
	menu_play_rect=Rect2(size.x/2-170,450,340,64); draw_button(menu_play_rect,"ABENTEUER STARTEN",true)
	tutorial_rect=Rect2(size.x/2-120,535,240,50); draw_button(tutorial_rect,"TUTORIAL",true)
	draw_string(ThemeDB.fallback_font,Vector2(size.x/2-250,size.y-55),"Bestwelle %d   ✦ %d Sternenstaub"%[best_wave,star_dust],1,500,17,Color("#e5d990"))

func draw_unit_card(size:Vector2,u:Dictionary) -> void:
	var d:Dictionary=UNIT_DEFS[u.type]; var rect:=Rect2(size.x-300,112,270,122)
	draw_rect(rect,Color(0.04,0.08,0.13,0.94)); draw_texture_rect(PORTRAITS[u.type],Rect2(rect.position+Vector2(12,14),Vector2(74,74)),false)
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(96,32),d.name,0,155,19,Color.WHITE)
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(96,55),"%s · %s"%[d.rarity,d.element],0,160,13,d.accent)
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(96,78),d.ability,0,160,15,Color("#dcebf2"))
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(12,108),"Stufe %d · Schaden %d · Reichweite %d"%[u.level,int(d.damage*u.level),int(d.range)],0,245,13,Color("#b9cad3"))

func begin_match() -> void:
	screen="match"; essence=120; lives=20; wave=0; units.clear(); enemies.clear(); projectiles.clear(); selected=-1; game_over=false

func save_progress() -> void:
	best_wave=maxi(best_wave,wave)
	var f:=FileAccess.open("user://save.json",FileAccess.WRITE)
	if f: f.store_string(JSON.stringify({"version":2,"best_wave":best_wave,"star_dust":star_dust,"last_map":map_index}))

func load_progress() -> void:
	if FileAccess.file_exists("user://save.json"):
		var data=JSON.parse_string(FileAccess.get_file_as_string("user://save.json"))
		if data is Dictionary:
			best_wave=int(data.get("best_wave",0)); star_dust=int(data.get("star_dust",0)); map_index=clampi(int(data.get("last_map",0)),0,GameContent.MAPS.size()-1)
			message="Willkommen zurück – Bestwelle %d" % best_wave
