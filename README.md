# Crónicas del Cazador

RPG top-down de caza de monstruos en pixel art — Godot 4.7.

## Cómo abrir
Abre Godot 4.7.2 → **Importar** → selecciona `project.godot`. Pulsa F5 para jugar.

## Controles
| Acción | Teclado | Mando |
|---|---|---|
| Mover | WASD / Flechas | Stick izquierdo |
| Correr | Shift | B |
| Atacar | Espacio / J / Clic | X |
| Poción de vida (30 %) | Q | Y |
| Habilidades | 1 a 6 | — |
| Personaje / Inventario / Habilidades / Talentos | C / I / K / L | Select |
| Mapa · Mapamundi | M · N | — |
| Diario (recompensa diaria, tareas, presa del día) | O | — |
| Bestiario · Logros y títulos | B | — |
| Fijar / soltar objetivo · cambiar objetivo | Tab · rueda del ratón | — |
| Montar / desmontar | H | — |
| Ranking del Gremio (en cualquier lugar) | R | — |
| Hablar · despertar / usar piedra rúnica | E / Enter | A |
| Pausa | Esc | Start |

## Estructura
```
assets/          imágenes y sonidos que usa el juego (+ licencias)
  audio/sfx/     efectos de sonido (generados con tools/worldgen/gen_sfx.py)
resources/       tilesets, SpriteFrames, minimapas y mapas de colisión de cada región
scenes/
  ui/            menú, carga, HUD, pausa, opciones
  world/         world (Valdoria), field (Llanura), forest (Bosque Profundo),
                 desert (Desierto de Ámbar), aurelia (Aurelia),
                 snowforest (Bosque Nevado), snowvillage (Villa Escarcha)
  interiors/     casas, Gremio...
  monsters/ characters/ npc/ objects/   monstruos, jugador, PNJ, cofres y piedras rúnicas
scripts/         mismo orden que scenes/ + autoload/game.gd (estado y progreso)
                 y data/game_data.gd (todos los datos del juego)
tools/worldgen/  generadores de mapas, sprites y sonidos (Python); leen los packs
                 descomprimidos de C:\Users\nicol\JobHunter_raw
build/web/       la versión web (la que publica Vercel)
_originals/      los .zip originales de los packs de arte (ignorada por Godot y git)
```

## Capas de colisión
1 `world` · 2 `player` · 3 `npc` · 4 `interactable` · 5 `enemy_hurtbox` (zona de golpe de los monstruos)

## El mundo: Valdoria (`scenes/world/world.tscn`)
Mapa continuo de 180×140 tiles:
- **Ciudadela** (centro): murallas con torres y 4 portones, plaza-mercado con fuente, puestos, taberna, músicos, el **Gremio de Cazadores (Guild Hall)**, avenidas empedradas y casas.
- **Puerto de Valdoria** (sur): malecón de tablones con barandas de madera, camino costero, bodegas y tabernas frente al mar, mercado de pescado, muelles con barcos, rompeolas con faro. El sendero costero continúa por la costa natural.
- **Pradera del Norte**, **Cuartel de la Guardia** (oeste) y **Granjas del Este**.
- El portón norte lleva a la **Llanura de Valdoria**: el adoquín se convierte en sendero de tierra, el mismo que recibe al jugador en la llanura. Los senderos costeros terminan en miradores (Costa del Oeste / del Este).

## La Llanura de Valdoria (`scenes/world/field.tscn`)
Mapa abierto de 170×130 tiles al norte de la ciudad, con senderos que unen sus lugares:
- **Ruinas Antiguas** (centro): patio empedrado roto, arcos y torres caídas. Guarda el **Gólem de las Ruinas**.
- **Campamento del Viajero** (norte): fogata y viajeros con los que se puede hablar.
- **Lago Espejo** (este): puente de madera que cruza por una isla hasta la orilla lejana.
- **Bosque de los Susurros** (noroeste): árboles secos y otoñales; ahí vive el **Ent Ancestral**.
- **Pantano del Norte**: lagunas, limos y el **Rey Limo**.
- **Campamento goblin** (oeste), **Colinas del Este** (gnolls) y mesetas con acantilados repartidas por el mapa.

### Combate
- 45 monstruos (limos, goblins, gnolls y 3 jefes) que deambulan por su territorio, persiguen al jugador al verlo y vuelven a aparecer después de un rato.
- Al derrotarlos sueltan oro. Los jefes muestran su barra de vida abajo en la pantalla.
- En la llanura correr gasta estamina (barra verde); al agotarse pasas a caminar hasta recuperar un 30 %. En la ciudad se corre libremente. Si la vida llega a 0, despiertas en la entrada de la llanura con la vida llena.
- La salida sur de la llanura vuelve al portón norte de la ciudad.

### Progresión
- **Nivel** (máximo 99): cada monstruo da experiencia; al subir ganas **3 puntos de talento** y mejoran vida, maná y ataque.
- **Aspecto**: el espadachín cambia de sprite en los niveles 10, 20, 30, 50, 70 y 90 (Espadachín, Veterano, Caballero, Guardián, Campeón, Leyenda de Valdoria). Los sprites salen de `swordman_part1/2/3` (`resources/sprite_frames/swordsman_lvlN.tres`).
- **Habilidades** (6, teclas 1–6): Corte giratorio (nv 1), Embestida (nv 3), Grito de guerra (nv 6), Respiro (nv 9), Onda de choque (nv 13), Tajo de luz (nv 20). Cada una tiene 5 rangos que se compran con **experiencia de habilidad**, que se gana cazando (la mitad de la experiencia de cada presa).
- **Talentos** (L): los puntos van a los **3 atributos principales** (sin límite) o al **árbol**:
  - Vida (+4 de vida), Energía (+10 de estamina y recuperación) y Magia (+6 de maná y +2 % de daño de habilidades), de a 1 o de a 5 puntos.
  - Árbol de 27 nodos en 3 sendas: **Guerrero** (vida, ataque, defensa, críticos, robo de vida), **Explorador** (estamina, velocidad, esquiva, oro, botín, experiencia) y **Místico** (maná, poder y recarga de habilidades, pociones, escudo de maná).
  - Cada nodo necesita uno de los nodos que lo conectan, y cada fila pide puntos gastados en esa senda (0, 2, 5, 9, 14).
  - **Reiniciar** devuelve todos los puntos a cambio de oro (25 × nivel).
- **Personaje** (C): 6 ranuras de equipo (arma, cabeza, torso, manos, pies, accesorio), bolsa de equipo para equipar y desequipar, y todas las estadísticas. Cada pieza pide un nivel mínimo. Los monstruos sueltan equipo a veces (5 %) y los jefes siempre.
- **Inventario** (I): pociones (vida y maná, en porcentaje), manzanas y materiales.
- **Monstruos adaptados**: cada monstruo toma un nivel cercano al tuyo (los jefes, 2 por encima) cada vez que aparece; su vida, daño, oro y experiencia escalan con ese nivel, que se ve sobre su barra de vida.
- Datos en `scripts/data/game_data.gd` (`GameData`); estado y reglas en `scripts/autoload/game.gd`.

### Minimapa, cofres y forja
- **Minimapa** arriba a la derecha: muestra el terreno alrededor del héroe, monstruos (rojo), jefes (naranja), cofres sin abrir (dorado) y salidas (verde). **M** abre el mapa completo. Las imágenes las genera el exportador (`resources/world/minimap_*.png`).
- **Cofres** en la Llanura (12, en ruinas, isla del lago, bosque, pantano, campamento goblin, colinas...): se abren con **E** una sola vez por partida y dan equipo acorde a tu nivel (los cofres más vistosos, mejor botín y a veces piezas ya mejoradas), oro y pociones. Se colocan en `w_field.py` (`w.chests`).
- **Forja de Kara la herrera** (puesto de armas del mercado, **E**): mejora cualquier pieza que lleves puesta de +1 a +10 con oro y materiales de los monstruos (gel, abalorios, pieles y los trofeos de los jefes para los niveles altos). Cada mejora sube ataque o defensa (~20 % de la base, mínimo 1) y algo de vida o maná. Costos en `GameData.FORGE_COSTS`.

### Cazadores del Gremio y ranking
- En la Llanura hay **10 cazadores** (`scripts/npc/hunter.gd`) con nombre y nivel sobre la cabeza: unos pelean junto a las manadas (los monstruos les responden; si caen, se retiran y vuelven más tarde), otros recorren los caminos caminando o corriendo. Saludan, comentan y se puede hablar con ellos (**E**). Usan los 9 aspectos del espadachín.
- **Renombre**: se gana cazando (más con **racha**: presas seguidas con menos de 6 s entre una y otra, hasta +90 %), con pedidos, contratos y cofres. Las presas que remata otro cazador no te dan recompensa: suman a su renombre.
- **Rangos del Gremio** E → D → C → B → A → S; cada ascenso da oro, pociones y una pieza de equipo.
- **Tablón del Gremio** (E en el Gremio): pestañas **Pedidos**, **Contratos** (3 encargos repetibles que se renuevan al cobrarlos; se pueden cambiar pagando oro) y **Ranking** (los cazadores de Valdoria; también suben con el tiempo y avisa cuando superas a alguien).
- Datos en `GameData.HUNTERS`, `GUILD_RANKS` y `CONTRACT_POOL`.

### Inicio, casa y primeros pasos
- La partida empieza en **tu casa** (`scenes/interiors/home.tscn`, una casa de la ciudad). Frente al dormitorio puedes **descansar** (E): recuperas todo y se guarda la partida.
- Al salir por primera vez: "Bienvenido a Valdoria" y dos líneas de la mensajera del Gremio. Después solo hay un **objetivo** discreto bajo el minimapa (Gremio → licencia con la maestra Ysolde → aceptar un pedido → salir a la Llanura) y algún consejo puntual. Nada bloquea al jugador.

### Combate: objetivo y ataque en movimiento
- **Tab** fija la presa más cercana (anillo y flecha sobre ella, y su ficha encima de la barra de acciones); **rueda del ratón** cambia de presa; Tab otra vez la suelta. Con objetivo, el golpe, la Embestida y el Tajo de luz apuntan hacia él.
- Se puede **atacar caminando o corriendo** (animaciones `walk_attack` / `run_attack`).

### Eventos: jefes colosales
- En la Llanura, cada 4–7 minutos aparece un **jefe colosal** (Gólem, Ent o Rey Limo, más grande y con 5× de vida) en una zona. Aviso en pantalla, temporizador bajo el minimapa y marca en el mapa.
- Los cazadores del Gremio acuden a pelear. Si lo golpeaste y sigues en pie cuando cae, te llevas el **botín**: oro, materiales del jefe, una pieza de equipo mejorada, renombre y experiencia. Si nadie lo vence en 5 minutos, se retira. (`scripts/world/event_director.gd`)

### Establo
- En las Granjas del Este, **Bruno, el mozo de cuadra** (junto al granero), vende el **ciervo de monta** (3000 oro, licencia D; H para montar, más rápido y sin estamina) y **compañeros**: Zorro rojo (2000, licencia D) y Jabalí de guerra (5000, licencia C). El compañero te sigue y ataca a tu objetivo o a lo que te ataque. En el potrero se ven los animales.
- No hay sprites de caballo en los packs: el ciervo hace de montura hasta tener uno.

### Guardado
- **Guardar partida** en el menú de pausa y **guardado automático cada 3 minutos** (`Game.AUTOSAVE_INTERVAL`).
- **Continuar** en el menú principal carga la partida: mapa, posición, nivel, objetos, equipo, habilidades, talentos y pedidos.
- El archivo es `user://partida.json` (en Windows: `%APPDATA%/Godot/app_userdata/Crónicas del Cazador/`).

### Interfaz
La UI usa el pack de `assets/ui/pack/`: retrato con barras de vida/maná/estamina, nivel y experiencia, oro y pociones, barra de acciones con las habilidades y su recarga, botones y paneles del tema (`resources/theme/ui_theme.tres`).

### Interiores (`scenes/interiors/`)
Se entra caminando hacia la puerta (flecha arriba) y se sale hacia abajo:
- `guild_1f` / `guild_2f`: Gremio (maestra Ysolde, tablones de pedidos, sala de entrenamiento con magos; escalera entre pisos).
- `house_red`: casas de piedra de la ciudad y la Taberna La Gaviota del puerto.
- `farmhouse`: casa de la ciudad y de la granja. `port_house`: pescadería de la abuela Nilda.
Las puertas enterables se marcan en `tools/worldgen/w_outside.py` (`ENTERABLE`).

### Tablón de pedidos
En el Gremio, junto a los tablones de las paredes, presiona **E**. Al aceptar un pedido de caza se cuentan las presas (`Progreso 3/5`); al completarlo vuelve al tablón y pulsa **Cobrar recompensa** (oro y experiencia). Los pedidos marcados "(pronto)" aún no se pueden aceptar. Están en `Game.quests` (`scripts/autoload/game.gd`).

### Vida en la ciudad
Los NPC calculan rutas con A* sobre `resources/world/walkmask.png` (rejilla de 8 px generada con todas las colisiones; prefieren las calles) y se mueven con física, así que no atraviesan puestos, casas ni muros.
Modos: **paseantes** (caminan entre puntos con pausas), **vecinos quietos** (pasan largos ratos en su lugar y solo dan cortos paseos) y **guardias** (patrullan).

- ~52 caminantes recorren la red de calles. Unos 28 tienen **rutinas**: entran y salen de sus casas, van a comprar a los puestos (el comerciante les responde), conversan entre ellos y saludan al jugador.
- 5 **guardias** patrullan los portones y avenidas.
- Comerciantes y personajes fijos pregonan con globos de diálogo; con **E** se habla con casi todos.

## Regiones
| Región | Escena | Niveles | Destacado |
|---|---|---|---|
| Valdoria | `world.tscn` | ciudad | Gremio, Kara (forja), establo, casa del héroe |
| Llanura de Valdoria | `field.tscn` | 1–16 | Ruinas, campamento (refugio), jefes Gólem, Ent y Rey Limo |
| Bosque Profundo | `forest.tscn` | 16–32 | Puesto del guardabosques (refugio), Gólem de Obsidiana |
| Desierto de Ámbar | `desert.tscn` | 30–50 | Oasis de Zafira (refugio), Guardián del Sol |
| Aurelia | `aurelia.tscn` | ciudad | Ciudad dorada con canales, Doran (forja), archivista Leandra |
| Bosque Nevado | `snowforest.tscn` | 50–70 | Linde Helada (refugio), Rey Limo de Escarcha, Ent Invernal |
| Villa Escarcha | `snowvillage.tscn` | ciudad | Plaza del Fuego, Bjorn (forja), anciana Freya |
| Páramo del Ocaso | `ocaso.tscn` | 72–90 | Post-game, al este de Aurelia: Puesto del Crepúsculo (refugio), acólitos del Sol Negro, Ent Corrupto Anciano |

## Clases (`GameData.CLASSES`, `scripts/ui/class_select.gd`)
Al empezar partida se elige **Guerrero** (espada, +15 % vida y +2 defensa), **Arquero** (flechas a
distancia, +8 % velocidad y +6 % crítico) o **Mago** (bolas de fuego que estallan, +40 maná y +20 %
de daño de habilidades). Cada clase tiene nueve aspectos según el nivel (sprites en
`assets/sprites/characters/{swordsman,archer,mage}`, generados con `tools/worldgen/gen_classes.py`) y
seis habilidades propias (`GameData.ARCHER_SKILLS` / `MAGE_SKILLS`): abanico, salto atrás, ojo de
halcón, flecha explosiva, lluvia y flecha perforante; bola de fuego, parpadeo, barrera, cadena de
rayos, nova de escarcha y meteoro. Proyectiles en `scripts/fx/projectile.gd`, efectos animados en
`scripts/fx/anim_fx.gd` (rayos y explosiones de los packs de efectos). Aldric, en el segundo piso del
Gremio, cambia la clase (el primer cambio es gratis; luego 500 de oro) y lo aprendido se conserva.

## Historia: «Crónica del Quinto Viento»
Un cazador que empieza tarde (rango E «a su edad») tumba al Gólem de las Ruinas y llama la atención de
los Cuatro Vientos, el grupo más fuerte de Valdoria: Brann Rompemuros, Seren Llamagris, Corvin
Sinsombra y Madre Tova. Lo entrenan «hasta caer» mientras alguien rompe los tres Sellos (Estrella, Luna
y Sol) que encierran al Devorador de Eclipses: Varian, el primer alumno de los Vientos. Al final el
novato tardío se convierte en el que entrena (Darío, el chico que se reía de él, le pide ser su alumno).
7 capítulos y 28 pasos: hablar, cazar (algunos con contador, p. ej. 10 gnolls), viajar y superar
mazmorras. El elenco aparece y se mueve por el mundo según avanza la historia (`GameData.STORY_CAST`,
`scripts/world/story_cast.gd`). El objetivo se ve bajo el minimapa, con una estrella dorada en el
minimapa (o una flecha hacia la salida que lleva a él) y en el mapamundi; se relee en el bestiario
(B) → Crónica. Las partidas con la historia anterior se convierten solas (`story_ver`).
Datos: `GameData.STORY`; lógica: `story_*` en `game.gd`.

## Mazmorras de oleadas (`scenes/dungeons/`, `scripts/world/dungeon.gd`)
Un portal por región: Cripta de las Ruinas (12), Raíces del Bosque (26), Tumba del Faraón (42),
Cripta de Escarcha (60) y el Santuario del Eclipse (70, se abre con la historia). Cinco oleadas
(élites dorados en la 3.ª y 4.ª, el jefe en la última), rango S/A/B/C por tiempo y golpes recibidos,
cofre con una pieza del set de la región y equipo con buenas probabilidades de rareza. Modo heroico
(+8 niveles, más botín) tras la primera victoria. Morir dentro devuelve al portal sin castigo.
Además: Cloacas de Valdoria (6, en el puerto), Oasis Hundido (36, desierto) y la Fosa del Ocaso
(84, con el Heraldo del Sol Negro).

## Post-game
- **Capítulo 8, «Ecos del Sol Negro»**: tras la historia, Varian despierta en el Gremio y lleva al
  Páramo del Ocaso (acólitos, el Ent Corrupto Anciano y la Fosa del Ocaso).
- **Torre del Abismo** (portal junto al Gremio; se abre al terminar la historia o en el nivel 60):
  pisos infinitos de 3 oleadas que rotan entre las cinco arenas, el nivel sube 2 por piso, jefe
  cada 5 pisos y punto de control cada 10. Récord en `stats.tower_best`; títulos en los pisos 10/25/50.
- **Niveles de leyenda**: pasado el nivel 99 la experiencia sigue contando; cada nivel de leyenda da
  un punto de talento (se ve como «Nv 99 ★N»).

## Equipo
- **Rareza**: Común < Rara < Épica < Legendaria < **Sello de Estrella (SOS)** < **Sello de Luna (SOM)** <
  **Sello de Sol (SOSUN)**. Los Sellos tienen más atributos, más bonus y un poder propio
  (estrella que cae, marea que cura, fuego solar). Ver `GameData.SEALS`.
- **Forja +5/+8/+10**: cada familia de arma despierta un efecto (quemadura, veneno, desgarro,
  aturdir, perforar, viento cortante, corte doble, siega de almas, tormenta) y la armadura gana un
  bonus por ranura. A +8/+10 el héroe muestra un aura del elemento.
- **Sets** (`GameData.SETS`): Guardia de Valdoria, Sombra del Bosque, Vestiduras del Sol, Coraza del
  Invierno y Reliquias del Eclipse; bonus con 2 y 4 piezas. Caen en mazmorras y de los jefes.

## Pruebas automáticas (`tools/tests/`)
`CDC_TEST=1 Godot --path . --resolution 960x540 --script tools/tests/<prueba>.gd` (con `CDC_TEST=1`
usan una partida de prueba y nunca tocan la real). `playtest_reach` comprueba que se puede llegar a
cada cofre, piedra, salida y PNJ; `playtest_fuzz` juega al azar en todas las regiones;
`story_test` recorre la historia entera; `story_real` juega de verdad el entrenamiento de Brann
(10 gnolls a espadazos); `cast_test` visita cada aparición del elenco; `collision_audit` compara la
navegación con las colisiones reales de cada región (paredes olvidadas, cosas dentro de muros,
bordes por los que se escapa el héroe); `dungeon_real` pelea una mazmorra de verdad.

## Modo desarrollador (editor de mapas)
Menú principal → **Modo desarrollador** → clave. Abre el mundo congelado (NPC quietos) con el editor encima.

| Herramienta | Uso |
|---|---|
| Seleccionar [V] | Clic para elegir objeto/NPC/animal, arrastrar para mover (Shift = sin ajuste a grilla). F voltear, Ctrl+D duplicar, Supr eliminar |
| Objetos [O] | Paleta por categorías con buscador. Clic en el mapa para colocar (con su colisión). Clic derecho suelta el objeto |
| Pintar tiles [B] | **Plantillas** listas de muelle (tablones, pasarela, postes, pilotes) y vallas (madera, cerca de granja). O elige capa y hoja: clic en un tile, o **mantén el clic y arrastra** sobre la paleta para tomar un bloque de varios tiles. Al pintar arrastrando, el bloque se repite como patrón. Clic derecho borra. "Tile con colisión" lo vuelve sólido |
| Terreno [T] | Pinceles con bordes automáticos: camino empedrado, sendero, tierra de cultivo, pavimento, pasto, agua |
| Goma [E] | Borra tiles de la capa elegida (tamaño de pincel ajustable) |

Cámara: WASD/flechas o botón central del mouse; rueda = zoom. **Ctrl+Z** deshace, **Ctrl+S** guarda.
Guardar escribe `scenes/world/world.tscn` (y el tileset si se crearon tiles nuevos) y recalcula la navegación de los NPC en `resources/world/walkmask.res`.
**Probar aquí** salta a jugar desde la cámara; **F1** vuelve al editor (los NPC regresan a su sitio).
Nota: guardar requiere ejecutar el juego desde la carpeta del proyecto (no funciona en un build exportado).
Si vuelves a ejecutar el generador (`tools/worldgen`), sobrescribe los cambios hechos con el editor.

## Notas técnicas
- Capas de tiles: `Water`, `Ground`, `Road`, `Walls`, `Fence`, etc. `Solids` es invisible y bloquea el mar y los cultivos.
- `Entities` usa Y-sort: edificios y objetos son `StaticBody2D` con la colisión solo en su base.
- `tools/worldgen/` contiene el generador en Python que construyó el mundo (Godot lo ignora): `python w_export.py` (ciudad), `python w_interiors_export.py` (interiores) y `python w_field.py` (llanura). **Ojo:** volver a ejecutarlo sobrescribe los `.tscn`.
- El editor de mapas trabaja sobre la ciudad (`world.tscn`).
