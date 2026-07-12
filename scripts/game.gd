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
var elite_wave := false
var paused := false
var emergency_ready := true
var victory := false
var match_kills := 0
var match_essence_earned := 0
var total_wins := 0
var matches_played := 0
var achievements:Array[String] = []
var speed_rect:=Rect2()
var pause_rect:=Rect2()
var emergency_rect:=Rect2()
var result_rect:=Rect2()
var collection_rect:=Rect2()
var codex_rect:=Rect2()
var profile_rect:=Rect2()
var back_rect:=Rect2()
var focused_rect:=Rect2()
var focus_cycle_rect:=Rect2()
var selected_collection_unit:=-1
var pity_counter:=0
var focus_element_index:=0
const FOCUS_ELEMENTS:=["Nature","Fire","Water","Storm","Arcane","Guardian","Alchemist"]

func _ready() -> void:
	rng.seed = int(Time.get_unix_time_from_system())
	load_progress()
	queue_redraw()

func _process(delta:float) -> void:
	if screen != "match": queue_redraw(); return
	if paused: queue_redraw(); return
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
		if wave>=MatchRules.FINAL_WAVE: finish_match(true); return
		var wave_reward:=MatchRules.wave_reward(wave)
		essence += wave_reward; match_essence_earned+=wave_reward
		message = "Welle geschafft! +%d Essence" % wave_reward
		message_time = 3.0
		save_progress()
	queue_redraw()

func start_wave() -> void:
	if wave_running or game_over: return
	wave += 1
	boss_wave = MatchRules.is_boss_wave(wave)
	elite_wave = MatchRules.is_elite_wave(wave)
	spawn_left = MatchRules.enemy_count(wave)
	wave_running = true
	message = "BOSS: Der Verderbnis-Koloss!" if boss_wave else ("ELITE-WELLE %d"%wave if elite_wave else "Welle %d beginnt" % wave)
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
	elif elite_wave and spawn_left%3==0:
		hp*=2.8; speed_value*=0.9; radius*=1.35; color=Color("#e65ca8")
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
				if lives <= 0: finish_match(false); return

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
				match_essence_earned+=reward; match_kills+=1
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

func emergency_bloom() -> void:
	if not emergency_ready or screen!="match": return
	emergency_ready=false
	for e in enemies:
		e.hp*=0.55; e.slow=4.0; burst(e.pos,Color("#8ffff0"),9)
	lives=mini(20,lives+3)
	message="COVENANT-BLÜTE: Gegner geschwächt · +3 Herzen"; message_time=3.0

func finish_match(won:bool) -> void:
	victory=won; screen="result"; wave_running=false; matches_played+=1
	best_wave=maxi(best_wave,wave)
	var reward:=MatchRules.result_reward(wave,won)
	star_dust+=reward
	if won: total_wins+=1; unlock_achievement("Covenant Ascendant")
	if wave>=10: unlock_achievement("Hold the Crossroads")
	if match_kills>=100: unlock_achievement("Hundred Sparks")
	if active_covenants().size()>=3: unlock_achievement("Oathweaver")
	save_progress()

func unlock_achievement(title:String) -> void:
	if not achievements.has(title): achievements.append(title)

func summon(focused:=false) -> void:
	var cost:=45 if focused else 25
	if essence < cost or units.size() >= 12: message="Nicht genug Essence oder Brett voll"; message_time=2; return
	essence -= cost
	var type:=pick_unit(focused)
	if SummonRules.resets_pity(UNIT_DEFS[type].rarity): pity_counter=0
	else: pity_counter+=1
	var slot:=first_free_slot()
	units.append({"type":type,"level":1,"pos":SLOTS[slot],"slot":slot,"cooldown":rng.randf_range(0,0.5)})
	message = "%s schließt sich dem Pakt an!" % UNIT_DEFS[type].name
	message_time=2
	if tutorial_step==0: tutorial_step=1

func pick_unit(focused:bool) -> int:
	var weights:Array[int]=[]; var total:=0; var focus:String=FOCUS_ELEMENTS[focus_element_index]
	for i in UNIT_DEFS.size():
		var weight:=SummonRules.adjusted_weight(GameContent.rarity_weight(i),UNIT_DEFS[i].rarity,UNIT_DEFS[i].element,pity_counter,focused,focus)
		weights.append(weight); total+=weight
	var roll:=rng.randi_range(1,total)
	for i in weights.size():
		roll-=weights[i]
		if roll<=0: return i
	return 0

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
		if tutorial_rect.has_point(p): begin_match(); tutorial_step=0; return
		if collection_rect.has_point(p): screen="collection"; return
		if codex_rect.has_point(p): screen="codex"; return
		if profile_rect.has_point(p): screen="profile"; return
		return
	if screen in ["collection","codex","profile"]:
		if back_rect.has_point(p): selected_collection_unit=-1; screen="menu"; return
		if screen=="collection":
			for i in UNIT_DEFS.size():
				var card:=Rect2(90+(i%4)*285,145+(i/4)*150,250,125)
				if card.has_point(p): selected_collection_unit=i; return
		return
	if screen=="result":
		if result_rect.has_point(p): screen="menu"
		return
	if game_over: get_tree().reload_current_scene(); return
	if pause_rect.has_point(p): paused=not paused; return
	if speed_rect.has_point(p): speed=1.0 if speed>=3.0 else speed+1.0; return
	if emergency_rect.has_point(p): emergency_bloom(); return
	if focused_rect.has_point(p): summon(true); return
	if focus_cycle_rect.has_point(p): focus_element_index=(focus_element_index+1)%FOCUS_ELEMENTS.size(); return
	if summon_rect.has_point(p): summon(); return
	if wave_rect.has_point(p): start_wave(); return
	if merge_rect.has_point(p): merge_selected(); return
	for i in units.size():
		if units[i].pos.distance_to(p)<32: selected=i; return
	if selected>=0: move_selected_to(p)

func _draw() -> void:
	var size := get_viewport_rect().size
	if screen=="menu": draw_menu(size); return
	if screen=="result": draw_result(size); return
	if screen=="collection": draw_collection(size); return
	if screen=="codex": draw_codex(size); return
	if screen=="profile": draw_profile(size); return
	var map:Dictionary=GameContent.MAPS[map_index]
	draw_rect(Rect2(0,0,size.x,92),Color(0.025,0.06,0.1,0.92))
	draw_rect(Rect2(0,size.y-96,size.x,96),Color(0.025,0.06,0.1,0.92))
	if map_index>0: draw_rect(Rect2(Vector2.ZERO,size),Color(map.ground,0.08))
	for slot in SLOTS:
		draw_circle(slot,31,Color(0.05,0.2,0.24,0.20)); draw_arc(slot,34,0,TAU,40,Color(0.35,0.95,0.88,0.48),2)
	draw_string(ThemeDB.fallback_font,Vector2(28,42),"CRITTER COVENANT",HORIZONTAL_ALIGNMENT_LEFT,400,30,Color("#f4e8bf"))
	draw_string(ThemeDB.fallback_font,Vector2(28,78),"❤ %d    ✦ %d Essence    Welle %d/30    Gegner %d" %[lives,essence,wave,enemies.size()+spawn_left],0,-1,21,Color.WHITE)
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
	emergency_rect=Rect2(size.x-465,size.y-72,195,50); draw_button(emergency_rect,"COVENANT-BLÜTE",emergency_ready)
	focused_rect=Rect2(245,size.y-72,190,50); draw_button(focused_rect,"FOCUS 45",essence>=45)
	focus_cycle_rect=Rect2(445,size.y-72,120,50); draw_button(focus_cycle_rect,FOCUS_ELEMENTS[focus_element_index],true)
	speed_rect=Rect2(size.x-155,18,55,42); pause_rect=Rect2(size.x-88,18,55,42)
	draw_button(speed_rect,"%d×"%int(speed),true); draw_button(pause_rect,"▶" if paused else "Ⅱ",true)
	if selected>=0 and selected<units.size(): draw_unit_card(size,units[selected])
	if combo>=2: draw_string(ThemeDB.fallback_font,Vector2(size.x-175,83),"%d× COMBO"%combo,1,150,18,Color("#ffe36d"))
	if message_time>0 or game_over:
		draw_rect(Rect2(size.x/2-260,112,520,48),Color(0.05,0.08,0.12,0.9))
		draw_string(ThemeDB.fallback_font,Vector2(size.x/2-245,145),message,1,490,20,Color.WHITE)
	if tutorial_step<3:
		var tips:=["Beschwöre einen zufälligen Hüter.","Wähle gleiche Hüter und merge drei davon.","Starte die Welle und verteidige den Pfad."]
		draw_rect(Rect2(330,size.y-126,620,42),Color(0.02,0.05,0.08,0.94))
		draw_string(ThemeDB.fallback_font,Vector2(345,size.y-98),"TUTORIAL %d/3  %s"%[tutorial_step+1,tips[tutorial_step]],1,590,16,Color("#fff0a6"))
	if paused:
		draw_rect(Rect2(Vector2.ZERO,size),Color(0,0,0,0.58)); draw_string(ThemeDB.fallback_font,Vector2(size.x/2-180,size.y/2),"PAUSIERT",1,360,36,Color.WHITE)

func draw_button(rect:Rect2,label:String,enabled:bool) -> void:
	draw_texture_rect(BUTTON_TEX,rect,false,Color("#ef9e3f") if enabled else Color("#65717c"))
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(8,33),label,1,rect.size.x-16,18,Color.WHITE)

func draw_menu(size:Vector2) -> void:
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
	tutorial_rect=Rect2(250,535,175,50); draw_button(tutorial_rect,"TUTORIAL",true)
	collection_rect=Rect2(440,535,175,50); draw_button(collection_rect,"SAMMLUNG",true)
	codex_rect=Rect2(630,535,175,50); draw_button(codex_rect,"COVENANTS",true)
	profile_rect=Rect2(820,535,175,50); draw_button(profile_rect,"PROFIL",true)
	draw_string(ThemeDB.fallback_font,Vector2(size.x/2-250,size.y-55),"Bestwelle %d   ✦ %d Sternenstaub"%[best_wave,star_dust],1,500,17,Color("#e5d990"))

func draw_meta_header(size:Vector2,title:String,subtitle:String) -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.01,0.035,0.06,0.88))
	draw_string(ThemeDB.fallback_font,Vector2(70,72),title,0,700,36,Color("#ffe59a"))
	draw_string(ThemeDB.fallback_font,Vector2(72,105),subtitle,0,850,16,Color("#a9cad0"))
	back_rect=Rect2(size.x-205,35,155,50); draw_button(back_rect,"ZURÜCK",true)

func draw_collection(size:Vector2) -> void:
	draw_meta_header(size,"HÜTER-SAMMLUNG","12 magische Verbündete · tippe eine Karte für Details")
	for i in UNIT_DEFS.size():
		var d:Dictionary=UNIT_DEFS[i]; var card:=Rect2(90+(i%4)*285,145+(i/4)*150,250,125)
		draw_rect(card,Color(0.035,0.09,0.12,0.94)); draw_rect(Rect2(card.position,Vector2(6,card.size.y)),d.color)
		draw_texture_rect(PORTRAITS[i],Rect2(card.position+Vector2(8,6),Vector2(105,105)),false)
		draw_string(ThemeDB.fallback_font,card.position+Vector2(112,30),d.name,0,130,17,Color.WHITE)
		draw_string(ThemeDB.fallback_font,card.position+Vector2(112,55),d.rarity,0,130,13,d.accent)
		draw_string(ThemeDB.fallback_font,card.position+Vector2(112,77),d.element+" · "+d.role,0,130,12,Color("#b5cbd1"))
		draw_string(ThemeDB.fallback_font,card.position+Vector2(112,101),d.ability,0,130,12,Color("#f2dca0"))
	if selected_collection_unit>=0:
		var d:Dictionary=UNIT_DEFS[selected_collection_unit]; var panel:=Rect2(300,155,680,400)
		draw_rect(panel,Color(0.015,0.045,0.075,0.98)); draw_texture_rect(PORTRAITS[selected_collection_unit],Rect2(325,185,260,260),false)
		draw_string(ThemeDB.fallback_font,Vector2(595,220),d.name,0,340,30,Color.WHITE)
		draw_string(ThemeDB.fallback_font,Vector2(595,252),d.rarity+" · "+d.element+" · "+d.role,0,340,15,d.accent)
		draw_string(ThemeDB.fallback_font,Vector2(595,300),d.ability,0,340,22,Color("#ffe49a"))
		draw_string(ThemeDB.fallback_font,Vector2(595,340),"Schaden %d   Reichweite %d   Tempo %.2f"%[int(d.damage),int(d.range),float(d.rate)],0,340,15,Color("#c9dce1"))
		draw_string(ThemeDB.fallback_font,Vector2(595,390),"Elementfähigkeiten verändern Angriffe und" ,0,340,14,Color("#a9c4cc"))
		draw_string(ThemeDB.fallback_font,Vector2(595,412),"kombinieren sich zu mächtigen Covenants.",0,340,14,Color("#a9c4cc"))

func draw_codex(size:Vector2) -> void:
	draw_meta_header(size,"COVENANT-CODEX","Pakte entstehen aus Elementkombinationen – nicht aus einzelnen Meta-Boni")
	var entries:=[
		["Dornenbund","2× Nature","Wachsende Dornen und verstärkte Projektile","#75dc7c"],
		["Flammenwirbel","Fire + Storm","Flächenschaden und Kettenreaktionen","#ff925f"],
		["Gezeitenblitz","Water + Storm","Slow kombiniert mit Kettenblitzen","#63d9ed"],
		["Schutzquell","Guardian + Water","Heilung und defensive Kontrolle","#8ed4b2"],
		["Sterneneid","2× Arcane","Execute-Schaden gegen geschwächte Gegner","#d09aff"]]
	for i in entries.size():
		var row:=Rect2(145,150+i*98,990,78); draw_rect(row,Color(0.03,0.085,0.115,0.94)); draw_rect(Rect2(row.position,Vector2(8,row.size.y)),Color(entries[i][3]))
		draw_string(ThemeDB.fallback_font,row.position+Vector2(35,31),entries[i][0],0,240,21,Color.WHITE)
		draw_string(ThemeDB.fallback_font,row.position+Vector2(285,29),entries[i][1],0,210,16,Color(entries[i][3]))
		draw_string(ThemeDB.fallback_font,row.position+Vector2(500,29),entries[i][2],0,450,15,Color("#c1d7dc"))

func draw_profile(size:Vector2) -> void:
	draw_meta_header(size,"HÜTER-PROFIL","Fortschritt, Quests und Achievements werden lokal gespeichert")
	draw_string(ThemeDB.fallback_font,Vector2(125,185),"PROFILSTUFE %d"%(1+star_dust/100),0,350,28,Color("#ffe18a"))
	draw_string(ThemeDB.fallback_font,Vector2(125,225),"%d Sternenstaub · %d Siege · %d Matches"%[star_dust,total_wins,matches_played],0,600,18,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(125,285),"AKTIVE QUESTS",0,300,20,Color("#8fe5d2"))
	var quests:=[["Erreiche Welle 10",mini(best_wave,10),10],["Gewinne 3 Matches",mini(total_wins,3),3],["Sammle 500 Sternenstaub",mini(star_dust,500),500]]
	for i in quests.size():
		var y:=320+i*74; draw_rect(Rect2(125,y,680,56),Color(0.035,0.09,0.12,0.95)); draw_string(ThemeDB.fallback_font,Vector2(145,y+25),quests[i][0],0,350,16,Color.WHITE)
		draw_rect(Rect2(500,y+20,270,12),Color("#163744")); draw_rect(Rect2(500,y+20,270.0*float(quests[i][1])/float(quests[i][2]),12),Color("#55d1a8"))
	draw_string(ThemeDB.fallback_font,Vector2(855,285),"ACHIEVEMENTS",0,300,20,Color("#f0d778"))
	for i in achievements.size(): draw_string(ThemeDB.fallback_font,Vector2(855,330+i*32),"✦ "+achievements[i],0,320,16,Color("#e9dfb0"))

func draw_unit_card(size:Vector2,u:Dictionary) -> void:
	var d:Dictionary=UNIT_DEFS[u.type]; var rect:=Rect2(size.x-300,112,270,122)
	draw_rect(rect,Color(0.04,0.08,0.13,0.94)); draw_texture_rect(PORTRAITS[u.type],Rect2(rect.position+Vector2(12,14),Vector2(74,74)),false)
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(96,32),d.name,0,155,19,Color.WHITE)
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(96,55),"%s · %s"%[d.rarity,d.element],0,160,13,d.accent)
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(96,78),d.ability,0,160,15,Color("#dcebf2"))
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(12,108),"Stufe %d · Schaden %d · Reichweite %d"%[u.level,int(d.damage*u.level),int(d.range)],0,245,13,Color("#b9cad3"))

func draw_result(size:Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.01,0.03,0.06,0.78))
	var panel:=Rect2(size.x/2-330,75,660,570); draw_rect(panel,Color(0.025,0.08,0.12,0.95))
	draw_string(ThemeDB.fallback_font,Vector2(size.x/2-280,150),"COVENANT GERETTET" if victory else "DIE VERDERBNIS SIEGT",1,560,38,Color("#ffe58c") if victory else Color("#ff799d"))
	draw_string(ThemeDB.fallback_font,Vector2(size.x/2-250,210),"Erreichte Welle",1,500,17,Color("#9fc8d2"))
	draw_string(ThemeDB.fallback_font,Vector2(size.x/2-180,285),str(wave),1,360,64,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(size.x/2-250,340),"%d Gegner besiegt   ·   %d Essence verdient"%[match_kills,match_essence_earned],1,500,18,Color("#d8e8eb"))
	draw_string(ThemeDB.fallback_font,Vector2(size.x/2-250,382),"Belohnung: +%d Sternenstaub"%MatchRules.result_reward(wave,victory),1,500,21,Color("#f7d76e"))
	draw_string(ThemeDB.fallback_font,Vector2(size.x/2-250,425),"Achievements: %d   ·   Siege: %d"%[achievements.size(),total_wins],1,500,16,Color("#a9c4cf"))
	result_rect=Rect2(size.x/2-160,510,320,62); draw_button(result_rect,"ZURÜCK ZUM HEILIGTUM",true)

func begin_match() -> void:
	screen="match"; essence=120; lives=20; wave=0; units.clear(); enemies.clear(); projectiles.clear(); particles.clear(); selected=-1; game_over=false
	match_kills=0; match_essence_earned=0; emergency_ready=true; paused=false; speed=1.0; tutorial_step=3

func save_progress() -> void:
	best_wave=maxi(best_wave,wave)
	var f:=FileAccess.open("user://save.json",FileAccess.WRITE)
	if f: f.store_string(JSON.stringify({"version":3,"best_wave":best_wave,"star_dust":star_dust,"last_map":map_index,"total_wins":total_wins,"matches_played":matches_played,"achievements":achievements}))

func load_progress() -> void:
	if FileAccess.file_exists("user://save.json"):
		var data=JSON.parse_string(FileAccess.get_file_as_string("user://save.json"))
		if data is Dictionary:
			best_wave=int(data.get("best_wave",0)); star_dust=int(data.get("star_dust",0)); map_index=clampi(int(data.get("last_map",0)),0,GameContent.MAPS.size()-1)
			total_wins=int(data.get("total_wins",0)); matches_played=int(data.get("matches_played",0))
			var saved_achievements=data.get("achievements",[])
			if saved_achievements is Array: achievements.assign(saved_achievements)
			message="Willkommen zurück – Bestwelle %d" % best_wave
