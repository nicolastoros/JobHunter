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
	"snowforest.tscn": [[Vector2(1288, 1760), 180.0, "el campamento de la Linde Helada"]],
	"ocaso.tscn": [[Vector2(232, 880), 170.0, "el Puesto del Crepúsculo"]],
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
	"carne": {"name": "Carne de jabalí", "desc": "Material. Los cocineros del campamento la pagan bien.", "icon": "res://assets/ui/icons/items/carne.png", "value": 5},
	"piel_lobo": {"name": "Piel de lobo blanco", "desc": "Material. Abriga como ninguna otra.", "icon": "res://assets/ui/icons/items/piel_lobo.png", "value": 16},
	"pelaje_yeti": {"name": "Pelaje de yeti", "desc": "Material. Largo, blanco y sorprendentemente suave.", "icon": "res://assets/ui/icons/items/pelaje_yeti.png", "value": 20},
	"escarcha": {"name": "Cristal de escarcha", "desc": "Material. Nunca se derrite, ni junto al fuego.", "icon": "res://assets/ui/icons/items/escarcha.png", "value": 18},
	"ceniza": {"name": "Ceniza umbría", "desc": "Material. Lo que el Eclipse dejó de la tierra que tocó. Todavía está tibia.", "icon": "res://assets/ui/icons/items/ceniza.png", "value": 24},
	"corazon_sol_negro": {"name": "Corazón del Sol Negro", "desc": "Late con una luz que no alumbra. Los acólitos lo llamaban «la segunda aurora».", "icon": "res://assets/ui/icons/items/corazon_sol_negro.png", "value": 700},
	"corazon_hielo": {"name": "Corazón de hielo", "desc": "Lo que queda de un guardián del invierno. Late, muy despacio.", "icon": "res://assets/ui/icons/items/corazon_hielo.png", "value": 450},
	"frag_estrella": {"name": "Fragmento de la Estrella", "desc": "Objeto clave. Una piedra fría con una estrella grabada. Late cuando la sostienes.", "icon": [80, 112]},
	"frag_sol": {"name": "Fragmento del Sol", "desc": "Objeto clave. Quema sin dar calor. Las letras grabadas son de una lengua olvidada.", "icon": "res://assets/ui/icons/items/tesoro_sol.png"},
	"frag_luna": {"name": "Fragmento de la Luna", "desc": "Objeto clave. Pálido como la escarcha; de noche brilla sin que nada lo ilumine.", "icon": "res://assets/ui/icons/items/escarcha.png"},
	"corona": {"name": "Corona de gel", "desc": "Lo único que quedó del Rey Limo. Tiembla si la tocas.", "icon": [64, 128], "value": 150},
}

# --- Equipment ------------------------------------------------------------------------
## Equipment bonuses that work like talent effects (weapon types): critical chance and damage,
## life steal and skill damage.
const EQUIP_FX := ["crit", "crit_dmg", "lifesteal", "skill_dmg", "gold", "xp", "guard", "dodge", "atk_pct", "hp_pct"]

# --- Loot rarity ----------------------------------------------------------------------------
## Each piece that drops rolls a rarity: more bonuses (affixes) and a coloured name.
const RARITY_NAMES := ["Común", "Rara", "Épica", "Legendaria", "Sello de Estrella (SOS)", "Sello de Luna (SOM)", "Sello de Sol (SOSUN)"]
const RARITY_COLORS := [Color(0.85, 0.82, 0.76), Color(0.35, 0.62, 1.0), Color(0.72, 0.42, 1.0), Color(1.0, 0.66, 0.15),
	Color(0.55, 0.85, 1.0), Color(0.82, 0.7, 1.0), Color(1.0, 0.93, 0.5)]
## Darker versions for text on parchment.
const RARITY_INK := [Color(0.25, 0.16, 0.1), Color(0.1, 0.32, 0.72), Color(0.45, 0.15, 0.7), Color(0.72, 0.38, 0.02),
	Color(0.05, 0.42, 0.62), Color(0.38, 0.22, 0.62), Color(0.68, 0.45, 0.0)]
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
const MAP_LEVELS := {"field.tscn": [1, 16], "forest.tscn": [16, 32], "desert.tscn": [30, 50], "snowforest.tscn": [50, 70], "ocaso.tscn": [72, 90]}
const MON_LEVELS := {
	"Limo": [1, 4], "Limo extraño": [4, 7], "Goblin": [5, 9], "Gnoll": [8, 12], "Limo musgoso": [9, 12], "Retoño del bosque": [10, 13],
	"Limo de bruma": [11, 14], "Ent frondoso": [12, 15], "Gólem de cristal": [13, 16], "Rey Limo": [12, 12], "Gólem de las Ruinas": [14, 14],
	"Ent Ancestral": [16, 16], "Gólem de Obsidiana": [24, 24],
	"Limo de arena": [30, 34], "Limo ácido": [33, 37], "Saqueador de las dunas": [36, 41], "Chacal de las dunas": [39, 44],
	"Gólem de arenisca": [42, 47], "Guardián del Sol": [50, 50],
	"Jabalí salvaje": [6, 9], "Lobo del bosque": [12, 16], "Árbol marchito": [38, 43],
	"Limo de escarcha": [50, 54], "Trasgo helado": [53, 57], "Lobo de escarcha": [56, 61], "Yeti": [59, 64],
	"Ent helado": [62, 66], "Gólem de hielo": [64, 68], "Rey Limo de Escarcha": [68, 68], "Ent Invernal": [70, 70],
	"Acólito del Sol Negro": [72, 78], "Limo umbrío": [72, 76], "Gnoll del Ocaso": [76, 82], "Lobo del Ocaso": [78, 84],
	"Ent corrupto": [80, 86], "Gólem del Eclipse": [84, 89], "Ent Corrupto Anciano": [90, 90], "Heraldo del Sol Negro": [92, 92],
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
	"Jabalí salvaje": [["carne", 0.6, 1], ["piel", 0.25, 1]], "Lobo del bosque": [["piel", 0.5, 1], ["savia", 0.1, 1]],
	"Árbol marchito": [["corteza", 0.05, 1], ["arenisca", 0.3, 1], ["savia", 0.3, 1]],
	"Limo de escarcha": [["escarcha", 0.4, 1], ["gel", 0.4, 1]], "Trasgo helado": [["escarcha", 0.3, 1], ["abalorio", 0.4, 1]],
	"Lobo de escarcha": [["piel_lobo", 0.5, 1]], "Yeti": [["pelaje_yeti", 0.5, 1]],
	"Ent helado": [["escarcha", 0.5, 1], ["corteza", 0.04, 1]], "Gólem de hielo": [["escarcha", 0.6, 2], ["cristal", 0.2, 1]],
	"Ent Invernal": [["corazon_hielo", 1.0, 1], ["escarcha", 1.0, 3], ["eter", 1.0, 2]],
	"Rey Limo de Escarcha": [["corazon_hielo", 1.0, 1], ["gel", 1.0, 4], ["eter", 1.0, 2]],
	"Gólem de las Ruinas": [["nucleo", 1.0, 1], ["eter", 1.0, 2]],
	"Ent Ancestral": [["corteza", 1.0, 1], ["eter", 1.0, 2]],
	"Rey Limo": [["corona", 1.0, 1], ["gel", 1.0, 3]],
	"Acólito del Sol Negro": [["ceniza", 0.4, 1], ["abalorio", 0.3, 1]], "Gnoll del Ocaso": [["ceniza", 0.35, 1], ["piel", 0.3, 1]],
	"Lobo del Ocaso": [["piel_lobo", 0.45, 1], ["ceniza", 0.2, 1]], "Ent corrupto": [["ceniza", 0.5, 1], ["corteza", 0.05, 1]],
	"Gólem del Eclipse": [["ceniza", 0.5, 1], ["cristal", 0.2, 1]], "Limo umbrío": [["gel", 0.5, 1], ["ceniza", 0.25, 1]],
	"Ent Corrupto Anciano": [["corteza", 1.0, 1], ["ceniza", 1.0, 4], ["eter", 1.0, 2]],
	"Heraldo del Sol Negro": [["corazon_sol_negro", 1.0, 1], ["ceniza", 1.0, 5], ["eter", 1.0, 3]],
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
	["Limo de arena", 8], ["Limo ácido", 6], ["Saqueador de las dunas", 6], ["Chacal de las dunas", 5], ["Gólem de arenisca", 4], ["Guardián del Sol", 1],
	["Jabalí salvaje", 6], ["Lobo del bosque", 6], ["Árbol marchito", 4], ["Limo de escarcha", 8], ["Trasgo helado", 6], ["Lobo de escarcha", 6],
	["Yeti", 5], ["Ent helado", 4], ["Gólem de hielo", 4], ["Ent Invernal", 1], ["Rey Limo de Escarcha", 1]]
## Where the Guild's hunters spend the day (each real day the roster changes): map file -> how many.
const HUNTER_SHIFTS := [["field.tscn", 10], ["forest.tscn", 6], ["desert.tscn", 6], ["world.tscn", 7], ["aurelia.tscn", 6],
	["snowforest.tscn", 5], ["snowvillage.tscn", 5], ["ocaso.tscn", 4]]

# --- World map ----------------------------------------------------------------------------------
## Every region on the world map: its thumbnail (the minimap picture), where it sits (px on a
## 480x270 canvas, top-left) and its gates to the neighbours, in the region's own tiles.
const WORLD_SCALE := 0.14
const WORLD_MAP := [
	{"file": "snowforest.tscn", "name": "Bosque Nevado", "pic": "res://resources/world/minimap_snowforest.png", "pos": Vector2(134.6, 32), "tiles": Vector2(160, 120)},
	{"file": "snowvillage.tscn", "name": "Villa Escarcha", "pic": "res://resources/world/minimap_snowvillage.png", "pos": Vector2(195.4, 37.6), "tiles": Vector2(110, 80)},
	{"file": "forest.tscn", "name": "Bosque Profundo", "pic": "res://resources/world/minimap_forest.png", "pos": Vector2(145.9, 87.6), "tiles": Vector2(160, 120)},
	{"file": "field.tscn", "name": "Llanura de Valdoria", "pic": "res://resources/world/minimap_field.png", "pos": Vector2(160, 143.2), "tiles": Vector2(170, 130)},
	{"file": "world.tscn", "name": "Valdoria", "pic": "res://resources/world/minimap_world.png", "pos": Vector2(158.8, 201.6), "tiles": Vector2(180, 140)},
	{"file": "desert.tscn", "name": "Desierto de Ámbar", "pic": "res://resources/world/minimap_desert.png", "pos": Vector2(223.6, 148.2), "tiles": Vector2(160, 120)},
	{"file": "aurelia.tscn", "name": "Aurelia", "pic": "res://resources/world/minimap_aurelia.png", "pos": Vector2(284.4, 142.2), "tiles": Vector2(200, 150)},
	{"file": "ocaso.tscn", "name": "Páramo del Ocaso", "pic": "res://resources/world/minimap_ocaso.png", "pos": Vector2(342.4, 150.0), "tiles": Vector2(150, 110)},
]
## Roads between regions: [file a, tile in a, file b, tile in b].
const WORLD_LINKS := [
	["world.tscn", Vector2(89.5, 0), "field.tscn", Vector2(85.5, 130)],
	["field.tscn", Vector2(30, 0), "forest.tscn", Vector2(80.5, 120)],
	["field.tscn", Vector2(170, 79), "desert.tscn", Vector2(0, 61)],
	["desert.tscn", Vector2(160, 61), "aurelia.tscn", Vector2(0, 82.5)],
	["forest.tscn", Vector2(40, 0), "snowforest.tscn", Vector2(80.5, 120)],
	["snowforest.tscn", Vector2(160, 61), "snowvillage.tscn", Vector2(0, 41)],
	["aurelia.tscn", Vector2(200, 82.5), "ocaso.tscn", Vector2(0, 55)],
]
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
	"waystone": {"icon": "res://assets/ui/icons/waystone.png", "title": "Piedra rúnica", "short": "Piedra rúnica"},
	"dungeon": {"icon": "res://assets/ui/icons/dungeon.png", "title": "Mazmorra", "short": "Mazmorra"},
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
	for list in [SKILLS, ARCHER_SKILLS, MAGE_SKILLS]:
		for s in list:
			if s["id"] == id:
				return s
	return {}


## Numbers of a skill at a rank (atk = the hero's attack).
static func skill_values(id: String, rank: int, atk: int) -> Dictionary:
	var r := maxi(rank, 1)
	var cv := class_skill_values(id, r, atk)
	if not cv.is_empty():
		return cv
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
	var ct := class_skill_text(id, v)
	if ct != "":
		return ct
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


# --- Bestiary ---------------------------------------------------------------------------------
## Each creature you hunt fills its page: at these kills you earn a star (I, II, III), and every star
## makes you deal more damage to that creature and earn more gold from it.
const BESTIARY_TIERS := [10, 50, 200]
const BESTIARY_BOSS_TIERS := [1, 5, 20]
const BESTIARY_DMG := 0.05     # per star
const BESTIARY_GOLD := 0.06    # per star
const MF := "res://resources/sprite_frames/monsters/"
## In hunting order (the page number). Bosses are marked.
const BESTIARY := [
	{"name": "Limo", "frames": MF + "slimes_01_slime1.tres", "where": "Llanura de Valdoria"},
	{"name": "Limo extraño", "frames": MF + "special_slimes_mobs01_slime1.tres", "where": "Llanura de Valdoria"},
	{"name": "Goblin", "frames": MF + "goblin_mobs01_goblin1.tres", "where": "Llanura · campamento goblin"},
	{"name": "Gnoll", "frames": MF + "gnolls_mobs01_gnoll1.tres", "where": "Llanura · colinas del este"},
	{"name": "Limo musgoso", "frames": MF + "slimes02_slime_boss2.tres", "where": "Bosques"},
	{"name": "Retoño del bosque", "frames": MF + "ent_bosses_01_ent2.tres", "where": "Bosques"},
	{"name": "Limo de bruma", "frames": MF + "slimes02_slime_boss3.tres", "where": "Pantanos"},
	{"name": "Ent frondoso", "frames": MF + "ent_bosses_01_ent3.tres", "where": "Bosques"},
	{"name": "Gólem de cristal", "frames": MF + "golem_bosses01_golem2.tres", "where": "Ruinas y Arboleda de Cristal"},
	{"name": "Rey Limo", "frames": MF + "slimes02_slime_boss1.tres", "where": "Pantano del Norte", "boss": true},
	{"name": "Gólem de las Ruinas", "frames": MF + "golem_bosses01_golem1.tres", "where": "Ruinas Antiguas", "boss": true},
	{"name": "Ent Ancestral", "frames": MF + "ent_bosses_01_ent1.tres", "where": "Bosque de los Susurros", "boss": true},
	{"name": "Gólem de Obsidiana", "frames": MF + "golem_bosses01_golem3.tres", "where": "Corazón del Bosque", "boss": true},
	{"name": "Limo de arena", "frames": MF + "desert_slimes_slime1.tres", "where": "Dunas Doradas"},
	{"name": "Limo ácido", "frames": MF + "desert_acid_slime1.tres", "where": "Llanos de Vidrio"},
	{"name": "Saqueador de las dunas", "frames": MF + "desert_raiders_goblin1.tres", "where": "Cañón Rojo"},
	{"name": "Chacal de las dunas", "frames": MF + "desert_jackals_gnoll1.tres", "where": "Dunas Doradas"},
	{"name": "Gólem de arenisca", "frames": MF + "desert_golems_golem1.tres", "where": "Ruinas del Sol"},
	{"name": "Guardián del Sol", "frames": MF + "desert_golems_golem3.tres", "where": "Ruinas del Sol", "boss": true},
	{"name": "Jabalí salvaje", "frames": MF + "beasts_boar.tres", "where": "Llanura de Valdoria"},
	{"name": "Lobo del bosque", "frames": MF + "beasts_wolf.tres", "where": "Bosque Profundo"},
	{"name": "Árbol marchito", "frames": MF + "dry_ents_ent2.tres", "where": "Cañón Rojo y Llanos de Vidrio"},
	{"name": "Limo de escarcha", "frames": MF + "snow_slimes_slime1.tres", "where": "Bosque Nevado"},
	{"name": "Trasgo helado", "frames": MF + "snow_goblins_goblin1.tres", "where": "Cementerio Olvidado"},
	{"name": "Lobo de escarcha", "frames": MF + "beasts_frostwolf.tres", "where": "Pinar Blanco"},
	{"name": "Yeti", "frames": MF + "snow_yetis_gnoll1.tres", "where": "Bosque Nevado"},
	{"name": "Ent helado", "frames": MF + "snow_ents_ent3.tres", "where": "Claro del Ent Invernal"},
	{"name": "Gólem de hielo", "frames": MF + "snow_golems_golem2.tres", "where": "Gruta de Cristal"},
	{"name": "Rey Limo de Escarcha", "frames": MF + "snow_kings_slime_boss1.tres", "where": "Lago Congelado", "boss": true},
	{"name": "Ent Invernal", "frames": MF + "snow_ents_ent1.tres", "where": "Claro del Ent Invernal", "boss": true},
	{"name": "Gólem del Eclipse", "frames": MF + "eclipse_golem2.tres", "where": "Santuario del Eclipse · Cráter del Sol Negro"},
	{"name": "Limo umbrío", "frames": MF + "eclipse_slimes_slime1.tres", "where": "Páramo del Ocaso"},
	{"name": "Acólito del Sol Negro", "frames": MF + "dusk_cult_goblin1.tres", "where": "Llanos de Ceniza"},
	{"name": "Gnoll del Ocaso", "frames": MF + "dusk_gnolls_gnoll1.tres", "where": "Llanos de Ceniza"},
	{"name": "Lobo del Ocaso", "frames": MF + "beasts_duskwolf.tres", "where": "Bosque Marchito"},
	{"name": "Ent corrupto", "frames": MF + "dusk_ents_ent3.tres", "where": "Bosque Marchito"},
	{"name": "Ent Corrupto Anciano", "frames": MF + "dusk_ents_ent1.tres", "where": "Bosque Marchito", "boss": true},
	{"name": "Heraldo del Sol Negro", "frames": MF + "dusk_herald_golem1.tres", "where": "Fosa del Ocaso", "boss": true},
	{"name": "Devorador de Eclipses", "frames": MF + "eclipse_golem3.tres", "where": "Santuario del Eclipse", "boss": true},
]

# --- Achievements & titles -----------------------------------------------------------------
## kind: kills (all), kill (one creature, `of`), bosses (different bosses beaten), level, rank, maps,
## legendary, chests, pets, streak (days in a row), bestiary (pages with a star), gold (earned),
## forge (best + on a piece), dailies (daily tasks done). Each one unlocks its title.
const ACHIEVEMENTS := [
	{"id": "k100", "title": "Cazador Novato", "kind": "kills", "n": 100, "desc": "Derrota 100 monstruos."},
	{"id": "k1000", "title": "Azote de Bestias", "kind": "kills", "n": 1000, "desc": "Derrota 1.000 monstruos."},
	{"id": "k5000", "title": "Pesadilla de la Llanura", "kind": "kills", "n": 5000, "desc": "Derrota 5.000 monstruos."},
	{"id": "slimes", "title": "Azote de Limos", "kind": "kill", "of": "Limo", "n": 300, "desc": "Derrota 300 limos."},
	{"id": "goblins", "title": "Terror Goblin", "kind": "kill", "of": "Goblin", "n": 200, "desc": "Derrota 200 goblins."},
	{"id": "jackals", "title": "Señor de las Dunas", "kind": "kill", "of": "Chacal de las dunas", "n": 150, "desc": "Derrota 150 chacales de las dunas."},
	{"id": "boss1", "title": "Matagigantes", "kind": "bosses", "n": 1, "desc": "Derrota a tu primer jefe."},
	{"id": "boss4", "title": "Rompedor de Colosos", "kind": "bosses", "n": 4, "desc": "Derrota a 4 jefes distintos."},
	{"id": "boss_all", "title": "Leyenda Viviente", "kind": "bosses", "n": 7, "desc": "Derrota a todos los jefes de Valdoria."},
	{"id": "lv10", "title": "Espadachín", "kind": "level", "n": 10, "desc": "Llega al nivel 10."},
	{"id": "lv30", "title": "Veterano", "kind": "level", "n": 30, "desc": "Llega al nivel 30."},
	{"id": "lv50", "title": "Campeón de Aurelia", "kind": "level", "n": 50, "desc": "Llega al nivel 50."},
	{"id": "rankC", "title": "Rastreador", "kind": "rank", "of": "C", "desc": "Consigue la licencia de rango C."},
	{"id": "rankA", "title": "Élite del Gremio", "kind": "rank", "of": "A", "desc": "Consigue la licencia de rango A."},
	{"id": "rankS", "title": "Cazador Legendario", "kind": "rank", "of": "S", "desc": "Consigue la licencia de rango S."},
	{"id": "maps", "title": "Trotamundos", "kind": "maps", "n": 7, "desc": "Visita todas las regiones del mapamundi."},
	{"id": "leg1", "title": "Tocado por la Suerte", "kind": "legendary", "n": 1, "desc": "Encuentra una pieza legendaria."},
	{"id": "leg10", "title": "Coleccionista Dorado", "kind": "legendary", "n": 10, "desc": "Encuentra 10 piezas legendarias."},
	{"id": "chest20", "title": "Buscatesoros", "kind": "chests", "n": 20, "desc": "Abre 20 cofres."},
	{"id": "pets3", "title": "Amigo de las Bestias", "kind": "pets", "n": 3, "desc": "Ten 3 compañeros en el establo."},
	{"id": "streak7", "title": "Constante", "kind": "streak", "n": 7, "desc": "Juega 7 días seguidos."},
	{"id": "streak30", "title": "Incansable", "kind": "streak", "n": 30, "desc": "Juega 30 días seguidos."},
	{"id": "best10", "title": "Erudito de Bestias", "kind": "bestiary", "n": 10, "desc": "Consigue una estrella en 10 páginas del bestiario."},
	{"id": "best_all", "title": "Maestro del Bestiario", "kind": "bestiary", "n": 30, "desc": "Consigue una estrella en todas las páginas."},
	{"id": "gold50k", "title": "Mercader de Fortuna", "kind": "gold", "n": 50000, "desc": "Gana 50.000 de oro en total."},
	{"id": "forge10", "title": "Discípulo de Kara", "kind": "forge", "n": 10, "desc": "Mejora una pieza hasta +10."},
	{"id": "daily30", "title": "Profesional del Gremio", "kind": "dailies", "n": 30, "desc": "Completa 30 tareas diarias."},
	{"id": "runes", "title": "Viajero Rúnico", "kind": "waystones", "n": 10, "desc": "Despierta todas las piedras rúnicas."},
	{"id": "wolves", "title": "Cazador de Lobos", "kind": "kill", "of": "Lobo de escarcha", "n": 150, "desc": "Derrota 150 lobos de escarcha."},
	{"id": "story", "title": "El Quinto Viento", "kind": "story", "n": 1, "desc": "Termina la Crónica del Quinto Viento."},
	{"id": "dungeons4", "title": "Conquistador de Mazmorras", "kind": "dungeons", "n": 4, "desc": "Supera las cuatro mazmorras de Valdoria."},
	{"id": "heroic", "title": "Héroe de las Profundidades", "kind": "heroic", "n": 4, "desc": "Supera cuatro mazmorras en modo heroico."},
	{"id": "seal1", "title": "Elegido de los Sellos", "kind": "seals", "n": 1, "desc": "Encuentra una pieza de Sello (SOS, SOM o SOSUN)."},
	{"id": "tower10", "title": "Escalador del Abismo", "kind": "tower", "n": 10, "desc": "Supera el piso 10 de la Torre del Abismo."},
	{"id": "tower25", "title": "Señor del Abismo", "kind": "tower", "n": 25, "desc": "Supera el piso 25 de la Torre del Abismo."},
	{"id": "tower50", "title": "Leyenda sin Fondo", "kind": "tower", "n": 50, "desc": "Supera el piso 50 de la Torre del Abismo."},
	{"id": "legend10", "title": "Más Allá del Límite", "kind": "legend", "n": 10, "desc": "Alcanza el nivel de leyenda 10 (después del nivel 99)."},
	{"id": "dusk", "title": "Azote del Sol Negro", "kind": "kill", "of": "Heraldo del Sol Negro", "n": 1, "desc": "Derrota al Heraldo del Sol Negro en la Fosa del Ocaso."},
	{"id": "dungeons7", "title": "Señor de las Profundidades", "kind": "dungeons", "n": 7, "desc": "Supera siete mazmorras de Valdoria."},
	{"id": "north", "title": "Corazón del Invierno", "kind": "kill", "of": "Ent Invernal", "n": 1, "desc": "Derrota al Ent Invernal."},
]
## The bosses that count for "all the bosses".
const BOSSES := ["Rey Limo", "Gólem de las Ruinas", "Ent Ancestral", "Gólem de Obsidiana", "Guardián del Sol", "Rey Limo de Escarcha", "Ent Invernal",
	"Ent Corrupto Anciano", "Heraldo del Sol Negro"]

# --- Every day -----------------------------------------------------------------------------
## Reward for each day in a row you play (the 7th is the big one; the cycle repeats).
const STREAK_REWARDS := [
	{"gold": 100, "eter": 1}, {"gold": 150, "eter": 2}, {"gold": 200, "piece": 0.5}, {"gold": 300, "eter": 2},
	{"gold": 400, "piece": 1.0}, {"gold": 500, "eter": 3}, {"gold": 800, "piece": 3.0},
]
const DAILY_TASKS := 3
## Monsters that can be the day's quarry (never bosses): double gold, more equipment, extra renown.
const PREY_MULT := 2.0


# --- Rune stones (teleports) ---------------------------------------------------------------
## Touch a stone (E) to wake it up; from any awake stone you can travel to every other awake one.
## pos in tiles; rune = which of the ten rune designs it wears.
const WAYSTONES := [
	{"id": "valdoria", "name": "Plaza de Valdoria", "map": "world.tscn", "pos": Vector2(89.5, 66.5), "rune": 3},
	{"id": "camp", "name": "Campamento de viajeros", "map": "field.tscn", "pos": Vector2(95, 32.5), "rune": 6},
	{"id": "ruins", "name": "Ruinas Antiguas", "map": "field.tscn", "pos": Vector2(86, 80), "rune": 2},
	{"id": "outpost", "name": "Puesto del Guardabosques", "map": "forest.tscn", "pos": Vector2(84.5, 113), "rune": 1},
	{"id": "heart", "name": "Corazón del Bosque", "map": "forest.tscn", "pos": Vector2(80.5, 47), "rune": 9},
	{"id": "oasis", "name": "Oasis de Zafira", "map": "desert.tscn", "pos": Vector2(31, 63.5), "rune": 5},
	{"id": "sunruins", "name": "Ruinas del Sol", "map": "desert.tscn", "pos": Vector2(104, 35), "rune": 0},
	{"id": "aurelia", "name": "Gran Plaza de Aurelia", "map": "aurelia.tscn", "pos": Vector2(99.5, 93), "rune": 4},
	{"id": "frostedge", "name": "Linde Helada", "map": "snowforest.tscn", "pos": Vector2(85, 114), "rune": 7},
	{"id": "frostvillage", "name": "Villa Escarcha", "map": "snowvillage.tscn", "pos": Vector2(55, 50), "rune": 8},
	{"id": "dusk", "name": "Puesto del Crepúsculo", "map": "ocaso.tscn", "pos": Vector2(17.5, 54), "rune": 6},
]


# --- Seals: the three tiers above legendary ----------------------------------------------------
## Rarity 4, 5 and 6. Pieces forged with fragments of the three Seals that, a thousand years ago,
## locked the Eclipse Devourer away. Each one carries the power of its Seal.
const SEAL_ODDS := [0.0025, 0.0008, 0.00025]     # SOS, SOM, SOSUN per roll (times 1 + 3 x luck)
const RARITY_STAT_MULT := [1.0, 1.0, 1.0, 1.2, 1.35, 1.55, 1.8]
const RARITY_AFFIX_COUNT := [0, 1, 2, 3, 3, 4, 5]
const RARITY_AFFIX_MULT := [1.0, 1.0, 1.25, 1.6, 1.8, 2.0, 2.3]
const SEALS := {
	4: {"short": "SOS", "name": "Sello de Estrella", "power": "Bendición estelar",
		"power_text": "12 % de probabilidad al golpear de que caiga una estrella sobre el enemigo (daño en área)",
		"lore": "Un fragmento del Sello de la Estrella late dentro de esta pieza. Brilla igual que el cielo del norte."},
	5: {"short": "SOM", "name": "Sello de Luna", "power": "Marea lunar",
		"power_text": "10 % de probabilidad al golpear de recuperar 4 % de vida y 6 % de maná",
		"lore": "Forjada con un fragmento del Sello de la Luna. De noche parece respirar, tranquila como el lago helado."},
	6: {"short": "SOSUN", "name": "Sello de Sol", "power": "Corona solar",
		"power_text": "+12 % de todo el daño y 20 % de probabilidad de incendiar al enemigo",
		"lore": "Un fragmento del Sello del Sol, el más poderoso de los tres. Quema al tacto de quien no es digno."},
}

# --- Forge effects --------------------------------------------------------------------------------
## Weapons improved to +5 wake an effect of their family; +8 and +10 make it more frequent.
const FORGE_PROC := {5: 0.12, 8: 0.2, 10: 0.3}
const FORGE_EFFECTS := {
	"llama": {"name": "Filo ardiente", "text": "quema al enemigo", "color": Color(1, 0.5, 0.15)},
	"veneno": {"name": "Hoja venenosa", "text": "envenena (se acumula hasta 3 veces)", "color": Color(0.45, 0.95, 0.3)},
	"desgarro": {"name": "Desgarro", "text": "hace sangrar al enemigo", "color": Color(0.95, 0.2, 0.2)},
	"aturdir": {"name": "Golpe sísmico", "text": "aturde al enemigo un instante", "color": Color(1, 0.9, 0.3)},
	"perforar": {"name": "Estocada perforante", "text": "atraviesa la guardia: +60 % de daño", "color": Color(0.9, 0.95, 1.0)},
	"viento": {"name": "Viento cortante", "text": "el corte salta a otro enemigo cercano", "color": Color(0.5, 1.0, 0.85)},
	"doble": {"name": "Corte doble", "text": "golpea dos veces", "color": Color(0.85, 0.85, 1.0)},
	"drenar": {"name": "Siega de almas", "text": "te cura con el daño que haces", "color": Color(0.75, 0.4, 1.0)},
	"rayo": {"name": "Tormenta", "text": "un rayo salta a dos enemigos cercanos", "color": Color(0.45, 0.75, 1.0)},
}
## Armour improved to +5 gains a bonus by slot (x1.5 at +8, x2 at +10).
const ARMOR_FORGE_FX := {"helmet": {"crit": 0.03}, "chest": {"guard": 0.04}, "gloves": {"crit_dmg": 0.1}, "boots": {"speed": 0.04}, "trinket": {"gold": 0.06}}

# --- Equipment sets -------------------------------------------------------------------------------
## Four pieces (head, torso, hands, feet). Wearing 2 or 4 of them wakes the set's bonuses.
const SETS := {
	"guardia": {"name": "Guardia de Valdoria", "level": 12, "pieces": ["set_guardia_helmet", "set_guardia_chest", "set_guardia_gloves", "set_guardia_boots"], "2": {"def": 3}, "4": {"hp_pct": 0.1, "guard": 0.05}, "2_text": "+3 de defensa", "4_text": "+10 % de vida y +5 % de daño bloqueado", "lore": "El equipo de quienes juraron proteger las murallas de Valdoria."},
	"sombra": {"name": "Sombra del Bosque", "level": 26, "pieces": ["set_sombra_helmet", "set_sombra_chest", "set_sombra_gloves", "set_sombra_boots"], "2": {"crit": 0.05}, "4": {"crit_dmg": 0.25, "dodge": 0.06}, "2_text": "+5 % de crítico", "4_text": "+25 % de daño crítico y +6 % de esquiva", "lore": "Tejido con hojas del Bosque Profundo: quien lo viste se vuelve parte de la espesura."},
	"sol": {"name": "Vestiduras del Sol", "level": 42, "pieces": ["set_sol_helmet", "set_sol_chest", "set_sol_gloves", "set_sol_boots"], "2": {"skill_dmg": 0.08}, "4": {"atk_pct": 0.08, "gold": 0.15}, "2_text": "+8 % de daño de habilidades", "4_text": "+8 % de ataque y +15 % de oro", "lore": "Los sacerdotes de las Ruinas del Sol vestían este oro para hablar con el astro."},
	"invierno": {"name": "Coraza del Invierno", "level": 60, "pieces": ["set_invierno_helmet", "set_invierno_chest", "set_invierno_gloves", "set_invierno_boots"], "2": {"guard": 0.06}, "4": {"hp_pct": 0.12, "lifesteal": 0.04}, "2_text": "+6 % de daño bloqueado", "4_text": "+12 % de vida y +4 % de robo de vida", "lore": "Hielo que no se derrite, forjado por los herreros de Villa Escarcha."},
	"eclipse": {"name": "Reliquias del Eclipse", "level": 70, "pieces": ["set_eclipse_helmet", "set_eclipse_chest", "set_eclipse_gloves", "set_eclipse_boots"], "2": {"atk_pct": 0.06, "crit": 0.04}, "4": {"skill_dmg": 0.15, "crit_dmg": 0.3, "lifesteal": 0.03}, "2_text": "+6 % de ataque y +4 % de crítico", "4_text": "+15 % de habilidades, +30 % de daño crítico y +3 % de robo de vida", "lore": "Reliquias de los cazadores que encerraron al Devorador. Aún guardan su sombra."},
}
const SET_EQUIPMENT := {
	"set_guardia_helmet": {"name": "Yelmo de la Guardia", "slot": "helmet", "level": 12, "def": 3, "hp": 8, "set": "guardia", "desc": "Pieza del set Guardia de Valdoria. El equipo de quienes juraron proteger las murallas de Valdoria."},
	"set_guardia_chest": {"name": "Coraza de la Guardia", "slot": "chest", "level": 12, "def": 4, "hp": 14, "set": "guardia", "desc": "Pieza del set Guardia de Valdoria. El equipo de quienes juraron proteger las murallas de Valdoria."},
	"set_guardia_gloves": {"name": "Guanteletes de la Guardia", "slot": "gloves", "level": 12, "atk": 2, "def": 1, "set": "guardia", "desc": "Pieza del set Guardia de Valdoria. El equipo de quienes juraron proteger las murallas de Valdoria."},
	"set_guardia_boots": {"name": "Grebas de la Guardia", "slot": "boots", "level": 12, "def": 2, "speed": 0.03, "set": "guardia", "desc": "Pieza del set Guardia de Valdoria. El equipo de quienes juraron proteger las murallas de Valdoria."},
	"set_sombra_helmet": {"name": "Capucha de la Sombra", "slot": "helmet", "level": 26, "def": 4, "hp": 12, "set": "sombra", "desc": "Pieza del set Sombra del Bosque. Tejido con hojas del Bosque Profundo: quien lo viste se vuelve parte de la espesura."},
	"set_sombra_chest": {"name": "Jubón de la Sombra", "slot": "chest", "level": 26, "def": 6, "hp": 21, "set": "sombra", "desc": "Pieza del set Sombra del Bosque. Tejido con hojas del Bosque Profundo: quien lo viste se vuelve parte de la espesura."},
	"set_sombra_gloves": {"name": "Guantes de la Sombra", "slot": "gloves", "level": 26, "atk": 3, "def": 2, "set": "sombra", "desc": "Pieza del set Sombra del Bosque. Tejido con hojas del Bosque Profundo: quien lo viste se vuelve parte de la espesura."},
	"set_sombra_boots": {"name": "Botas de la Sombra", "slot": "boots", "level": 26, "def": 3, "speed": 0.03, "set": "sombra", "desc": "Pieza del set Sombra del Bosque. Tejido con hojas del Bosque Profundo: quien lo viste se vuelve parte de la espesura."},
	"set_sol_helmet": {"name": "Corona del Sol", "slot": "helmet", "level": 42, "def": 6, "hp": 18, "set": "sol", "desc": "Pieza del set Vestiduras del Sol. Los sacerdotes de las Ruinas del Sol vestían este oro para hablar con el astro."},
	"set_sol_chest": {"name": "Peto del Sol", "slot": "chest", "level": 42, "def": 9, "hp": 29, "set": "sol", "desc": "Pieza del set Vestiduras del Sol. Los sacerdotes de las Ruinas del Sol vestían este oro para hablar con el astro."},
	"set_sol_gloves": {"name": "Brazales del Sol", "slot": "gloves", "level": 42, "atk": 4, "def": 3, "set": "sol", "desc": "Pieza del set Vestiduras del Sol. Los sacerdotes de las Ruinas del Sol vestían este oro para hablar con el astro."},
	"set_sol_boots": {"name": "Sandalias del Sol", "slot": "boots", "level": 42, "def": 4, "speed": 0.03, "set": "sol", "desc": "Pieza del set Vestiduras del Sol. Los sacerdotes de las Ruinas del Sol vestían este oro para hablar con el astro."},
	"set_invierno_helmet": {"name": "Yelmo del Invierno", "slot": "helmet", "level": 60, "def": 8, "hp": 24, "set": "invierno", "desc": "Pieza del set Coraza del Invierno. Hielo que no se derrite, forjado por los herreros de Villa Escarcha."},
	"set_invierno_chest": {"name": "Coraza del Invierno", "slot": "chest", "level": 60, "def": 11, "hp": 38, "set": "invierno", "desc": "Pieza del set Coraza del Invierno. Hielo que no se derrite, forjado por los herreros de Villa Escarcha."},
	"set_invierno_gloves": {"name": "Manoplas del Invierno", "slot": "gloves", "level": 60, "atk": 6, "def": 5, "set": "invierno", "desc": "Pieza del set Coraza del Invierno. Hielo que no se derrite, forjado por los herreros de Villa Escarcha."},
	"set_invierno_boots": {"name": "Botas del Invierno", "slot": "boots", "level": 60, "def": 6, "speed": 0.03, "set": "invierno", "desc": "Pieza del set Coraza del Invierno. Hielo que no se derrite, forjado por los herreros de Villa Escarcha."},
	"set_eclipse_helmet": {"name": "Máscara del Eclipse", "slot": "helmet", "level": 70, "def": 9, "hp": 27, "set": "eclipse", "desc": "Pieza del set Reliquias del Eclipse. Reliquias de los cazadores que encerraron al Devorador. Aún guardan su sombra."},
	"set_eclipse_chest": {"name": "Manto del Eclipse", "slot": "chest", "level": 70, "def": 13, "hp": 43, "set": "eclipse", "desc": "Pieza del set Reliquias del Eclipse. Reliquias de los cazadores que encerraron al Devorador. Aún guardan su sombra."},
	"set_eclipse_gloves": {"name": "Garras del Eclipse", "slot": "gloves", "level": 70, "atk": 6, "def": 5, "set": "eclipse", "desc": "Pieza del set Reliquias del Eclipse. Reliquias de los cazadores que encerraron al Devorador. Aún guardan su sombra."},
	"set_eclipse_boots": {"name": "Pasos del Eclipse", "slot": "boots", "level": 70, "def": 6, "speed": 0.03, "set": "eclipse", "desc": "Pieza del set Reliquias del Eclipse. Reliquias de los cazadores que encerraron al Devorador. Aún guardan su sombra."},
}


## Any piece of equipment by id (normal pieces and set pieces).
static func equip_def(id: String) -> Dictionary:
	if EQUIPMENT.has(id):
		return EQUIPMENT[id]
	return SET_EQUIPMENT.get(id, {})


## The forge family of a weapon (what its +5 effect does).
static func weapon_family(base: String) -> String:
	for pair in [["daga", "veneno"], ["colmillo", "veneno"], ["lanza", "perforar"], ["pica", "perforar"], ["hacha", "desgarro"],
			["martillo", "aturdir"], ["maza", "aturdir"], ["cimitarra", "viento"], ["estoque", "doble"], ["katana", "doble"],
			["hoz", "drenar"], ["guadana", "drenar"], ["tridente", "rayo"]]:
		if base.begins_with(pair[0]):
			return pair[1]
	return "llama"


# --- Wave dungeons ----------------------------------------------------------------------------------
## Each region hides a portal to a closed arena: five waves (an elite or two on the way, the boss at the
## end), a reward chest and a piece of the region's set. Heroic mode (after a first victory) is harder
## and pays better. The Sanctuary of the Eclipse opens only at the end of the story.
const DUNGEONS := {
	"ruinas": {"name": "Cripta de las Ruinas", "theme": "crypt", "map": "field.tscn", "pos": Vector2(80, 77), "level": 12, "set": "guardia",
		"pool": ["Limo", "Limo extraño", "Goblin", "Gnoll", "Jabalí salvaje", "Gólem de cristal"], "boss": "Gólem de las Ruinas",
		"color": Color(0.75, 0.7, 0.6), "lore": "Bajo las Ruinas Antiguas duerme la cripta de los primeros cazadores. Algo la ha despertado."},
	"raices": {"name": "Raíces del Bosque", "theme": "forest", "map": "forest.tscn", "pos": Vector2(86, 58), "level": 26, "set": "sombra",
		"pool": ["Retoño del bosque", "Limo musgoso", "Ent frondoso", "Lobo del bosque", "Limo de bruma"], "boss": "Gólem de Obsidiana",
		"color": Color(0.45, 0.85, 0.45), "lore": "Entre las raíces del Bosque Profundo hay un claro que no aparece en ningún mapa."},
	"tumba": {"name": "Tumba del Faraón", "theme": "sand", "map": "desert.tscn", "pos": Vector2(118, 49), "level": 42, "set": "sol",
		"pool": ["Limo de arena", "Limo ácido", "Saqueador de las dunas", "Chacal de las dunas", "Árbol marchito", "Gólem de arenisca"], "boss": "Guardián del Sol",
		"color": Color(1.0, 0.8, 0.35), "lore": "El rey que nadie recuerda fue enterrado con su oro... y con sus guardianes."},
	"escarcha": {"name": "Cripta de Escarcha", "theme": "ice", "map": "snowforest.tscn", "pos": Vector2(132, 40), "level": 60, "set": "invierno",
		"pool": ["Limo de escarcha", "Trasgo helado", "Lobo de escarcha", "Yeti", "Ent helado", "Gólem de hielo"], "boss": "Rey Limo de Escarcha",
		"color": Color(0.6, 0.85, 1.0), "lore": "Bajo la Gruta de Cristal, el hielo guarda lo que el invierno no quiso olvidar."},
	"eclipse": {"name": "Santuario del Eclipse", "theme": "eclipse", "map": "aurelia.tscn", "pos": Vector2(100, 65), "level": 70, "set": "eclipse",
		"pool": ["Gólem del Eclipse", "Limo umbrío", "Yeti", "Chacal de las dunas", "Ent helado"], "boss": "Devorador de Eclipses",
		"color": Color(0.75, 0.5, 1.0), "story": 6,
		"lore": "Bajo el palacio de Aurelia, el santuario donde los tres Sellos encerraron al Devorador de Eclipses."},
	"cloacas": {"name": "Cloacas de Valdoria", "theme": "crypt", "map": "world.tscn", "pos": Vector2(60, 106.5), "level": 6, "set": "guardia",
		"pool": ["Limo", "Limo extraño", "Goblin", "Limo musgoso"], "boss": "Rey Limo",
		"color": Color(0.55, 0.75, 0.5), "lore": "Bajo las calles de Valdoria corre un laberinto de cloacas. Los limos se multiplican allí abajo, y algo grande los manda."},
	"oasis_hundido": {"name": "Oasis Hundido", "theme": "sand", "map": "desert.tscn", "pos": Vector2(70, 92), "level": 36, "set": "sol",
		"pool": ["Limo de arena", "Limo ácido", "Saqueador de las dunas", "Chacal de las dunas"], "boss": "Gólem de arenisca",
		"color": Color(0.4, 0.8, 0.85), "lore": "Un oasis que la arena se tragó hace siglos. Los saqueadores dicen que el agua todavía corre allí abajo... y que algo la custodia."},
	"fosa": {"name": "Fosa del Ocaso", "theme": "eclipse", "map": "ocaso.tscn", "pos": Vector2(124, 38), "level": 84, "set": "eclipse",
		"pool": ["Acólito del Sol Negro", "Gnoll del Ocaso", "Lobo del Ocaso", "Ent corrupto", "Gólem del Eclipse"], "boss": "Heraldo del Sol Negro",
		"color": Color(0.9, 0.25, 0.4), "lore": "Bajo el Cráter del Sol Negro, los acólitos cavaron una fosa hacia la oscuridad. Su Heraldo espera abajo una segunda aurora."},
	"abismo": {"name": "Torre del Abismo", "theme": "crypt", "map": "world.tscn", "pos": Vector2(109.5, 44.5), "level": 62, "set": "guardia",
		"pool": ["Limo"], "boss": "Gólem de las Ruinas", "color": Color(0.95, 0.3, 0.45), "tower": true,
		"lore": "Cuando el Devorador cayó, una torre negra brotó junto al Gremio. Nadie ha visto su cima. Cada piso es más hondo que el anterior... y paga mejor."},
}
## The Abyss Tower (post-game): endless floors. Its entry here only places the portal and gives the
## defaults; Game.dungeon_def builds each floor (arena, monsters, boss, level) on the fly.
const TOWER_ID := "abismo"
const TOWER_THEMES := ["crypt", "forest", "sand", "ice", "eclipse"]
const TOWER_BOSSES := ["Gólem de las Ruinas", "Ent Ancestral", "Gólem de Obsidiana", "Guardián del Sol", "Rey Limo de Escarcha", "Ent Invernal", "Devorador de Eclipses"]
const TOWER_WAVES := 3
## Floors needed to unlock it without finishing the story.
const TOWER_LEVEL := 60
const DUNGEON_WAVES := 5
const DUNGEON_RANKS := [["S", 150.0, 15], ["A", 240.0, 30], ["B", 360.0, 60], ["C", 99999.0, 99999]]


# --- The story: «Crónica del Quinto Viento» --------------------------------------------------------------
## Un cazador que empezó tarde. El grupo más fuerte de Valdoria, los Cuatro Vientos, lo ve tumbar un gólem
## con la guardia abierta y decide «adoptarlo»: lo entrenan hasta caer, una y otra vez. Mientras tanto,
## alguien está rompiendo los tres Sellos que encierran al Devorador de Eclipses: Varian, el alumno que
## los Vientos rompieron hace diez años. Al final, el novato tardío se convierte en el que entrena.
## Each step: kind talk (an NPC whose name contains `target`), kill (a monster; `n` of them if given),
## visit (a region), dungeon (clear it). `map`/`pos` place the marker; `lines` is what the NPC says on a
## talk step; `done` is the line shown when the step is completed; `give` items / `reward` on completion.
const STORY_CHAPTERS := ["", "El novato tardío", "Entrenamiento hasta caer", "Arena y oro", "El invierno eterno", "El Quinto Viento", "El Eclipse", "Epílogo: el que entrena",
	"Ecos del Sol Negro"]
## Steps from here on are the post-game chapter (the story counts as finished before them).
const STORY_MAIN_STEPS := 28
## Bumped whenever STORY changes shape; old saves are remapped in Game.
const STORY_VERSION := 2
const STORY := [
	# 1 · El novato tardío
	{"ch": 1, "kind": "talk", "target": "Ysolde", "map": "guild_1f.tscn", "pos": Vector2(11.5, 8), "text": "Habla con la Maestra Ysolde en el Gremio",
		"lines": ["¿Ya cumpliste tu primer pedido? Bien. No hagas caso de las risas: a tu edad, casi todos ya se retiraron, y tú recién empiezas.",
			"Escucha. Anoche la tierra tembló bajo las Ruinas Antiguas, en el centro de la Llanura. El gólem que duerme allí ha despertado.",
			"Los rangos altos están todos fuera, y los jóvenes no se atreven. Ve a mirar... y si puedes, derríbalo. Pero vuelve con vida, ¿eh?"]},
	{"ch": 1, "kind": "kill", "target": "Gólem de las Ruinas", "map": "field.tscn", "pos": Vector2(83, 69), "text": "Derrota al Gólem de las Ruinas",
		"done": "El gólem se derrumba. Entre los escombros brilla una piedra con una estrella... y desde lo alto de las ruinas, alguien aplaude.",
		"give": {"frag_estrella": 1}},
	{"ch": 1, "kind": "talk", "target": "Brann", "map": "field.tscn", "pos": Vector2(87, 72), "text": "Un guerrero enorme te espera junto a las ruinas",
		"lines": ["¡JA! ¡Un rango E tumbando un gólem! Con la guardia abierta como puerta de granero, pero lo tumbaste.",
			"Soy Brann Rompemuros. Los otros tres y yo somos los Cuatro Vientos. Sí, esos Cuatro Vientos. Cierra la boca, que te entran moscas.",
			"Esa piedra que recogiste es un fragmento del Sello de la Estrella. Alguien está rompiendo los Sellos, y nosotros vamos a averiguar quién.",
			"Y tú vienes con nosotros. Pero así no te sirves ni a ti mismo. Desde hoy entrenas con los Cuatro Vientos.",
			"No, no era una pregunta. Primera lección: hay gnolls al sureste de las ruinas. Diez. Antes de que se me enfríe la cena."]},
	# 2 · Entrenamiento hasta caer
	{"ch": 2, "kind": "kill", "target": "Gnoll", "n": 10, "map": "field.tscn", "pos": Vector2(144, 100), "text": "Entrenamiento de Brann: derrota gnolls",
		"done": "«¿Diez? ¿Ya? Entonces eran pocos. Tova, cúralo... que se viene la segunda lección.»"},
	{"ch": 2, "kind": "talk", "target": "Tova", "map": "field.tscn", "pos": Vector2(85, 73), "text": "Deja que Madre Tova te cure",
		"lines": ["Quieto, que te curo. Ya está. ¿Sabes cuántas veces se rompió Brann los huesos aprendiendo eso? Yo tampoco: perdí la cuenta.",
			"Te va a doler todo durante un mes. Después, nada te va a doler igual. Así funciona nuestro entrenamiento.",
			"Seren te espera arriba, en la sala de entrenamiento del Gremio. Es seca, pero no muerde. Casi nunca."],
		"reward": {"gold": 150}},
	{"ch": 2, "kind": "talk", "target": "Seren", "map": "guild_2f.tscn", "pos": Vector2(12.5, 7.5), "text": "Sube a la sala de entrenamiento del Gremio y habla con Seren",
		"lines": ["Así que tú eres el novato de Brann. Mm. Peleas como quien parte leña: fuerza sin pensar.",
			"Lección de hoy: el maná no se gasta, se administra. Una habilidad a tiempo vale más que diez golpes a destiempo.",
			"Bajo las Ruinas está la cripta de los primeros cazadores. Cinco oleadas sin descanso. Entra, y no salgas hasta que acabe.",
			"Si sobrevives, te enseño algo de verdad. Si no... Tova es muy buena sanadora."]},
	{"ch": 2, "kind": "dungeon", "target": "ruinas", "map": "field.tscn", "pos": Vector2(80, 77), "text": "Prueba de Seren: supera la Cripta de las Ruinas (mazmorra)",
		"done": "En lo más hondo de la cripta, un mural muestra cinco figuras. Una de ellas está tachada con una espada."},
	{"ch": 2, "kind": "talk", "target": "Corvin", "map": "field.tscn", "pos": Vector2(31, 8), "text": "Corvin, el explorador de los Vientos, te espera en el camino del norte",
		"lines": ["...Saliste vivo de la cripta. Seren dijo que no lo harías. Me debe diez de oro.",
			"Soy Corvin. No hablo mucho. El Bosque Profundo, al norte, es la última prueba. Allí está el altar del Sello de la Estrella.",
			"Lo custodia un gólem de obsidiana. Yo no te voy a ayudar. Ellos tampoco. Esa es la gracia."]},
	{"ch": 2, "kind": "visit", "target": "forest.tscn", "map": "field.tscn", "pos": Vector2(30, 4), "text": "Viaja al Bosque Profundo (al norte del Bosque de los Susurros)"},
	{"ch": 2, "kind": "talk", "target": "Hilde", "map": "forest.tscn", "pos": Vector2(74.5, 110.5), "text": "Habla con Hilde, la guardabosques",
		"lines": ["¿Te mandan los Cuatro Vientos? Pobre de ti. La última vez que entrenaron a alguien aquí, el bosque tardó un año en crecer de nuevo.",
			"Hace diez años vino otro alumno suyo. Varian, se llamaba. Brillante. Demasiado. Un día dejó de sonreír, y al otro se fue.",
			"El altar está en el Corazón del Bosque. El gólem de obsidiana no deja pasar a nadie. Pasa por encima de él."]},
	{"ch": 2, "kind": "kill", "target": "Gólem de Obsidiana", "map": "forest.tscn", "pos": Vector2(80, 30), "text": "Derrota al Gólem de Obsidiana en el Corazón del Bosque",
		"done": "El altar se abre: el Sello de la Estrella está hecho pedazos. Alguien llegó antes... y dejó una pluma negra."},
	{"ch": 2, "kind": "talk", "target": "Ysolde", "map": "guild_1f.tscn", "pos": Vector2(11.5, 8), "text": "Vuelve al Gremio con la Maestra Ysolde",
		"lines": ["Brann vino a verme. Dijo, palabra por palabra: «El viejo aguanta. Súbanle el rango antes de que me avergüence».",
			"Viniendo de él, es lo más bonito que le oí decir a nadie. Y lo del Sello de la Estrella... me temo que es cierto.",
			"Una pluma negra. Es la firma de la Orden del Sol Negro, una secta que quiere despertar al Devorador de Eclipses.",
			"Los archivos más antiguos de Valdoria están en Aurelia, al otro lado del desierto. Busca a la archivista Leandra. Toma, para el camino."],
		"reward": {"gold": 500, "piece": 2.0}},
	# 3 · Arena y oro
	{"ch": 3, "kind": "kill", "target": "Saqueador de las dunas", "n": 8, "map": "desert.tscn", "pos": Vector2(128, 96), "text": "Los saqueadores del desierto llevan un sol negro cosido: derrótalos",
		"done": "El último saqueador suelta una carta: «El Quinto Viento paga bien. Retrasad al viejo»."},
	{"ch": 3, "kind": "talk", "target": "Encapuchado", "map": "desert.tscn", "pos": Vector2(140, 60), "text": "Una figura encapuchada te espera camino de Aurelia",
		"lines": ["Así que tú eres el nuevo juguete de Brann. Te imaginaba más joven.",
			"Me llamo Varian. Yo también fui su alumno. El quinto viento. Me entrenaron hasta romperme... y nadie se quedó a recoger los pedazos.",
			"Ahora tengo un maestro mejor. Uno que no se cansa ni se ríe. El Devorador me enseñará lo que los Vientos nunca supieron.",
			"Vuelve a casa, viejo. Esto ya no es entrenamiento."],
		"done": "El encapuchado se disuelve en una sombra violeta."},
	{"ch": 3, "kind": "visit", "target": "aurelia.tscn", "map": "desert.tscn", "pos": Vector2(158, 61), "text": "Cruza el Desierto de Ámbar hasta Aurelia"},
	{"ch": 3, "kind": "talk", "target": "Leandra", "map": "aurelia.tscn", "pos": Vector2(108, 62), "text": "Busca a la archivista Leandra frente al palacio de Aurelia",
		"lines": ["¿Varian? Estuvo aquí hace un mes. Se llevó los mapas de los tres Sellos y dejó los archivos patas arriba.",
			"El Sello del Sol se forjó en el templo que hoy llamamos Ruinas del Sol. Su guardián es un coloso de oro.",
			"Si Varian ya pasó por allí, el Guardián no protege: destruye. Detenlo y trae lo que quede del Sello."]},
	{"ch": 3, "kind": "kill", "target": "Guardián del Sol", "map": "desert.tscn", "pos": Vector2(124, 29), "text": "Derrota al Guardián del Sol en las Ruinas del Sol",
		"done": "Del pecho del Guardián cae un fragmento que quema sin dar calor.", "give": {"frag_sol": 1}},
	{"ch": 3, "kind": "talk", "target": "Leandra", "map": "aurelia.tscn", "pos": Vector2(108, 62), "text": "Lleva el Fragmento del Sol a Leandra",
		"lines": ["Estrella y Sol a salvo... por ahora. Solo falta la Luna, y Varian sabe tan bien como yo dónde está.",
			"En el norte, más allá del Bosque Profundo, hay una aldea donde el invierno nunca termina: Villa Escarcha.",
			"Su anciana, Freya, es la última que recuerda las canciones de los Sellos. Corre: él te lleva ventaja."],
		"reward": {"gold": 800, "piece": 2.5}},
	# 4 · El invierno eterno
	{"ch": 4, "kind": "visit", "target": "snowvillage.tscn", "map": "forest.tscn", "pos": Vector2(40, 4), "text": "Viaja al norte, a Villa Escarcha (cruzando el Bosque Nevado)"},
	{"ch": 4, "kind": "talk", "target": "Freya", "map": "snowvillage.tscn", "pos": Vector2(62, 47), "text": "Habla con la anciana Freya en la Plaza del Fuego",
		"lines": ["Siéntate junto al fuego. Un muchacho de capa negra pasó por aquí hace tres noches. Tenía los ojos más tristes que he visto.",
			"El Sello de la Luna descansaba bajo el Lago Congelado. Él despertó a un limo enorme y le hizo tragárselo.",
			"Y al Ent Invernal, que guardaba el camino, le susurró algo. Ahora no distingue amigos de enemigos. Libéralos a los dos."]},
	{"ch": 4, "kind": "kill", "target": "Rey Limo de Escarcha", "map": "snowforest.tscn", "pos": Vector2(103, 71), "text": "Derrota al Rey Limo de Escarcha en el Lago Congelado",
		"done": "El limo se deshace y deja un fragmento pálido como la escarcha.", "give": {"frag_luna": 1}},
	{"ch": 4, "kind": "kill", "target": "Ent Invernal", "map": "snowforest.tscn", "pos": Vector2(80, 26), "text": "Derrota al Ent Invernal en su claro",
		"done": "Con el último crujido del Ent, el bosque entero suspira. El invierno parece menos frío."},
	{"ch": 4, "kind": "talk", "target": "Freya", "map": "snowvillage.tscn", "pos": Vector2(62, 47), "text": "Vuelve con la anciana Freya",
		"lines": ["Estrella, Sol y Luna en manos de un solo cazador. Las canciones decían que volvería a pasar... pero no decían que sería alguien como tú.",
			"Los Sellos no se reparan: se renuevan donde se forjaron, en el santuario bajo Aurelia. Varian ya va hacia allí.",
			"Unos viajeros muy ruidosos pasaron preguntando por ti. Uno de ellos gritaba más que la tormenta. Te esperan en Aurelia."],
		"reward": {"gold": 1200, "piece": 3.0}},
	# 5 · El Quinto Viento
	{"ch": 5, "kind": "talk", "target": "Brann", "map": "aurelia.tscn", "pos": Vector2(104, 64), "text": "Los Cuatro Vientos te esperan frente al palacio de Aurelia",
		"lines": ["Llegaste. Bien. Siéntate, que esto me cuesta.",
			"Varian fue nuestro primer alumno. Lo entrenamos como a ti... pero cuando caía, yo le gritaba que se levantara. Nunca le pregunté si podía.",
			"Tova dice que la culpa es de los cuatro. Seren dice que es mía. Corvin no dice nada, que es peor.",
			"Esta vez no te vamos a entrenar. Esta vez peleamos a tu lado. Y cuando lo encontremos... déjame hablar con él primero."]},
	{"ch": 5, "kind": "talk", "target": "Leandra", "map": "aurelia.tscn", "pos": Vector2(108, 62), "text": "Lleva los tres fragmentos a Leandra",
		"lines": ["Los tres... Nunca pensé que los vería juntos. Y con los Cuatro Vientos detrás, nada menos.",
			"Bajo el palacio está el Santuario del Eclipse. Varian abrió la puerta anoche con sangre; con los fragmentos, también se abrirá para ti.",
			"El Devorador está despertando dentro de él. Si cae, los Sellos se renovarán. Si no... no habrá más amaneceres."]},
	# 6 · El Eclipse
	{"ch": 6, "kind": "dungeon", "target": "eclipse", "map": "aurelia.tscn", "pos": Vector2(100, 65), "text": "Entra al Santuario del Eclipse y derrota al Devorador",
		"done": "El Devorador cae. Entre la luz, Varian susurra: «Así que eso era ser fuerte...». Los tres fragmentos brillan y vuelven a ser Sellos."},
	# 7 · Epílogo: el que entrena
	{"ch": 7, "kind": "talk", "target": "Ysolde", "map": "guild_1f.tscn", "pos": Vector2(11.5, 8), "text": "Vuelve al Gremio: la Maestra Ysolde te espera",
		"lines": ["Todo Valdoria vio la luz anoche. Dicen que el sol salió dos veces.",
			"Tova trajo a Varian. Duerme abajo. Está débil, pero vivo, y cuando despertó preguntó por ti. Brann no se ha movido de su lado.",
			"Los Sellos están renovados, y su poder ha quedado repartido por el mundo. Dicen que ahora aparece más a menudo en el equipo de los grandes cazadores.",
			"Ah, y alguien lleva toda la mañana esperándote junto a la puerta. Creo que lo conoces."],
		"reward": {"gold": 3000, "piece": 6.0}},
	{"ch": 7, "kind": "talk", "target": "Darío", "map": "guild_1f.tscn", "pos": Vector2(7.2, 11.2), "text": "Habla con Darío, el novato del Gremio",
		"lines": ["El primer día me reí de ti. «El abuelo de rango E», te llamé. Delante de todos.",
			"Ahora todos hablan de ti. Y yo... llevo un año sin pasar de rango D. Los Vientos dicen que no entrenan a nadie más.",
			"Así que... ¿Me entrenarías tú? Aguanto lo que sea. Te lo juro.",
			"(Brann, desde la mesa del fondo: «¡Diez gnolls antes de cenar, novato! ¡Ya sabes cómo va!»)"],
		"done": "Has encontrado tu lugar: el novato tardío ahora es el que entrena. Los Cuatro Vientos te nombran el Quinto Viento.",
		"reward": {"gold": 1000, "title": "El Quinto Viento"}},
	# 8 · Ecos del Sol Negro (post-game)
	{"ch": 8, "kind": "talk", "target": "Varian", "map": "guild_1f.tscn", "pos": Vector2(19.5, 12), "text": "Varian ha despertado: búscalo en el Gremio",
		"lines": ["Así que tú eres el que me sacó de ahí dentro. No esperaba que el juguete de Brann fuera... amable.",
			"Escucha. El Devorador no estaba solo en mi cabeza. Había otra voz: la Orden. Ellos no querían liberarlo. Querían ser él.",
			"Al este de Aurelia la tierra se volvió ceniza cuando cayó. Los acólitos siguen allí, cavando hacia algo que llaman «la segunda aurora».",
			"No puedo pedirte perdón todavía. Pero puedo decirte dónde golpear: el Páramo del Ocaso."]},
	{"ch": 8, "kind": "visit", "target": "ocaso.tscn", "map": "aurelia.tscn", "pos": Vector2(198, 82.5), "text": "Cruza la puerta este de Aurelia hacia el Páramo del Ocaso"},
	{"ch": 8, "kind": "talk", "target": "Maren", "map": "ocaso.tscn", "pos": Vector2(10.5, 58.5), "text": "Habla con la Vigía Maren en el Puesto del Crepúsculo",
		"lines": ["¿Te manda el chico de la capa negra? Entonces sabes lo que hay ahí fuera.",
			"Los acólitos del Sol Negro se reúnen en los Llanos de Ceniza. Cada uno lleva una astilla de ese corazón negro que adoran.",
			"Acaba con ellos y tráeme sus astillas: así sabremos cuánto les queda para su «aurora»."]},
	{"ch": 8, "kind": "kill", "target": "Acólito del Sol Negro", "n": 12, "map": "ocaso.tscn", "pos": Vector2(60, 58), "text": "Derrota acólitos del Sol Negro en los Llanos de Ceniza",
		"done": "Las astillas negras laten al unísono... y apuntan al norte, al Bosque Marchito."},
	{"ch": 8, "kind": "kill", "target": "Ent Corrupto Anciano", "map": "ocaso.tscn", "pos": Vector2(60, 16), "text": "Libera al Ent Corrupto Anciano en el Bosque Marchito",
		"done": "Al caer el Anciano, sus raíces se retiran del Cráter: el camino a la Fosa queda abierto."},
	{"ch": 8, "kind": "dungeon", "target": "fosa", "map": "ocaso.tscn", "pos": Vector2(124, 38), "text": "Baja a la Fosa del Ocaso y derrota al Heraldo del Sol Negro",
		"done": "El Heraldo se apaga. Su corazón negro ya no late: la segunda aurora no llegará."},
	{"ch": 8, "kind": "talk", "target": "Varian", "map": "guild_1f.tscn", "pos": Vector2(19.5, 12), "text": "Vuelve con Varian al Gremio",
		"lines": ["Lo sentí. Cuando el Heraldo cayó, la última voz se calló. Por primera vez en diez años, hay silencio aquí dentro.",
			"Brann quiere que vuelva a entrenar. Le dije que solo si me entrenas tú. Puso una cara...",
			"El mundo no se acabó, maestro. Hay una torre negra junto al Gremio que nadie ha subido, y bestias que nadie ha visto. Ve. Nosotros cuidamos la casa."],
		"done": "Fin de los Ecos del Sol Negro. Valdoria sigue ahí fuera: la Torre del Abismo, las mazmorras y las cacerías te esperan.",
		"reward": {"gold": 5000, "piece": 8.0}},
]

## The story's cast, placed in the world at runtime depending on how far the story has gone.
## spots: [first_step, last_step (inclusive), map, tile position]; lines: [[from_step, lines]] (the last
## one that applies is used when they are not the current talk target).
const _F := "res://resources/sprite_frames/"
const STORY_CAST := {
	"brann": {"name": "Brann Rompemuros", "frames": _F + "world/actor_7a336a8789.tres", "offset": Vector2(0, -12),
		"spots": [[2, 4, "field.tscn", Vector2(87, 72)], [5, 22, "guild_1f.tscn", Vector2(16.3, 7.4)], [23, 25, "aurelia.tscn", Vector2(104, 64)], [26, 99, "guild_1f.tscn", Vector2(16.3, 7.4)]],
		"lines": [[0, ["¡Diez gnolls! ¡No te oigo contar!", "Cuando te caigas, levántate. Cuando no puedas levantarte, levántate igual. Y luego ve con Tova."]],
			[5, ["La cerveza del Gremio es aguada, pero no le digas a Ysolde que lo dije.", "¿Ya fuiste a ver a Seren? Arriba. No la hagas esperar: se pone a congelar cosas."]],
			[22, ["Nunca le pregunté a Varian si podía seguir. A ti te lo pregunto: ¿puedes?", "Cuando entres al santuario, no mires atrás. Estaremos ahí."]],
			[26, ["¡Ahí está mi alumno favorito! No se lo digas a Varian.", "¿Que si te voy a seguir entrenando? Ahora entrenas tú. Yo miro y critico."]]]},
	"tova": {"name": "Madre Tova", "frames": _F + "world/actor_c395131db0.tres", "offset": Vector2(0, -10),
		"spots": [[3, 4, "field.tscn", Vector2(85, 73)], [23, 25, "aurelia.tscn", Vector2(101.5, 66.5)], [26, 99, "guild_1f.tscn", Vector2(14.9, 6.6)]],
		"lines": [[0, ["Ve, ve. Yo te curo cuando caigas. Porque vas a caer.", "Brann grita, pero le tiembla la voz cuando alguien se lastima. No se lo digas."]],
			[22, ["Llevo diez años guardando una venda para Varian. Hoy quizá la use.", "Que la luz te cubra la espalda. Yo cubro el resto."]],
			[26, ["Varian comió sopa hoy. Dos platos. Es un buen día.", "No te olvides de dormir. Los grandes cazadores también duermen."]]]},
	"seren": {"name": "Seren Llamagris", "frames": _F + "world/actor_b2d662f689.tres", "offset": Vector2(0, -7),
		"spots": [[5, 6, "guild_2f.tscn", Vector2(12.5, 7.5)], [23, 25, "aurelia.tscn", Vector2(106, 66.5)], [26, 99, "guild_1f.tscn", Vector2(15.2, 9.0)]],
		"lines": [[0, ["La cripta está bajo las Ruinas. ¿Qué haces aquí todavía?", "Tienes maná. Úsalo. Es gratis. Bueno, casi."]],
			[22, ["Si Varian usa el poder del Devorador, sus hechizos serán violeta. Esquívalos. No es un consejo, es una orden.", "Corvin apostó contra ti otra vez. Ya perdió veinte de oro."]],
			[26, ["Admito que me equivoqué contigo. Una vez. No te acostumbres.", "¿Entrenar a Darío? Pobre chico. Haz que sufra lo justo."]]]},
	"corvin": {"name": "Corvin Sinsombra", "frames": _F + "world/actor_0ffa6092ff.tres", "offset": Vector2(0, -13),
		"spots": [[7, 8, "field.tscn", Vector2(31, 8)], [23, 25, "aurelia.tscn", Vector2(110, 66.5)], [26, 99, "guild_1f.tscn", Vector2(17.4, 9.2)]],
		"lines": [[0, ["...Al norte.", "..."]],
			[22, ["...Varian me enseñó a tallar flechas. Ese era él.", "...Vuelve vivo."]],
			[26, ["...Buen trabajo.", "...Seren me debe treinta de oro. Ahora sí."]]]},
	"dario": {"name": "Darío, novato", "frames": _F + "aurelia/actor_5fe1c31bff.tres", "offset": Vector2(0, -11),
		"spots": [[0, 99, "guild_1f.tscn", Vector2(7.2, 11.2)]],
		"lines": [[0, ["¿Rango E a tu edad? ¡Ja! ¿Te perdiste camino de la taberna, abuelo?", "Yo soy Darío, rango D. Algún día los Cuatro Vientos me van a reclutar a mí, no a un viejo."]],
			[5, ["Espera... ¿Brann Rompemuros te está entrenando? ¿A TI?", "No es justo. Yo llevo un año pidiéndoselo."]],
			[12, ["Dicen que tumbaste al gólem de obsidiana solo. Yo... no me reía de ti. Bueno, un poco.", "¿Cómo es el entrenamiento de los Vientos? ¿Duele mucho?"]],
			[28, ["¡Diez gnolls más antes de cenar! ...¿Era así, maestro?", "Algún día voy a ser el Sexto Viento. Ya verás."]]]},
	"varian": {"name": "Encapuchado", "frames": _F + "interiors/actor_b5d77c3815.tres", "offset": Vector2(0, -13),
		"spots": [[13, 13, "desert.tscn", Vector2(140, 60)]],
		"lines": [[0, ["..."]]]},
	"varian_g": {"name": "Varian", "frames": _F + "interiors/actor_b5d77c3815.tres", "offset": Vector2(0, -13),
		"spots": [[28, 999, "guild_1f.tscn", Vector2(19.5, 12)]],
		"lines": [[0, ["Todavía no sé bien quién soy sin esa voz. Pero sé quién quiero ser."]],
			[35, ["¿Subiste la Torre? Cuéntamelo todo. Despacio. Brann exagera.", "Diez gnolls antes de cenar, ¿eh? Algunas cosas no cambian."]]]},
}


# --- Classes --------------------------------------------------------------------------------------
## The hero's class: its looks (nine per class, by level), its basic attack, its six skills and a small
## bonus. `fx` uses the same keys as the talents. The class can be changed in the Guild (2nd floor).
const CLASSES := {
	"guerrero": {"name": "Guerrero", "frames": "res://resources/sprite_frames/swordsman_lvl%d.tres", "attack": "melee",
		"desc": "Espada en mano y al frente. Aguanta más golpes y pega donde duele.",
		"perk": "+15 % de vida y +2 de defensa.", "fx": {"hp_pct": 0.15, "def": 2.0}, "color": Color(0.85, 0.35, 0.25)},
	"arquero": {"name": "Arquero", "frames": "res://resources/sprite_frames/archer_lvl%d.tres", "attack": "arrow",
		"desc": "Dispara flechas desde lejos. Rápido, preciso y difícil de alcanzar.",
		"perk": "+8 % de velocidad y +6 % de crítico.", "fx": {"speed": 0.08, "crit": 0.06}, "color": Color(0.35, 0.75, 0.3)},
	"mago": {"name": "Mago", "frames": "res://resources/sprite_frames/mage_lvl%d.tres", "attack": "fireball",
		"desc": "Bolas de fuego que estallan, rayos y meteoros. Frágil, pero devastador.",
		"perk": "+40 de maná, +20 % de daño de habilidades y más regeneración de maná.", "fx": {"mana": 40.0, "skill_dmg": 0.2, "mana_regen": 0.5}, "color": Color(0.45, 0.45, 0.95)},
}
const CLASS_ORDER := ["guerrero", "arquero", "mago"]
## What the hero is called at each look tier (1-7), by class.
const CLASS_TITLES := {
	"guerrero": ["Aprendiz", "Espadachín", "Veterano", "Caballero", "Guardián", "Campeón", "Leyenda de Valdoria"],
	"arquero": ["Aprendiz", "Arquero", "Tirador", "Montaraz", "Ojo de Halcón", "Maestro Arquero", "Leyenda de Valdoria"],
	"mago": ["Aprendiz", "Hechicero", "Mago", "Arcanista", "Archimago", "Sabio del Eclipse", "Leyenda de Valdoria"],
}
## Gold to change class in the Guild (the first change is free).
const CLASS_CHANGE_COST := 500

const ARCHER_SKILLS := [
	{"id": "abanico", "name": "Abanico de flechas", "icon": SK + "abanico.png", "mana": 18, "level": 1},
	{"id": "salto", "name": "Salto atrás", "icon": SK + "salto.png", "mana": 12, "level": 3},
	{"id": "ojo_halcon", "name": "Ojo de halcón", "icon": SK + "ojo_halcon.png", "mana": 30, "level": 6},
	{"id": "explosiva", "name": "Flecha explosiva", "icon": SK + "explosiva.png", "mana": 28, "level": 9},
	{"id": "lluvia", "name": "Lluvia de flechas", "icon": SK + "lluvia.png", "mana": 36, "level": 13},
	{"id": "perforante", "name": "Flecha perforante", "icon": SK + "perforante.png", "mana": 40, "level": 20},
]
const MAGE_SKILLS := [
	{"id": "bola_fuego", "name": "Bola de fuego", "icon": SK + "bola_fuego.png", "mana": 16, "level": 1},
	{"id": "parpadeo", "name": "Parpadeo", "icon": SK + "parpadeo.png", "mana": 14, "level": 3},
	{"id": "barrera", "name": "Barrera arcana", "icon": SK + "barrera.png", "mana": 30, "level": 6},
	{"id": "rayo", "name": "Cadena de rayos", "icon": SK + "rayo.png", "mana": 28, "level": 9},
	{"id": "nova", "name": "Nova de escarcha", "icon": SK + "nova.png", "mana": 34, "level": 13},
	{"id": "meteoro", "name": "Meteoro", "icon": SK + "meteoro.png", "mana": 45, "level": 20},
]


static func skills_for(cls: String) -> Array:
	match cls:
		"arquero":
			return ARCHER_SKILLS
		"mago":
			return MAGE_SKILLS
	return SKILLS


## Numbers of the archer's and mage's skills (the warrior's are in skill_values).
static func class_skill_values(id: String, r: int, atk: int) -> Dictionary:
	match id:
		"abanico":
			return {"dmg": 1 + r + int(atk * 0.75), "arrows": 4 + int((r + 1) / 2), "cd": 3.0}
		"salto":
			return {"time": 0.16 + 0.02 * r, "cd": maxf(1.6, 3.4 - 0.2 * r)}
		"ojo_halcon":
			return {"bonus": 1 + int((r - 1) / 2) + int(atk / 6), "time": 8.0 + 2.0 * r, "cd": 22.0}
		"explosiva":
			return {"dmg": 2 + 2 * r + int(atk * 1.3), "radius": 38.0 + 3.0 * r, "cd": 8.0}
		"lluvia":
			return {"dmg": 1 + r + int(atk * 0.6), "radius": 56.0 + 4.0 * r, "arrows": 10 + 2 * r, "cd": 12.0}
		"perforante":
			return {"dmg": 4 + 3 * r + int(atk * 1.9), "length": 230.0, "cd": 8.0}
		"bola_fuego":
			return {"dmg": 2 + r + int(atk * 1.15), "radius": 34.0 + 2.0 * r, "cd": 2.6}
		"parpadeo":
			return {"dist": 80.0 + 8.0 * r, "cd": maxf(1.6, 4.0 - 0.25 * r)}
		"barrera":
			return {"heal": 0.12 + 0.04 * r, "shield": 1.4 + 0.3 * r, "cd": maxf(14.0, 26.0 - 2.0 * r)}
		"rayo":
			return {"dmg": 3 + 2 * r + int(atk * 1.4), "chains": 1 + r, "cd": 7.0}
		"nova":
			return {"dmg": 2 + 2 * r + int(atk * 1.1), "radius": 78.0, "stun": 0.8 + 0.2 * r, "cd": 12.0}
		"meteoro":
			return {"dmg": 6 + 4 * r + int(atk * 2.4), "radius": 66.0 + 3.0 * r, "cd": 14.0}
	return {}


static func class_skill_text(id: String, v: Dictionary) -> String:
	match id:
		"abanico":
			return "Disparas %d flechas en abanico (%d de daño cada una)." % [v["arrows"], v["dmg"]]
		"salto":
			return "Saltas hacia atrás, lejos de tu presa. Nada te alcanza mientras estás en el aire."
		"ojo_halcon":
			return "Durante %d segundos tienes +%d de ataque." % [v["time"], v["bonus"]]
		"explosiva":
			return "Una flecha que estalla al impactar y daña a todo lo que hay alrededor (%d de daño)." % v["dmg"]
		"lluvia":
			return "%d flechas caen del cielo sobre tu presa y su alrededor (%d de daño cada una)." % [v["arrows"], v["dmg"]]
		"perforante":
			return "Una flecha que atraviesa a todos los enemigos alineados (%d de daño)." % v["dmg"]
		"bola_fuego":
			return "Una gran bola de fuego que estalla y quema todo a su alrededor (%d de daño)." % v["dmg"]
		"parpadeo":
			return "Te teletransportas %d pasos en la dirección en que te mueves." % int(v["dist"] / 16.0)
		"barrera":
			return "Sanas un %d %% de tu vida y una barrera te protege %.1f segundos." % [int(round(v["heal"] * 100)), v["shield"]]
		"rayo":
			return "Un rayo cae sobre tu presa y salta a %d enemigos cercanos (%d de daño)." % [v["chains"], v["dmg"]]
		"nova":
			return "Una ola de escarcha daña y congela a todo lo que te rodea (%d de daño, %.1f s)." % [v["dmg"], v["stun"]]
		"meteoro":
			return "Invocas un meteoro sobre tu presa: un instante después, todo arde (%d de daño)." % v["dmg"]
	return ""
