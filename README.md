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
| Poción (+4 de vida) | Q | Y |
| Hablar | E / Enter | A |
| Pausa | Esc | Start |

## Estructura
```
assets/        sprites originales (mercado, espadachín lvl1-3, naturaleza) + licencias
resources/     tileset del mercado, SpriteFrames, tema de UI
scenes/
  ui/          menú principal, HUD (diálogos), pausa, opciones
  world/       world.tscn (Valdoria), field.tscn (la llanura)
  monsters/    monster.tscn (IA, vida, golpes, reaparición)
  characters/  player.tscn
  npc/         trader.tscn (comerciante), citizen.tscn (ciudadano que pasea)
scripts/       mismo orden que scenes/ + autoload/game.gd (transiciones, ajustes)
```

## Capas de colisión
1 `world` · 2 `player` · 3 `npc` · 4 `interactable` · 5 `enemy_hurtbox` (zona de golpe de los monstruos)

## El mundo: Valdoria (`scenes/world/world.tscn`)
Mapa continuo de 180×140 tiles:
- **Ciudadela** (centro): murallas con torres y 4 portones, plaza-mercado con fuente, puestos, taberna, músicos, el **Gremio de Cazadores (Guild Hall)**, avenidas empedradas y casas.
- **Puerto de Valdoria** (sur): malecón de tablones con barandas de madera, camino costero, bodegas y tabernas frente al mar, mercado de pescado, muelles con barcos, rompeolas con faro. El sendero costero continúa por la costa natural.
- **Pradera del Norte**, **Cuartel de la Guardia** (oeste) y **Granjas del Este**.
- El portón norte lleva a la **Llanura de Valdoria**.

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
- Correr gasta estamina (barra verde). Si la vida llega a 0, despiertas en la entrada de la llanura con la vida llena.
- La salida sur de la llanura vuelve al portón norte de la ciudad.

### Interfaz
La UI usa el pack de `assets/ui/pack/`: retrato con barras de vida/maná/estamina, oro y pociones, barra de acciones, botones y paneles del tema (`resources/theme/ui_theme.tres`).

### Interiores (`scenes/interiors/`)
Se entra caminando hacia la puerta (flecha arriba) y se sale hacia abajo:
- `guild_1f` / `guild_2f`: Gremio (maestra Ysolde, tablones de pedidos, sala de entrenamiento con magos; escalera entre pisos).
- `house_red`: casas de piedra de la ciudad y la Taberna La Gaviota del puerto.
- `farmhouse`: casa de la ciudad y de la granja. `port_house`: pescadería de la abuela Nilda.
Las puertas enterables se marcan en `tools/worldgen/w_outside.py` (`ENTERABLE`).

### Tablón de pedidos
En el Gremio, junto a los tablones de las paredes, presiona **E**. Los pedidos están en `Game.quests` (`scripts/autoload/game.gd`); aceptar uno lo marca "En curso".

### Vida en la ciudad
Los NPC calculan rutas con A* sobre `resources/world/walkmask.png` (rejilla de 8 px generada con todas las colisiones; prefieren las calles) y se mueven con física, así que no atraviesan puestos, casas ni muros.
Modos: **paseantes** (caminan entre puntos con pausas), **vecinos quietos** (pasan largos ratos en su lugar y solo dan cortos paseos) y **guardias** (patrullan).

- ~52 caminantes recorren la red de calles. Unos 28 tienen **rutinas**: entran y salen de sus casas, van a comprar a los puestos (el comerciante les responde), conversan entre ellos y saludan al jugador.
- 5 **guardias** patrullan los portones y avenidas.
- Comerciantes y personajes fijos pregonan con globos de diálogo; con **E** se habla con casi todos.

## Modo desarrollador (editor de mapas)
Menú principal → **Modo desarrollador** → clave. Abre el mundo congelado (NPC quietos) con el editor encima.

| Herramienta | Uso |
|---|---|
| Seleccionar [V] | Clic para elegir objeto/NPC/animal, arrastrar para mover (Shift = sin ajuste a grilla). F voltear, Ctrl+D duplicar, Supr eliminar |
| Objetos [O] | Paleta por categorías con buscador. Clic en el mapa para colocar (con su colisión). Clic derecho suelta el objeto |
| Pintar tiles [B] | Elige capa y hoja, clic en el tile. Clic pinta, clic derecho borra. "Tile con colisión" lo vuelve sólido |
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
