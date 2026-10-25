class_name GameData
extends RefCounted
## Static game data: items, equipment, skills, talents, loot and the hero's looks.
## Icons are either a path to a PNG or [x, y] of a 16x16 cell in the UI pack's Icons.png.

const UI_ICONS := "res://assets/ui/pack/Icons.png"
const EQ := "res://assets/ui/icons/equip/"
const SK := "res://assets/ui/icons/skills/"
const MAX_LEVEL := 99
## Healing potions: the hero carries a few and they refill in town and at safe havens.
const POTION_MAX := 3
## Safe havens in the wild (by scene file): [center px, radius px, name]. Potions refill there.
const SAFE_SPOTS := {
	"field.tscn": [[Vector2(1520, 410), 170.0, "el Campamento de viajeros"]],
	"forest.tscn": [[Vector2(1288, 1728), 170.0, "el Puesto del Guardabosques"]],
	"desert.tscn": [[Vector2(392, 960), 190.0, "el Oasis de Zafira"]],
}

# --- Consumables & materials --------------------------------------------------------
const ITEMS := {
	"pocion": {"name": "Poción de vida", "desc": "Recupera 30 % de la vida. Llevas un máximo de 3; se rellenan en la ciudad y en los refugios.", "icon": [48, 272], "use": "hp", "amount": 0.3},
	"eter": {"name": "Poción de maná", "desc": "Recupera 40 % del maná.", "icon": [32, 272], "value": 15, "use": "mana", "amount": 0.4},
	"manzana": {"name": "Manzana", "desc": "Fresca y crujiente. Recupera 15 % de la vida.", "icon": [80, 80], "value": 2, "use": "hp", "amount": 0.15},
	"gel": {"name": "Gel de limo", "desc": "Material. Pegajoso y algo tibio. Los alquimistas lo aprecian.", "icon": [48, 144], "value": 4},
	"abalorio": {"name": "Abalorio goblin", "desc": "Material. Los goblins los cuelgan de sus lanzas como trofeo.", "icon": [0, 144], "value": 7},
	"piel": {"name": "Piel de gnoll", "desc": "Material. Gruesa y resistente; buena para curtir.", "icon": [64, 144], "value": 10},
	"nucleo": {"name": "Núcleo de piedra", "desc": "El corazón del Gólem de las Ruinas. Todavía brilla con una luz tenue.", "icon": [80, 160], "value": 150},
	"corteza": {"name": "Corteza antigua", "desc": "Un trozo del Ent Ancestral. Huele a lluvia y a siglos.", "icon": [64, 80], "value": 150},
	"musgo": {"name": "Musgo vivo", "desc": "Material. Se arrastra solo si lo dejas en el suelo.", "icon": [80, 144], "value": 6},
	"savia": {"name": "Savia del bosque", "desc": "Material. Espesa y dulce; los curanderos pagan bien por ella.", "icon": [32, 112], "value": 12},
	"bruma": {"name": "Esencia de bruma", "desc": "Material. Un frasco de niebla del pantano que nunca se disipa.", "icon": [64, 112], "value": 10},
	"cristal": {"name": "Fragmento de cristal", "desc": "Material. Vibra con un zumbido suave. Kara lo usa para templar el acero.", "icon": [80, 112], "value": 16},
	"arenisca": {"name": "Bloque de arenisca", "desc": "Material. Pesado y caliente al tacto, aunque sea de noche.", "icon": "res://assets/ui/icons/items/arenisca.png", "value": 9},
	"acido": {"name": "Frasco de ácido", "desc": "Material. Burbujea solo. No lo abras cerca de tu ropa.", "icon": "res://assets/ui/icons/items/acido.png", "value": 11},
	"colmillo_chacal": {"name": "Colmillo de chacal", "desc": "Material. Afilado como una daga; los nómadas lo usan de amuleto.", "icon": "res://assets/ui/icons/items/colmillo_chacal.png", "value": 13},
	"polvo_dorado": {"name": "Polvo dorado", "desc": "Material. Los saqueadores lo roban de las ruinas. Brilla al sol.", "icon": "res://assets/ui/icons/items/polvo_dorado.png", "value": 16},
	"tesoro_sol": {"name": "Tesoro del Sol", "desc": "El tesoro que custodiaba el Guardián del Sol. Una fortuna en oro antiguo.", "icon": "res://assets/ui/icons/items/tesoro_sol.png", "value": 400},
	"corona": {"name": "Corona de gel", "desc": "Lo único que quedó del Rey Limo. Tiembla si la tocas.", "icon": [64, 128], "value": 150},
}

# --- Equipment ------------------------------------------------------------------------
## Equipment bonuses that work like talent effects (weapon types): critical chance and damage,
## life steal and skill damage.
const EQUIP_FX := ["crit", "crit_dmg", "lifesteal", "skill_dmg", "gold", "xp"]

# --- Loot rarity ----------------------------------------------------------------------------
## Each piece that drops rolls a rarity: more bonuses (affixes) and a coloured name.
const RARITY_NAMES := ["Común", "Rara", "Épica", "Legendaria"]
const RARITY_COLORS := [Color(0.85, 0.82, 0.76), Color(0.35, 0.62, 1.0), Color(0.72, 0.42, 1.0), Color(1.0, 0.66, 0.15)]
## Darker versions for text on parchment.
const RARITY_INK := [Color(0.25, 0.16, 0.1), Color(0.1, 0.32, 0.72), Color(0.45, 0.15, 0.7), Color(0.72, 0.38, 0.02)]
## Chance of rare / epic / legendary (the rest is common). `luck` (bosses, chests) shifts the odds.
const RARITY_ODDS := [0.26, 0.08, 0.015]
## Random bonuses a piece can carry: key -> [min, max] at level 1, [min, max] extra per level.
const AFFIXES := {
	"atk": [1, 1, 0.12, 0.16], "def": [1, 1, 0.08, 0.12], "hp": [3, 6, 0.4, 0.6], "mana": [5, 8, 0.5, 0.7],
	"crit": [0.02, 0.05, 0.0, 0.0], "crit_dmg": [0.08, 0.2, 0.0, 0.0], "lifesteal": [0.015, 0.035, 0.0, 0.0],
	"skill_dmg": [0.04, 0.1, 0.0, 0.0], "speed": [0.03, 0.06, 0.0, 0.0], "gold": [0.05, 0.12, 0.0, 0.0], "xp": [0.04, 0.1, 0.0, 0.0],
}

# --- Zone levels ------------------------------------------------------------------------------
## Monsters no longer follow the hero's level: each region has its own, so you feel how you grow.
const MAP_LEVELS := {"field.tscn": [1, 16], "forest.tscn": [16, 32], "desert.tscn": [30, 50]}
const MON_LEVELS := {
	"Limo": [1, 4], "Limo extraño": [4, 7], "Goblin": [5, 9], "Gnoll": [8, 12], "Limo musgoso": [9, 12], "Retoño del bosque": [10, 13],
	"Limo de bruma": [11, 14], "Ent frondoso": [12, 15], "Gólem de cristal": [13, 16], "Rey Limo": [12, 12], "Gólem de las Ruinas": [14, 14],
	"Ent Ancestral": [16, 16], "Gólem de Obsidiana": [24, 24],
	"Limo de arena": [30, 34], "Limo ácido": [33, 37], "Saqueador de las dunas": [36, 41], "Chacal de las dunas": [39, 44],
	"Gólem de arenisca": [42, 47], "Guardián del Sol": [50, 50],
}
## The same creatures are tougher deeper in: levels added on each map.
const MAP_LEVEL_BONUS := {"forest.tscn": 8}
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
	"daga_bronce": {"name": "Daga de bronce", "slot": "weapon", "level": 4, "atk": 2, "crit": 0.05, "desc": "Daga. Ligera y traicionera: golpes críticos más a menudo."},
	"daga_sombra": {"name": "Daga de sombra", "slot": "weapon", "level": 14, "atk": 5, "crit": 0.08, "desc": "Daga. Forjada de noche, para que nadie la vea venir."},
	"colmillo_dunas": {"name": "Colmillo de las dunas", "slot": "weapon", "level": 28, "atk": 9, "crit": 0.12, "desc": "Daga. Tallada con el colmillo de un chacal gigante."},
	"daga_eclipse": {"name": "Daga del eclipse", "slot": "weapon", "level": 48, "atk": 15, "crit": 0.15, "desc": "Daga. Brilla solo cuando el sol se esconde."},
	"lanza_cazador": {"name": "Lanza de cazador", "slot": "weapon", "level": 6, "atk": 3, "def": 1, "desc": "Lanza. Mantiene a las bestias a distancia."},
	"lanza_acero": {"name": "Lanza de acero", "slot": "weapon", "level": 18, "atk": 7, "def": 2, "desc": "Lanza. La usan los guardias de las murallas."},
	"pica_dunas": {"name": "Pica de las dunas", "slot": "weapon", "level": 32, "atk": 11, "def": 3, "desc": "Lanza. Los nómadas la clavan en la arena para marcar su camino."},
	"lanza_sol": {"name": "Lanza del sol", "slot": "weapon", "level": 52, "atk": 18, "def": 4, "desc": "Lanza. Su punta arde como el mediodía del desierto."},
	"hacha_doble": {"name": "Hacha doble", "slot": "weapon", "level": 12, "atk": 7, "speed": -0.04, "desc": "Hacha de guerra. Dos filos, el doble de problemas."},
	"hacha_berserker": {"name": "Hacha berserker", "slot": "weapon", "level": 30, "atk": 13, "speed": -0.04, "lifesteal": 0.03, "desc": "Hacha de guerra. Cada golpe te devuelve algo de vida."},
	"hacha_titan": {"name": "Hacha del titán", "slot": "weapon", "level": 60, "atk": 24, "speed": -0.05, "desc": "Hacha de guerra. Solo un titán podría levantarla... o tú."},
	"martillo_guerra": {"name": "Martillo de guerra", "slot": "weapon", "level": 16, "atk": 8, "hp": 8, "speed": -0.05, "desc": "Martillo. Lento, pero aplasta caparazones y piedras."},
	"martillo_runico": {"name": "Martillo rúnico", "slot": "weapon", "level": 40, "atk": 16, "hp": 16, "speed": -0.05, "desc": "Martillo. Las runas zumban cuando golpea."},
	"cimitarra": {"name": "Cimitarra", "slot": "weapon", "level": 22, "atk": 8, "crit_dmg": 0.2, "desc": "Cimitarra. La hoja curva de los nómadas del desierto: críticos más fuertes."},
	"cimitarra_dorada": {"name": "Cimitarra dorada", "slot": "weapon", "level": 38, "atk": 13, "crit_dmg": 0.3, "desc": "Cimitarra. Bañada en el oro de las Ruinas del Sol."},
	"cimitarra_faraon": {"name": "Cimitarra del faraón", "slot": "weapon", "level": 58, "atk": 21, "crit_dmg": 0.4, "desc": "Cimitarra. Perteneció a un rey que nadie recuerda."},
	"estoque": {"name": "Estoque", "slot": "weapon", "level": 26, "atk": 9, "crit": 0.04, "crit_dmg": 0.15, "desc": "Espada fina. Precisión antes que fuerza."},
	"katana_luna": {"name": "Katana de luna", "slot": "weapon", "level": 45, "atk": 16, "crit": 0.06, "crit_dmg": 0.25, "desc": "Katana. Corta tan limpio que el enemigo tarda en notarlo."},
	"hoz_segador": {"name": "Hoz del segador", "slot": "weapon", "level": 20, "atk": 8, "lifesteal": 0.04, "desc": "Guadaña. Cosecha la vida de lo que corta."},
	"guadana_alma": {"name": "Guadaña de almas", "slot": "weapon", "level": 50, "atk": 18, "lifesteal": 0.07, "desc": "Guadaña. Susurra con voces que no son tuyas."},
	"tridente_marea": {"name": "Tridente de la marea", "slot": "weapon", "level": 24, "atk": 8, "mana": 20, "skill_dmg": 0.1, "desc": "Tridente. Potencia tus habilidades con la fuerza del mar."},
	"tridente_abismo": {"name": "Tridente del abismo", "slot": "weapon", "level": 46, "atk": 15, "mana": 30, "skill_dmg": 0.15, "desc": "Tridente. Arrastra a sus presas hacia el fondo."},
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
	{"gold": 450, "items": {"piel": 3, "gel": 6, "savia": 2}},
	{"gold": 600, "items": {"piel": 4, "cristal": 2, "nucleo": 1}},
	{"gold": 800, "items": {"piel": 5, "bruma": 2, "corteza": 1}},
	{"gold": 1000, "items": {"abalorio": 5, "musgo": 4, "corona": 1}},
	{"gold": 1500, "items": {"nucleo": 1, "corteza": 1, "corona": 1}},
]

# --- Loot ---------------------------------------------------------------------------
## [item, chance, amount] dropped by each monster (by name).
const LOOT := {
	"Limo": [["gel", 0.6, 1]], "Limo extraño": [["gel", 0.8, 2]],
	"Goblin": [["abalorio", 0.45, 1], ["manzana", 0.2, 1]], "Gnoll": [["piel", 0.5, 1]],
	"Retoño del bosque": [["savia", 0.4, 1], ["musgo", 0.3, 1]], "Ent frondoso": [["savia", 0.6, 1], ["corteza", 0.04, 1]],
	"Limo musgoso": [["musgo", 0.6, 1], ["gel", 0.3, 1]], "Limo de bruma": [["bruma", 0.5, 1], ["gel", 0.3, 1]],
	"Gólem de cristal": [["cristal", 0.5, 1], ["nucleo", 0.02, 1]],
	"Gólem de Obsidiana": [["cristal", 1.0, 3], ["nucleo", 1.0, 1], ["eter", 1.0, 2]],
	"Limo de arena": [["gel", 0.5, 1], ["arenisca", 0.2, 1]], "Limo ácido": [["acido", 0.55, 1], ["gel", 0.3, 1]],
	"Saqueador de las dunas": [["polvo_dorado", 0.4, 1], ["abalorio", 0.3, 1]], "Chacal de las dunas": [["colmillo_chacal", 0.5, 1], ["piel", 0.3, 1]],
	"Gólem de arenisca": [["arenisca", 0.6, 1], ["cristal", 0.1, 1]],
	"Guardián del Sol": [["tesoro_sol", 1.0, 1], ["polvo_dorado", 1.0, 3], ["eter", 1.0, 2]],
	"Gólem de las Ruinas": [["nucleo", 1.0, 1], ["eter", 1.0, 2]],
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
	{"name": "Alaric", "tier": 2, "level": 13, "base": 235, "rate": 1.2, "line": "¡Buena caza!"},
	{"name": "Beatriz", "tier": 5, "level": 52, "base": 2185, "rate": 4.6, "line": "Los goblins roban todo lo que brilla."},
	{"name": "Cedric", "tier": 2, "level": 16, "base": 347, "rate": 1.5, "line": "No salgas sin pociones."},
	{"name": "Daria", "tier": 4, "level": 38, "base": 1353, "rate": 3.0, "line": "Los gólems de cristal pegan más fuerte de lo que parece."},
	{"name": "Elian", "tier": 2, "level": 19, "base": 486, "rate": 2.1, "line": "Cuidado con los gnolls de las colinas."},
	{"name": "Fiona", "tier": 3, "level": 28, "base": 681, "rate": 2.6, "line": "¡Buena caza!"},
	{"name": "Gaspar", "tier": 5, "level": 56, "base": 2816, "rate": 4.3, "line": "Los goblins roban todo lo que brilla."},
	{"name": "Helga", "tier": 2, "level": 15, "base": 343, "rate": 1.5, "line": "Estoy juntando oro para un ciervo de monta."},
	{"name": "Ivo", "tier": 5, "level": 51, "base": 2109, "rate": 3.5, "line": "Los limos de bruma salen del pantano al anochecer."},
	{"name": "Jana", "tier": 5, "level": 58, "base": 1902, "rate": 4.5, "line": "Las rachas de caza dan mucho renombre."},
	{"name": "Kael", "tier": 2, "level": 12, "base": 263, "rate": 1.4, "line": "Los goblins roban todo lo que brilla."},
	{"name": "Lucia", "tier": 4, "level": 36, "base": 1314, "rate": 2.8, "line": "Los gólems de cristal pegan más fuerte de lo que parece."},
	{"name": "Marek", "tier": 2, "level": 11, "base": 199, "rate": 1.3, "line": "Las rachas de caza dan mucho renombre."},
	{"name": "Nadia", "tier": 3, "level": 27, "base": 741, "rate": 2.2, "line": "Vendo savia a buen precio en la forja."},
	{"name": "Orin", "tier": 3, "level": 21, "base": 537, "rate": 2.0, "line": "Los gólems de cristal pegan más fuerte de lo que parece."},
	{"name": "Petra", "tier": 4, "level": 34, "base": 1110, "rate": 2.5, "line": "¿Ya probaste el campamento? Ahí se rellenan las pociones."},
	{"name": "Quinn", "tier": 3, "level": 23, "base": 439, "rate": 1.8, "line": "La herrera Kara es la mejor de Valdoria."},
	{"name": "Rhea", "tier": 3, "level": 23, "base": 543, "rate": 2.0, "line": "Los goblins roban todo lo que brilla."},
	{"name": "Silas", "tier": 5, "level": 54, "base": 2139, "rate": 4.8, "line": "Los goblins roban todo lo que brilla."},
	{"name": "Tamsin", "tier": 3, "level": 29, "base": 998, "rate": 2.3, "line": "Quiero comprar el lobo gris del establo."},
	{"name": "Ulric", "tier": 1, "level": 7, "base": 101, "rate": 0.9, "line": "La herrera Kara es la mejor de Valdoria."},
	{"name": "Vera", "tier": 4, "level": 42, "base": 1519, "rate": 3.1, "line": "Estoy juntando oro para un ciervo de monta."},
	{"name": "Wilma", "tier": 4, "level": 42, "base": 1278, "rate": 3.8, "line": "Necesito más pieles para la forja."},
	{"name": "Yorick", "tier": 4, "level": 31, "base": 756, "rate": 2.5, "line": "Estoy juntando oro para un ciervo de monta."},
	{"name": "Zora", "tier": 6, "level": 75, "base": 4510, "rate": 6.2, "line": "El lago esconde algo, estoy seguro."},
	{"name": "Anselm", "tier": 3, "level": 20, "base": 434, "rate": 2.1, "line": "Las rachas de caza dan mucho renombre."},
	{"name": "Brisa", "tier": 3, "level": 27, "base": 802, "rate": 2.7, "line": "Estoy juntando oro para un ciervo de monta."},
	{"name": "Corvin", "tier": 2, "level": 17, "base": 298, "rate": 1.8, "line": "Necesito más pieles para la forja."},
	{"name": "Delia", "tier": 5, "level": 58, "base": 2010, "rate": 4.7, "line": "Los limos de bruma salen del pantano al anochecer."},
	{"name": "Edmund", "tier": 2, "level": 19, "base": 510, "rate": 1.7, "line": "Los goblins roban todo lo que brilla."},
	{"name": "Freya", "tier": 2, "level": 19, "base": 387, "rate": 1.7, "line": "Vendo savia a buen precio en la forja."},
	{"name": "Gideon", "tier": 2, "level": 12, "base": 186, "rate": 1.2, "line": "Entreno cada mañana en el patio del cuartel."},
	{"name": "Hilda", "tier": 1, "level": 8, "base": 127, "rate": 1.0, "line": "No salgas sin pociones."},
	{"name": "Isolde", "tier": 4, "level": 36, "base": 1052, "rate": 3.4, "line": "Un colosal apareció la semana pasada. Casi no lo cuento."},
	{"name": "Joran", "tier": 3, "level": 26, "base": 757, "rate": 2.4, "line": "El lago esconde algo, estoy seguro."},
	{"name": "Katia", "tier": 2, "level": 19, "base": 339, "rate": 1.7, "line": "Los goblins roban todo lo que brilla."},
	{"name": "Leoric", "tier": 4, "level": 33, "base": 921, "rate": 2.5, "line": "Los gólems de cristal pegan más fuerte de lo que parece."},
	{"name": "Maren", "tier": 4, "level": 39, "base": 1419, "rate": 3.7, "line": "El lago esconde algo, estoy seguro."},
	{"name": "Nilo", "tier": 3, "level": 25, "base": 781, "rate": 2.4, "line": "Algún día llegaré al rango S."},
	{"name": "Odalys", "tier": 1, "level": 6, "base": 70, "rate": 1.0, "line": "¡Buena caza!"},
	{"name": "Pascal", "tier": 2, "level": 17, "base": 411, "rate": 1.5, "line": "Entreno cada mañana en el patio del cuartel."},
	{"name": "Runa", "tier": 2, "level": 16, "base": 288, "rate": 1.5, "line": "Vendo savia a buen precio en la forja."},
	{"name": "Soren", "tier": 2, "level": 16, "base": 342, "rate": 1.7, "line": "Las rachas de caza dan mucho renombre."},
	{"name": "Thalia", "tier": 2, "level": 14, "base": 212, "rate": 1.4, "line": "Las rachas de caza dan mucho renombre."},
	{"name": "Uriel", "tier": 4, "level": 40, "base": 1674, "rate": 3.7, "line": "Entreno cada mañana en el patio del cuartel."},
	{"name": "Valen", "tier": 5, "level": 68, "base": 2603, "rate": 5.2, "line": "La herrera Kara es la mejor de Valdoria."},
	{"name": "Ximena", "tier": 6, "level": 74, "base": 3041, "rate": 6.6, "line": "La herrera Kara es la mejor de Valdoria."},
	{"name": "Yara", "tier": 3, "level": 21, "base": 509, "rate": 1.7, "line": "Los limos de bruma salen del pantano al anochecer."},
	{"name": "Zeno", "tier": 4, "level": 36, "base": 1140, "rate": 2.5, "line": "Algún día llegaré al rango S."},
	{"name": "Arden", "tier": 3, "level": 26, "base": 731, "rate": 2.2, "line": "El bosque del noroeste está lleno de retoños."},
	{"name": "Belen", "tier": 4, "level": 44, "base": 1893, "rate": 3.8, "line": "Los ents frondosos son lentos, pero duros."},
	{"name": "Caspian", "tier": 4, "level": 36, "base": 1026, "rate": 2.8, "line": "El lago esconde algo, estoy seguro."},
	{"name": "Dalia", "tier": 2, "level": 14, "base": 319, "rate": 1.4, "line": "El lago esconde algo, estoy seguro."},
	{"name": "Evander", "tier": 4, "level": 41, "base": 1276, "rate": 3.0, "line": "No salgas sin pociones."},
	{"name": "Faela", "tier": 4, "level": 40, "base": 1640, "rate": 2.8, "line": "Algún día llegaré al rango S."},
	{"name": "Goran", "tier": 4, "level": 44, "base": 1636, "rate": 3.9, "line": "La herrera Kara es la mejor de Valdoria."},
	{"name": "Hester", "tier": 2, "level": 12, "base": 243, "rate": 1.2, "line": "Me falta poco para subir de rango."},
	{"name": "Ismael", "tier": 2, "level": 16, "base": 327, "rate": 1.7, "line": "Los limos de bruma salen del pantano al anochecer."},
	{"name": "Jessa", "tier": 3, "level": 22, "base": 668, "rate": 1.8, "line": "Necesito más pieles para la forja."},
	{"name": "Kiran", "tier": 5, "level": 50, "base": 2146, "rate": 3.8, "line": "Los gólems de cristal pegan más fuerte de lo que parece."},
	{"name": "Liesel", "tier": 3, "level": 24, "base": 607, "rate": 2.5, "line": "El bosque del noroeste está lleno de retoños."},
	{"name": "Matthias", "tier": 3, "level": 23, "base": 647, "rate": 2.1, "line": "Las rachas de caza dan mucho renombre."},
	{"name": "Noemi", "tier": 2, "level": 17, "base": 381, "rate": 1.8, "line": "Cada contrato cuenta para el ranking."},
	{"name": "Osric", "tier": 4, "level": 31, "base": 818, "rate": 2.5, "line": "Los ents frondosos son lentos, pero duros."},
	{"name": "Paloma", "tier": 2, "level": 13, "base": 190, "rate": 1.3, "line": "Vendo savia a buen precio en la forja."},
	{"name": "Ragnar", "tier": 3, "level": 28, "base": 766, "rate": 2.6, "line": "Los limos de bruma salen del pantano al anochecer."},
	{"name": "Selene", "tier": 4, "level": 31, "base": 914, "rate": 2.8, "line": "Los gólems de cristal pegan más fuerte de lo que parece."},
	{"name": "Tobin", "tier": 4, "level": 33, "base": 856, "rate": 2.9, "line": "Cuidado con los gnolls de las colinas."},
	{"name": "Una", "tier": 3, "level": 26, "base": 808, "rate": 2.6, "line": "Necesito más pieles para la forja."},
	{"name": "Viggo", "tier": 5, "level": 63, "base": 2173, "rate": 5.0, "line": "El lago esconde algo, estoy seguro."},
	{"name": "Wren", "tier": 3, "level": 23, "base": 692, "rate": 2.4, "line": "Los goblins roban todo lo que brilla."},
	{"name": "Ysabel", "tier": 4, "level": 45, "base": 1270, "rate": 3.2, "line": "Me falta poco para subir de rango."},
	{"name": "Abel", "tier": 3, "level": 24, "base": 643, "rate": 2.5, "line": "Los ents frondosos son lentos, pero duros."},
	{"name": "Brina", "tier": 4, "level": 38, "base": 1515, "rate": 3.5, "line": "Las rachas de caza dan mucho renombre."},
	{"name": "Cato", "tier": 4, "level": 42, "base": 1208, "rate": 2.9, "line": "No salgas sin pociones."},
	{"name": "Dunya", "tier": 2, "level": 12, "base": 218, "rate": 1.2, "line": "Mi zorro encontró un cofre ayer."},
	{"name": "Emeric", "tier": 4, "level": 31, "base": 980, "rate": 2.7, "line": "Vendo savia a buen precio en la forja."},
	{"name": "Fenna", "tier": 3, "level": 24, "base": 473, "rate": 2.2, "line": "Dicen que el Rey Limo vuelve siempre."},
	{"name": "Hugo", "tier": 1, "level": 5, "base": 54, "rate": 0.9, "line": "Dicen que el Rey Limo vuelve siempre."},
	{"name": "Inés", "tier": 4, "level": 44, "base": 1837, "rate": 4.0, "line": "Cada contrato cuenta para el ranking."},
	{"name": "Lazlo", "tier": 6, "level": 76, "base": 4425, "rate": 6.7, "line": "Las rachas de caza dan mucho renombre."},
	{"name": "Milo", "tier": 2, "level": 16, "base": 277, "rate": 1.6, "line": "El lago esconde algo, estoy seguro."},
	{"name": "Ottilie", "tier": 4, "level": 40, "base": 1104, "rate": 2.8, "line": "Estoy juntando oro para un ciervo de monta."},
	{"name": "Rurik", "tier": 4, "level": 33, "base": 1131, "rate": 3.0, "line": "Las rachas de caza dan mucho renombre."},
	{"name": "Saskia", "tier": 5, "level": 55, "base": 2712, "rate": 4.8, "line": "No salgas sin pociones."},
	{"name": "Tilde", "tier": 2, "level": 16, "base": 343, "rate": 1.8, "line": "Los goblins roban todo lo que brilla."},
	{"name": "Varg", "tier": 3, "level": 26, "base": 806, "rate": 2.2, "line": "¡Buena caza!"},
]
const HUNTER_CHATTER := ["¡Uno menos!", "¡Toma eso!", "¡Por el Gremio!", "Otro limo...", "¡Cuidado, vienen más!", "Buena caza.",
	"Necesito una poción.", "¿Viste al gólem?", "Esta zona está llena.", "Ya casi subo de rango."]
## Contract templates: [monster, base count]. Rewards scale with the hero's level.
const CONTRACT_POOL := [["Limo", 8], ["Limo extraño", 5], ["Goblin", 6], ["Gnoll", 5], ["Goblin", 10], ["Limo", 14], ["Gnoll", 8],
	["Retoño del bosque", 6], ["Ent frondoso", 4], ["Limo musgoso", 8], ["Limo de bruma", 6], ["Gólem de cristal", 4],
	["Gólem de las Ruinas", 1], ["Ent Ancestral", 1], ["Rey Limo", 1], ["Gólem de Obsidiana", 1],
	["Limo de arena", 8], ["Limo ácido", 6], ["Saqueador de las dunas", 6], ["Chacal de las dunas", 5], ["Gólem de arenisca", 4], ["Guardián del Sol", 1]]
## Where the Guild's hunters spend the day (each real day the roster changes): map file -> how many.
const HUNTER_SHIFTS := [["field.tscn", 10], ["forest.tscn", 6], ["desert.tscn", 6], ["world.tscn", 7]]
const HUNTER_TOWN_LINES := ["Hoy me tomo el día libre. Mañana vuelvo a la llanura.", "Vengo de venderle mis trofeos a Kara.",
	"Estoy esperando a mi grupo para ir al Bosque Profundo.", "Después de una buena cacería, nada como un paseo por la plaza.",
	"Mañana salgo de caza temprano.", "Vine a revisar el tablón del Gremio."]


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
## `fx` uses the same keys as the talents: the active companion adds its bonus to the hero.
const PETS := {
	"liebre": {"name": "Liebre de las colinas", "price": 800, "rank": "E", "power": 0.3, "rate": 0.7, "speed": 100.0, "frames": CF + "hare.tres",
		"fx": {"gold": 0.08}, "perk": "+8 % de oro", "desc": "Inquieta y curiosa. Siempre encuentra alguna moneda entre la hierba."},
	"zorro": {"name": "Zorro rojo", "price": 2000, "rank": "D", "power": 0.45, "rate": 0.9, "speed": 92.0, "frames": CF + "fox.tres",
		"fx": {"crit": 0.03}, "perk": "+3 % de crítico", "desc": "Rápido y astuto. Muerde a menudo, pero no muy fuerte."},
	"urogallo": {"name": "Urogallo negro", "price": 3500, "rank": "D", "power": 0.5, "rate": 1.0, "speed": 90.0, "frames": CF + "grouse.tres",
		"fx": {"xp": 0.08}, "perk": "+8 % de experiencia", "desc": "Se lanza en vuelo contra las bestias. Dicen que trae buena suerte al aprendiz."},
	"jabali": {"name": "Jabalí de guerra", "price": 5000, "rank": "C", "power": 0.9, "rate": 1.6, "speed": 74.0, "frames": CF + "boar.tres",
		"fx": {"def": 2}, "perk": "+2 de defensa", "desc": "Lento y terco, pero cada embestida duele de verdad."},
	"zorro_nieve": {"name": "Zorro de las nieves", "price": 9000, "rank": "C", "power": 0.75, "rate": 0.85, "speed": 96.0, "frames": CF + "snow_fox.tres",
		"fx": {"mana_regen": 0.25}, "perk": "+25 % de maná recuperado", "desc": "Bajó de los picos helados. Su aliento frío despeja la mente."},
	"lobo": {"name": "Lobo gris", "price": 15000, "rank": "B", "power": 1.2, "rate": 1.1, "speed": 98.0, "frames": CF + "wolf.tres", "scale": 1.2,
		"fx": {"atk_pct": 0.06}, "perk": "+6 % de ataque", "desc": "Un lobo de manada que eligió un nuevo líder: tú."},
	"jabali_ebano": {"name": "Jabalí de ébano", "price": 26000, "rank": "A", "power": 1.6, "rate": 1.5, "speed": 78.0, "frames": CF + "ebony_boar.tres", "scale": 1.15,
		"fx": {"hp_pct": 0.08}, "perk": "+8 % de vida", "desc": "Negro como el carbón y duro como la roca. Ninguna bestia lo hace retroceder."},
	"zorro_igneo": {"name": "Zorro ígneo", "price": 45000, "rank": "S", "power": 2.0, "rate": 0.8, "speed": 104.0, "frames": CF + "fire_fox.tres",
		"fx": {"skill_dmg": 0.12}, "perk": "+12 % de daño de habilidades", "desc": "Una leyenda de Valdoria. Donde pisa, la hierba humea."},
}
const RANK_ORDER := ["E", "D", "C", "B", "A", "S"]

# --- Points of interest (badge over the head and icon on the maps) ---------------------------------
const POI := {
	"forge": {"icon": [0, 96], "title": "Herrera"},
	"stable": {"icon": [32, 16], "title": "Establo"},
	"master": {"icon": [16, 48], "title": "Maestra del Gremio"},
	"guild": {"icon": [16, 48], "title": "Gremio de Cazadores", "short": "Gremio"},
	"home": {"icon": [64, 0], "title": "Tu casa", "short": "Casa"},
	"board": {"icon": [16, 16], "title": "Pedidos"},
	"camp": {"icon": [48, 272], "title": "Refugio: rellena pociones", "short": "Refugio"},
}
## Doors that show on the maps, by their label.
const POI_DOORS := {"Gremio de Cazadores": "guild", "Tu casa": "home"}

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
