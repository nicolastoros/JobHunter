class_name GameData
extends RefCounted
## Static game data: items, equipment, skills, talents, loot and the hero's looks.
## Icons are either a path to a PNG or [x, y] of a 16x16 cell in the UI pack's Icons.png.

const UI_ICONS := "res://assets/ui/pack/Icons.png"
const EQ := "res://assets/ui/icons/equip/"
const SK := "res://assets/ui/icons/skills/"
const MAX_LEVEL := 99

# --- Consumables & materials --------------------------------------------------------
const ITEMS := {
	"pocion": {"name": "Poción de vida", "desc": "Recupera 30 % de la vida.", "icon": [48, 272], "use": "hp", "amount": 0.3},
	"eter": {"name": "Poción de maná", "desc": "Recupera 40 % del maná.", "icon": [32, 272], "use": "mana", "amount": 0.4},
	"manzana": {"name": "Manzana", "desc": "Fresca y crujiente. Recupera 15 % de la vida.", "icon": [80, 80], "use": "hp", "amount": 0.15},
	"gel": {"name": "Gel de limo", "desc": "Material. Pegajoso y algo tibio. Los alquimistas lo aprecian.", "icon": [48, 144]},
	"abalorio": {"name": "Abalorio goblin", "desc": "Material. Los goblins los cuelgan de sus lanzas como trofeo.", "icon": [0, 144]},
	"piel": {"name": "Piel de gnoll", "desc": "Material. Gruesa y resistente; buena para curtir.", "icon": [64, 144]},
	"nucleo": {"name": "Núcleo de piedra", "desc": "El corazón del Gólem de las Ruinas. Todavía brilla con una luz tenue.", "icon": [80, 160]},
	"corteza": {"name": "Corteza antigua", "desc": "Un trozo del Ent Ancestral. Huele a lluvia y a siglos.", "icon": [64, 80]},
	"corona": {"name": "Corona de gel", "desc": "Lo único que quedó del Rey Limo. Tiembla si la tocas.", "icon": [64, 128]},
}

# --- Equipment ------------------------------------------------------------------------
const SLOTS := ["weapon", "helmet", "chest", "gloves", "boots", "trinket"]
const SLOT_NAMES := {"weapon": "Arma", "helmet": "Cabeza", "chest": "Torso", "gloves": "Manos", "boots": "Pies", "trinket": "Accesorio"}
## atk / def / hp / mana / speed (fraction) bonuses; `level` = level required to equip.
const EQUIPMENT := {
	"espada_corta": {"name": "Espada corta", "slot": "weapon", "level": 1, "atk": 1, "desc": "Una hoja sencilla, pero bien equilibrada."},
	"espada_hierro": {"name": "Espada de hierro", "slot": "weapon", "level": 3, "atk": 2, "desc": "La espada de cualquier guardia de Valdoria."},
	"hacha_lenador": {"name": "Hacha de leñador", "slot": "weapon", "level": 5, "atk": 3, "speed": -0.03, "desc": "Pesada. Corta leña y lo que se ponga delante."},
	"espada_acero": {"name": "Espada de acero", "slot": "weapon", "level": 8, "atk": 4, "desc": "Acero templado en las forjas del puerto."},
	"maza_tachonada": {"name": "Maza tachonada", "slot": "weapon", "level": 11, "atk": 6, "speed": -0.03, "desc": "Lenta, pero ningún caparazón la resiste."},
	"hoja_centinela": {"name": "Hoja del centinela", "slot": "weapon", "level": 15, "atk": 7, "def": 1, "desc": "La llevaban los guardianes de las antiguas ruinas."},
	"espada_ignea": {"name": "Espada ígnea", "slot": "weapon", "level": 24, "atk": 10, "desc": "El filo nunca termina de enfriarse."},
	"hoja_marina": {"name": "Hoja marina", "slot": "weapon", "level": 36, "atk": 14, "mana": 20, "desc": "Forjada con acero que pasó un siglo bajo el mar."},
	"espada_alba": {"name": "Espada del alba", "slot": "weapon", "level": 55, "atk": 20, "hp": 10, "desc": "Dicen que brilla un poco más cada amanecer."},
	"gorro_cuero": {"name": "Capucha de cuero", "slot": "helmet", "level": 1, "def": 1, "desc": "Protege del sol y de algún que otro golpe."},
	"casco_hierro": {"name": "Casco de hierro", "slot": "helmet", "level": 7, "def": 2, "hp": 4, "desc": "Abollado, pero firme."},
	"yelmo_astado": {"name": "Yelmo astado", "slot": "helmet", "level": 20, "def": 4, "hp": 10, "desc": "Los cuernos son de un ciervo de las colinas."},
	"jubon_cuero": {"name": "Jubón de cuero", "slot": "chest", "level": 1, "def": 1, "desc": "Ropa de viaje reforzada."},
	"coraza_hierro": {"name": "Coraza de hierro", "slot": "chest", "level": 8, "def": 3, "hp": 6, "desc": "Pesa, pero detiene casi cualquier mordida."},
	"coraza_templada": {"name": "Coraza templada", "slot": "chest", "level": 18, "def": 5, "hp": 12, "desc": "Acero templado con remaches de bronce."},
	"armadura_abisal": {"name": "Armadura abisal", "slot": "chest", "level": 34, "def": 8, "hp": 20, "mana": 20, "desc": "Escamas de algo que vivía muy por debajo del muelle."},
	"guantes_cuero": {"name": "Guantes de cuero", "slot": "gloves", "level": 2, "def": 1, "desc": "Para que la empuñadura no resbale."},
	"guanteletes_hierro": {"name": "Guanteletes de hierro", "slot": "gloves", "level": 12, "def": 2, "atk": 1, "desc": "Cada golpe pesa un poco más."},
	"botas_viaje": {"name": "Botas de viaje", "slot": "boots", "level": 1, "def": 1, "speed": 0.03, "desc": "Cómodas para recorrer la llanura."},
	"grebas_hierro": {"name": "Grebas de hierro", "slot": "boots", "level": 10, "def": 2, "hp": 4, "desc": "Firmes en cualquier terreno."},
	"botas_igneas": {"name": "Botas ígneas", "slot": "boots", "level": 26, "def": 3, "speed": 0.06, "desc": "Dejan un leve olor a ceniza al caminar."},
	"anillo_cobre": {"name": "Anillo de cobre", "slot": "trinket", "level": 3, "hp": 4, "desc": "Un regalo sencillo. Da algo de ánimo."},
	"amuleto_cazador": {"name": "Amuleto del cazador", "slot": "trinket", "level": 9, "mana": 20, "desc": "El Gremio se lo entrega a quienes vuelven de su primera cacería."},
	"anillo_rubi": {"name": "Anillo de rubí", "slot": "trinket", "level": 16, "atk": 2, "hp": 6, "desc": "La piedra se calienta cuando hay peligro cerca."},
	"amuleto_brasa": {"name": "Amuleto de brasa", "slot": "trinket", "level": 30, "atk": 4, "mana": 30, "desc": "Una brasa que no se apaga, encerrada en metal."},
}
const START_EQUIPMENT := {"weapon": "espada_corta", "chest": "jubon_cuero"}

# --- Forge ------------------------------------------------------------------------------
## Equipment can be improved up to +10 at the forge. An improved piece is stored as "id+N".
const MAX_PLUS := 10
## Materials and gold to reach each level (+1 ... +10).
const FORGE_COSTS := [
	{"gold": 40, "items": {"gel": 2}},
	{"gold": 80, "items": {"gel": 3}},
	{"gold": 140, "items": {"gel": 4, "abalorio": 1}},
	{"gold": 220, "items": {"abalorio": 2, "piel": 1}},
	{"gold": 320, "items": {"abalorio": 3, "piel": 2}},
	{"gold": 450, "items": {"piel": 3, "gel": 6}},
	{"gold": 600, "items": {"piel": 4, "nucleo": 1}},
	{"gold": 800, "items": {"piel": 5, "corteza": 1}},
	{"gold": 1000, "items": {"abalorio": 5, "corona": 1}},
	{"gold": 1500, "items": {"nucleo": 1, "corteza": 1, "corona": 1}},
]

# --- Loot ---------------------------------------------------------------------------
## [item, chance, amount] dropped by each monster (by name).
const LOOT := {
	"Limo": [["gel", 0.6, 1]], "Limo extraño": [["gel", 0.8, 2]],
	"Goblin": [["abalorio", 0.45, 1], ["manzana", 0.2, 1]], "Gnoll": [["piel", 0.5, 1]],
	"Gólem de las Ruinas": [["nucleo", 1.0, 1], ["pocion", 1.0, 2]],
	"Ent Ancestral": [["corteza", 1.0, 1], ["eter", 1.0, 2]],
	"Rey Limo": [["corona", 1.0, 1], ["gel", 1.0, 3]],
}
const EQUIP_DROP_CHANCE := 0.05

# --- Skills -----------------------------------------------------------------------------
## Six active skills on keys 1-6. `level` = hero level to learn it. Ranks 1-5 are bought with skill experience.
const MAX_SKILL_RANK := 5
const SKILLS := [
	{"id": "giro", "name": "Corte giratorio", "icon": SK + "giro.png", "mana": 20, "level": 1},
	{"id": "embestida", "name": "Embestida", "icon": SK + "embestida.png", "mana": 15, "level": 3},
	{"id": "grito", "name": "Grito de guerra", "icon": SK + "grito.png", "mana": 30, "level": 6},
	{"id": "respiro", "name": "Respiro", "icon": SK + "respiro.png", "mana": 35, "level": 9},
	{"id": "onda", "name": "Onda de choque", "icon": SK + "onda.png", "mana": 35, "level": 13},
	{"id": "tajo", "name": "Tajo de luz", "icon": SK + "tajo.png", "mana": 40, "level": 20},
]

# --- Talents ----------------------------------------------------------------------------
## Talent points: 3 per level. They go to the three main attributes (no limit) or to the tree.
const TALENT_POINTS_PER_LEVEL := 3
const TI := "res://assets/ui/icons/talents/"
const MAINS := [
	{"id": "vida", "name": "Vida", "desc": "+4 de vida máxima por punto.", "icon": TI + "main_vida.png", "color": Color(0.75, 0.2, 0.18)},
	{"id": "energia", "name": "Energía", "desc": "+10 de estamina máxima por punto; la estamina vuelve un 2 % más rápido.", "icon": TI + "main_energia.png", "color": Color(0.25, 0.6, 0.22)},
	{"id": "magia", "name": "Magia", "desc": "+6 de maná máximo y +2 % de daño de habilidades por punto.", "icon": TI + "main_magia.png", "color": Color(0.22, 0.38, 0.8)},
]
const BRANCHES := [
	{"id": "guerrero", "name": "Senda del Guerrero", "color": Color(0.72, 0.22, 0.16)},
	{"id": "explorador", "name": "Senda del Explorador", "color": Color(0.24, 0.55, 0.2)},
	{"id": "mistico", "name": "Senda del Místico", "color": Color(0.24, 0.38, 0.78)},
]
## Points spent in a branch needed to open each tier (row) of it.
const TIER_POINTS := [0, 2, 5, 9, 14]
## Tree nodes. `fx` = bonus per rank; `req` = nodes that need at least one rank first.
## Bonus keys: hp, hp_pct, atk, atk_pct, def, crit, crit_dmg, lifesteal, guard (less damage taken),
## stamina, stamina_regen, run_cost, speed, dodge, gold, loot, xp, sxp, mana, mana_regen,
## skill_dmg, cdr, mana_cost, potion, mana_shield, kill_mana.
const TALENT_TREE := [
	# --- Guerrero
	{"id": "vigor", "branch": 0, "tier": 0, "col": 0, "name": "Vigor", "max": 5, "fx": {"hp": 3}, "req": [],
	 "desc": "+3 de vida máxima por rango."},
	{"id": "filo", "branch": 0, "tier": 0, "col": 2, "name": "Filo templado", "max": 5, "fx": {"atk": 1}, "req": [],
	 "desc": "+1 de ataque por rango."},
	{"id": "aguante", "branch": 0, "tier": 1, "col": 0, "name": "Aguante", "max": 3, "fx": {"hp_pct": 0.04}, "req": ["vigor"],
	 "desc": "+4 % de vida máxima por rango."},
	{"id": "piel_hierro", "branch": 0, "tier": 1, "col": 1, "name": "Piel de hierro", "max": 5, "fx": {"def": 1}, "req": ["vigor"],
	 "desc": "+1 de defensa por rango."},
	{"id": "golpe_certero", "branch": 0, "tier": 2, "col": 2, "name": "Golpe certero", "max": 5, "fx": {"crit": 0.03}, "req": ["filo"],
	 "desc": "+3 % de probabilidad de golpe crítico por rango."},
	{"id": "coraza_viva", "branch": 0, "tier": 2, "col": 0, "name": "Coraza viva", "max": 3, "fx": {"guard": 0.04}, "req": ["piel_hierro"],
	 "desc": "Recibes un 4 % menos de daño por rango."},
	{"id": "sed_sangre", "branch": 0, "tier": 3, "col": 1, "name": "Sed de sangre", "max": 3, "fx": {"lifesteal": 0.03}, "req": ["golpe_certero", "coraza_viva"],
	 "desc": "Recuperas un 3 % del daño que causas como vida, por rango."},
	{"id": "golpe_brutal", "branch": 0, "tier": 3, "col": 2, "name": "Golpe brutal", "max": 3, "fx": {"crit_dmg": 0.2}, "req": ["golpe_certero"],
	 "desc": "Los golpes críticos hacen un 20 % más de daño por rango."},
	{"id": "furia", "branch": 0, "tier": 4, "col": 1, "name": "Furia del cazador", "max": 3, "fx": {"atk_pct": 0.08}, "req": ["sed_sangre"],
	 "desc": "+8 % de ataque por rango."},
	# --- Explorador
	{"id": "pulmones", "branch": 1, "tier": 0, "col": 0, "name": "Pulmones de explorador", "max": 5, "fx": {"stamina": 15}, "req": [],
	 "desc": "+15 de estamina máxima por rango."},
	{"id": "paso_ligero", "branch": 1, "tier": 0, "col": 2, "name": "Paso ligero", "max": 5, "fx": {"speed": 0.03}, "req": [],
	 "desc": "+3 % de velocidad de movimiento por rango."},
	{"id": "recuperacion", "branch": 1, "tier": 1, "col": 0, "name": "Recuperación", "max": 3, "fx": {"stamina_regen": 0.15}, "req": ["pulmones"],
	 "desc": "La estamina se recupera un 15 % más rápido por rango."},
	{"id": "reflejos", "branch": 1, "tier": 1, "col": 2, "name": "Reflejos", "max": 5, "fx": {"dodge": 0.03}, "req": ["paso_ligero"],
	 "desc": "+3 % de probabilidad de esquivar un golpe por rango."},
	{"id": "ojo_mercader", "branch": 1, "tier": 2, "col": 0, "name": "Ojo de mercader", "max": 5, "fx": {"gold": 0.15}, "req": ["recuperacion"],
	 "desc": "Los monstruos sueltan un 15 % más de oro por rango."},
	{"id": "incansable", "branch": 1, "tier": 2, "col": 2, "name": "Corredor incansable", "max": 3, "fx": {"run_cost": 0.12}, "req": ["reflejos"],
	 "desc": "Correr gasta un 12 % menos de estamina por rango."},
	{"id": "botin", "branch": 1, "tier": 3, "col": 0, "name": "Botín del cazador", "max": 3, "fx": {"loot": 0.2}, "req": ["ojo_mercader"],
	 "desc": "Un 20 % más de probabilidad de encontrar objetos y equipo, por rango."},
	{"id": "aprendiz", "branch": 1, "tier": 3, "col": 2, "name": "Aprendiz veloz", "max": 3, "fx": {"xp": 0.06}, "req": ["incansable"],
	 "desc": "+6 % de experiencia por rango."},
	{"id": "instinto", "branch": 1, "tier": 4, "col": 1, "name": "Instinto de cazador", "max": 3, "fx": {"sxp": 0.12}, "req": ["botin", "aprendiz"],
	 "desc": "+12 % de experiencia de habilidad por rango."},
	# --- Místico
	{"id": "mente", "branch": 2, "tier": 0, "col": 0, "name": "Mente serena", "max": 5, "fx": {"mana": 10}, "req": [],
	 "desc": "+10 de maná máximo por rango."},
	{"id": "concentracion", "branch": 2, "tier": 0, "col": 2, "name": "Concentración", "max": 5, "fx": {"mana_regen": 0.15}, "req": [],
	 "desc": "El maná se recupera un 15 % más rápido por rango."},
	{"id": "poder_arcano", "branch": 2, "tier": 1, "col": 0, "name": "Poder arcano", "max": 5, "fx": {"skill_dmg": 0.06}, "req": ["mente"],
	 "desc": "+6 % de daño de habilidades por rango."},
	{"id": "alquimia", "branch": 2, "tier": 1, "col": 2, "name": "Alquimia", "max": 3, "fx": {"potion": 0.15}, "req": ["concentracion"],
	 "desc": "Las pociones y la comida recuperan un 15 % más por rango."},
	{"id": "celeridad", "branch": 2, "tier": 2, "col": 0, "name": "Celeridad", "max": 4, "fx": {"cdr": 0.05}, "req": ["poder_arcano"],
	 "desc": "Las habilidades se recargan un 5 % más rápido por rango."},
	{"id": "eficiencia", "branch": 2, "tier": 2, "col": 2, "name": "Eficiencia", "max": 4, "fx": {"mana_cost": 0.05}, "req": ["alquimia"],
	 "desc": "Las habilidades cuestan un 5 % menos de maná por rango."},
	{"id": "escudo_mana", "branch": 2, "tier": 3, "col": 0, "name": "Escudo de maná", "max": 3, "fx": {"mana_shield": 0.1}, "req": ["celeridad"],
	 "desc": "Un 10 % del daño que recibes se paga con maná en lugar de vida, por rango."},
	{"id": "vinculo", "branch": 2, "tier": 3, "col": 2, "name": "Vínculo vital", "max": 3, "fx": {"kill_mana": 3}, "req": ["eficiencia"],
	 "desc": "Cada presa abatida te devuelve 3 de maná por rango."},
	{"id": "maestria", "branch": 2, "tier": 4, "col": 1, "name": "Maestría arcana", "max": 2, "fx": {"skill_dmg": 0.1, "cdr": 0.05}, "req": ["escudo_mana", "vinculo"],
	 "desc": "+10 % de daño de habilidades y recarga un 5 % más rápida, por rango."},
]


static func talent_node(id: String) -> Dictionary:
	for t in TALENT_TREE:
		if t["id"] == id:
			return t
	return {}


# --- Hunters' Guild: renown, ranks, rivals and contracts ---------------------------------------
## [renown needed, rank letter, title]. Each new rank pays out a reward.
const GUILD_RANKS := [[0, "E", "Novato"], [150, "D", "Cazador"], [450, "C", "Rastreador"], [1000, "B", "Veterano"],
	[2000, "A", "Élite"], [4000, "S", "Leyenda"]]
## Other hunters of Valdoria. They roam the plain and climb the ranking as time goes by
## (renown = base + rate per minute played + what they hunt in front of you).
const HUNTERS := [
	{"name": "Brenna", "tier": 7, "level": 71, "base": 3400, "rate": 6.0, "line": "La llanura cambia de noche. Ten los ojos abiertos."},
	{"name": "Aldric", "tier": 6, "level": 58, "base": 2500, "rate": 5.0, "line": "Si ves al gólem, no lo enfrentes sin pociones."},
	{"name": "Sorin", "tier": 5, "level": 44, "base": 1700, "rate": 4.5, "line": "Me falta poco para el rango A."},
	{"name": "Lyra", "tier": 5, "level": 39, "base": 1300, "rate": 4.0, "line": "Los gnolls atacan en grupo. Sepáralos."},
	{"name": "Tomas", "tier": 4, "level": 31, "base": 950, "rate": 3.5, "line": "Kara me dejó la espada en +6. Corta como nunca."},
	{"name": "Ilse", "tier": 4, "level": 27, "base": 720, "rate": 3.2, "line": "Los cofres de las ruinas siempre tienen algo bueno."},
	{"name": "Garrick", "tier": 3, "level": 22, "base": 520, "rate": 2.8, "line": "Hoy vengo por los goblins del oeste."},
	{"name": "Mira", "tier": 3, "level": 18, "base": 380, "rate": 2.5, "line": "¿También vas por el Rey Limo?"},
	{"name": "Dorian", "tier": 2, "level": 14, "base": 260, "rate": 2.2, "line": "Cada día hay más limos en el camino."},
	{"name": "Nell", "tier": 2, "level": 11, "base": 170, "rate": 2.0, "line": "Estoy juntando gel para la forja."},
	{"name": "Bram", "tier": 2, "level": 9, "base": 110, "rate": 1.7, "line": "¡Buena caza, compañero!"},
	{"name": "Wynn", "tier": 1, "level": 6, "base": 60, "rate": 1.4, "line": "Es mi primera semana en el Gremio."},
	{"name": "Pip", "tier": 1, "level": 4, "base": 30, "rate": 1.2, "line": "¿Cómo se usa la embestida?"},
	{"name": "Oswin", "tier": 1, "level": 3, "base": 15, "rate": 1.0, "line": "Los limos no son tan blandos como parecen..."},
]
const HUNTER_CHATTER := ["¡Uno menos!", "¡Toma eso!", "¡Por el Gremio!", "Otro limo...", "¡Cuidado, vienen más!", "Buena caza.",
	"Necesito una poción.", "¿Viste al gólem?", "Esta zona está llena.", "Ya casi subo de rango."]
## Contract templates: [monster, base count]. Rewards scale with the hero's level.
const CONTRACT_POOL := [["Limo", 8], ["Limo extraño", 5], ["Goblin", 6], ["Gnoll", 5], ["Goblin", 10], ["Limo", 14], ["Gnoll", 8],
	["Gólem de las Ruinas", 1], ["Ent Ancestral", 1], ["Rey Limo", 1]]


static func guild_rank_index(renown: int) -> int:
	var idx := 0
	for i in GUILD_RANKS.size():
		if renown >= int(GUILD_RANKS[i][0]):
			idx = i
	return idx


# --- Stable: mount and companions -----------------------------------------------------------
const CF := "res://resources/sprite_frames/companions/"
## The mount (H to ride): faster than running and no stamina. `rank` = guild rank needed to buy.
const MOUNT := {"id": "ciervo", "name": "Ciervo de monta", "price": 3000, "rank": "D", "speed": 1.8, "frames": CF + "deer.tres",
	"desc": "Un ciervo criado en las granjas del este. Dócil, rápido y valiente. Con él cruzas la llanura en un suspiro."}
## Companions follow you and fight your target (or whatever attacks you). `power` = share of your attack per bite.
const PETS := {
	"zorro": {"name": "Zorro rojo", "price": 2000, "rank": "D", "power": 0.45, "rate": 0.9, "speed": 92.0, "frames": CF + "fox.tres",
		"desc": "Rápido y astuto. Muerde a menudo, pero no muy fuerte."},
	"jabali": {"name": "Jabalí de guerra", "price": 5000, "rank": "C", "power": 0.9, "rate": 1.6, "speed": 74.0, "frames": CF + "boar.tres",
		"desc": "Lento y terco, pero cada embestida duele de verdad."},
}
const RANK_ORDER := ["E", "D", "C", "B", "A", "S"]

# --- World events -------------------------------------------------------------------------------
## Colossal versions of the bosses appear on the plain from time to time.
const EVENT_FIRST := Vector2(80.0, 140.0)      # seconds until the first event
const EVENT_EVERY := Vector2(240.0, 420.0)     # seconds between events
const EVENT_DURATION := 300.0                  # seconds before the colossus leaves
const EVENT_HP_MULT := 5.0
const EVENT_DMG_MULT := 1.4

# --- Looks ------------------------------------------------------------------------------
## [hero level, swordsman sprite tier, title]: the hero's appearance improves at these levels.
const LOOKS := [[1, 1, "Aprendiz"], [10, 2, "Espadachín"], [20, 3, "Veterano"], [30, 4, "Caballero"],
	[50, 5, "Guardián"], [70, 6, "Campeón"], [90, 7, "Leyenda de Valdoria"]]


static func look_for(level: int) -> Array:
	var best: Array = LOOKS[0]
	for l in LOOKS:
		if level >= int(l[0]):
			best = l
	return best


static func skill_def(id: String) -> Dictionary:
	for s in SKILLS:
		if s["id"] == id:
			return s
	return {}


## Numbers of a skill at a rank (atk = the hero's attack).
static func skill_values(id: String, rank: int, atk: int) -> Dictionary:
	var r := maxi(rank, 1)
	match id:
		"giro":
			return {"dmg": 1 + r + atk, "radius": 44.0 + 3.0 * r, "cd": 3.0}
		"embestida":
			return {"dmg": r + int(atk * 0.7), "time": 0.18 + 0.02 * r, "cd": 2.8 - 0.2 * r}
		"grito":
			return {"bonus": 1 + int((r - 1) / 2) + int(atk / 6), "time": 8.0 + 2.0 * r, "cd": 22.0}
		"respiro":
			return {"heal": 0.2 + 0.05 * r, "cd": 26.0 - 2.0 * r}
		"onda":
			return {"dmg": 2 + 2 * r + int(atk * 1.2), "radius": 72.0, "cd": 12.0}
		"tajo":
			return {"dmg": 4 + 3 * r + int(atk * 1.8), "length": 130.0, "cd": 8.0}
	return {}


static func skill_text(id: String, rank: int, atk: int) -> String:
	var v := skill_values(id, rank, atk)
	match id:
		"giro":
			return "Giras con la espada y golpeas a todos los enemigos cercanos (%d de daño)." % v["dmg"]
		"embestida":
			return "Te lanzas hacia adelante golpeando a quien encuentres (%d de daño). No recibes daño mientras dura." % v["dmg"]
		"grito":
			return "Durante %d segundos tienes +%d de ataque." % [v["time"], v["bonus"]]
		"respiro":
			return "Te detienes a recuperar el aliento y sanas un %d %% de tu vida." % int(round(v["heal"] * 100))
		"onda":
			return "Golpeas el suelo y una onda empuja y daña a todo lo que te rodea (%d de daño)." % v["dmg"]
		"tajo":
			return "Un corte de luz que alcanza a los enemigos alineados frente a ti (%d de daño)." % v["dmg"]
	return ""


## Skill experience needed to learn (rank 0 -> 1) or improve a skill.
static func skill_cost(rank: int) -> int:
	return 10 + 25 * rank * rank


static func xp_to_next(level: int) -> int:
	return 20 + 15 * (level - 1)


## Monster strength for a monster level.
static func mon_hp_mult(level: int) -> float:
	return 1.0 + 0.24 * (level - 1)


static func mon_dmg_mult(level: int) -> float:
	return 1.0 + 0.13 * (level - 1)
